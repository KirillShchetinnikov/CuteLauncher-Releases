package com.leanbitlab.ltvL;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

public class RemoteButtonReportTest {
    private static void require(boolean ok, String message) {
        if (!ok) throw new AssertionError(message);
    }
    public static void main(String[] args) throws Exception {
        Path directory = Files.createTempDirectory("cute-remote-report-");
        Path report = directory.resolve("remote-buttons-last.txt");
        Path pending = directory.resolve("remote-buttons-last.tmp");
        try {
            Map<String, Object> down = new LinkedHashMap<>();
            down.put("id", 42); down.put("sessionMs", 1200L);
            down.put("keyName", "4159"); down.put("keyCode", 4159);
            down.put("action", 0); down.put("repeat", 0); down.put("elapsedMs", 0L);
            down.put("scanCode", 240); down.put("deviceId", 5); down.put("source", 769);
            down.put("cancelled", false);
            Map<String, Object> up = new LinkedHashMap<>(down);
            up.put("id", 43); up.put("sessionMs", 1347L); up.put("elapsedMs", 147L); up.put("action", 1);
            RemoteButtonReport.write(directory.toFile(), List.of(down, up), 3, "2026-10-19T15:00:00Z");
            String text = Files.readString(report);
            require(text.contains("Events: 2; dropped: 3"), "Explicit history completeness");
            require(text.contains("Started (UTC): 2026-10-19T15:00:00Z"), "Distinguish previous sessions");
            require(text.contains("#42 +1200ms 4159 keyCode=4159 DOWN"), "Preserve OEM keyCode and ordering");
            require(text.contains("#43 +1347ms 4159 keyCode=4159 UP repeat=0 heldMs=147"), "Preserve release and timing");
            require(!Files.exists(pending), "Completed report has no pending file");
            RemoteButtonReport.write(directory.toFile(), List.of(), 0, "new-session");
            require(!Files.readString(report).contains("keyCode=4159"), "Replace previous session without mixing keys");
            require(Files.readString(report).contains("Events: 0; dropped: 0"), "Empty capture is explicit");
            System.out.println("RemoteButtonReport: all checks passed");
        } finally {
            Files.deleteIfExists(report); Files.deleteIfExists(pending); Files.deleteIfExists(directory);
        }
    }
}
