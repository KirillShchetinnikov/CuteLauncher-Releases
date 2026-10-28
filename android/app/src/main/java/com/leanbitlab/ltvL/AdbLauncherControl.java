package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ComponentName;
import org.json.JSONObject;
import java.util.*;

/** Fixed HOME actions and read-only ADB state. Never accepts shell text from Dart. */
final class AdbLauncherControl {
    private static final Set<String> BUILT_INS = AdbSystemHomeOps.BUILT_INS;
    static List<Map<String, Object>> launchers(Activity activity, AdbBridge.Shell adb) throws Exception {
        String disabled = adb.execute("pm list packages -d --user 0");
        List<Map<String, Object>> items = new ArrayList<>();
        for (var entry : AdbCapabilities.homes(activity)) {
            String pkg = entry.activityInfo.packageName;
            if (pkg.equals(activity.getPackageName())) continue;
            String component = pkg + "/" + entry.activityInfo.name;
            if (!component.matches("[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+")) continue;
            boolean enabled = !Arrays.asList(disabled.split("\\r?\\n")).contains("package:" + pkg)
                && AdbCapabilities.enabled(activity, entry);
            items.add(Map.of("package", pkg, "component", component,
                "name", entry.loadLabel(activity.getPackageManager()).toString(),
                "enabled", enabled, "priority", entry.priority, "builtin", BUILT_INS.contains(pkg)));
        }
        items.sort(Comparator.comparing(item -> (String)item.get("component")));
        return items;
    }
    private static String home(AdbBridge.Shell adb) throws Exception {
        String value = adb.execute("cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME");
        String[] lines = value.split("\\r?\\n");
        return AdbLauncherPolicy.normalizeComponent(lines[lines.length - 1].trim());
    }
    private static String services(AdbBridge.Shell adb) throws Exception {
        String value = adb.execute("settings get secure enabled_accessibility_services");
        if (value.equals("null")) return "";
        if (!value.matches("[a-zA-Z0-9_./:]*")) throw new IllegalStateException("Invalid services");
        return value;
    }
    static Map<String, Object> snapshot(Activity activity, AdbBridge.Shell adb) throws Exception {
        String component = activity.getPackageName() + "/com.leanbitlab.ltvL.LauncherAccessibilityService";
        var recovery = activity.getSharedPreferences("adb_recovery", 0);
        var launchers = launchers(activity, adb);
        return Map.of("compatibility", AdbCapabilities.info(activity), "status", "ready", "isHome", home(adb).startsWith(activity.getPackageName()+"/"),
            "accessibility", adb.execute("settings get secure accessibility_enabled").equals("1")
                && Arrays.asList(services(adb).split(":")).contains(component),
            "accessibilitySaved", recovery.getBoolean("accessibility_saved", false),
            "homeRecoverySaved", BUILT_INS.stream().anyMatch(target -> recovery.contains("home_states_" + target)),
            "currentHome", home(adb), "launchers", launchers, "restoreTarget", restoreTarget(activity, launchers),
            "restoreSupported", AdbCapabilities.canRestore(activity, restoreTarget(activity, launchers)));
    }
    static String restoreTarget(Activity activity, List<Map<String,Object>> launchers) {
        String previous = activity.getSharedPreferences("adb_recovery",0).getString("previous_home", "");
        return AdbLauncherPolicy.restoreTarget(previous, launchers);
    }
    private static LinkedHashMap<String, Integer> savedStates(Activity activity, String target) throws Exception {
        String saved = activity.getSharedPreferences("adb_recovery", 0).getString("home_states_" + target, "{}");
        var json = new JSONObject(saved);
        var states = new LinkedHashMap<String, Integer>();
        // Restore stock HOME before setup. Old component journals came from an operation shell
        // could not perform; never reinterpret a component state as a package state.
        for (String candidate : List.of(target, AdbSystemHomeOps.RECOVERY_PACKAGE)) if (json.has(candidate)) {
            int state = json.getInt(candidate);
            AdbSystemHomeOps.command(candidate, state);
            states.put(candidate, state);
        }
        return states;
    }
    private static int state(Activity activity, String target) {
        var pm = activity.getPackageManager();
        return target.contains("/") ? pm.getComponentEnabledSetting(ComponentName.unflattenFromString(target))
            : pm.getApplicationEnabledSetting(target);
    }
    private static boolean applyHomeStates(Activity activity, AdbBridge.Shell adb, String action,
                                           String target, Map<String, Integer> desired, String selectedHome, String expectedHome) throws Exception {
        var preferences = activity.getSharedPreferences("adb_recovery", 0);
        var original = savedStates(activity, target);
        boolean success = AdbSystemHomeOps.apply(desired, selectedHome, expectedHome, adb::execute,
            value -> state(activity, value), before -> {
                if (!action.equals("disableSystem")) return true; // Keep the existing journal until restore succeeds.
                before.forEach(original::putIfAbsent);
                return preferences.edit().putString("home_states_" + target, new JSONObject(original).toString()).commit();
            }, () -> home(adb));
        if (success && !action.equals("disableSystem"))
            success = preferences.edit().remove("home_states_" + target).commit();
        return success;
    }
    static Map<String, Object> plan(Activity activity, AdbBridge.Shell adb, String action, String target) throws Exception {
        return plan(activity, adb, action, target, false);
    }
    static Map<String, Object> plan(Activity activity, AdbBridge.Shell adb, String action, String target, boolean allowOwnedWifi) throws Exception {
        AdbOperationDiagnostics.stage("plan");
        String own = activity.getPackageName();
        if (!AdbCapabilities.supported(activity, action)) return Map.of("status", "unsupported");
        List<String> commands = new ArrayList<>();
        String resolved = "", targetName = "";
        switch (action) {
            case "home": commands.add("cmd package set-home-activity '"+own+"/com.leanbitlab.ltvL.MainActivity'"); break;
            case "restore":
                var candidates = launchers(activity, adb);
                resolved = restoreTarget(activity, candidates);
                int targetPriority = Integer.MIN_VALUE;
                for (var item : candidates) if (item.get("component").equals(resolved)) {
                    targetName = (String)item.get("name");
                    targetPriority = ((Number)item.get("priority")).intValue();
                }
                if (resolved.isEmpty()) return Map.of("status", "noRecovery");
                if (!AdbCapabilities.canRestore(activity, resolved)) return Map.of("status", "unsupported");
                String restorePackage = resolved.split("/")[0];
                var restoreStates = BUILT_INS.contains(restorePackage) ? savedStates(activity, restorePackage) : new LinkedHashMap<String, Integer>();
                if (restoreStates.isEmpty()) commands.add("pm enable --user 0 '"+restorePackage+"'");
                else commands.addAll(AdbSystemHomeOps.commands(restoreStates, ""));
                // A higher-priority system HOME wins automatically once enabled; set-home would be ineffective.
                boolean priorityHome = targetPriority > AdbCapabilities.ownPriority(activity);
                if (!priorityHome) commands.add("cmd package set-home-activity '"+resolved+"'"); break;
            case "disableSystem": case "enableSystem":
                if (target == null || !BUILT_INS.contains(target)) return Map.of("status", "invalid");
                boolean found = launchers(activity, adb).stream().anyMatch(item -> item.get("package").equals(target));
                if (!found) return Map.of("status", "invalid");
                if (action.equals("disableSystem") && !AdbCapabilities.canDisable(activity, target)) return Map.of("status", "unsupported");
                resolved = target;
                var states = action.equals("disableSystem")
                    ? AdbSystemHomeOps.disableStates(AdbCapabilities.ownPriority(activity), target, AdbCapabilities.homeStates(activity))
                    : savedStates(activity, target);
                if (states.isEmpty()) states.put(target, 1);
                if (action.equals("disableSystem")) {
                    AdbOperationDiagnostics.stage("wifiSafety");
                    var safety = AdbWifiSafety.checkDetailed(states, adb::execute, allowOwnedWifi);
                    AdbOperationDiagnostics.wifi(safety);
                    if (!safety.status().equals("ready")) return Map.of("status", safety.status());
                    AdbOperationDiagnostics.stage("plan");
                }
                commands.addAll(AdbSystemHomeOps.commands(states, action.equals("disableSystem")
                    ? own + "/com.leanbitlab.ltvL.MainActivity" : "")); break;
            case "accessibility": case "disableAccessibility": case "restoreAccessibility":
                String component = own+"/com.leanbitlab.ltvL.LauncherAccessibilityService";
                var recovery = activity.getSharedPreferences("adb_recovery",0);
                if (action.equals("restoreAccessibility") && !recovery.getBoolean("accessibility_saved",false)) return Map.of("status","noRecovery");
                LinkedHashSet<String> values = new LinkedHashSet<>();
                String current = services(adb);
                if (!current.isEmpty()) values.addAll(Arrays.asList(current.split(":")));
                if (action.equals("accessibility") || (action.equals("restoreAccessibility") && recovery.getBoolean("accessibility_own_was_enabled",false))) values.add(component);
                else values.remove(component);
                String value = String.join(":", values);
                if (values.contains(component)) commands.addAll(AdbAccessibilityOps.plan(own, adb::execute));
                commands.add(value.isEmpty() ? "settings delete secure enabled_accessibility_services"
                    : "settings put secure enabled_accessibility_services '"+value+"'");
                commands.add("settings put secure accessibility_enabled "+(values.isEmpty() ? (action.equals("disableAccessibility") ? 0 : recovery.getInt("accessibility_enabled",0)) : 1)); break;
            case "overlay":
                commands.add("appops set --uid '"+own+"' SYSTEM_ALERT_WINDOW allow");
                commands.add("appops set --user 0 '"+own+"' SYSTEM_ALERT_WINDOW allow"); break;
            case "notifications": commands.add("cmd notification allow_listener '"+own+"/com.leanbitlab.ltvL.LauncherNotificationListenerService' 0"); break;
            case "watchNext": commands.add("pm grant --user 0 '"+own+"' "+AdbCapabilities.watchNextPermission(activity)); break;
            case "usage": case "writeSettings": commands.add("appops set --user 0 '"+own+"' "+(action.equals("usage") ? "GET_USAGE_STATS" : "WRITE_SETTINGS")+" allow"); break;
            default: return Map.of("status", "invalid");
        }
        return Map.of("status", "ready", "commands", commands, "target", resolved, "targetName", targetName);
    }
    static String apply(Activity activity, AdbBridge.Shell adb, String action, String target, List<?> expected) throws Exception {
        return apply(activity, adb, action, target, expected, false);
    }
    static String apply(Activity activity, AdbBridge.Shell adb, String action, String target, List<?> expected, boolean allowOwnedWifi) throws Exception {
        AdbOperationDiagnostics.stage("apply");
        if (!adb.execute("am get-current-user").equals("0") || !adb.execute("id -u").equals("2000")) return "denied";
        Map<String,Object> plan = plan(activity, adb, action, target, action.equals("disableSystem") && allowOwnedWifi);
        if (!plan.get("status").equals("ready")) return (String)plan.get("status");
        AdbOperationDiagnostics.stage("apply");
        if (!AdbLauncherPolicy.confirmed(expected, plan.get("commands"))) return "changed";
        if (action.equals("disableAccessibility") || action.equals("restoreAccessibility")) UpdatePermissionRecovery.cancelAccessibility(activity);
        if ((action.equals("accessibility") || action.equals("restoreAccessibility"))
            && !AdbAccessibilityOps.apply(activity.getPackageName(), adb::execute, (List<?>)plan.get("commands"))) return "denied";
        if (action.equals("restore") || action.equals("disableSystem") || action.equals("enableSystem")) {
            if (action.equals("disableSystem")) {
                String previous = home(adb);
                if (savedStates(activity, target).isEmpty() && !previous.startsWith(activity.getPackageName()+"/") && !activity.getSharedPreferences("adb_recovery",0)
                    .edit().putString("previous_home", previous).commit()) return "denied";
            }
            String resolved = (String)plan.get("target");
            String stockPackage = action.equals("restore") ? resolved.split("/")[0] : resolved;
            if (BUILT_INS.contains(stockPackage)) {
                var desired = action.equals("disableSystem")
                    ? AdbSystemHomeOps.disableStates(AdbCapabilities.ownPriority(activity), stockPackage, AdbCapabilities.homeStates(activity))
                    : savedStates(activity, stockPackage);
                if (desired.isEmpty()) desired.put(stockPackage, 1);
                List<?> commands = (List<?>)plan.get("commands");
                String expectedHome = action.equals("disableSystem") ? activity.getPackageName()+"/com.leanbitlab.ltvL.MainActivity"
                    : action.equals("restore") ? resolved : "";
                String selected = commands.stream().anyMatch(command -> ((String)command).startsWith("cmd package set-home-activity"))
                    ? expectedHome : "";
                if (!AdbSystemHomeOps.commands(desired, selected).equals(commands)) return "changed";
                boolean success = applyHomeStates(activity, adb, action, stockPackage, desired, selected, expectedHome);
                return success ? "success" : "denied";
            }
            for (Object command : (List<?>)plan.get("commands")) adb.execute((String)command);
            if (action.equals("restore")) return home(adb).equals(resolved) ? "success" : "denied";
            boolean disabled = Arrays.asList(adb.execute("pm list packages -d --user 0").split("\\r?\\n")).contains("package:"+resolved);
            return disabled == action.equals("disableSystem") ? "success" : "denied";
        }
        return AdbBridge.perform(activity, adb, action);
    }
}
