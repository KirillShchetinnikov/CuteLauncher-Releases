package com.leanbitlab.ltvL;

import org.junit.Test;
import static org.junit.Assert.*;
import java.util.List;

public class DiagnosticErrorDetailsTest {
    @Test public void wrappedFailureRetainsRootCauseWithoutCredentials() {
        var root = new SecurityException("password=hunter2");
        var failure = new IllegalStateException("Operation failed", root);
        failure.addSuppressed(new RuntimeException("private cleanup"));
        var details = DiagnosticErrorDetails.from(failure);
        assertEquals("IllegalStateException", details.get("type"));
        assertTrue(details.toString().contains("SecurityException"));
        assertFalse(details.toString().contains("hunter2"));
        assertFalse(details.toString().contains("private cleanup"));
        assertEquals(1, details.get("suppressedCount"));
    }
    @Test public void causeChainIsBoundedAndCyclesTerminate() {
        var first = new RuntimeException("first");
        var second = new RuntimeException("second", first);
        first.initCause(second);
        assertEquals(1, ((List<?>)DiagnosticErrorDetails.from(first).get("causes")).size());
        Throwable failure = new RuntimeException();
        for (int index = 0; index < 20; index++) failure = new RuntimeException(failure);
        assertEquals(4, ((List<?>)DiagnosticErrorDetails.from(failure).get("causes")).size());
    }
}
