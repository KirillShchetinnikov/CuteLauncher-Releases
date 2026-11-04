package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.concurrent.Executors;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {31, 34}, shadows = LocalWallpaperFilesTest.StorageEnvironment.class)
public class AllFilesAccessSettingsTest {
    private static final String TV = "com.android.tv.settings";
    private static final String PAGE = TV + ".device.apps.specialaccess.AllFilesAccessActivity";
    public static class Host extends Activity {
        final ArrayList<Intent> started = new ArrayList<>();
        final HashSet<String> rejected = new HashSet<>();
        @Override public void startActivityForResult(Intent intent, int request) {
            assertEquals(LocalWallpaperFiles.REQUEST, request);
            if (rejected.contains(intent.getAction())) throw new ActivityNotFoundException();
            started.add(intent);
        }
    }
    private static class Reply implements MethodChannel.Result {
        Object value;
        String error;
        public void success(Object value) { this.value = value; }
        public void error(String code, String message, Object details) { error = code; }
        public void notImplemented() { fail("Not implemented"); }
    }
    private static Intent app(Host host) {
        return new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                Uri.parse("package:" + host.getPackageName()));
    }
    private static void install(Host host, String pkg, String name, boolean exported, Intent... intents) {
        var application = new ApplicationInfo();
        application.packageName = pkg; application.enabled = true;
        application.flags = ApplicationInfo.FLAG_SYSTEM;
        var activity = new ActivityInfo();
        activity.packageName = pkg; activity.name = name; activity.applicationInfo = application;
        activity.enabled = true; activity.exported = exported;
        var info = new PackageInfo();
        info.packageName = pkg; info.applicationInfo = application;
        info.activities = new ActivityInfo[]{activity};
        var pm = Shadows.shadowOf(host.getPackageManager());
        pm.installPackage(info);
        for (Intent intent : intents) {
            var resolved = new ResolveInfo();
            resolved.activityInfo = activity; resolved.isDefault = true;
            pm.addResolveInfoForIntent(intent, resolved);
        }
    }

    @Test public void android12CanFallBackToOwnAppCardWhenSpecialScreensAreMissing() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            var card = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, app(host).getData());
            install(host, TV, TV + ".AppCard", true, card);
            boolean applicable = android.os.Build.VERSION.SDK_INT <= 32;
            var worker = Executors.newSingleThreadExecutor();
            try {
                LocalWallpaperFilesTest.StorageEnvironment.manager = false;
                var files = new LocalWallpaperFiles(host, worker);
                var reply = new Reply();
                files.request(reply);
                assertTrue(host.started.isEmpty());
                if (applicable) {
                    var dialog = org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog();
                    assertTrue(dialog.isShowing());
                    dialog.cancel();
                    Shadows.shadowOf(android.os.Looper.getMainLooper()).idle();
                    assertEquals(false, reply.value);
                    files.request(new Reply());
                    dialog = org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog();
                    dialog.getButton(android.app.AlertDialog.BUTTON_POSITIVE).performClick();
                    Shadows.shadowOf(android.os.Looper.getMainLooper()).idle();
                    assertEquals(card.getAction(), host.started.get(0).getAction());
                    assertEquals(card.getData(), host.started.get(0).getData());
                } else assertEquals("storage_settings_unavailable", reply.error);
            } finally {
                worker.shutdownNow();
            }
        }
    }

    @Test @Config(sdk = 31)
    public void appCardWithInstructionsWinsOverOemCatchAllFilterOnAndroid12() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            var card = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, app(host).getData());
            install(host, TV, TV + ".AppCard", true, card);
            install(host, "com.tcl.guard", "com.tcl.guard.PermissionFilter", true, app(host));
            var worker = Executors.newSingleThreadExecutor();
            try {
                LocalWallpaperFilesTest.StorageEnvironment.manager = false;
                var files = new LocalWallpaperFiles(host, worker);
                var reply = new Reply();
                files.request(reply);
                assertTrue(host.started.isEmpty());
                var dialog = org.robolectric.shadows.ShadowAlertDialog.getLatestAlertDialog();
                assertTrue(dialog.isShowing());
                dialog.getButton(android.app.AlertDialog.BUTTON_POSITIVE).performClick();
                Shadows.shadowOf(android.os.Looper.getMainLooper()).idle();
                assertEquals(1, host.started.size());
                assertEquals(card.getAction(), host.started.get(0).getAction());
                assertEquals(card.getData(), host.started.get(0).getData());
                LocalWallpaperFilesTest.StorageEnvironment.manager = true;
                files.complete();
                assertEquals(true, reply.value);
            } finally {
                worker.shutdownNow();
            }
        }
    }

    @Test public void exportedTvPageWinsOverOemPermissionFilterEvenWithoutIntentFilter() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            install(host, "com.tcl.guard", "com.tcl.guard.PermissionFilter", true, app(host));
            install(host, TV, PAGE, true);
            assertTrue(AllFilesAccessSettings.open(host, LocalWallpaperFiles.REQUEST));
            assertEquals(1, host.started.size());
            assertEquals(new ComponentName(TV, PAGE), host.started.get(0).getComponent());
            assertEquals(app(host).getData(), host.started.get(0).getData());
        }
    }

    @Test public void inaccessibleTvPageFallsBackToScopedSystemHandler() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            install(host, TV, PAGE, false);
            String phone = "com.android.settings";
            install(host, phone, phone + ".AllFilesPage", true, new Intent(app(host)).setPackage(phone));
            assertTrue(AllFilesAccessSettings.open(host, LocalWallpaperFiles.REQUEST));
            assertEquals(phone, host.started.get(0).getComponent().getPackageName());
            assertEquals(app(host).getData(), host.started.get(0).getData());
        }
    }

    @Test public void systemAllFilesListWinsOverOemAppPermissionFilter() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            install(host, "com.tcl.guard", "com.tcl.guard.PermissionFilter", true, app(host));
            String phone = "com.android.settings";
            install(host, phone, phone + ".AllFilesList", true,
                    new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).setPackage(phone));
            assertTrue(AllFilesAccessSettings.open(host, LocalWallpaperFiles.REQUEST));
            assertEquals(phone, host.started.get(0).getComponent().getPackageName());
            assertEquals(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION, host.started.get(0).getAction());
        }
    }

    @Test public void failingAppPageRetriesSystemAllFilesListWithNoPackageData() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            host.rejected.add(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION);
            install(host, TV, PAGE, true,
                    new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).setPackage(TV));
            assertTrue(AllFilesAccessSettings.open(host, LocalWallpaperFiles.REQUEST));
            assertEquals(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION, host.started.get(0).getAction());
            assertNull(host.started.get(0).getData());
        }
    }

    @Test public void oemOnlyGenericPermissionListIsNotOpenedAndRequestCanBeRetried() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            install(host, "com.tcl.guard", "com.tcl.guard.PermissionFilter", true,
                    new Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION));
            var worker = Executors.newSingleThreadExecutor();
            try {
                LocalWallpaperFilesTest.StorageEnvironment.manager = false;
                var files = new LocalWallpaperFiles(host, worker);
                var unavailable = new Reply();
                files.request(unavailable);
                assertEquals("storage_settings_unavailable", unavailable.error);
                assertTrue(host.started.isEmpty());
                install(host, TV, PAGE, true);
                var retry = new Reply();
                files.request(retry);
                assertNull(retry.error);
                LocalWallpaperFilesTest.StorageEnvironment.manager = true;
                files.complete();
                assertEquals(true, retry.value);
                assertEquals(1, host.started.size());
            } finally { worker.shutdownNow(); }
        }
    }
}
