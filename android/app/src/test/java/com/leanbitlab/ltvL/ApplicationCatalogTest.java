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
    @Test public void iconPackMatchesInstalledComponentsIncludingShortActivityNames() throws Exception {
        var parser = android.util.Xml.newPullParser();
        parser.setInput(new java.io.StringReader("<resources>"
                + "<item component='ComponentInfo{tv.example/.Player}' drawable='player'/>"
                + "<item component='ComponentInfo{tv.example/tv.example.Settings}' drawable='settings'/>"
                + "<item component='ComponentInfo{tv.example/.Missing}' drawable='other:drawable/bad'/>"
                + "<item component='ComponentInfo{not.installed/.Player}' drawable='player'/>"
                + "<item component='broken' drawable='x'/></resources>"));
        var icons = IconPacks.parse(parser, java.util.Set.of("tv.example"));
        assertEquals(2, icons.size());
        assertEquals("player", icons.get(new android.content.ComponentName("tv.example", "tv.example.Player")));
        assertEquals("settings", icons.get(new android.content.ComponentName("tv.example", "tv.example.Settings")));
    }

    @Test public void discoversOneEntryPerPackAndHandlesMissingPack() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var pack = install(activity, "example.icons");
            var manager = Shadows.shadowOf(activity.getPackageManager());
            manager.addResolveInfoForIntent(new Intent("org.adw.launcher.THEMES"), pack);
            manager.addResolveInfoForIntent(new Intent("com.novalauncher.THEME"), pack);
            var catalog = new ApplicationCatalog(activity);
            assertEquals(java.util.Map.of("example.icons", "example.icons"), catalog.iconPacks.available());
            assertEquals(0, catalog.packedIcon("missing.pack", "example.tv").length);
        }
    }

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

    @Test public void reportsAndCatalogsShareNamesButReloadAfterPackageUpdate() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var manager = activity.getPackageManager();
            String name = "example.labels";
            install(activity, name);
            var original = new ApplicationCatalog(activity);
            assertEquals(name, nameOf(original.getApplications(), name));

            var changed = manager.getPackageInfo(name, 0);
            changed.applicationInfo.nonLocalizedLabel = "New label";
            Shadows.shadowOf(manager).installPackage(changed);
            assertEquals(name, nameOf(new ApplicationCatalog(activity).getDiagnosticApplications(), name));

            changed.lastUpdateTime += 10_000;
            Shadows.shadowOf(manager).installPackage(changed);
            assertEquals("New label", nameOf(original.getDiagnosticApplications(), name));
            assertEquals("New label", nameOf(original.getApplications(), name));
        }
    }

    @Test public void persistedNamesAreScopedToLocaleRevisionAndComponent() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var directory = controller.get().getCacheDir();
            var russian = new AppLabelCache(directory).batch("firmware:ru");
            var activity = "activity:example.tv/Main";
            assertEquals("Русское имя", russian.resolve(activity, "1:100:100", () -> "Русское имя"));
            russian.save(() -> "firmware:ru");

            var reopened = new AppLabelCache(directory);
            assertEquals("Русское имя", reopened.batch("firmware:ru")
                .resolve(activity, "1:100:100", () -> { throw new AssertionError("disk cache miss"); }));
            assertEquals("Updated", reopened.batch("firmware:ru")
                .resolve(activity, "1:100:200", () -> "Updated"));
            assertEquals("Second activity", reopened.batch("firmware:ru")
                .resolve("activity:example.tv/Other", "1:100:100", () -> "Second activity"));
            var english = reopened.batch("firmware:en");
            assertEquals("English label", english.resolve(activity, "1:100:100", () -> "English label"));
            english.save(() -> "firmware:en");
            var stale = reopened.batch("firmware:ru");
            stale.resolve(activity, "1:100:100", () -> "Late name");
            stale.save(() -> "firmware:en");
            assertEquals("English label", new AppLabelCache(directory).batch("firmware:en")
                .resolve(activity, "1:100:100", () -> { throw new AssertionError("late locale write"); }));
        }
    }

    private static Object nameOf(java.util.List<? extends java.util.Map<String, ?>> rows, String packageName) {
        return rows.stream().filter(row -> packageName.equals(row.get("packageName")))
            .findFirst().orElseThrow().get("name");
    }

    @Test public void missingBannerIsCachedButPackageUpdatesInvalidateIt() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            String name = "example.artwork";
            install(activity, name);
            var catalog = new ApplicationCatalog(activity);
            assertArrayEquals(new byte[0], catalog.getCachedArtwork(name, true));

            var path = activity.getCacheDir().toPath().resolve("app-artwork-v1/" + name + ".banner");
            byte[] entry = java.nio.file.Files.readAllBytes(path);
            var newCatalog = new ApplicationCatalog(activity);
            assertArrayEquals(new byte[0], newCatalog.getCachedArtwork(name, true));
            assertArrayEquals(entry, java.nio.file.Files.readAllBytes(path));

            var manager = activity.getPackageManager();
            var updated = manager.getPackageInfo(name, 0);
            updated.lastUpdateTime += 10_000;
            Shadows.shadowOf(manager).installPackage(updated);
            assertArrayEquals(new byte[0], newCatalog.getCachedArtwork(name, true));
            assertFalse(java.util.Arrays.equals(entry, java.nio.file.Files.readAllBytes(path)));
        }
    }
}
