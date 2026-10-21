package com.leanbitlab.ltvL;

import java.util.Map;

public class RemoteButtonCaptureTest {
    private static void require(boolean ok, String message) {
        if (!ok) throw new AssertionError(message);
    }
    public static void main(String[] args) {
        RemoteButtonCapture c = new RemoteButtonCapture();
        require(!c.active(0), "Idle capture must not record");
        require(!c.record(0, Map.of("keyCode", 1)), "Ignore keys before explicit start");
        c.start(100);
        require(c.remaining(100) == 120_000, "Two minute deadline");
        for (int i = 0; i < 324; i++) c.record(101 + i, Map.of("keyCode", i));
        require(c.snapshot().size() == 256, "Bounded history");
        require(c.dropped() == 68, "Report dropped events explicitly");
        require(c.snapshot().get(0).get("keyCode").equals(68), "Keep latest events");
        c.snapshot().get(0).put("keyCode", -1);
        require(c.snapshot().get(0).get("keyCode").equals(68), "Defensive snapshot");
        require(!c.active(120_100), "Expire at deadline");
        require(!c.record(120_100, Map.of()), "Ignore keys after deadline");
        require(c.remaining(120_101) == 0, "No negative time");
        require(c.snapshot().size() == 256, "Keep result after expiration for return from OEM app");
        c.start(40_000);
        require(c.snapshot().isEmpty(), "New session clears old observations");
        require(c.dropped() == 0, "New session resets dropped count");
        c.record(40_001, Map.of("action", 0, "repeat", 0));
        c.record(40_002, Map.of("action", 0, "repeat", 1));
        c.record(40_003, Map.of("action", 1, "repeat", 0));
        require(c.snapshot().size() == 3, "Keep down, repeat and up separately");
        require(c.snapshot().get(2).get("sessionMs").equals(3L), "Keep time since session start for button matching");
        c.stop();
        require(!c.active(40_004), "Stop immediately");
        require(!c.record(40_004, Map.of()), "Ignore keys after stop");
        System.out.println("RemoteButtonCapture: all checks passed");
    }
}
