package com.leanbitlab.ltvL;

import android.app.Activity;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import java.util.ArrayList;
import java.util.List;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class VpnAlwaysOnTest {
    static final class SimulatedDeath extends Error { }
    @Test public void interruptedDisableRetainsOwnershipForRetry() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var prefs = activity.get().getSharedPreferences(VpnController.PREFS, 0);
            var shell = new Shell();
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            VpnAlwaysOn.Shell interrupted = command -> {
                if (command.contains(" get secure ")) return shell.execute(command);
                throw new SimulatedDeath();
            };
            assertThrows(SimulatedDeath.class, () -> VpnAlwaysOn.configure(prefs, interrupted, 0, ""));
            assertEquals("com.happproxy", prefs.getString("ownedAlwaysOn", ""));
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, ""));
            assertEquals("null", shell.app);
        }
    }
    static final class Shell implements VpnAlwaysOn.Shell {
        String app = "null", lockdown = "null";
        boolean reject;
        final List<String> writes = new ArrayList<>();
        public String execute(String command) {
            if (command.equals("settings --user 0 get secure always_on_vpn_app")) return app;
            if (command.equals("settings --user 0 get secure always_on_vpn_lockdown")) return lockdown;
            writes.add(command);
            if (reject) return "";
            if (command.equals("settings --user 0 delete secure always_on_vpn_app")) app = "null";
            else if (command.startsWith("settings --user 0 put secure always_on_vpn_app '"))
                app = command.substring(command.indexOf('\'') + 1, command.lastIndexOf('\''));
            else throw new AssertionError(command);
            return "";
        }
    }
    @Test public void persistsSelectionAndRestoresPreviousWithoutChangingLockdown() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var prefs = activity.get().getSharedPreferences(VpnController.PREFS, 0);
            var shell = new Shell(); shell.app = "org.amnezia.awg";
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            assertEquals("com.happproxy", shell.app);
            assertTrue(prefs.getBoolean("restartRequired", false));
            assertEquals("org.amnezia.awg", prefs.getString("previousAlwaysOn", ""));
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, "com.mantaray.vpn"));
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, ""));
            assertEquals("org.amnezia.awg", shell.app);
            assertFalse(prefs.contains("ownedAlwaysOn"));
            assertTrue(shell.writes.stream().allMatch(command -> command.contains("always_on_vpn_app")));
            assertEquals("null", shell.lockdown);
        }
    }
    @Test public void refusesLockdownAndExternalChanges() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var prefs = activity.get().getSharedPreferences(VpnController.PREFS, 0);
            var shell = new Shell(); shell.lockdown = "1";
            assertFalse(VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            assertTrue(shell.writes.isEmpty());
            shell.lockdown = "0";
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            shell.app = "another.vpn";
            int count = shell.writes.size();
            assertFalse(VpnAlwaysOn.configure(prefs, shell, 0, "com.mantaray.vpn"));
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, ""));
            assertEquals(count, shell.writes.size());
            assertEquals("another.vpn", shell.app);
            assertFalse(prefs.contains("ownedAlwaysOn"));
        }
    }
    @Test public void doesNotClearUnownedSelectionAndReadbackFailureIsNotSuccess() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var prefs = activity.get().getSharedPreferences(VpnController.PREFS, 0);
            var shell = new Shell(); shell.app = "another.vpn";
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, ""));
            assertTrue(shell.writes.isEmpty());
            shell.reject = true;
            assertThrows(IllegalStateException.class, () -> VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            assertEquals("another.vpn", shell.app);
            assertEquals("", prefs.getString("ownedAlwaysOn", ""));
            assertFalse(prefs.getBoolean("restartRequired", false));
        }
    }
    @Test public void restoresNoSelectionAndClearsRestartNoticeOnlyAtBoot() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var context = activity.get(); var prefs = context.getSharedPreferences(VpnController.PREFS, 0);
            var shell = new Shell();
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, "com.happproxy"));
            assertTrue(VpnAlwaysOn.configure(prefs, shell, 0, ""));
            assertEquals("null", shell.app);
            assertTrue(prefs.getBoolean("restartRequired", false));
            VpnAlwaysOn.boot(context);
            assertFalse(prefs.getBoolean("restartRequired", true));
        }
    }
}
