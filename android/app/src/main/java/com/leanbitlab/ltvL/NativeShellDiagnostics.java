package com.leanbitlab.ltvL;

import dadb.Dadb;
import dadb.AdbShellResponse;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Shared by every ADB shell entry point, including timers and recovery. In-memory only. */
final class NativeShellDiagnostics {
    private static final List<Map<String, Object>> RECENT = new ArrayList<>();
    private static final List<Map<String, Object>> FAILURES = new ArrayList<>();
    private static final long START = System.nanoTime();
    static AdbShellResponse execute(Dadb adb, String command, String source) throws Exception {
        long start = System.nanoTime();
        var event = new LinkedHashMap<String, Object>();
        event.put("source", source);
        event.put("command", DiagnosticRedactor.redact(command));
        try {
            var response = adb.shell(command);
            event.put("exitCode", response.getExitCode());
            event.put("stdout", DiagnosticRedactor.redact(response.getOutput()));
            event.put("stderr", DiagnosticRedactor.redact(response.getErrorOutput()));
            event.put("status", response.getExitCode() == 0 ? "success" : "error");
            return response;
        } catch (Exception | LinkageError failure) {
            event.put("status", "error");
            event.put("exception", AdbOperationDiagnostics.exceptionKind(failure));
            event.put("errorText", DiagnosticRedactor.redact(failure.toString()));
            throw failure;
        } finally {
            event.put("elapsedMs", (start - START) / 1000000);
            event.put("durationMs", (System.nanoTime() - start) / 1000000);
            add(event);
        }
    }
    private static synchronized void add(Map<String, Object> event) {
        RECENT.add(event);
        if (RECENT.size() > 30) RECENT.remove(0);
        if ("error".equals(event.get("status"))) {
            FAILURES.add(event);
            if (FAILURES.size() > 50) FAILURES.remove(0);
        }
    }
    static void failure(String source, Throwable failure) {
        add(Map.of("source", source, "status", "error", "elapsedMs", (System.nanoTime() - START) / 1000000,
            "exception", AdbOperationDiagnostics.exceptionKind(failure),
            "errorText", DiagnosticRedactor.redact(failure.toString())));
    }
    static synchronized Map<String, Object> snapshot() {
        return Map.of("recent", new ArrayList<>(RECENT), "failures", new ArrayList<>(FAILURES));
    }
    static synchronized void clear() { RECENT.clear(); FAILURES.clear(); }
}
