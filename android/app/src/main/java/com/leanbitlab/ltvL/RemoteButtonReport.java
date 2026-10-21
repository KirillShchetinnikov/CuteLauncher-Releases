package com.leanbitlab.ltvL;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

/** Writes only the latest explicitly requested, bounded capture. */
final class RemoteButtonReport {
    static void write(File directory, List<Map<String, Object>> history, int dropped, String started)
            throws IOException {
        StringBuilder text = new StringBuilder("CuteLauncher remote button capture\n")
            .append("Started (UTC): ").append(started).append('\n')
            .append("Events: ").append(history.size()).append("; dropped: ").append(dropped)
            .append("\nOnly events received during the explicit capture session are included.\n\n");
        for (Map<String, Object> event : history) {
            int action = ((Number)event.get("action")).intValue();
            text.append('#').append(event.get("id"))
                .append(" +").append(event.get("sessionMs")).append("ms ")
                .append(event.get("keyName")).append(" keyCode=").append(event.get("keyCode"))
                .append(' ').append(action == 0 ? "DOWN" : action == 1 ? "UP" : "MULTIPLE")
                .append(" repeat=").append(event.get("repeat"))
                .append(" heldMs=").append(event.get("elapsedMs"))
                .append(" scanCode=").append(event.get("scanCode"))
                .append(" deviceId=").append(event.get("deviceId"))
                .append(" source=").append(event.get("source"))
                .append(" cancelled=").append(event.get("cancelled")).append('\n');
        }
        File pending = new File(directory, "remote-buttons-last.tmp");
        Files.write(pending.toPath(), text.toString().getBytes(StandardCharsets.UTF_8));
        Files.move(pending.toPath(), new File(directory, "remote-buttons-last.txt").toPath(),
            StandardCopyOption.REPLACE_EXISTING);
    }
}
