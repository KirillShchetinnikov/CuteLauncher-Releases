package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Looper;
import android.os.SystemClock;
import java.io.File;
import dadb.AdbKeyPair;
import dadb.Dadb;
import org.json.JSONObject;

/** Read-only fallback using the existing, explicitly verified localhost ADB connection. */
final class AdbEthernetUsage {
    private static final EthernetUsageCache CACHE = new EthernetUsageCache();
    static synchronized long[] readBreakdown(Context context, long start, long end) {
        if (read(context, start, end) < 0) return new long[]{NetworkUsageTotals.UNAVAILABLE, NetworkUsageTotals.UNAVAILABLE};
        return CACHE.breakdown(start, end);
    }
    static long read(Context context, long start, long end) {
        if (Looper.myLooper() == Looper.getMainLooper()) return NetworkUsageTotals.UNAVAILABLE;
        var saved = context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE);
        int port = saved.getInt("port", 5555);
        File privateKey = new File(context.getNoBackupFilesDir(), "adb/private-key");
        File publicKey = new File(context.getNoBackupFilesDir(), "adb/public-key");
        try {
            String status = new JSONObject(saved.getString("connection_snapshot", "{}")).optString("status");
            if (!status.equals("ready") || saved.getBoolean("tls", false) || port < 1024 || port > 65535
                    || !privateKey.isFile() || !publicKey.isFile()) return NetworkUsageTotals.UNAVAILABLE;
        } catch (Exception unavailable) { return NetworkUsageTotals.UNAVAILABLE; }
        return CACHE.read(start, end, SystemClock.elapsedRealtime(), () -> {
            synchronized (AdbBridge.LOCK) {
                // 35 days cover a calendar month plus buckets crossing the starting boundary.
                // No UID/tag history, forced polling, arbitrary shell input or permission changes.
                try (Dadb adb = Dadb.create("127.0.0.1", port, AdbKeyPair.read(privateKey, publicKey), 3000, 8000)) {
                    var response = NativeShellDiagnostics.execute(adb, "dumpsys -t 5 netstats --checkin --duration=3024000000 | head -c 1048577", "networkUsage");
                    if (response.getExitCode() != 0) throw new IllegalStateException("History unavailable");
                    return response.getOutput();
                }
            }
        });
    }
    private AdbEthernetUsage() { }
}
