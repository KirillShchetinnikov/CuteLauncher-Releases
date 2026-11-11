package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Context;
import android.content.pm.*;
import android.provider.Settings;
import android.view.accessibility.AccessibilityManager;
import java.util.*;
import org.json.JSONObject;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36}, application = android.app.Application.class)
public class AppPermissionsTest {
    private static final String COMPONENT = "example.app/example.app.Service";
    Context context;
    AppPermissions manager;
    Shell shell;
    PackageInfo pkg;
    static final class Shell implements AdbBridge.Shell {
        Context c; String services = "other.app/.Service", enabled = "1";
        boolean fail, rejectGrant, addDuringReconnect;
        String user = "0";
        final Map<String, String> modes = new LinkedHashMap<>();
        final List<String> writes = new ArrayList<>();
        Shell(Context c) {
            this.c = c;
            for (String op : AdbAccessibilityOps.OPERATIONS) modes.put(op, "deny");
        }
        public String execute(String command) {
            if (fail) throw new IllegalStateException("offline");
            if (command.equals("id -u")) return "2000";
            if (command.equals("am get-current-user")) return user;
            if (command.startsWith("appops get")) {
                String op = command.split(" ")[5];
                return modes.get(op).equals("unsupported") ? "Unknown operation" : op + ": " + modes.get(op);
            }
            if (command.equals("settings get secure enabled_accessibility_services")) return services;
            if (command.equals("settings get secure accessibility_enabled")) return enabled;
            writes.add(command);
            if (command.startsWith("appops set")) {
                if (!rejectGrant) modes.put(command.split(" ")[5], "allow");
            } else if (command.equals("settings delete secure enabled_accessibility_services")) services = "null";
            else if (command.startsWith("settings put secure enabled_accessibility_services '")) {
                services = command.substring(command.indexOf('\'') + 1, command.lastIndexOf('\''));
                if (addDuringReconnect && !services.contains(COMPONENT)) {
                    services += ":late.app/.Service"; addDuringReconnect = false;
                }
            } else if (command.equals("settings put secure accessibility_enabled 1")) enabled = "1";
            else throw new AssertionError(command);
            Settings.Secure.putString(c.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES, services);
            Settings.Secure.putInt(c.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED, Integer.parseInt(enabled));
            return "";
        }
        public void close() { }
    }
    @Before public void setup() {
        context = RuntimeEnvironment.getApplication();
        AppPermissions.prefs(context).edit().clear().commit();
        pkg = new PackageInfo(); pkg.packageName = "example.app";
        pkg.applicationInfo = new ApplicationInfo(); pkg.applicationInfo.packageName = pkg.packageName;
        pkg.applicationInfo.enabled = true; pkg.applicationInfo.nonLocalizedLabel = "Example";
        pkg.signingInfo = new SigningInfo();
        shadowOf(pkg.signingInfo).setSignatures(new Signature[]{new Signature("010203")});
        shadowOf(context.getPackageManager()).installPackage(pkg);
        ServiceInfo service = new ServiceInfo(); service.name = "example.app.Service";
        service.packageName = pkg.packageName; service.applicationInfo = pkg.applicationInfo;
        service.enabled = true; service.permission = "android.permission.BIND_ACCESSIBILITY_SERVICE";
        ResolveInfo resolve = new ResolveInfo(); resolve.serviceInfo = service;
        AccessibilityServiceInfo info = new AccessibilityServiceInfo();
        ReflectionHelpers.setField(info, "mResolveInfo", resolve);
        shadowOf((AccessibilityManager) context.getSystemService(Context.ACCESSIBILITY_SERVICE))
            .setInstalledAccessibilityServiceList(List.of(info));
        shell = new Shell(context); manager = new AppPermissions(context, shell);
    }
    JSONObject saved() throws Exception { return new JSONObject(AppPermissions.prefs(context).getString(COMPONENT, "{}")); }
    void grant() throws Exception {
        var plan = manager.run("preview", COMPONENT, null, null);
        manager.run("apply", COMPONENT, null, (String) plan.get("token"));
    }
    @Test public void listingAndRestoreDefaultNeverGrantAccess() throws Exception {
        var rows = (List<?>) manager.run("list", null, null, null).get("services");
        assertEquals(1, rows.size());
        assertEquals(true, ((Map<?, ?>)rows.get(0)).get("restore"));
        manager.run("configure", COMPONENT, true, null);
        manager.recover(100000);
        assertTrue(shell.writes.isEmpty()); assertFalse(saved().optBoolean("managed"));
    }
    @Test public void systemAndUpdatedSystemAppsAreHiddenAndRejectAllActions() throws Exception {
        for (int flags : new int[]{ApplicationInfo.FLAG_SYSTEM, ApplicationInfo.FLAG_UPDATED_SYSTEM_APP,
                ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP}) {
            pkg.applicationInfo.flags = flags;
            shadowOf(context.getPackageManager()).installPackage(pkg);
            assertTrue(((List<?>)manager.run("list", null, null, null).get("services")).isEmpty());
            for (String action : List.of("inspect", "preview", "apply", "configure", "reconnect", "disable")) {
                try { manager.run(action, COMPONENT, true, "token"); fail(action); }
                catch (IllegalStateException expected) { assertEquals("target_missing", expected.getMessage()); }
            }
            assertTrue(shell.writes.isEmpty());
        }
    }
    @Test public void legacySystemConsentIsRemovedWithoutChangingItsPermissions() throws Exception {
        grant(); shell.writes.clear();
        pkg.applicationInfo.flags = ApplicationInfo.FLAG_SYSTEM;
        shadowOf(context.getPackageManager()).installPackage(pkg);
        manager.recover(100000);
        assertTrue(shell.writes.isEmpty());
        assertFalse(AppPermissions.prefs(context).contains(COMPONENT));
        assertTrue(AppPermissionOps.contains(shell.services, COMPONENT));
    }
    @Test public void packageBecomingSystemAfterPreviewCannotBeGranted() throws Exception {
        var plan = manager.run("preview", COMPONENT, null, null);
        pkg.applicationInfo.flags = ApplicationInfo.FLAG_UPDATED_SYSTEM_APP;
        shadowOf(context.getPackageManager()).installPackage(pkg);
        try { manager.run("apply", COMPONENT, null, (String)plan.get("token")); fail(); }
        catch (IllegalStateException expected) { assertEquals("target_missing", expected.getMessage()); }
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void explicitGrantAppliesOpsBeforeEnableAndPreservesOthers() throws Exception {
        grant();
        assertTrue(saved().getBoolean("managed")); assertTrue(saved().optBoolean("restore", true));
        assertTrue(shell.services.contains("other.app/.Service"));
        assertTrue(AppPermissionOps.contains(shell.services, COMPONENT));
        assertTrue(shell.writes.get(0).startsWith("appops set"));
        for (String mode : shell.modes.values()) assertEquals("allow", mode);
    }
    @Test public void inspectingAfterActionRefreshesModesWithoutLosingItsResult() throws Exception {
        grant(); shell.modes.put("AUTO_START", "deny"); shell.writes.clear();
        var row = (Map<?, ?>)manager.run("inspect", COMPONENT, null, null).get("service");
        assertEquals("deny", ((Map<?, ?>)row.get("modes")).get("AUTO_START"));
        assertEquals("success", row.get("result"));
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void staleOrMissingConsentTokenCannotWrite() throws Exception {
        try { manager.run("apply", COMPONENT, null, "invalid"); fail(); } catch (IllegalStateException expected) { }
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void unsupportedOpsAreSkippedAndNotReportedAsGranted() throws Exception {
        shell.modes.put("AUTO_START", "unsupported"); grant();
        assertTrue(shell.writes.stream().noneMatch(s -> s.contains("AUTO_START")));
        assertEquals("unsupported", saved().getJSONObject("modes").getString("AUTO_START"));
    }
    @Test public void rejectedAppOpDoesNotEnableServiceOrReportSuccess() throws Exception {
        shell.rejectGrant = true;
        try { grant(); fail(); } catch (IllegalStateException expected) { }
        assertFalse(AppPermissionOps.contains(shell.services, COMPONENT));
        assertEquals("pending", saved().getString("result"));
    }
    @Test public void recoveryRestoresBothOpsAndMissingService() throws Exception {
        grant(); shell.services = "other.app/.Service"; shell.modes.put("AUTO_START", "deny"); shell.writes.clear();
        manager.recover(100000);
        assertTrue(AppPermissionOps.contains(shell.services, COMPONENT));
        assertEquals("allow", shell.modes.get("AUTO_START"));
        assertEquals("restored", saved().getString("result"));
    }
    @Test public void enabledServiceIsNotPeriodicallyReconnected() throws Exception {
        grant(); shell.writes.clear(); manager.recover(100000);
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void pausedRecoveryLeavesServiceAndGrantsUntouched() throws Exception {
        grant(); manager.run("configure", COMPONENT, false, null); shell.writes.clear();
        manager.recover(100000);
        assertTrue(shell.writes.isEmpty()); assertTrue(AppPermissionOps.contains(shell.services, COMPONENT));
    }
    @Test public void disablingOfflineStillRevokesAutomaticConsent() throws Exception {
        grant(); shell.fail = true;
        try { manager.run("disable", COMPONENT, null, null); fail(); } catch (IllegalStateException expected) { }
        assertFalse(saved().getBoolean("managed")); assertFalse(saved().getBoolean("restore"));
        shell.fail = false; shell.services = "other.app/.Service"; shell.writes.clear(); manager.recover(100000);
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void reconnectMergesLatestServiceList() throws Exception {
        grant(); shell.addDuringReconnect = true; manager.run("reconnect", COMPONENT, null, null);
        assertTrue(shell.services.contains("late.app/.Service"));
        assertTrue(shell.services.contains("other.app/.Service"));
        assertTrue(AppPermissionOps.contains(shell.services, COMPONENT));
    }
    @Test public void uninstallAndSignerChangeDoNotReuseConsent() throws Exception {
        grant(); AppPermissions.packageRemoved(context, "example.app");
        assertFalse(saved().optBoolean("managed"));
        grant(); shadowOf(pkg.signingInfo).setSignatures(new Signature[]{new Signature("040506")});
        shadowOf(context.getPackageManager()).installPackage(pkg);
        shell.writes.clear(); manager.recover(100000);
        assertTrue(shell.writes.isEmpty()); assertFalse(saved().optBoolean("managed"));
        assertEquals("identity_changed", saved().getString("result"));
    }
    @Test public void adbFailureHasBoundedRetriesAndPreservesConsent() throws Exception {
        grant(); shell.fail = true; manager.recover(100000);
        assertEquals(115000, saved().getLong("next"));
        manager.recover(100001); assertEquals(1, saved().getInt("attempts"));
        manager.recover(115000); assertEquals(175000, saved().getLong("next"));
        manager.recover(175000); assertEquals(3775000, saved().getLong("next"));
        assertTrue(saved().getBoolean("managed"));
    }
    @Test public void sameSignerReinstallWithoutBroadcastNeedsNewConsent() throws Exception {
        grant(); pkg.firstInstallTime = 12345;
        shadowOf(context.getPackageManager()).installPackage(pkg);
        shell.writes.clear(); manager.recover(100000);
        assertTrue(shell.writes.isEmpty()); assertFalse(saved().optBoolean("managed"));
    }
    @Test public void wrongAndroidUserCannotWrite() throws Exception {
        shell.user = "10";
        try { grant(); fail(); } catch (IllegalStateException expected) { }
        assertTrue(shell.writes.isEmpty());
    }
    @Test public void deletingLastServiceDoesNotDisableGlobalAccessibility() throws Exception {
        shell.services = COMPONENT; AppPermissionOps.setEnabled(shell, COMPONENT, false);
        assertEquals("null", shell.services); assertEquals("1", shell.enabled);
    }
}
