package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.os.Build;

/** Entry point for the firmware's own Audio Only countdown. */
final class TclScreenOff {
    private static final String ACTION = "com.tcl.settings.SHOW_WINDOW";
    private static final ComponentName SERVICE = new ComponentName(
        "com.android.tv.settings", "com.tcl.settings.ShowWindowService");
    private static final String TYPE = "Type";
    private static final String AUDIO_ONLY = "AudioOnly";
    static final String SHELL_COMMAND = "am startservice -a " + ACTION + " -n "
        + SERVICE.flattenToShortString() + " --es " + TYPE + " " + AUDIO_ONLY;

    static Intent intent() {
        return new Intent(ACTION).setComponent(SERVICE).putExtra(TYPE, AUDIO_ONLY);
    }

    static boolean available(Context context) {
        if (!"TCL".equalsIgnoreCase(Build.MANUFACTURER)) return false;
        var resolved = context.getPackageManager().resolveService(intent(), PackageManager.MATCH_SYSTEM_ONLY);
        return resolved != null && resolved.serviceInfo.exported && resolved.serviceInfo.permission == null;
    }
}
