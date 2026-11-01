package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Looper;
import android.os.SystemClock;
import dadb.AdbKeyPair;
import dadb.Dadb;
import java.io.File;
import java.util.concurrent.atomic.AtomicBoolean;
import org.json.JSONObject;

/** Fixed read-only fallback. Never creates keys, enables ADB or opens its setup screen. */
final class SystemCpuAdb {
    private static final AtomicBoolean READING = new AtomicBoolean();
    private long retryAfter;

    String read(Context context) {
        if (Looper.myLooper() == Looper.getMainLooper() || SystemClock.elapsedRealtime() < retryAfter) return null;
        var saved = context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE);
        int port = saved.getInt("port", 5555);
        File privateKey = new File(context.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(context.getNoBackupFilesDir(), "adb/public-key");
        try {
            String status = new JSONObject(saved.getString("connection_snapshot", "{}")).optString("status");
            if (!status.equals("ready") || saved.getBoolean("tls", false) || port < 1024 || port > 65535
                    || !privateKey.isFile() || !publicKey.isFile()) return null;
        } catch (Exception unavailable) { return null; }
        if (!READING.compareAndSet(false, true)) return null;
        // A separate read-only connection never waits behind long ADB management operations.
        try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 750, 750)) {
            var response = NativeShellDiagnostics.execute(adb, "head -n 1 /proc/stat", "systemCpu");
            if (response.getExitCode() != 0 || response.getOutput().length() > 1024) {
                retryAfter = SystemClock.elapsedRealtime() + 30000;
                return null;
            }
            return response.getOutput().trim();
        } catch (Exception | LinkageError unavailable) {
            retryAfter = SystemClock.elapsedRealtime() + 30000;
            NativeShellDiagnostics.failure("systemCpu", unavailable);
            return null;
        } finally { READING.set(false); }
    }
}
