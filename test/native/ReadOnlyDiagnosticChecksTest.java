package com.leanbitlab.ltvL;

public final class ReadOnlyDiagnosticChecksTest {
    public static void main(String[] args) {
        var checks = new ReadOnlyDiagnosticChecks();
        checks.add("denied", () -> "notGranted");
        checks.add("broken", () -> { throw new SecurityException("private"); });
        checks.add("afterFailure", () -> "available");
        checks.add("invalid", () -> "private");
        checks.add("null", () -> null);
        var result = checks.snapshot();
        if (!result.get("broken").equals("unknown") || !result.get("afterFailure").equals("available")
            || !result.get("denied").equals("notGranted") || !result.get("invalid").equals("unknown")
            || !result.get("null").equals("unknown") || result.toString().contains("private")) throw new AssertionError();
        result.clear();
        if (checks.snapshot().size() != 5) throw new AssertionError();
        System.out.println("ReadOnlyDiagnosticChecksTest passed");
    }
}
