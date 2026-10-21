package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.AppOpsManager;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.tv.TvInputManager;
import android.os.Build;
import android.provider.Settings;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.BooleanSupplier;

/** Build metadata and API reads only: no ADB, prompts, intent launches or settings writes. */
final class TvCompatibilityDiagnostics {
    private static String permitted(boolean value) { return value ? "available" : "notGranted"; }
    @SuppressWarnings("deprecation") // AppOps read supports Android 11+; no noteOp or permission changes.
    static Map<String, Object> collect(Activity activity, BooleanSupplier accessibility) {
        var pm = activity.getPackageManager();
        var identity = new LinkedHashMap<String, String>();
        identity.put("manufacturer", Build.MANUFACTURER);
        identity.put("model", Build.MODEL);
        identity.put("device", Build.DEVICE);
        identity.put("fingerprint", Build.FINGERPRINT);
        identity.put("firmware", Build.DISPLAY);
        identity.put("android", Build.VERSION.RELEASE);
        identity.put("sdk", Integer.toString(Build.VERSION.SDK_INT));
        identity.put("abis", String.join(",", Build.SUPPORTED_ABIS));
        boolean emulator = Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish") || Build.PRODUCT.startsWith("sdk_");
        var checks = new ReadOnlyDiagnosticChecks();
        checks.add("androidTv", () -> pm.hasSystemFeature(PackageManager.FEATURE_LEANBACK) ? "available" : "unsupported");
        checks.add("androidVersion", () -> Build.VERSION.SDK_INT >= 30 ? "available" : "unsupported");
        checks.add("homeRegistered", () -> AdbCapabilities.ownPriority(activity) != Integer.MIN_VALUE ? "available" : "unsupported");
        checks.add("defaultHome", () -> {
            var home = pm.resolveActivity(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), PackageManager.MATCH_DEFAULT_ONLY);
            if (home == null || home.activityInfo == null) return "unknown";
            return home.activityInfo.packageName.equals(activity.getPackageName()) ? "available" : "notConfigured";
        });
        checks.add("homeSelection", () -> AdbCapabilities.canHome(activity) ? "available" : "restricted");
        checks.add("overlay", () -> permitted(OverlayPermission.granted(activity)));
        checks.add("notifications", () -> permitted(activity.getSystemService(NotificationManager.class).areNotificationsEnabled()));
        checks.add("notificationListener", () -> permitted(activity.getSystemService(NotificationManager.class)
            .isNotificationListenerAccessGranted(new ComponentName(activity, LauncherNotificationListenerService.class))));
        checks.add("accessibility", () -> permitted(accessibility.getAsBoolean()));
        checks.add("writeSettings", () -> permitted(Settings.System.canWrite(activity)));
        checks.add("usageStats", () -> permitted(activity.getSystemService(AppOpsManager.class).unsafeCheckOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS, android.os.Process.myUid(), activity.getPackageName()) == AppOpsManager.MODE_ALLOWED));
        checks.add("watchNext", () -> permitted(new WatchNextBridge(activity).checkWatchNextPermission()));
        checks.add("tvInputs", () -> {
            TvInputManager inputs = activity.getSystemService(TvInputManager.class);
            if (inputs == null) return "unsupported";
            return inputs.getTvInputList().isEmpty() ? "notConfigured" : "available";
        });
        checks.add("documentExport", () -> {
            var picker = new Intent(Intent.ACTION_CREATE_DOCUMENT).setType("application/json").addCategory(Intent.CATEGORY_OPENABLE);
            var share = new Intent(Intent.ACTION_SEND).setType("application/json");
            return DocumentFiles.compatibleIntent(picker, pm.queryIntentActivities(picker, 0)) != null
                || DocumentFiles.compatibleIntent(share, pm.queryIntentActivities(share, 0)) != null ? "available" : "unsupported";
        });
        checks.add("screensaverSelection", () -> Boolean.TRUE.equals(new ScreensaverBridge(activity).capabilities().get("canChoose")) ? "available" : "unsupported");
        return Map.of("identity", identity, "kind", emulator ? "emulator" : "physical", "checks", checks.snapshot());
    }
}
