package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.app.AppOpsManager;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ResolveInfo;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 31, 34}, shadows = LocalWallpaperFilesTest.StorageEnvironment.class)
public class FileStorageDiagnosticsTest {
    public static class Host extends Activity {
        int launches;
        @Override public void startActivity(Intent intent) { launches++; }
        @Override public void startActivityForResult(Intent intent, int request) { launches++; }
    }

    private static void install(Host host, String pkg, String name, boolean enabled, Intent intent) {
        var app = new ApplicationInfo();
        app.packageName = pkg;
        app.enabled = enabled;
        var activity = new ActivityInfo();
        activity.packageName = pkg;
        activity.name = name;
        activity.applicationInfo = app;
        activity.enabled = enabled;
        activity.exported = true;
        var info = new PackageInfo();
        info.packageName = pkg;
        info.versionName = "fixture";
        info.applicationInfo = app;
        info.activities = new ActivityInfo[]{activity};
        var pm = Shadows.shadowOf(host.getPackageManager());
        pm.installPackage(info);
        if (intent != null) {
            var match = new ResolveInfo();
            match.activityInfo = activity;
            match.isDefault = true;
            pm.addResolveInfoForIntent(intent, match);
        }
    }

    @Test public void showsOemHandlerAndTvPageWithoutLaunchingOrChangingAppOps() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            var app = new Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:" + host.getPackageName()));
            install(host, "com.tcl.guard", "com.tcl.guard.PermissionFilter", true, app);
            install(host, "com.android.tv.settings",
                    "com.android.tv.settings.device.apps.specialaccess.AllFilesAccessActivity", true, null);
            LocalWallpaperFilesTest.StorageEnvironment.manager = true;
            var ops = host.getSystemService(AppOpsManager.class);
            String op = AppOpsManager.permissionToOp(Manifest.permission.MANAGE_EXTERNAL_STORAGE);
            if (Build.VERSION.SDK_INT >= 30) Shadows.shadowOf(ops).setMode(op,
                    host.getApplicationInfo().uid, host.getPackageName(), AppOpsManager.MODE_IGNORED);
            String result = FileStorageDiagnostics.collect(host);
            assertTrue(result.contains("scope=app UID (not ADB)"));
            assertTrue(result.contains("com.tcl.guard/.PermissionFilter"));
            assertTrue(result.contains("AllFilesAccessActivity enabled=true exported=true permitted=true"));
            if (Build.VERSION.SDK_INT >= 30) {
                assertTrue(result.contains("allFilesAccess=true"));
                assertTrue(result.contains("MANAGE_EXTERNAL_STORAGE AppOps=ignore"));
                assertEquals(AppOpsManager.MODE_IGNORED, ops.checkOpNoThrow(
                        op,
                        host.getApplicationInfo().uid, host.getPackageName()));
            } else assertTrue(result.contains("not applicable (API < 30)"));
            assertEquals(0, host.launches);
        }
    }

    @Test public void missingGuardAndMissingSettingsDoNotHidePermissionState() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            LocalWallpaperFilesTest.StorageEnvironment.manager = false;
            String result = FileStorageDiagnostics.collect(host);
            assertTrue(result.contains("tguard=unavailable (NameNotFoundException)"));
            assertTrue(result.contains("resolved=none visible"));
            assertTrue(result.contains("handlers=0"));
            assertTrue(result.contains("android.permission.READ_EXTERNAL_STORAGE="));
            if (Build.VERSION.SDK_INT >= 30) assertTrue(result.contains("allFilesAccess=false"));
            assertEquals(0, host.launches);
        }
    }

    @Test public void disabledTvPageIsReportedAsDisabled() {
        try (var lifecycle = Robolectric.buildActivity(Host.class).setup()) {
            var host = lifecycle.get();
            install(host, "com.android.tv.settings",
                    "com.android.tv.settings.device.apps.specialaccess.AllFilesAccessActivity", false, null);
            assertTrue(FileStorageDiagnostics.collect(host).contains("AllFilesAccessActivity enabled=false"));
        }
    }
}
