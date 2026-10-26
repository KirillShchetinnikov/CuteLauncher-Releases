package com.leanbitlab.ltvL;

import android.app.ActivityManager;
import android.app.ApplicationExitInfo;
import android.content.Context;
import java.util.ArrayList;

/** Local crash journal, deliberately separate from exported Flutter preferences. */
final class CrashLoopGuard {
    private CrashLoopGuard() {}
    private static volatile Boolean inspectedBlocked;
    static Boolean inspectedState() { return inspectedBlocked; }
    private static android.content.SharedPreferences prefs(Context c) {
        return c.getSharedPreferences("crash_loop", Context.MODE_PRIVATE);
    }
    static synchronized boolean inspect(Context c) {
        if (inspectedBlocked != null) return inspectedBlocked;
        var p = prefs(c);
        // A killed recovery worker is retried on the next cold native entry.
        if ("running".equals(p.getString("cleaner_restore", "")))
            p.edit().remove("cleaner_restore").commit();
        long now = System.currentTimeMillis();
        if (!p.contains("since")) p.edit().putLong("since", now).commit();
        long since = p.getLong("since", now), seen = p.getLong("seen", since);
        var events = events(c);
        if (android.os.Build.VERSION.SDK_INT >= 30) try {
            var manager = (ActivityManager)c.getSystemService(Context.ACTIVITY_SERVICE);
            for (var exit : manager.getHistoricalProcessExitReasons(c.getPackageName(), 0, 32)) {
                if (!c.getPackageName().equals(exit.getProcessName()) || exit.getTimestamp() <= since
                        || exit.getTimestamp() <= p.getLong("seen", since)) continue;
                seen = Math.max(seen, exit.getTimestamp());
                int reason = exit.getReason();
                if (exit.getPid() != p.getInt("dart_pid", -1)
                        && (reason == ApplicationExitInfo.REASON_CRASH
                        || reason == ApplicationExitInfo.REASON_CRASH_NATIVE
                        || reason == ApplicationExitInfo.REASON_ANR)) events.add(exit.getTimestamp());
            }
        } catch (RuntimeException unavailable) {
            android.util.Log.w("CrashLoopGuard", "Exit history unavailable");
        }
        var recent = CrashLoopPolicy.recent(events, now);
        boolean blocked = p.getBoolean("blocked", false) || CrashLoopPolicy.blocked(recent, now);
        save(c, recent, blocked, seen);
        inspectedBlocked = blocked;
        return blocked;
    }
    static synchronized boolean dartFailure(Context c) {
        var p = prefs(c);
        int pid = android.os.Process.myPid();
        if (p.getInt("dart_pid", -1) == pid) return p.getBoolean("blocked", false);
        var events = events(c);
        events.add(System.currentTimeMillis());
        var recent = CrashLoopPolicy.recent(events, System.currentTimeMillis());
        boolean blocked = p.getBoolean("blocked", false) || CrashLoopPolicy.blocked(recent, System.currentTimeMillis());
        p.edit().putInt("dart_pid", pid).commit();
        save(c, recent, blocked, p.getLong("seen", 0));
        inspectedBlocked = blocked;
        return blocked;
    }
    private static ArrayList<Long> events(Context c) {
        var out = new ArrayList<Long>();
        for (String value : prefs(c).getString("events", "").split(",")) {
            try { out.add(Long.parseLong(value)); } catch (NumberFormatException ignored) { }
        }
        return out;
    }
    private static void save(Context c, java.util.List<Long> events, boolean blocked, long seen) {
        var encoded = new StringBuilder();
        for (long at : events) encoded.append(at).append(',');
        prefs(c).edit().putString("events", encoded.toString()).putBoolean("blocked", blocked)
            .putLong("seen", seen).commit();
    }
    static synchronized void retry(Context c) {
        prefs(c).edit().clear().putLong("since", System.currentTimeMillis()).commit();
        inspectedBlocked = false;
    }
    static synchronized boolean claimCleanerRestore(Context c) {
        var p = prefs(c);
        if (!p.getBoolean("blocked", false) || !p.getString("cleaner_restore", "").isEmpty()) return false;
        return p.edit().putString("cleaner_restore", "running").commit();
    }
    static synchronized String cleanerRestoreStatus(Context c) { return prefs(c).getString("cleaner_restore", ""); }
    static synchronized void cleanerRestoreFinished(Context c, String status) {
        prefs(c).edit().putString("cleaner_restore", status).commit();
    }
}
