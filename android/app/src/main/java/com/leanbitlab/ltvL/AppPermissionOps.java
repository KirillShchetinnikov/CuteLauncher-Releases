package com.leanbitlab.ltvL;

import android.content.ComponentName;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Targeted operations: never replay a saved accessibility service list. Caller holds AdbBridge.LOCK. */
final class AppPermissionOps {
    static void checkUser(AdbBridge.Shell shell) throws Exception {
        if (!shell.execute("id -u").trim().equals("2000")
                || !shell.execute("am get-current-user").trim().equals("0"))
            throw new IllegalStateException("unsupported_user");
    }
    static Map<String, String> modes(String pkg, AdbBridge.Shell shell) throws Exception {
        if (!pkg.matches("[a-zA-Z0-9_.]+")) throw new IllegalArgumentException("Invalid package");
        Map<String, String> result = new LinkedHashMap<>();
        for (String op : AdbAccessibilityOps.OPERATIONS)
            result.put(op, AdbAccessibilityOps.mode(op,
                shell.execute("appops get --user 0 '" + pkg + "' " + op + " 2>&1 || true").trim()));
        return result;
    }
    static List<String> plan(String pkg, Map<String, String> modes) {
        return modes.entrySet().stream().filter(e -> AdbAccessibilityOps.needsAllow(e.getKey(), e.getValue()))
            .map(e -> "appops set --user 0 '" + pkg + "' " + e.getKey() + " allow")
            .collect(java.util.stream.Collectors.toList());
    }
    static boolean contains(String list, String component) {
        ComponentName target = ComponentName.unflattenFromString(component);
        for (String item : list.trim().split(":"))
            if (target != null && target.equals(ComponentName.unflattenFromString(item))) return true;
        return false;
    }
    static boolean enabled(AdbBridge.Shell shell, String component) throws Exception {
        return contains(shell.execute("settings get secure enabled_accessibility_services"), component)
            && shell.execute("settings get secure accessibility_enabled").trim().equals("1");
    }
    static void setEnabled(AdbBridge.Shell shell, String component, boolean enable) throws Exception {
        String current = shell.execute("settings get secure enabled_accessibility_services").trim();
        String next = UpdatePermissionPolicy.serviceList(current, component, enable);
        if (!current.equals(next)) {
            if (next.isEmpty()) shell.execute("settings delete secure enabled_accessibility_services");
            else shell.execute("settings put secure enabled_accessibility_services '" + next + "'");
        }
        if (enable && !shell.execute("settings get secure accessibility_enabled").trim().equals("1"))
            shell.execute("settings put secure accessibility_enabled 1");
        // Other writers may legitimately change unrelated entries between our write and read.
        String actual = shell.execute("settings get secure enabled_accessibility_services").trim();
        if (contains(actual, component) != enable || (enable && !enabled(shell, component)))
            throw new IllegalStateException("permission_rejected");
    }
    static void reconnect(AdbBridge.Shell shell, String component) throws Exception {
        if (!enabled(shell, component)) throw new IllegalStateException("service_disabled");
        try {
            setEnabled(shell, component, false);
            Thread.sleep(250);
        } finally {
            setEnabled(shell, component, true);
        }
    }
}
