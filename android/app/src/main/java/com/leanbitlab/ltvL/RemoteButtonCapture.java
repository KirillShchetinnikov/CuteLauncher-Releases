package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Short, bounded, in-memory observation. It never decides whether to consume a key. */
final class RemoteButtonCapture {
    static final long DURATION_MS = 120_000;
    static final int CAPACITY = 256;
    private final List<Map<String, Object>> events = new ArrayList<>();
    private long deadline;
    private long sequence;
    private long startedAt;
    private int dropped;

    void start(long now) { events.clear(); startedAt = now; dropped = 0; deadline = now + DURATION_MS; }
    void stop() { deadline = 0; }
    boolean active(long now) { return deadline != 0 && now < deadline; }
    long remaining(long now) { return active(now) ? deadline - now : 0; }

    boolean record(long now, Map<String, Object> event) {
        if (!active(now)) return false;
        if (events.size() == CAPACITY) { events.remove(0); dropped++; }
        Map<String, Object> copy = new LinkedHashMap<>(event);
        copy.put("id", ++sequence);
        copy.put("sessionMs", Math.max(0L, now - startedAt));
        events.add(copy);
        return true;
    }

    int dropped() { return dropped; }

    List<Map<String, Object>> snapshot() {
        List<Map<String, Object>> copy = new ArrayList<>();
        for (Map<String, Object> event : events) copy.add(new LinkedHashMap<>(event));
        return copy;
    }
}
