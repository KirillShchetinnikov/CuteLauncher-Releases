package com.leanbitlab.ltvL;

import java.util.*;
import java.util.regex.Pattern;

/** Only live tasks from stack list; recents supplies ordering, never invents live windows. */
final class RecentTaskPolicy {
    record Task(int id, String pkg) {}
    private static final Pattern LIVE = Pattern.compile("taskId=(\\d+):\\s+([A-Za-z][A-Za-z0-9_.]*)/");
    private static final Pattern RECENT = Pattern.compile("\\* Recent #\\d+:.*?Task\\{[^\\r\\n]*? #(\\d+)");
    private static final Pattern USER_ZERO = Pattern.compile("\\buserId=0\\b");
    static List<Task> parse(String stacks, String recents) {
        if (stacks.length() > 4 * 1024 * 1024 || recents.length() > 4 * 1024 * 1024)
            throw new IllegalArgumentException("Task response too large");
        Map<Integer, Task> live = new LinkedHashMap<>();
        for (String line : stacks.split("\\r?\\n")) {
            if (!USER_ZERO.matcher(line).find()) continue;
            var matches = LIVE.matcher(line);
            if (!matches.find()) continue;
            int id;
            try { id = Integer.parseInt(matches.group(1)); } catch (NumberFormatException invalid) { continue; }
            if (id > 0 && live.size() < 256) live.put(id, new Task(id, matches.group(2)));
        }
        List<Task> ordered = new ArrayList<>();
        var recent = RECENT.matcher(recents);
        while (recent.find()) {
            try {
                Task task = live.remove(Integer.parseInt(recent.group(1)));
                if (task != null) ordered.add(task);
            } catch (NumberFormatException ignored) { }
        }
        ordered.addAll(live.values());
        return ordered;
    }
}
