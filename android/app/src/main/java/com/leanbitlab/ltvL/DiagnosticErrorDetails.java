package com.leanbitlab.ltvL;

import java.util.ArrayList;
import java.util.Map;

/** Redacted evidence for native channel errors, without changing their UI-facing code. */
final class DiagnosticErrorDetails {
    static Map<String, Object> from(Throwable failure) {
        var frames = new ArrayList<String>();
        for (var frame : failure.getStackTrace()) {
            if (frames.size() >= 12) break;
            frames.add(DiagnosticRedactor.redact(frame.getClassName() + "." + frame.getMethodName()
                + " (" + frame.getFileName() + ":" + frame.getLineNumber() + ")"));
        }
        return Map.of("exception", AdbOperationDiagnostics.exceptionKind(failure),
            "message", DiagnosticRedactor.redact(failure.toString()), "frames", frames);
    }
}
