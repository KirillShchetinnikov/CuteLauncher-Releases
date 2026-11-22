package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

/** UID policy for local ADB. Warning state is local to this installation. */
final class AdbShellIdentity {
    static final String NOTICE_EVENT = "adb_root_warning";
    private static final String STATE = "root_warning";
    private static final int PENDING = 1;
    private static final int SHOWN = 2;

    static boolean supported(String uid) {
        return "2000".equals(uid) || "0".equals(uid);
    }

    static boolean supported(Context context, String uid) {
        observe(context, uid);
        return supported(uid);
    }

    static synchronized void observe(Context context, String uid) {
        if (!"0".equals(uid)) return;
        var prefs = context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE);
        if (prefs.getInt(STATE, 0) != 0) return;
        prefs.edit().putInt(STATE, PENDING).apply();
        new Handler(Looper.getMainLooper()).post(LauncherActivity::adbRootWarning);
    }

    static boolean warningPending(Context context) {
        return context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE)
            .getInt(STATE, 0) == PENDING;
    }

    static synchronized boolean takeWarning(Context context) {
        if (!warningPending(context)) return false;
        context.getSharedPreferences("adb_connection", Context.MODE_PRIVATE)
            .edit().putInt(STATE, SHOWN).apply();
        return true;
    }
}
