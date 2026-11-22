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
    @Test public void connectionCheckAcceptsRootAndWarnsOnce() throws Exception {
        var context = org.robolectric.RuntimeEnvironment.getApplication();
        assertEquals("ready", checkConnection(context, "0", "2000"));
        assertFalse(AdbShellIdentity.warningPending(context));
        assertEquals("denied", checkConnection(context, "10", "0"));
        assertEquals("denied", checkConnection(context, "0", "1000"));
        assertFalse(AdbShellIdentity.takeWarning(context));

        assertEquals("ready", checkConnection(context, "0", "0"));
        assertEquals("ready", checkConnection(context, "0", "0"));
        assertTrue(AdbShellIdentity.takeWarning(context));
        assertEquals("ready", checkConnection(context, "0", "0"));
        assertFalse(AdbShellIdentity.takeWarning(context));
    }

    private static String checkConnection(android.content.Context context, String user, String uid) throws Exception {
        return AdbBridge.perform(context, new AdbBridge.Shell() {
            @Override public String execute(String command) {
                return switch (command) {
                    case "am get-current-user" -> user;
                    case "id -u" -> uid;
                    default -> throw new AssertionError(command);
                };
            }
            @Override public void close() { }
        }, "check");
    }

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
