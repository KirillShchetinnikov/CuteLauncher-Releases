package com.leanbitlab.ltvL;

import android.app.AppOpsManager;
import android.app.usage.UsageEvents;
import android.app.usage.UsageStatsManager;
import android.content.Context;
import android.os.Process;
import android.os.Build;

/** Bounded, incremental foreground history; used only while night exclusions are active. */
final class NightForegroundTracker {
    private long cursor;
    private String current;
    static boolean allowed(Context context) {
        try {
            AppOpsManager ops = context.getSystemService(AppOpsManager.class);
            int mode = ops.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), context.getPackageName());
            return mode == AppOpsManager.MODE_ALLOWED || mode == AppOpsManager.MODE_DEFAULT
                && context.checkSelfPermission(android.Manifest.permission.PACKAGE_USAGE_STATS)
                    == android.content.pm.PackageManager.PERMISSION_GRANTED;
        } catch (RuntimeException ignored) { return false; }
    }
    void reset() { cursor = 0; current = null; }
    String read(Context context, long now) {
        if (!allowed(context)) { reset(); return null; }
        try {
            long start = cursor == 0 || cursor > now ? now - 86400000L : Math.max(0, cursor - 1);
            UsageEvents events = context.getSystemService(UsageStatsManager.class).queryEvents(start, now);
            if (events == null) { reset(); return null; }
            UsageEvents.Event event = new UsageEvents.Event();
            int count = 0;
            while (events.hasNextEvent()) {
                if (++count > 20000) { reset(); return null; }
                events.getNextEvent(event);
                accept(event.getEventType(), event.getPackageName());
            }
            cursor = now;
            return current;
        } catch (RuntimeException ignored) { reset(); return null; }
    }
    void accept(int type, String packageName) {
        if (type == UsageEvents.Event.ACTIVITY_RESUMED) current = packageName;
        else if (type == UsageEvents.Event.SCREEN_NON_INTERACTIVE) current = null;
    }
    String current() { return current; }
}
