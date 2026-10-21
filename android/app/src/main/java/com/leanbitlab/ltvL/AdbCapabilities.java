package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.ComponentName;
import android.content.pm.PackageManager;
import java.util.*;

/** Non-invasive compatibility detection: package/permission metadata, never shell probes. */
final class AdbCapabilities {
    static final String WATCH_NEXT = "com.android.providers.tv.permission.READ_WRITE_WATCH_NEXT_PROGRAMS";
    static final String TV_LISTINGS = "android.permission.READ_TV_LISTINGS";
    static List<android.content.pm.ResolveInfo> homes(Activity activity) {
        var items = new ArrayList<>(activity.getPackageManager().queryIntentActivities(
            new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), PackageManager.MATCH_DISABLED_COMPONENTS));
        // MATCH_DISABLED_COMPONENTS includes setup/locked HOME activities. Manifest enabled is not
        // their effective state: the component may have been disabled after setup finished.
        items.removeIf(item -> !componentEnabled(activity, item));
        return items;
    }
    private static boolean componentEnabled(Activity activity, android.content.pm.ResolveInfo item) {
        int state = activity.getPackageManager().getComponentEnabledSetting(
            new ComponentName(item.activityInfo.packageName, item.activityInfo.name));
        return state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT ? item.activityInfo.enabled
            : state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED;
    }
    static boolean enabled(Activity activity, android.content.pm.ResolveInfo item) {
        int state = activity.getPackageManager().getApplicationEnabledSetting(item.activityInfo.packageName);
        return componentEnabled(activity, item) && (state == PackageManager.COMPONENT_ENABLED_STATE_DEFAULT
            ? item.activityInfo.applicationInfo.enabled : state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED);
    }
    static int ownPriority(Activity activity) {
        return homes(activity).stream().filter(item -> enabled(activity, item) && item.activityInfo.packageName.equals(activity.getPackageName()))
            .mapToInt(item -> item.priority).max().orElse(Integer.MIN_VALUE);
    }
    static boolean canHome(Activity activity) {
        int own = ownPriority(activity);
        return AdbCompatibilityPolicy.canSelectHome(own, homes(activity).stream()
            .filter(item -> enabled(activity, item)).mapToInt(item -> item.priority).max().orElse(Integer.MIN_VALUE));
    }
    static boolean canDisable(Activity activity, String target) {
        return AdbSystemHomeOps.canDisable(ownPriority(activity), target, homeStates(activity));
    }
    static List<Map<String, Object>> homeStates(Activity activity) {
        var result = new ArrayList<Map<String, Object>>();
        for (var item : homes(activity)) result.add(Map.of(
            "package", item.activityInfo.packageName,
            "component", item.activityInfo.packageName + "/" + item.activityInfo.name,
            "enabled", enabled(activity, item), "priority", item.priority,
            "system", (item.activityInfo.applicationInfo.flags & android.content.pm.ApplicationInfo.FLAG_SYSTEM) != 0));
        return result;
    }
    static boolean canRestore(Activity activity, String component) {
        var items = homes(activity);
        int priority = items.stream().filter(item -> (item.activityInfo.packageName+"/"+item.activityInfo.name).equals(component))
            .mapToInt(item -> item.priority).max().orElse(Integer.MIN_VALUE);
        return AdbCompatibilityPolicy.canSelectHome(priority, items.stream().filter(item -> enabled(activity, item))
            .mapToInt(item -> item.priority).max().orElse(Integer.MIN_VALUE));
    }
    static boolean grantable(Activity activity, String permission) {
        try {
            var info = activity.getPackageManager().getPermissionInfo(permission, 0);
            var requested = activity.getPackageManager().getPackageInfo(activity.getPackageName(), PackageManager.GET_PERMISSIONS).requestedPermissions;
            return requested != null && Arrays.asList(requested).contains(permission)
                && AdbCompatibilityPolicy.grantable(info.protectionLevel);
        } catch (PackageManager.NameNotFoundException e) { return false; }
    }
    static String watchNextPermission(Activity activity) {
        // Public provider permission is portable; use an OEM permission only when it can be granted.
        if (grantable(activity, TV_LISTINGS)) return TV_LISTINGS;
        return grantable(activity, WATCH_NEXT) ? WATCH_NEXT : "";
    }
    static Map<String, Object> info(Activity activity) {
        var homes = homes(activity);
        boolean google;
        try { activity.getPackageManager().getPackageInfo("com.google.android.apps.tv.launcherx", 0); google = true; }
        catch (PackageManager.NameNotFoundException e) { google = false; }
        boolean tv = AdbCompatibilityPolicy.supportedSdk(android.os.Build.VERSION.SDK_INT)
            && activity.getPackageManager().hasSystemFeature(PackageManager.FEATURE_LEANBACK);
        Map<String, Boolean> actions = new LinkedHashMap<>();
        for (String action : List.of("overlay", "usage", "writeSettings", "notifications", "accessibility", "disableAccessibility", "restoreAccessibility", "enableSystem")) actions.put(action, tv);
        actions.put("home", tv && canHome(activity));
        actions.put("restore", tv && homes.stream().anyMatch(item -> !item.activityInfo.packageName.equals(activity.getPackageName())
            && canRestore(activity, item.activityInfo.packageName+"/"+item.activityInfo.name)));
        actions.put("disableSystem", tv && ownPriority(activity) != Integer.MIN_VALUE);
        actions.put("watchNext", tv && !watchNextPermission(activity).isEmpty());
        Map<String, Boolean> disable = new HashMap<>();
        for (var item : homes) disable.put(item.activityInfo.packageName, tv && canDisable(activity, item.activityInfo.packageName));
        return Map.of("system", google ? "Google TV" : tv ? "Android TV" : "Android", "sdk", android.os.Build.VERSION.SDK_INT,
            "actions", actions, "disableTargets", disable);
    }
    static boolean supported(Activity activity, String action) {
        return Boolean.TRUE.equals(((Map<?, ?>)info(activity).get("actions")).get(action));
    }
}
