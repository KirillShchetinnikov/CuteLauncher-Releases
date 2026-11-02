package com.leanbitlab.ltvL;
import java.util.List;
import java.util.Arrays;
import java.util.Map;

/** Pure selection policy shared by the native bridge and local regression tests. */
final class AdbLauncherPolicy {
    static List<String> lines(String output) { return Arrays.asList(output.trim().split("\\r?\\n")); }
    static String resolvedHome(String output) {
        var lines = lines(output);
        return normalizeComponent(lines.get(lines.size()-1).trim());
    }
    static String normalizeComponent(String component) {
        int slash = component.indexOf("/.");
        return slash < 0 ? component : component.substring(0, slash+1) + component.substring(0, slash) + component.substring(slash+1);
    }
    static String restoreTarget(String previous, List<Map<String,Object>> launchers) {
        launchers = launchers.stream().filter(item -> usableHome((String)item.get("component"))).toList();
        for (var item : launchers) if (item.get("component").equals(normalizeComponent(previous))) return (String)item.get("component");
        for (var item : launchers) if (Boolean.TRUE.equals(item.get("enabled"))) return (String)item.get("component");
        return launchers.isEmpty() ? "" : (String)launchers.get(0).get("component");
    }
    static boolean usableHome(String component) {
        if (component == null || !component.matches("[a-zA-Z0-9_.$]+/[a-zA-Z0-9_.$]+")) return false;
        String[] parts = component.split("/", 2);
        String pkg = parts[0].toLowerCase(java.util.Locale.ROOT);
        String activity = parts[1].toLowerCase(java.util.Locale.ROOT);
        return !java.util.Set.of("android", "com.android.settings", "com.android.tv.settings",
                "com.android.provision", "com.google.android.tungsten.setupwraith").contains(pkg)
            && !pkg.matches(".*(factorytest|factory_test|factorymode).*")
            && !activity.endsWith("fallbackhome") && !activity.endsWith("lockedhomeactivity")
            && !activity.endsWith("factorylauncher");
    }
    static boolean confirmed(List<?> expected, Object current) {
        return expected != null && !expected.isEmpty() && expected.equals(current);
    }
}
