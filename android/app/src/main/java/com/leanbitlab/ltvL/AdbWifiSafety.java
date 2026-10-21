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

    static String check(Map<String, Integer> desired, Shell shell) {
        if (!Integer.valueOf(3).equals(desired.get(AdbSystemHomeOps.RECOVERY_PACKAGE))) return "ready";
        try { return inspect(shell.execute(COMMAND)); }
        catch (Exception failure) { return "wifiUnknown"; }
    }

    static String inspect(String dump) {
        if (dump == null) return "wifiUnknown";
        int begin = dump.indexOf(BEGIN), end = dump.indexOf(END);
        if (begin < 0 || end <= begin || dump.indexOf(BEGIN, begin + BEGIN.length()) >= 0) return "wifiUnknown";
        String configs = dump.substring(begin + BEGIN.length(), end);
        var records = NETWORK.matcher(configs);
        int count = 0, previous = -1;
        while (records.find()) {
            if (previous >= 0 && !knownOwner(configs.substring(previous, records.start()))) return "wifiUnknown";
            previous = records.start();
            count++;
        }
        // Empty/unrecognised output cannot prove ownership, even when Ethernet is connected.
        if (count == 0 || !knownOwner(configs.substring(previous))) return "wifiUnknown";
        var owners = OWNER.matcher(configs);
        while (owners.find()) if (owners.group(1).split(":", 2)[0].equals(AdbSystemHomeOps.RECOVERY_PACKAGE)) return "wifiOwned";
        return "ready";
    }

    private static boolean knownOwner(String record) {
        var owner = OWNER.matcher(record);
        return owner.find() && PACKAGE.matcher(owner.group(1)).matches() && !owner.find();
    }
}
