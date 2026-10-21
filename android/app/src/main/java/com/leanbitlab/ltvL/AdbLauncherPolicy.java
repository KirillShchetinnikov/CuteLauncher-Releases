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
        for (var item : launchers) if (item.get("component").equals(normalizeComponent(previous))) return (String)item.get("component");
        for (var item : launchers) if (Boolean.TRUE.equals(item.get("enabled"))) return (String)item.get("component");
        return launchers.isEmpty() ? "" : (String)launchers.get(0).get("component");
    }
    static boolean confirmed(List<?> expected, Object current) {
        return expected != null && !expected.isEmpty() && expected.equals(current);
    }
}
