package com.leanbitlab.ltvL;

import org.junit.Test;
import static org.junit.Assert.*;

public class VpnPolicyTest {
    private static final String DUMP = "VPNs:\n  0: org.amnezia.awg\n"
        + "    Active package name: org.amnezia.awg\n"
        + "    NetworkCapabilities: [ Transports: VPN TransportInfo: <VpnTransportInfo{type=1, sessionId=tv-tcl-43, bypassable=false}> ]\n"
        + "  10: com.wireguard.android\n    Active package name: com.wireguard.android\n"
        + "    NetworkCapabilities: [sessionId=work, bypassable=false]\n";
    @Test public void tclFormatSelectsOnlyCurrentUser() {
        assertEquals(new VpnPolicy.Active("org.amnezia.awg", "tv-tcl-43"), VpnPolicy.parse(DUMP, 0));
        assertEquals(new VpnPolicy.Active("com.wireguard.android", "work"), VpnPolicy.parse(DUMP, 10));
        assertEquals(new VpnPolicy.Active("", ""), VpnPolicy.parse(DUMP, 11));
    }
    @Test public void unknownOrMalformedDumpDoesNotGuess() {
        for (String dump : new String[]{null, "Permission denied", "Active package name: org.amnezia.awg", "  0:\n Active package name: [Legacy VPN]\n"})
            assertEquals(new VpnPolicy.Active("", ""), VpnPolicy.parse(dump, 0));
        assertEquals("", VpnPolicy.parse(DUMP.replace("tv-tcl-43", "null"), 0).profile());
    }
    @Test public void automaticSelectionNeverFallsBackToLastWhileOwnerUnknown() {
        assertEquals("org.amnezia.awg", VpnPolicy.target("", true, "org.amnezia.awg", "com.wireguard.android"));
        assertEquals("", VpnPolicy.target("", true, "", "com.wireguard.android"));
        assertEquals("com.wireguard.android", VpnPolicy.target("", false, "", "com.wireguard.android"));
        assertEquals("org.amnezia.awg", VpnPolicy.target("org.amnezia.awg", true, "com.wireguard.android", ""));
    }
    @Test public void profilesAndPackagesHaveStrictBounds() {
        assertTrue(VpnPolicy.profileName("tv-tcl-43"));
        for (String value : new String[]{"", "0123456789012345", "a\nb", "$(id)", "../../secret"}) assertFalse(VpnPolicy.profileName(value));
        assertFalse(VpnPolicy.packageName("bad;name"));
        assertFalse(VpnPolicy.supported("org.amnezia.vpn"));
    }
}
