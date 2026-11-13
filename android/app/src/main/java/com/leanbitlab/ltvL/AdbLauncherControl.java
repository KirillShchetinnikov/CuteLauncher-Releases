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
            if (!AdbLauncherPolicy.usableHome(component)) continue;
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
        String current = home(adb);
        var restore = restoreTarget(activity, launchers);
        return Map.of("compatibility", AdbCapabilities.info(activity), "status", "ready", "isHome", current.startsWith(activity.getPackageName()+"/"),
            "accessibility", adb.execute("settings get secure accessibility_enabled").equals("1")
                && Arrays.asList(services(adb).split(":")).contains(component),
            "accessibilitySaved", recovery.getBoolean("accessibility_saved", false),
            "homeRecoverySaved", BUILT_INS.stream().anyMatch(target -> recovery.contains("home_states_" + target)),
            "currentHome", current, "launchers", launchers, "restoreTarget", restore.component(),
            "restoreSupported", AdbCapabilities.canRestore(activity, restore.component()));
    }

    private record HomeRestore(String component, String name, String stockPackage, int priority) {
        String selectedHome(int ownPriority) {
            return component.startsWith(stockPackage + "/") && priority > ownPriority ? "" : component;
        }
    }

    private static HomeRestore restoreTarget(Activity activity, List<Map<String,Object>> launchers) {
        var recovery = activity.getSharedPreferences("adb_recovery", 0);
        String previous = AdbLauncherPolicy.normalizeComponent(recovery.getString("previous_home", ""));
        String component = AdbLauncherPolicy.restoreTarget(previous, launchers);
        var candidate = launchers.stream().filter(item -> component.equals(item.get("component"))).findFirst().orElse(null);
        var stock = launchers.stream()
            .filter(item -> Boolean.TRUE.equals(item.get("builtin")))
            .max(Comparator.comparing((Map<String, Object> item) -> recovery.contains("home_states_" + item.get("package")))
                .thenComparing(item -> previous.equals(item.get("component")))
                .thenComparingInt(AdbLauncherControl::priority))
            .orElse(null);
        // A higher-priority stock HOME would win once re-enabled.
        if (stock != null && (candidate == null || !previous.equals(component)
                || !Boolean.TRUE.equals(candidate.get("enabled")) || priority(candidate) < priority(stock)))
            candidate = stock;
        if (candidate == null) return new HomeRestore("", "", "", Integer.MIN_VALUE);
        String packageName = (String)candidate.get("package");
        String stockPackage = stock == null ? "" : (String)stock.get("package");
        if (BUILT_INS.contains(packageName) && !recovery.contains("home_states_" + stockPackage)) {
            stockPackage = packageName;
        }
        return new HomeRestore((String)candidate.get("component"), (String)candidate.get("name"), stockPackage,
            priority(candidate));
    }

    private static int priority(Map<String, Object> launcher) {
        return ((Number)launcher.get("priority")).intValue();
    }

    private static String enabledBuiltin(List<Map<String, Object>> launchers, String current) {
        return launchers.stream()
            .filter(item -> Boolean.TRUE.equals(item.get("builtin")) && Boolean.TRUE.equals(item.get("enabled")))
            .max(Comparator.comparing((Map<String, Object> item) -> current.equals(item.get("component")))
                .thenComparingInt(AdbLauncherControl::priority))
            .map(item -> (String)item.get("package")).orElse("");
    }

    private static LinkedHashMap<String, Integer> restoreStates(Activity activity, String stockPackage) throws Exception {
        var states = savedStates(activity, stockPackage);
        int saved = states.getOrDefault(stockPackage, 1);
        states.put(stockPackage, saved == 0 ? 0 : 1);
        return states;
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
        switch (action) {
            case "home":
                var candidates = launchers(activity, adb);
                String stock = enabledBuiltin(candidates, home(adb));
                if (target != null && !target.equals(stock)) return Map.of("status", "changed");
                if (stock.isEmpty()) {
                    commands.add(AdbSystemHomeOps.selectHome(own + "/" + MainActivity.class.getName()));
                    break;
                }
                return stockPlan(activity, adb, stock, candidates, true, target != null && allowOwnedWifi);
            case "restore":
                var restore = restoreTarget(activity, launchers(activity, adb));
                String resolved = restore.component();
                if (resolved.isEmpty()) return Map.of("status", "noRecovery");
                if (!AdbCapabilities.canRestore(activity, resolved)) return Map.of("status", "unsupported");
                if (!restore.stockPackage().isEmpty()) {
                    commands.addAll(AdbSystemHomeOps.commands(restoreStates(activity, restore.stockPackage()),
                        restore.selectedHome(AdbCapabilities.ownPriority(activity))));
                } else {
                    commands.add("pm enable --user 0 '" + resolved.split("/")[0] + "'");
                    if (restore.priority() <= AdbCapabilities.ownPriority(activity))
                        commands.add(AdbSystemHomeOps.selectHome(resolved));
                }
                return Map.of("status", "ready", "commands", commands, "target", resolved,
                    "targetName", restore.name(), "stockPackage", restore.stockPackage());
            case "disableSystem": case "enableSystem":
                if (target == null || !BUILT_INS.contains(target)) return Map.of("status", "invalid");
                return stockPlan(activity, adb, target, launchers(activity, adb), action.equals("disableSystem"), allowOwnedWifi);
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
        return Map.of("status", "ready", "commands", commands, "target", "", "targetName", "");
    }

    private static Map<String, Object> stockPlan(Activity activity, AdbBridge.Shell adb, String target,
                                                 List<Map<String, Object>> launchers, boolean disable,
                                                 boolean allowOwnedWifi) throws Exception {
        var builtin = launchers.stream().filter(item -> target.equals(item.get("package"))).findFirst();
        if (builtin.isEmpty()) return Map.of("status", "invalid");
        LinkedHashMap<String, Integer> states;
        String selectedHome = "";
        if (disable) {
            int ownPriority = AdbCapabilities.ownPriority(activity);
            var homeStates = AdbCapabilities.homeStates(activity);
            if (!AdbSystemHomeOps.canDisable(ownPriority, target, homeStates)) return Map.of("status", "unsupported");
            states = AdbSystemHomeOps.disableStates(ownPriority, target, homeStates);
            String dependency = AdbHomeDependencies.blocked(activity, states, adb);
            if (!dependency.isEmpty()) return Map.of("status", "dependencyProtected", "reason", dependency);
            AdbOperationDiagnostics.stage("wifiSafety");
            var safety = AdbWifiSafety.checkDetailed(states, adb::execute, allowOwnedWifi);
            AdbOperationDiagnostics.wifi(safety);
            if (!safety.status().equals("ready")) return Map.of("status", safety.status(), "target", target);
            AdbOperationDiagnostics.stage("plan");
            selectedHome = activity.getPackageName() + "/" + MainActivity.class.getName();
        } else states = restoreStates(activity, target);
        return Map.of("status", "ready", "commands", AdbSystemHomeOps.commands(states, selectedHome),
            "target", target, "targetName", builtin.get().get("name"));
    }
    static String apply(Activity activity, AdbBridge.Shell adb, String action, String target, List<?> expected) throws Exception {
        return apply(activity, adb, action, target, expected, false);
    }
    static String apply(Activity activity, AdbBridge.Shell adb, String action, String target, List<?> expected, boolean allowOwnedWifi) throws Exception {
        AdbOperationDiagnostics.stage("apply");
        if (!adb.execute("am get-current-user").equals("0") || !adb.execute("id -u").equals("2000")) return "denied";
        Map<String,Object> plan = plan(activity, adb, action, target, allowOwnedWifi);
        if (!plan.get("status").equals("ready")) return (String)plan.get("status");
        AdbOperationDiagnostics.stage("apply");
        if (!AdbLauncherPolicy.confirmed(expected, plan.get("commands"))) return "changed";
        String resolved = (String)plan.get("target");
        if (action.equals("home") && BUILT_INS.contains(resolved)) {
            action = "disableSystem";
            target = resolved;
        }
        if (action.equals("disableAccessibility") || action.equals("restoreAccessibility")) UpdatePermissionRecovery.cancelAccessibility(activity);
        if ((action.equals("accessibility") || action.equals("restoreAccessibility"))
            && !AdbAccessibilityOps.apply(activity.getPackageName(), adb::execute, (List<?>)plan.get("commands"))) return "denied";
        if (action.equals("restore") || action.equals("disableSystem") || action.equals("enableSystem")) {
            if (action.equals("disableSystem")) {
                String previous = home(adb);
                if (savedStates(activity, target).isEmpty() && !previous.startsWith(activity.getPackageName()+"/") && !activity.getSharedPreferences("adb_recovery",0)
                    .edit().putString("previous_home", previous).commit()) return "denied";
            }
            String stockPackage = action.equals("restore") ? (String)plan.get("stockPackage") : resolved;
            if (BUILT_INS.contains(stockPackage)) {
                var desired = action.equals("disableSystem")
                    ? AdbSystemHomeOps.disableStates(AdbCapabilities.ownPriority(activity), stockPackage, AdbCapabilities.homeStates(activity))
                    : restoreStates(activity, stockPackage);
                List<?> commands = (List<?>)plan.get("commands");
                String expectedHome = action.equals("disableSystem") ? activity.getPackageName()+"/"+MainActivity.class.getName()
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
        String outcome = AdbBridge.perform(activity, adb, action);
        if (action.equals("accessibility") && outcome.equals("success")) UpdatePermissionRecovery.enabledAccessibility(activity);
        return outcome;
    }
}
