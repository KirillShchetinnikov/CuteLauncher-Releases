package com.leanbitlab.ltvL;

import android.app.AppOpsManager;
import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Process;
import android.provider.Settings;

final class OverlayPermission {
    static boolean granted(Context context) {
        try {
            AppOpsManager ops = context.getSystemService(AppOpsManager.class);
            int mode = rawMode(ops, context);
            // canDrawOverlays also has OEM/default-mode exemptions; they are not an explicit grant.
            boolean allowed = mode == AppOpsManager.MODE_ALLOWED || (mode == AppOpsManager.MODE_DEFAULT
                    && context.checkSelfPermission(android.Manifest.permission.SYSTEM_ALERT_WINDOW)
                    == PackageManager.PERMISSION_GRANTED);
            return allowed && Settings.canDrawOverlays(context);
        } catch (RuntimeException e) { return false; }
    }

    @SuppressWarnings("deprecation") // Raw mode has no replacement before API 36.
    private static int rawMode(AppOpsManager ops, Context context) {
        if (android.os.Build.VERSION.SDK_INT >= 36) {
            return ops.checkOpRawNoThrow(AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW,
                    Process.myUid(), context.getPackageName(), null);
        }
        return ops.unsafeCheckOpRawNoThrow(AppOpsManager.OPSTR_SYSTEM_ALERT_WINDOW,
                Process.myUid(), context.getPackageName());
    }
}
