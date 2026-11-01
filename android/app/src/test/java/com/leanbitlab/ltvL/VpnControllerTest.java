package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicReference;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class VpnControllerTest {
    @Test public void stoppingOldAttemptPreservesNewConfigurationStatus() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var prefs = lifecycle.get().getSharedPreferences(VpnController.PREFS, 0);
            prefs.edit().putString("startupStatus", "idle").commit();
            VpnStartupJob.recordStop(prefs, 1);
            assertEquals("idle", prefs.getString("startupStatus", ""));
            prefs.edit().putLong("startupAttempt", 2).putString("startupStatus", "pending").commit();
            VpnStartupJob.recordStop(prefs, 1);
            assertEquals("pending", prefs.getString("startupStatus", ""));
            VpnStartupJob.recordStop(prefs, 2);
            assertEquals("failed", prefs.getString("startupStatus", ""));
        }
    }
    @Test public void firstPanelSnapshotDoesNotWaitForAdb() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); install(context, "org.amnezia.awg");
            var reads = new java.util.concurrent.atomic.AtomicInteger();
            var vpn = new VpnController(context, () -> {
                reads.incrementAndGet(); return new VpnPolicy.Active("org.amnezia.awg", "home");
            }, () -> true);
            assertEquals(true, vpn.snapshot(false).get("active"));
            assertEquals(0, reads.get());
            assertEquals("org.amnezia.awg", vpn.snapshot().get("target"));
            assertEquals(1, reads.get());
        }
    }
    private void install(Activity context, String app) {
        var info = new ApplicationInfo(); info.packageName = app; info.enabled = true; info.nonLocalizedLabel = app; info.targetSdkVersion = 34;
        var service = new ServiceInfo(); service.name = app + ".VpnService"; service.packageName = app;
        service.applicationInfo = info; service.enabled = true; service.permission = "android.permission.BIND_VPN_SERVICE";
        var pkg = new PackageInfo(); pkg.packageName = app; pkg.applicationInfo = info; pkg.services = new ServiceInfo[]{service};
        var pm = Shadows.shadowOf(context.getPackageManager()); pm.installPackage(pkg);
        var resolved = new ResolveInfo(); resolved.serviceInfo = service;
        pm.addResolveInfoForIntent(new Intent("android.net.VpnService"), resolved);
    }
    @Test public void happUsesExplicitConnectAndDisconnectWithoutNamedProfile() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "com.happproxy"; install(context, app);
            var active = new AtomicBoolean(false);
            var vpn = new VpnController(context, () -> new VpnPolicy.Active(app, ""), active::get);
            for (String action : java.util.List.of("connect_without_ui", "disconnect_without_ui")) {
                var activity = new ActivityInfo(); activity.packageName = app; activity.name = app + ".External"; activity.exported = true;
                var resolved = new ResolveInfo(); resolved.activityInfo = activity;
                Shadows.shadowOf(context.getPackageManager()).addResolveInfoForIntent(
                    new Intent(Intent.ACTION_VIEW, android.net.Uri.parse("happ://" + action)).setPackage(app), resolved);
            }
            assertEquals("sent", vpn.command(app, "", true));
            var first = Shadows.shadowOf(context).getNextStartedActivity();
            assertEquals("happ://connect_without_ui", first.getDataString());
            assertEquals(app, first.getPackage());
            active.set(true);
            assertEquals("sent", vpn.command(app, "", false));
            assertEquals("happ://disconnect_without_ui", Shadows.shadowOf(context).getNextStartedActivity().getDataString());
        }
    }
    @Test public void mantarayUsesPublicActionsAndPreservesClientConfirmation() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "com.mantaray.vpn"; install(context, app);
            var active = new AtomicBoolean(false);
            var vpn = new VpnController(context, () -> new VpnPolicy.Active(app, ""), active::get);
            var activity = new ActivityInfo(); activity.packageName = app; activity.name = app + ".VpnActionActivity"; activity.exported = true;
            var resolved = new ResolveInfo(); resolved.activityInfo = activity;
            for (String action : java.util.List.of("CONNECT", "DISCONNECT"))
                Shadows.shadowOf(context.getPackageManager()).addResolveInfoForIntent(
                    new Intent(app + ".action." + action).setClassName(app, activity.name), resolved);
            assertEquals("sent", vpn.command(app, "", true));
            var first = Shadows.shadowOf(context).getNextStartedActivity();
            assertEquals(app + ".action.CONNECT", first.getAction());
            assertEquals(activity.name, first.getComponent().getClassName());
            active.set(true);
            assertEquals("connected", vpn.command(app, "", true));
            assertEquals("sent", vpn.command(app, "", false));
            assertEquals(app + ".action.DISCONNECT", Shadows.shadowOf(context).getNextStartedActivity().getAction());
            assertTrue(Shadows.shadowOf(context).getBroadcastIntents().isEmpty());
        }
    }
    @Test public void manualConnectionIsRememberedAndAnotherClientIsAdopted() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            install(context, "org.amnezia.awg"); install(context, "com.wireguard.android");
            var active = new AtomicBoolean(true);
            var owner = new AtomicReference<>(new VpnPolicy.Active("org.amnezia.awg", "home"));
            var vpn = new VpnController(context, owner::get, active::get);
            assertEquals("org.amnezia.awg", vpn.snapshot().get("target"));
            assertEquals("home", vpn.snapshot().get("profile"));
            assertEquals("", vpn.prefs.getString("bootApp", ""));
            active.set(false);
            assertEquals("org.amnezia.awg", vpn.snapshot().get("target"));
            active.set(true); owner.set(new VpnPolicy.Active("com.wireguard.android", "work"));
            assertEquals("com.wireguard.android", vpn.snapshot().get("target"));
            assertEquals("home", vpn.prefs.getString("profile_org.amnezia.awg", ""));
            owner.set(new VpnPolicy.Active("", ""));
            assertEquals("", vpn.snapshot().get("target"));
            assertEquals(false, vpn.snapshot().get("canControl"));
        }
    }
    @Test public void pinnedClientDoesNotControlAnotherVpnAndRejectedConfigIsPreserved() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get();
            install(context, "org.amnezia.awg"); install(context, "com.wireguard.android");
            Shadows.shadowOf(context).grantPermissions(VpnController.permission("org.amnezia.awg"));
            var vpn = new VpnController(context, () -> new VpnPolicy.Active("com.wireguard.android", "work"), () -> true);
            assertTrue(vpn.save(Map.of("key", "selected", "value", "org.amnezia.awg")));
            assertTrue(vpn.save(Map.of("key", "profile_org.amnezia.awg", "value", "home")));
            assertEquals("org.amnezia.awg", vpn.snapshot().get("target"));
            assertEquals(false, vpn.snapshot().get("canControl"));
            assertEquals("other", vpn.command("org.amnezia.awg", "home", false));
            assertFalse(vpn.save(Map.of("key", "selected", "value", "not.installed")));
            assertFalse(vpn.save(Map.of("key", "profile_org.amnezia.awg", "value", "bad profile")));
            assertEquals("home", vpn.prefs.getString("profile_org.amnezia.awg", ""));
            assertTrue(Shadows.shadowOf(context).getBroadcastIntents().isEmpty());
        }
    }
    @Test public void controlRequiresPermissionAndExplicitlyTargetsTheClient() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "org.amnezia.awg";
            install(context, app);
            var vpn = new VpnController(context, () -> new VpnPolicy.Active("", ""), () -> false);
            assertEquals("permission", vpn.command(app, "home", true));
            Shadows.shadowOf(context).grantPermissions(VpnController.permission(app));
            var receiver = new ActivityInfo(); receiver.packageName = app; receiver.name = app + ".Receiver";
            receiver.exported = true;
            var resolved = new ResolveInfo(); resolved.activityInfo = receiver;
            Shadows.shadowOf(context.getPackageManager()).addResolveInfoForIntent(
                new Intent(app + ".action.SET_TUNNEL_UP").setPackage(app), resolved);
            assertEquals("sent", vpn.command(app, "home", true));
            var intents = Shadows.shadowOf(context).getBroadcastIntents();
            assertEquals(1, intents.size());
            assertEquals(app, intents.get(0).getPackage());
            assertEquals(app + ".Receiver", intents.get(0).getComponent().getClassName());
            assertEquals("home", intents.get(0).getStringExtra("tunnel"));
            assertEquals(app + ".action.SET_TUNNEL_UP", intents.get(0).getAction());
        }
    }
    @Test public void startupIsSeparateAndDisabledByDefault() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); install(context, "org.amnezia.awg");
            var vpn = new VpnController(context, () -> new VpnPolicy.Active("", ""), () -> false);
            var jobs = context.getSystemService(android.app.job.JobScheduler.class);
            VpnStartupJob.schedule(context, false);
            assertTrue(jobs.getAllPendingJobs().isEmpty());
            assertTrue(vpn.save(Map.of("key", "bootApp", "value", "org.amnezia.awg")));
            assertEquals("", vpn.snapshot().get("selected"));
            VpnStartupJob.schedule(context, true);
            assertTrue(jobs.getAllPendingJobs().isEmpty());
            VpnStartupJob.schedule(context, false);
            assertEquals(1, jobs.getAllPendingJobs().size());
            assertTrue(vpn.save(Map.of("key", "bootApp", "value", "")));
            assertTrue(jobs.getAllPendingJobs().isEmpty());
            vpn.prefs.edit().putString("bootApp", "org.amnezia.awg").putString("bootMode", "alwaysOn").putBoolean("wake", true).commit();
            VpnStartupJob.schedule(context, false);
            VpnStartupJob.schedule(context, true);
            assertEquals(1, jobs.getAllPendingJobs().size());
            assertTrue(vpn.save(Map.of("key", "bootEnabled", "value", false)));
            assertTrue(jobs.getAllPendingJobs().isEmpty());
            assertEquals("org.amnezia.awg", vpn.prefs.getString("bootApp", ""));
            VpnStartupJob.schedule(context, false);
            assertTrue(jobs.getAllPendingJobs().isEmpty());
        }
    }
    @Test public void systemManagedVpnCannotBeDisconnectedByClientCommand() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "com.happproxy"; install(context, app);
            var vpn = new VpnController(context, () -> new VpnPolicy.Active(app, ""), () -> true);
            vpn.prefs.edit().putString("systemApp", app).commit();
            assertEquals(true, vpn.snapshot(false).get("active"));
            assertEquals(true, vpn.snapshot().get("managed"));
            assertEquals(false, vpn.snapshot().get("canControl"));
            assertEquals("alwaysOn", vpn.command(app, "", false));
            assertNull(Shadows.shadowOf(context).getNextStartedActivity());
        }
    }
    @Test public void removedClientDoesNotPreventDisablingStartup() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var vpn = new VpnController(lifecycle.get(), () -> new VpnPolicy.Active("", ""), () -> false);
            vpn.prefs.edit().putString("bootApp", "removed.vpn").putBoolean("bootEnabled", true)
                .putString("bootMode", "alwaysOn").commit();
            assertTrue(vpn.save(Map.of("key", "bootEnabled", "value", false)));
            assertFalse(vpn.prefs.getBoolean("bootEnabled", true));
            assertEquals("removed.vpn", vpn.prefs.getString("bootApp", ""));
        }
    }
    @Test public void cancellationDuringSnapshotPreventsClientCommand() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "com.happproxy"; install(context, app);
            var valid = new AtomicBoolean(true);
            var vpn = new VpnController(context, () -> {
                valid.set(false); return new VpnPolicy.Active(app, "");
            }, () -> true);
            assertEquals("cancelled", vpn.command(app, "", false, valid::get));
            assertNull(Shadows.shadowOf(context).getNextStartedActivity());
        }
    }
    @Test public void clearingSystemSelectionReturnsWidgetControlDespitePendingReboot() {
        try (var lifecycle = Robolectric.buildActivity(Activity.class).setup()) {
            var context = lifecycle.get(); String app = "com.happproxy"; install(context, app);
            var vpn = new VpnController(context, () -> new VpnPolicy.Active(app, ""), () -> true);
            vpn.prefs.edit().putString("systemApp", "").putBoolean("restartRequired", true)
                .putBoolean("bootEnabled", false).commit();
            assertEquals(false, vpn.snapshot().get("managed"));
            assertEquals(true, vpn.snapshot().get("canControl"));
            assertEquals(true, vpn.snapshot().get("restartRequired"));
            var activity = new ActivityInfo(); activity.packageName = app; activity.name = app + ".External"; activity.exported = true;
            var resolved = new ResolveInfo(); resolved.activityInfo = activity;
            Shadows.shadowOf(context.getPackageManager()).addResolveInfoForIntent(
                new Intent(Intent.ACTION_VIEW, android.net.Uri.parse("happ://disconnect_without_ui")).setPackage(app), resolved);
            assertEquals("sent", vpn.command(app, "", false));
        }
    }
}
