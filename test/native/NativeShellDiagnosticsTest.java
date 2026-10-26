package com.leanbitlab.ltvL;

import java.util.List;

public final class NativeShellDiagnosticsTest {
    public static void main(String[] args) {
        NativeShellDiagnostics.clear();
        for (int i = 0; i < 70; i++)
            NativeShellDiagnostics.failure("sleepTimer", new java.net.ConnectException("192.168.1.73 password=hunter2"));
        var report = NativeShellDiagnostics.snapshot();
        if (((List<?>)report.get("recent")).size() != 30 || ((List<?>)report.get("failures")).size() != 50)
            throw new AssertionError("Unbounded native history");
        if (report.toString().contains("192.168") || report.toString().contains("hunter2"))
            throw new AssertionError("Private data retained");
        NativeShellDiagnostics.clear();
        if (!((List<?>)NativeShellDiagnostics.snapshot().get("recent")).isEmpty()
                || !((List<?>)NativeShellDiagnostics.snapshot().get("failures")).isEmpty())
            throw new AssertionError("Clear did not remove failures");
        if (((List<?>)report.get("recent")).isEmpty()) throw new AssertionError("Snapshot changed after clear");
        System.out.println("NativeShellDiagnosticsTest passed");
    }
}
