package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ComponentName;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class PermissionRecoveryAccessTest {
    private static class Shell implements AdbBridge.Shell {
        String services, enabled = "1";
        final List<String> commands = new ArrayList<>();
        boolean addOther;
        String restricted = "default";
        boolean rejectRestricted;
        Shell(String services) { this.services = services; }
        public String execute(String command) {
            commands.add(command);
            if (command.startsWith("appops get ")) return "ACCESS_RESTRICTED_SETTINGS: " + restricted;
            if (command.startsWith("appops set ")) {
                if (!rejectRestricted) restricted = "allow";
                return "";
            }
            if (command.equals("settings get secure enabled_accessibility_services")) return services;
            if (command.equals("settings get secure accessibility_enabled")) return enabled;
            String prefix = "settings put secure enabled_accessibility_services '";
            if (command.startsWith(prefix)) {
                services = command.substring(prefix.length(), command.length() - 1);
                if (addOther) { services += ":late/.Service"; addOther = false; }
                return "";
            }
            if (command.equals("settings put secure accessibility_enabled 1")) { enabled = "1"; return ""; }
            throw new AssertionError(command);
        }
        public void close() { }
    }
    @Test @Config(sdk = 34) public void updateRestoresRestrictedSettingsBeforeEnablingService() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get();
            var shell = new Shell("other/.Service"); shell.enabled = "0"; shell.restricted = "deny";
            assertEquals("success", PermissionRecoveryAccess.reconnect(c, shell, false));
            assertEquals("allow", shell.restricted);
            assertTrue(shell.services.contains(new ComponentName(c, LauncherAccessibilityService.class).flattenToString()));
            int grant = shell.commands.indexOf("appops set --user 0 '" + c.getPackageName() + "' ACCESS_RESTRICTED_SETTINGS allow");
            int enable = shell.commands.indexOf("settings put secure enabled_accessibility_services '" + shell.services + "'");
            assertTrue(grant >= 0 && grant < enable);
        }
    }
    @Test @Config(sdk = 34) public void rejectedRestrictedSettingsDoesNotReportSuccess() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var shell = new Shell("other/.Service"); shell.restricted = "deny"; shell.rejectRestricted = true;
            try { PermissionRecoveryAccess.reconnect(controller.get(), shell, false); fail(); }
            catch (PermissionRecoveryAccess.Unavailable expected) { assertEquals("permission_rejected", expected.reason); }
            assertEquals("other/.Service", shell.services);
        }
    }
    @Test @Config(sdk = {28, 34}) public void updateLeavesDefaultRestrictedSettingsUnchanged() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var shell = new Shell("other/.Service"); shell.enabled = "0";
            PermissionRecoveryAccess.reconnect(controller.get(), shell, false);
            assertEquals("default", shell.restricted);
            assertTrue(shell.commands.stream().noneMatch(command -> command.startsWith("appops set")));
        }
    }
    @Test @Config(sdk = 34) public void healthDoesNotChangeRestrictedSettings() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get();
            var shell = new Shell(new ComponentName(c, LauncherAccessibilityService.class).flattenToString());
            shell.restricted = "deny";
            PermissionRecoveryAccess.reconnect(c, shell, true);
            assertEquals("deny", shell.restricted);
            assertTrue(shell.commands.stream().noneMatch(command -> command.startsWith("appops")));
        }
    }
    @Test public void rebindPreservesOtherServicesChangedDuringReconnect() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); String own = new ComponentName(c, LauncherAccessibilityService.class).flattenToString();
            var shell = new Shell("other/.Service:" + own); shell.addOther = true;
            assertEquals("success", PermissionRecoveryAccess.reconnect(c, shell, true));
            assertEquals("other/.Service:late/.Service:" + own, shell.services);
        }
    }
    @Test public void backgroundRebindDoesNotWriteAfterPermissionWasRevoked() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var shell = new Shell("other/.Service"); shell.enabled = "0";
            assertEquals("revoked", PermissionRecoveryAccess.reconnect(controller.get(), shell, true));
            assertTrue(shell.commands.stream().noneMatch(command -> command.startsWith("settings put")));
        }
    }
    @Test public void interruptionStillRestoresOnlyTheOwnEnabledComponent() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); String own = new ComponentName(c, LauncherAccessibilityService.class).flattenToString();
            var shell = new Shell("other/.Service:" + own);
            Thread.currentThread().interrupt();
            try { PermissionRecoveryAccess.reconnect(c, shell, true); fail(); }
            catch (InterruptedException expected) { assertEquals("other/.Service:" + own, shell.services); }
            finally { Thread.interrupted(); }
        }
    }
}
