package com.leanbitlab.ltvL;

import java.util.Map;
import java.util.Set;

/** No device or Android runtime: exercise HDMI/TV/app transitions with the same viewer. */
public final class NightHdmiTrackerTest {
    public static void main(String[] args) {
        Map<String, Set<String>> viewers = Map.of(
            "15", Set.of("com.tcl.tv"), "16", Set.of("com.tcl.tv"),
            "17", Set.of("com.tcl.tv"), "18", Set.of("com.tcl.tv"));
        for (String port : viewers.keySet()) {
            require(NightHdmiTracker.matches("com.tcl.tv", port, viewers), "Every HDMI port");
            require(!NightHdmiTracker.matches("com.example.launcher", port, viewers), "Home restores filter");
            require(!NightHdmiTracker.matches("com.example.player", port, viewers), "App restores filter");
            require(!NightHdmiTracker.matches(null, port, viewers), "Unknown foreground");
        }
        require(!NightHdmiTracker.matches("com.tcl.tv", "2", viewers), "Tuner in same viewer");
        require(!NightHdmiTracker.matches("com.tcl.tv", "1", viewers), "AV is not HDMI");
        require(!NightHdmiTracker.matches("com.tcl.tv", null, viewers), "No OEM setting");
        require(!NightHdmiTracker.matches("com.tcl.tv", "unknown", viewers), "Unknown input");
        require(!NightHdmiTracker.matches("com.tcl.tv", "16", Map.of()), "No discoverable HDMI");
        require(NightHdmiTracker.selected("port2", null), "Default ignores all ports");
        require(NightHdmiTracker.selected("port2", Set.of("port2")), "Selected physical port");
        require(!NightHdmiTracker.selected("port1", Set.of("port2")), "Other physical port stays filtered");
        require(!NightHdmiTracker.selected("port2", Set.of()), "Empty selection ignores nothing");
        require(!NightHdmiTracker.selected(null, null), "Unknown port is never excluded");
        System.out.println("NightHdmiTrackerTest passed");
    }

    private static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
}
