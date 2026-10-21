package com.leanbitlab.ltvL;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.function.Supplier;

/** Per-observation isolation; errors never become false success or exported exception text. */
final class ReadOnlyDiagnosticChecks {
    private static final Set<String> STATUSES = Set.of("available", "notGranted", "notConfigured", "restricted", "unsupported", "unknown");
    private final Map<String, String> results = new LinkedHashMap<>();
    void add(String id, Supplier<String> read) {
        String status;
        try { status = read.get(); }
        catch (RuntimeException failure) { status = "unknown"; }
        results.put(id, STATUSES.contains(status == null ? "" : status) ? status : "unknown");
    }
    Map<String, String> snapshot() { return new LinkedHashMap<>(results); }
}
