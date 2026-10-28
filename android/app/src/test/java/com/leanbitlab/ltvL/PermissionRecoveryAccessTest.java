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
        Shell(String services) { this.services = services; }
        public String execute(String command) {
            commands.add(command);
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
