package com.leanbitlab.ltvL;

import java.util.regex.Pattern;

/** Pure parsing/selection rules. Never infer a VPN owner from the installed-app list. */
final class VpnPolicy {
    record Active(String app, String profile) { }
    static boolean packageName(String value) {
        return value != null && value.length() <= 255
            && value.matches("[A-Za-z][A-Za-z0-9_]*(\\.[A-Za-z][A-Za-z0-9_]*)+");
    }
    static boolean supported(String app) {
        return requiresProfile(app) || "com.happproxy".equals(app)
            || "su.happ.proxyutility".equals(app) || "com.mantaray.vpn".equals(app);
    }
    static boolean requiresProfile(String app) {
        return "org.amnezia.awg".equals(app) || "com.wireguard.android".equals(app);
    }
    static boolean profileName(String value) {
        return value != null && value.matches("[A-Za-z0-9_=+.-]{1,15}");
    }
    static Active parse(String dump, int user) {
        if (dump == null || dump.length() > 2_000_000) return new Active("", "");
        // AOSP prints one block per user, headed by "<userId>:" inside VPNs.
        var block = Pattern.compile("(?ms)^[ \\t]*(?:User )?" + user
            + ":[^\\r\\n]*\\r?\\n(.*?)(?=^[ \\t]*(?:User )?\\d+:[^\\r\\n]*\\r?\\n|\\z)").matcher(dump);
        if (!block.find()) return new Active("", "");
        String text = block.group(1);
        var owner = Pattern.compile("(?m)^\\s*Active package name:\\s*(\\S+)\\s*$").matcher(text);
        if (!owner.find() || !packageName(owner.group(1))) return new Active("", "");
        var session = Pattern.compile("sessionId=([^,}\\r\\n]+)").matcher(text);
        String profile = session.find() ? session.group(1).trim() : "";
        return new Active(owner.group(1), profileName(profile) && !profile.equals("null") ? profile : "");
    }
    static String target(String selected, boolean active, String owner, String last) {
        if (!selected.isEmpty()) return selected;
        return active ? owner : last;
    }
}
