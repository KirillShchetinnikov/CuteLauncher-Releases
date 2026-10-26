package com.leanbitlab.ltvL;

import java.util.Map;
import java.util.regex.Pattern;

/** Read-only precondition for disabling the setup wizard. Never persists network data. */
final class AdbWifiSafety {
    private static final String BEGIN = "WifiConfigManager - Configured networks Begin ----";
    private static final String END = "WifiConfigManager - Configured networks End ----";
    static final String COMMAND = "dumpsys wifi | sed -n '/" + BEGIN + "/,/" + END + "/p'";
    private static final Pattern NETWORK = Pattern.compile("(?m)^\\s*(?:\\*\\s*)?ID:\\s*\\d+");
    private static final Pattern OWNER = Pattern.compile("(?:^|\\s)cname=([^\\s]+)");
    private static final Pattern PACKAGE = Pattern.compile("[A-Za-z_][A-Za-z0-9_]*(?:\\.[A-Za-z0-9_]+)+(?::\\d+)?");
    interface Shell { String execute(String command) throws Exception; }
    record Inspection(String status, String reason, int networkCount, int knownOwnerCount, int setupOwnerCount) {
        Map<String, Object> diagnostic() {
            return Map.of("reason", reason, "networkCount", networkCount,
                "knownOwnerCount", knownOwnerCount, "setupOwnerCount", setupOwnerCount);
        }
    }

    static String check(Map<String, Integer> desired, Shell shell) {
        return checkDetailed(desired, shell).status();
    }

    static Inspection checkDetailed(Map<String, Integer> desired, Shell shell) {
        return checkDetailed(desired, shell, false);
    }

    static Inspection checkDetailed(Map<String, Integer> desired, Shell shell, boolean allowOwnedWifi) {
        if (!Integer.valueOf(3).equals(desired.get(AdbSystemHomeOps.RECOVERY_PACKAGE)))
            return new Inspection("ready", "wifi_not_required", 0, 0, 0);
        try {
            Inspection result = inspectDetailed(shell.execute(COMMAND));
            if (allowOwnedWifi && result.status().equals("wifiOwned")) {
                return new Inspection("ready", "wifi_owner_override", result.networkCount(),
                    result.knownOwnerCount(), result.setupOwnerCount());
            }
            return result;
        }
        catch (Exception failure) { return new Inspection("wifiUnknown", "wifi_query_failed", 0, 0, 0); }
    }

    static String inspect(String dump) {
        return inspectDetailed(dump).status();
    }

    static Inspection inspectDetailed(String dump) {
        if (dump == null || dump.isBlank()) return unknown("wifi_dump_missing", 0, 0, 0);
        int begin = dump.indexOf(BEGIN), end = dump.indexOf(END);
        if (begin < 0) return unknown("wifi_section_missing", 0, 0, 0);
        if (end <= begin) return unknown("wifi_section_incomplete", 0, 0, 0);
        if (dump.indexOf(BEGIN, begin + BEGIN.length()) >= 0) return unknown("wifi_section_duplicate", 0, 0, 0);
        String configs = dump.substring(begin + BEGIN.length(), end);
        var records = NETWORK.matcher(configs);
        var starts = new java.util.ArrayList<Integer>();
        while (records.find()) {
            starts.add(records.start());
        }
        // Empty/unrecognised output cannot prove ownership, even when Ethernet is connected.
        int count = starts.size(), known = 0, setup = 0;
        if (count == 0) return unknown("wifi_no_records", 0, 0, 0);
        String reason = "";
        for (int i = 0; i < count; i++) {
            String record = configs.substring(starts.get(i), i + 1 < count ? starts.get(i + 1) : configs.length());
            var owner = OWNER.matcher(record);
            if (!owner.find()) { if (reason.isEmpty()) reason = "wifi_owner_missing"; continue; }
            String name = owner.group(1);
            if (!PACKAGE.matcher(name).matches()) { if (reason.isEmpty()) reason = "wifi_owner_invalid"; continue; }
            if (owner.find()) { if (reason.isEmpty()) reason = "wifi_owner_ambiguous"; continue; }
            known++;
            if (name.split(":", 2)[0].equals(AdbSystemHomeOps.RECOVERY_PACKAGE)) setup++;
        }
        if (!reason.isEmpty()) return unknown(reason, count, known, setup);
        var owners = OWNER.matcher(configs);
        while (owners.find()) if (owners.group(1).split(":", 2)[0].equals(AdbSystemHomeOps.RECOVERY_PACKAGE))
            return new Inspection("wifiOwned", "wifi_owner_setup", count, known, setup);
        return new Inspection("ready", "wifi_safe", count, known, setup);
    }

    private static Inspection unknown(String reason, int count, int known, int setup) {
        return new Inspection("wifiUnknown", reason, count, known, setup);
    }
}
