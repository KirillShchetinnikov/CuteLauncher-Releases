package com.leanbitlab.ltvL;

import java.util.List;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class AdbRuntimeCompatibilityTest {
    @Test public void restoreSelectionFiltersServiceScreensWithoutMutatingInput() {
        var fallback = Map.<String, Object>of("component", "com.vendor/.FallbackHome", "enabled", true);
        var disabled = Map.<String, Object>of("component", "com.builtin/com.builtin.Home", "enabled", false);
        var enabled = Map.<String, Object>of("component", "com.other/com.other.Home", "enabled", true);
        var candidates = List.of(fallback, disabled, enabled);
        assertEquals("com.builtin/com.builtin.Home", AdbLauncherPolicy.restoreTarget("com.builtin/.Home", candidates));
        assertEquals("com.other/com.other.Home", AdbLauncherPolicy.restoreTarget("missing/Home", candidates));
        assertEquals("com.builtin/com.builtin.Home", AdbLauncherPolicy.restoreTarget("", List.of(fallback, disabled)));
        assertEquals("", AdbLauncherPolicy.restoreTarget("", List.of(fallback)));
        assertEquals(List.of(fallback, disabled, enabled), candidates);
    }

    @Test public void linkageFailureIsNotReportedAsConnectionFailure() {
        assertEquals("operation_failed", AdbOperationDiagnostics.failureStatus(new NoSuchMethodError("Stream.toList")));
        assertEquals("unavailable", AdbOperationDiagnostics.failureStatus(new java.net.ConnectException()));
        assertEquals("unavailable", AdbOperationDiagnostics.failureStatus(new java.net.SocketTimeoutException()));
    }
}
