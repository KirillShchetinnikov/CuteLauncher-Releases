package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.List;

/** Bounded five-minute crash window; ordinary stops and low-memory kills are not crashes. */
final class CrashLoopPolicy {
    static final long WINDOW = 300_000L;
    static final int LIMIT = 3;
    static List<Long> recent(List<Long> events, long now) {
        var result = new ArrayList<Long>();
        for (long at : events) if (at <= now && now - at < WINDOW) result.add(at);
        return result.subList(Math.max(0, result.size() - LIMIT), result.size());
    }
    static boolean blocked(List<Long> events, long now) { return recent(events, now).size() >= LIMIT; }
}
