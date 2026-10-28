package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import java.util.Set;
import java.util.HashSet;
import java.io.IOException;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class UpdatePermissionRecoveryTest {
    private static final long NOW = 1_000_000L;
    private static class Access implements UpdatePermissionRecovery.Access {
        final Set<String> grants = new HashSet<>();
        boolean connected, unavailable, bind = true;
        int opened, restored;
        public Set<String> granted() { return new HashSet<>(grants); }
        public boolean accessibilityEnabled() { return grants.contains("accessibility"); }
        public boolean connected() { return connected; }
        public boolean supported(String action) { return true; }
        public UpdatePermissionRecovery.Session open() throws Exception {
            opened++;
            if (unavailable) throw new IOException("temporary failure");
            return new UpdatePermissionRecovery.Session() {
                public String restore(String action, boolean requireEnabled) {
                    if (requireEnabled && !grants.contains(action)) throw new AssertionError("Manual revoke overwritten");
                    restored++; grants.add(action); connected = bind; return "success";
                }
                public void close() { }
            };
        }
    }
    private void baseline(Context c) {
        UpdatePermissionRecovery.saved(c).edit().clear().putLong("installation", 100)
                .putStringSet("granted", Set.of("accessibility")).commit();
    }
    @Test public void failedConnectionRetainsConsentAndRetriesAfterProcessRestart() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c);
            var first = new Access(); first.unavailable = true;
            UpdatePermissionRecovery.recover(c, 200, NOW, first);
            assertEquals(Set.of("accessibility"), UpdatePermissionRecovery.saved(c).getStringSet("pending", Set.of()));
            assertEquals("adb_unavailable", UpdatePermissionRecovery.report(c).get("status"));
            UpdatePermissionRecovery.recover(c, 200, NOW + 1000, first);
            assertEquals(1, first.opened);
            var restarted = new Access();
            UpdatePermissionRecovery.recover(c, 200, NOW + 16_000, restarted);
            assertEquals(1, restarted.restored);
            assertTrue(UpdatePermissionRecovery.saved(c).getStringSet("pending", Set.of()).isEmpty());
            UpdatePermissionRecovery.recover(c, 200, NOW + 60_000, restarted);
            assertEquals(1, restarted.opened);
        }
    }
    @Test public void absentBaselineNeverGrantsAndRetriesExpire() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); UpdatePermissionRecovery.saved(c).edit().clear().commit();
            var access = new Access();
            UpdatePermissionRecovery.recover(c, 200, NOW, access);
            assertEquals(0, access.opened);
            baseline(c); access.unavailable = true;
            UpdatePermissionRecovery.recover(c, 200, NOW, access);
            UpdatePermissionRecovery.recover(c, 200, NOW + UpdatePermissionPolicy.RECOVERY_WINDOW_MS, access);
            assertEquals(1, access.opened);
            assertTrue(UpdatePermissionRecovery.saved(c).getStringSet("pending", Set.of()).isEmpty());
            assertEquals("expired", UpdatePermissionRecovery.report(c).get("status"));
        }
    }
    @Test public void observedManualRevokeCancelsPendingBindingRetry() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c);
            var access = new Access(); access.bind = false;
            UpdatePermissionRecovery.recover(c, 200, NOW, access);
            assertTrue(access.grants.contains("accessibility"));
            access.grants.clear();
            UpdatePermissionRecovery.recover(c, 200, NOW + 16_000, access);
            assertEquals(1, access.opened);
            assertTrue(UpdatePermissionRecovery.saved(c).getStringSet("pending", Set.of()).isEmpty());
        }
    }
    @Test public void backgroundCheckHasGraceAndNeverRestoresDisabledPermission() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c); var access = new Access();
            UpdatePermissionRecovery.health(c, NOW, access);
            assertEquals(0, access.opened);
            access.grants.add("accessibility");
            UpdatePermissionRecovery.health(c, NOW + 1000, access);
            UpdatePermissionRecovery.health(c, NOW + 10_000, access);
            assertEquals(0, access.opened);
            UpdatePermissionRecovery.health(c, NOW + 32_000, access);
            assertEquals(1, access.restored);
            access.grants.clear(); access.connected = false;
            UpdatePermissionRecovery.health(c, NOW + 100_000, access);
            assertEquals(1, access.opened);
        }
    }
    @Test public void explicitDisableCancelsAnUpdateRetry() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c); var access = new Access(); access.unavailable = true;
            UpdatePermissionRecovery.recover(c, 200, NOW, access);
            UpdatePermissionRecovery.cancelAccessibility(c);
            access.unavailable = false;
            UpdatePermissionRecovery.recover(c, 200, NOW + 16_000, access);
            assertEquals(0, access.restored);
        }
    }
    @Test public void anotherApkUpdateRetainsStillPendingConsent() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c); var access = new Access(); access.unavailable = true;
            UpdatePermissionRecovery.recover(c, 200, NOW, access);
            access.unavailable = false;
            UpdatePermissionRecovery.recover(c, 300, NOW + 16_000, access);
            assertEquals(1, access.restored);
        }
    }
    @Test public void retryBudgetStopsConnectionStormAndBackgroundHasCooldown() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var c = controller.get(); baseline(c); var access = new Access(); access.unavailable = true;
            long now = NOW;
            for (int attempt = 1; attempt <= 5; attempt++) {
                UpdatePermissionRecovery.recover(c, 200, now, access);
                now += UpdatePermissionPolicy.retryDelay(attempt);
            }
            UpdatePermissionRecovery.recover(c, 200, now, access);
            assertEquals(5, access.opened);
            assertTrue(UpdatePermissionRecovery.saved(c).getStringSet("pending", Set.of()).isEmpty());
            access.grants.add("accessibility");
            UpdatePermissionRecovery.health(c, now, access);
            now += 31_000;
            for (int attempt = 1; attempt <= 3; attempt++) {
                UpdatePermissionRecovery.health(c, now, access);
                now += attempt * 60_000L;
            }
            int opened = access.opened;
            UpdatePermissionRecovery.health(c, now, access);
            assertEquals(opened, access.opened);
        }
    }
    public static class CountingActivity extends Activity {
        int permissionReads;
        @Override public Object getSystemService(String name) {
            if (Context.NOTIFICATION_SERVICE.equals(name)) permissionReads++;
            return super.getSystemService(name);
        }
    }

    @Test public void unchangedVersionSkipsRepeatedPermissionInventory() throws Exception {
        var field = UpdatePermissionRecovery.class.getDeclaredField("checkedInstallation");
        field.setAccessible(true);
        field.setLong(null, -1);
        try (var controller = Robolectric.buildActivity(CountingActivity.class).setup()) {
            var activity = controller.get();
            var info = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0);
            info.lastUpdateTime = 100;
            Shadows.shadowOf(activity.getPackageManager()).installPackage(info);
            UpdatePermissionRecovery.afterUpdate(activity);
            assertEquals(100, activity.getSharedPreferences("update_permissions", 0).getLong("installation", 0));
            activity.permissionReads = 0;
            UpdatePermissionRecovery.afterUpdate(activity);
            assertEquals(0, activity.permissionReads);
            info.lastUpdateTime = 200;
            Shadows.shadowOf(activity.getPackageManager()).installPackage(info);
            UpdatePermissionRecovery.afterUpdate(activity);
            assertTrue(activity.permissionReads > 0);
            assertEquals(200, activity.getSharedPreferences("update_permissions", 0).getLong("installation", 0));
        }
    }
}
