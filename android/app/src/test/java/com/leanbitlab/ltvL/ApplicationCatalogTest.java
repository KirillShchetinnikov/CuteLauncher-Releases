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
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class ApplicationCatalogTest {
    @Test public void panelIconsRespectSmallerBoundAndKeepAspectRatio() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var catalog = new ApplicationCatalog(controller.get());
            var drawable = new android.graphics.drawable.ColorDrawable(android.graphics.Color.WHITE) {
                @Override public int getIntrinsicWidth() { return 1024; }
                @Override public int getIntrinsicHeight() { return 512; }
            };
            var small = catalog.drawableToBitmap(drawable, 128);
            var normal = catalog.drawableToBitmap(drawable);
            assertEquals(128, small.getWidth()); assertEquals(64, small.getHeight());
            assertEquals(960, normal.getWidth()); assertEquals(480, normal.getHeight());
            small.recycle(); normal.recycle();
        }
    }
    private ResolveInfo install(Activity context, String name) {
        var app = new ApplicationInfo(); app.packageName = name; app.enabled = true; app.nonLocalizedLabel = name;
        var activity = new ActivityInfo(); activity.packageName = name; activity.name = name + ".Main";
        activity.applicationInfo = app; activity.enabled = true; activity.exported = true;
        var info = new PackageInfo(); info.packageName = name; info.versionName = "1";
        info.applicationInfo = app; info.activities = new ActivityInfo[]{activity};
        Shadows.shadowOf(context.getPackageManager()).installPackage(info);
        var resolve = new ResolveInfo(); resolve.activityInfo = activity;
        return resolve;
    }
    @Test public void fastHomeQueryOmitsServiceInventoryButFullQueryRetainsIt() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var tv = install(activity, "example.tv");
            install(activity, "example.service");
            Shadows.shadowOf(activity.getPackageManager()).addResolveInfoForIntent(
                    new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER), tv);
            var catalog = new ApplicationCatalog(activity);
            var home = catalog.getLauncherApplications();
            assertTrue(home.stream().anyMatch(app -> "example.tv".equals(app.get("packageName"))));
            assertFalse(home.stream().anyMatch(app -> "example.service".equals(app.get("packageName"))));
            var full = catalog.getApplications();
            assertTrue(full.stream().anyMatch(app -> "example.service".equals(app.get("packageName")) && Boolean.FALSE.equals(app.get("launchable"))));
        }
    }
    @Test public void diagnosticsIncludeDisabledServicePackagesAndTheirEnabledSetting() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            install(activity, "example.disabled");
            activity.getPackageManager().setApplicationEnabledSetting("example.disabled",
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER, 0);
            var row = new ApplicationCatalog(activity).getDiagnosticApplications().stream()
                .filter(app -> "example.disabled".equals(app.get("packageName"))).findFirst().orElseThrow();
            assertEquals(PackageManager.COMPONENT_ENABLED_STATE_DISABLED_USER, row.get("enabledSetting"));
            assertEquals(false, row.get("enabled"));
            assertEquals(false, row.get("launchable"));
            assertTrue(row.containsKey("versionCode"));
        }
    }
}
