package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.AppOpsManager;
import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.Settings;
import java.util.List;

/** On-demand reads in the app UID. Never executes shell commands or opens settings. */
final class FileStorageDiagnostics {
    private static final int LIMIT = 20;
    private FileStorageDiagnostics() {}

    @SuppressWarnings("deprecation")
    static String collect(Context context) {
        var out = new StringBuilder();
        var pm = context.getPackageManager();
        String own = context.getPackageName();
        out.append("scope=app UID (not ADB)\npackage=").append(own).append('\n');
        section(out, "version", () -> {
            var info = pm.getPackageInfo(own, 0);
            return info.versionName + "+" + info.getLongVersionCode();
        });
        out.append("\nAndroid=").append(Build.VERSION.RELEASE).append(" API=").append(Build.VERSION.SDK_INT)
            .append("\ndevice=").append(Build.MANUFACTURER).append(' ').append(Build.MODEL)
            .append("\nfirmware=").append(Build.DISPLAY).append('\n');
        section(out, "allFilesAccess", () -> Build.VERSION.SDK_INT >= 30
                ? Boolean.toString(Environment.isExternalStorageManager()) : "not applicable (API < 30)");
        section(out, "MANAGE_EXTERNAL_STORAGE AppOps", () -> {
            if (Build.VERSION.SDK_INT < 30) return "not applicable (API < 30)";
            var ops = context.getSystemService(AppOpsManager.class);
            if (ops == null) return "unavailable";
            String op = AppOpsManager.permissionToOp(Manifest.permission.MANAGE_EXTERNAL_STORAGE);
            if (op == null) return "unavailable (no permission mapping)";
            int mode = ops.checkOpNoThrow(op,
                    context.getApplicationInfo().uid, own);
            return switch (mode) {
                case AppOpsManager.MODE_ALLOWED -> "allow";
                case AppOpsManager.MODE_IGNORED -> "ignore";
                case AppOpsManager.MODE_ERRORED -> "deny";
                case AppOpsManager.MODE_DEFAULT -> "default";
                case AppOpsManager.MODE_FOREGROUND -> "foreground";
                default -> "mode=" + mode;
            };
        });
        for (String permission : new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.MANAGE_EXTERNAL_STORAGE}) {
            section(out, permission, () -> context.checkSelfPermission(permission)
                    == PackageManager.PERMISSION_GRANTED ? "granted" : "not granted");
        }
        for (String pkg : new String[]{own, "com.alphainventor.filemanager"}) {
            section(out, pkg.equals(own) ? "CuteLauncher" : "FM+", () -> {
                var info = pm.getPackageInfo(pkg, PackageManager.GET_PERMISSIONS);
                var summary = new StringBuilder().append(info.versionName)
                        .append(" targetSdk=").append(info.applicationInfo.targetSdkVersion);
                for (String permission : new String[]{Manifest.permission.READ_EXTERNAL_STORAGE,
                        Manifest.permission.WRITE_EXTERNAL_STORAGE, Manifest.permission.MANAGE_EXTERNAL_STORAGE}) {
                    boolean declared = info.requestedPermissions != null
                            && java.util.Arrays.asList(info.requestedPermissions).contains(permission);
                    summary.append('\n').append(permission.substring("android.permission.".length()))
                            .append(declared ? " declared" : " absent")
                            .append(pm.checkPermission(permission, pkg) == PackageManager.PERMISSION_GRANTED
                                    ? " granted" : " not granted");
                }
                return summary.toString();
            });
        }
        handlers(out, context, "APP_DETAILS", new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.parse("package:" + own)));
        section(out, "tguard", () -> {
            var info = pm.getPackageInfo("com.tcl.guard", PackageManager.MATCH_DISABLED_COMPONENTS);
            ApplicationInfo app = info.applicationInfo;
            return info.versionName + " enabled=" + (app != null && app.enabled)
                    + " setting=" + pm.getApplicationEnabledSetting("com.tcl.guard");
        });
        Intent app = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:" + own));
        handlers(out, context, "APP_ALL_FILES (implicit)", app);
        for (String settings : new String[]{"com.android.tv.settings", "com.android.settings"}) {
            handlers(out, context, "APP_ALL_FILES " + settings, new Intent(app).setPackage(settings));
            handlers(out, context, "ALL_FILES_LIST " + settings,
                    new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).setPackage(settings));
        }
        handlers(out, context, "ALL_FILES_LIST (implicit)",
                new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
        out.append("\nTV page without intent filter:\n");
        section(out, "AllFilesAccessActivity", () -> describe(context, pm.getActivityInfo(
                new ComponentName("com.android.tv.settings",
                    "com.android.tv.settings.device.apps.specialaccess.AllFilesAccessActivity"),
                PackageManager.MATCH_DISABLED_COMPONENTS)));
        return out.toString();
    }

    @SuppressWarnings("deprecation")
    private static void handlers(StringBuilder out, Context context, String label, Intent intent) {
        out.append('\n').append(label).append(':').append('\n');
        var pm = context.getPackageManager();
        section(out, "resolved", () -> {
            var match = pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
            return match == null || match.activityInfo == null ? "none visible" : describe(context, match.activityInfo);
        });
        try {
            List<ResolveInfo> matches = pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY);
            out.append("handlers=").append(matches.size()).append('\n');
            for (int i = 0; i < Math.min(matches.size(), LIMIT); i++) {
                var match = matches.get(i);
                if (match.activityInfo != null) out.append(describe(context, match.activityInfo))
                    .append(" priority=").append(match.priority).append('\n');
            }
            if (matches.size() > LIMIT) out.append("[truncated after ").append(LIMIT).append("]\n");
        } catch (RuntimeException error) {
            out.append("handlers=unavailable (").append(error.getClass().getSimpleName()).append(")\n");
        }
    }

    private static String describe(Context context, ActivityInfo info) {
        boolean enabled = info.enabled && info.applicationInfo != null && info.applicationInfo.enabled;
        boolean permitted = info.permission == null || context.checkSelfPermission(info.permission)
                == PackageManager.PERMISSION_GRANTED;
        return new ComponentName(info.packageName, info.name).flattenToShortString()
            + " enabled=" + enabled + " exported=" + info.exported + " permitted=" + permitted;
    }

    private interface Read { String get() throws Exception; }
    private static void section(StringBuilder out, String label, Read read) {
        out.append(label).append('=');
        try { out.append(read.get()); }
        catch (Exception error) { out.append("unavailable (").append(error.getClass().getSimpleName()).append(')'); }
        out.append('\n');
    }
}
