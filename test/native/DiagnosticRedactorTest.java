package com.leanbitlab.ltvL;

public final class DiagnosticRedactorTest {
    public static void main(String[] args) {
        String output = DiagnosticRedactor.redact("ID: 0 SSID: \"Home wifi\"\n"
            + "cname=com.google.android.tungsten.setupwraith\n"
            + "192.168.1.73 ::1 fe80::abcd 00:11:22:33:44:55\n"
            + "/private/backup.json C:\\Users\\Alice\\backup.json\n"
            + "https://alice:pass@example.com/path alice@example.com\n"
            + "password=hunter2\ntoken=abcdef\ncom.private.application\n"
            + "java.lang.SecurityException: Permission Denial");
        for (String secret : new String[]{"Home wifi", "192.168", "::1", "fe80", "00:11:22",
                "Alice", "alice", "hunter2", "abcdef", "com.private.application", "/private/"})
            if (output.contains(secret)) throw new AssertionError(secret + " was not redacted");
        if (!output.contains("com.google.android.tungsten.setupwraith") || !output.contains("Permission Denial"))
            throw new AssertionError("Useful context removed");
        if (DiagnosticRedactor.redact("x".repeat(100000)).length() > 2061) throw new AssertionError("Not bounded");
        AdbOperationDiagnostics.begin();
        AdbOperationDiagnostics.command("pm disable-user --user 0 'com.google.android.tungsten.setupwraith'");
        AdbOperationDiagnostics.exit(1);
        AdbOperationDiagnostics.output("", "Permission Denial");
        AdbOperationDiagnostics.failure(new java.net.ConnectException("192.168.1.73"));
        String metadata = AdbOperationDiagnostics.finish().toString();
        if (metadata.contains("192.168") || !metadata.contains("Permission Denial")) throw new AssertionError(metadata);
        if (!AdbOperationDiagnostics.finish().isEmpty()) throw new AssertionError("Thread-local leaked");
        String details = DiagnosticErrorDetails.from(new SecurityException("password=hunter2")).toString();
        if (details.contains("hunter2") || !details.contains("security")) throw new AssertionError(details);
        System.out.println("DiagnosticRedactorTest passed");
    }
}
