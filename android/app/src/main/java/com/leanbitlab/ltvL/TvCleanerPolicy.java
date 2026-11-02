package com.leanbitlab.ltvL;

import java.util.regex.Pattern;

/** Shell arguments are package IDs only. Recommendations never follow name heuristics. */
final class TvCleanerPolicy {
    // Exact core/middleware IDs: protection must not depend on OEM UID or persistent flags.
    private static final java.util.Set<String> CORE_PACKAGES = java.util.Set.of(
        "android.ext.services", "android.ext.shared",
        "com.google.android.ext.services", "com.google.android.ext.shared",
        "com.google.android.modulemetadata", "com.cltv.mal",
        "com.mediatek.tis", "com.mediatek.tv.service", "com.mediatek.tv.agent");
    static int parseState(String dump) {
        var match = Pattern.compile("(?m)^\\s*User 0:.*?installed=true.*?enabled=([0-4])(?:\\s|$)").matcher(dump);
        if (!match.find()) throw new IllegalStateException("Package state unavailable");
        return Integer.parseInt(match.group(1));
    }
    static boolean packageId(String name) {
        return name != null && name.length() <= 220
            && Pattern.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z0-9_]+)+|android", name);
    }
    static String command(String name, int state) {
        if (!packageId(name)) throw new IllegalArgumentException("Invalid package");
        String[] actions = {"default-state", "enable", "disable", "disable-user", "disable-until-used"};
        if (state < 0 || state >= actions.length) throw new IllegalArgumentException("Invalid state");
        return "pm " + actions[state] + " --user 0 '" + name + "'";
    }
    static boolean critical(String name) {
        return CORE_PACKAGES.contains(name) || name.equals("android") || name.contains("setupwraith")
            || name.startsWith("com.android.") || name.startsWith("com.google.android.overlay.")
            || name.startsWith("com.google.android.networkstack")
            || name.equals("com.google.android.gms") || name.equals("com.google.android.gsf")
            || name.contains("permissioncontroller") || name.contains("packageinstaller")
            || name.contains("inputmethod") || name.contains("tvinput")
            || name.contains("systemui") || name.contains("systemserver")
            || name.equals("com.tcl.tv") || name.equals("com.tcl.suspension")
            || name.equals("com.tcl.initsetup") || name.equals("com.sei.hdmi.services")
            || name.equals("com.realtek.power") || name.equals("com.realtek.energymode")
            || name.equals("com.dolby.android.audio.service") || name.equals("com.nes.coreservice")
            || name.equals("com.google.android.katniss")
            || name.equals("com.google.android.apps.mediashell")
            || name.contains("webview") || name.contains(".overlay")
            || name.contains("rro_") || name.endsWith(".resources")
            || name.contains("globalkey") || name.contains(".providers.")
            || name.equals("com.google.android.tv.remote.service")
            || name.equals("com.google.android.tv.googletvremotepairer");
    }
}
