package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.provider.Settings;
import java.util.HashSet;

/** Prefer the actual TV settings page over OEM catch-all permission screens. */
final class AllFilesAccessSettings {
    private AllFilesAccessSettings() {}

    static boolean open(Activity activity, int request) {
        Intent app = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:" + activity.getPackageName()));
        var tried = new HashSet<String>();
        // Try the exported TV page even when no intent filter advertises it.
        Intent tvPage = new Intent(app).setClassName("com.android.tv.settings",
                "com.android.tv.settings.device.apps.specialaccess.AllFilesAccessActivity");
        if (start(activity, tvPage, request, tried)) return true;
        for (String settings : new String[]{"com.android.tv.settings", "com.android.settings"}) {
            if (start(activity, new Intent(app).setPackage(settings), request, tried)) return true;
        }
        // The broad implicit action can be intercepted by a generic OEM permission
        // filter with no all-files switch. Only use the system settings list here.
        for (String settings : new String[]{"com.android.tv.settings", "com.android.settings"}) {
            Intent list = new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).setPackage(settings);
            if (start(activity, list, request, tried)) return true;
        }
        return start(activity, app, request, tried);
    }

    private static boolean start(Activity activity, Intent intent, int request,
            HashSet<String> tried) {
        try {
            var pm = activity.getPackageManager();
            ActivityInfo info;
            if (intent.getComponent() != null) info = pm.getActivityInfo(intent.getComponent(), 0);
            else {
                var resolved = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
                if (resolved == null || resolved.activityInfo == null) return false;
                info = resolved.activityInfo;
            }
            if (!info.enabled || !info.exported || info.applicationInfo == null || !info.applicationInfo.enabled
                    || info.permission != null && activity.checkSelfPermission(info.permission)
                    != PackageManager.PERMISSION_GRANTED) return false;
            var target = new ComponentName(info.packageName, info.name);
            if (!tried.add(intent.getAction() + ":" + target.flattenToString())) return false;
            activity.startActivityForResult(new Intent(intent).setComponent(target), request);
            return true;
        } catch (PackageManager.NameNotFoundException | RuntimeException unavailable) {
            return false;
        }
    }
}
