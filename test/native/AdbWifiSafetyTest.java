package com.leanbitlab.ltvL;

import java.util.Map;

public final class AdbWifiSafetyTest {
    private static void check(boolean value) { if (!value) throw new AssertionError(); }
    private static String dump(String body) {
        return "WifiConfigManager - Configured networks Begin ----\n" + body
            + "\nWifiConfigManager - Configured networks End ----\n";
    }
    public static void main(String[] args) {
        String safe = dump("* ID: 0 SSID: \"private\"\n cuid=1000 cname=android.uid.system:1000\n"
            + "ID: 3 SSID: \"other\"\n cuid=1000 cname=com.android.settings");
        String owned = dump("ID: 0 SSID: \"private\"\n cname=" + AdbSystemHomeOps.RECOVERY_PACKAGE);
        check(AdbWifiSafety.inspect(safe).equals("ready"));
        check(AdbWifiSafety.inspect(owned).equals("wifiOwned"));
        check(AdbWifiSafety.inspectDetailed(owned).reason().equals("wifi_owner_setup"));
        check(AdbWifiSafety.inspectDetailed(owned).setupOwnerCount() == 1);
        check(AdbWifiSafety.inspectDetailed(safe).networkCount() == 2);
        check(AdbWifiSafety.inspectDetailed(dump("ID: 0\n cuid=1000")).reason().equals("wifi_owner_missing"));
        check(AdbWifiSafety.inspectDetailed(dump("ID: 0\n cname=null")).reason().equals("wifi_owner_invalid"));
        check(AdbWifiSafety.inspectDetailed(dump("ID: 0\n cname=com.android.settings cname=android.uid.system")).reason().equals("wifi_owner_ambiguous"));
        check(AdbWifiSafety.inspectDetailed("").reason().equals("wifi_dump_missing"));
        check(AdbWifiSafety.inspectDetailed("Permission Denial").reason().equals("wifi_section_missing"));
        check(AdbWifiSafety.inspectDetailed(dump("")).reason().equals("wifi_no_records"));
        check(!AdbWifiSafety.inspectDetailed(owned).diagnostic().toString().contains("private"));
        // A history entry outside configured networks must not influence the decision.
        check(AdbWifiSafety.inspect("cname=" + AdbSystemHomeOps.RECOVERY_PACKAGE + "\n" + safe).equals("ready"));
        for (String invalid : new String[] {"", "Permission Denial", dump(""), dump("cname=com.android.settings"),
                dump("ID: 0\n cname=null"), dump("ID: 0\n cname=com.android.settings\nID: 1\n cuid=1000"),
                dump("ID: 0\n cname=com.android.settings cname=android.uid.system"),
                safe.replace(" End ----", " unfinished"), safe + safe}) {
            check(AdbWifiSafety.inspect(invalid).equals("wifiUnknown"));
        }
        check(AdbWifiSafety.inspect(null).equals("wifiUnknown"));
        var changes = Map.of(AdbSystemHomeOps.RECOVERY_PACKAGE, 3);
        check(AdbWifiSafety.check(changes, command -> { check(command.equals(AdbWifiSafety.COMMAND)); return owned; }).equals("wifiOwned"));
        check(AdbWifiSafety.check(changes, command -> safe).equals("ready"));
        check(AdbWifiSafety.check(changes, command -> { throw new java.io.IOException(); }).equals("wifiUnknown"));
        // Already disabled setup / ordinary HOME / restore never query or block Wi-Fi.
        for (var desired : java.util.List.of(Map.of("com.google.android.tvlauncher", 3),
                Map.of(AdbSystemHomeOps.RECOVERY_PACKAGE, 0))) {
            check(AdbWifiSafety.check(desired, command -> { throw new AssertionError(); }).equals("ready"));
        }
        System.out.println("AdbWifiSafetyTest passed");
    }
}
