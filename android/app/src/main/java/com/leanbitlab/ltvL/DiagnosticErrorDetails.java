package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.Map;
import java.util.LinkedHashMap;
import java.util.IdentityHashMap;

/** Redacted evidence for native channel errors, without changing their UI-facing code. */
final class DiagnosticErrorDetails {
    static Map<String, Object> from(Throwable failure) {
        var frames = new ArrayList<String>();
        for (var frame : failure.getStackTrace()) {
            if (frames.size() >= 12) break;
            frames.add(DiagnosticRedactor.redact(frame.getClassName() + "." + frame.getMethodName()
                + " (" + frame.getFileName() + ":" + frame.getLineNumber() + ")"));
        }
        var result = new LinkedHashMap<String, Object>();
        result.put("exception", AdbOperationDiagnostics.exceptionKind(failure));
        result.put("type", failure.getClass().getSimpleName());
        result.put("message", DiagnosticRedactor.redact(failure.toString()));
        result.put("frames", frames);
        var causes = new ArrayList<Map<String, Object>>();
        var seen = new IdentityHashMap<Throwable, Boolean>();
        seen.put(failure, true);
        Throwable cause = failure.getCause();
        while (cause != null && causes.size() < 4 && seen.put(cause, true) == null) {
            causes.add(Map.of("exception", AdbOperationDiagnostics.exceptionKind(cause),
                "type", cause.getClass().getSimpleName(),
                "message", DiagnosticRedactor.redact(cause.toString())));
            cause = cause.getCause();
        }
        if (!causes.isEmpty()) result.put("causes", causes);
        result.put("suppressedCount", failure.getSuppressed().length);
        return result;
    }
}
