package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Looper;
import android.os.SystemClock;
import androidx.annotation.Nullable;
import dadb.AdbKeyPair;
import dadb.Dadb;
import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.JSONObject;

/** Fixed read-only fallback. Never creates keys, enables ADB or opens its setup screen. */
final class SystemCpuAdb {
    record Readings(@Nullable long[] counters, @Nullable Double temperature) {}

    private static final Readings UNAVAILABLE = new Readings(null, null);
    private static final String CPU_COMMAND = "head -n 1 /proc/stat";
    private static final String TEMPERATURE_COMMAND =
            "dumpsys -t 1 hardware_properties | grep -m 1 '^CPU temperatures:'";
    private static final AtomicBoolean READING = new AtomicBoolean();
    private long retryAfter;
    private long countersRetryAfter;
    private long temperatureRetryAfter;

    Readings read(Context context, long now, boolean needCounters, boolean needTemperature) {
        boolean readCounters = needCounters && now >= countersRetryAfter;
        boolean readTemperature = needTemperature && now >= temperatureRetryAfter;
        if ((!readCounters && !readTemperature) || now < retryAfter
                || Looper.myLooper() == Looper.getMainLooper()) return UNAVAILABLE;
        var saved = context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE);
        File privateKey = new File(context.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(context.getNoBackupFilesDir(), "adb/public-key");
        int port;
        try {
            port = saved.getInt("port", 5555);
            String status = new JSONObject(saved.getString("connection_snapshot", "{}")).optString("status");
            if (!status.equals("ready") || saved.getBoolean("tls", false) || port < 1024 || port > 65535
                    || !privateKey.isFile() || !publicKey.isFile()) return UNAVAILABLE;
        } catch (Exception unavailable) { return UNAVAILABLE; }
        if (!READING.compareAndSet(false, true)) return UNAVAILABLE;
        long[] counters = null;
        Double temperature = null;
        // A separate read-only connection never waits behind long ADB management operations.
        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 750, 750)) {
            if (readCounters) {
                String line = readLine(adb, CPU_COMMAND, "systemCpu", 1024);
                counters = SystemStatusController.readCpu(() -> line);
                if (counters == null) countersRetryAfter = SystemClock.elapsedRealtime() + 30_000;
            }
            if (readTemperature) {
                try {
                    String line = readLine(adb, TEMPERATURE_COMMAND, "systemCpuTemperature", 4096);
                    temperature = SystemCpuTemperature.parseDump(line);
                } catch (Exception | LinkageError unavailable) {
                    // The shell diagnostic already recorded the failure. Keep the CPU counters.
                }
                if (temperature == null) temperatureRetryAfter = SystemClock.elapsedRealtime() + 60_000;
            }
        } catch (Exception | LinkageError unavailable) {
            retryAfter = SystemClock.elapsedRealtime() + 30_000;
            NativeShellDiagnostics.failure("systemCpu", unavailable);
        } finally { READING.set(false); }
        return new Readings(counters, temperature);
    }

    @Nullable private static String readLine(Dadb adb, String command, String source, int limit) throws Exception {
        var response = NativeShellDiagnostics.execute(adb, command, source);
        String output = response.getOutput();
        return response.getExitCode() == 0 && output.length() <= limit ? output.trim() : null;
    }
}
