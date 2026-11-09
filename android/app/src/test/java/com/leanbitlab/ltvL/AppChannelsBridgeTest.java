package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.database.Cursor;
import android.database.MatrixCursor;
import android.media.tv.TvContract;
import android.net.Uri;
import java.util.List;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.shadows.ShadowContentResolver;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class AppChannelsBridgeTest {
    public static class Provider extends ContentProvider {
        int programQueries;
        boolean denied;
        boolean filteredEmpty;
        boolean posterArt;
        boolean missingPosterProvider;
        boolean unknownAspect;
        boolean brokenFeed;
        boolean emptyFeed;
        boolean tclFavorites;
        public boolean onCreate() { return true; }
        public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) {
            if (denied) throw new SecurityException("denied");
            MatrixCursor c = new MatrixCursor(projection);
            if (filteredEmpty) return c;
            if (uri.equals(TvContract.Channels.CONTENT_URI)) {
                c.addRow(new Object[]{1L, "video.app", "New", TvContract.Channels.TYPE_PREVIEW});
                c.addRow(new Object[]{2L, "video.app", tclFavorites ? "Избранное" : "Saved",
                        TvContract.Channels.TYPE_PREVIEW});
                c.addRow(new Object[]{3L, "tv.app", "Live", TvContract.Channels.TYPE_DVB_T});
                c.addRow(new Object[]{4L, "removed.app", "Stale", TvContract.Channels.TYPE_PREVIEW});
                if (tclFavorites) {
                    c.addRow(new Object[]{5L, "com.tcl.partnercustomizer", "Избранное", TvContract.Channels.TYPE_PREVIEW});
                }
            } else if (uri.equals(TvContract.PreviewPrograms.CONTENT_URI)) {
                if (!emptyFeed) {
                    c.addRow(new Object[]{1L, "video.app", "video://watch/1",
                            "content://missing.poster/1", null});
                    c.addRow(new Object[]{1L, "video.app", "video://watch/2",
                            "android.resource://video.app/drawable/missing",
                            brokenFeed ? null : "https://images.test/thumbnail/2"});
                    c.addRow(new Object[]{1L, "video.app", "video://watch/4", null, null});
                }
                c.addRow(new Object[]{2L, "video.app", "video://watch/3",
                        "content://missing.poster/3", "https://images.test/thumbnail/3"});
                if (tclFavorites) {
                    c.addRow(new Object[]{5L, "com.tcl.partnercustomizer", "video://watch/tcl",
                            "https://images.test/poster/tcl", null});
                }
            } else {
                assertEquals(TvContract.buildPreviewProgramsUriForChannel(2), uri);
                programQueries++;
                c.addRow(new Object[]{1L, "other.app", "Wrong owner", "", "video://wrong", "", "", null, null});
                c.addRow(new Object[]{2L, "video.app", "No intent", "", "", "", "", null, null});
                for (int i = 0; i < 30; i++) {
                    c.addRow(new Object[]{10L + i, "video.app", "Item " + i, "Description",
                            "video://watch/" + i, missingPosterProvider ? "content://missing.poster/" + i
                                    : posterArt ? "https://images.test/poster/" + i : "",
                            "https://images.test/thumbnail/" + i, unknownAspect ? 99 : 0, unknownAspect ? 99 : 4});
                }
            }
            return c;
        }
        public String getType(Uri uri) { return null; }
        public Uri insert(Uri uri, ContentValues values) { throw new AssertionError("read only"); }
        public int delete(Uri uri, String selection, String[] args) { throw new AssertionError("read only"); }
        public int update(Uri uri, ContentValues values, String selection, String[] args) { throw new AssertionError("read only"); }
    }

    @Test public void excludesTclFavoritesEvenWhenSelectedWithoutHidingSameNameFromOtherApps() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            installPublisher(activity, "video.app");
            installPublisher(activity, "com.tcl.partnercustomizer");
            Shadows.shadowOf(activity.getApplication()).grantPermissions("android.permission.READ_TV_LISTINGS");
            Provider provider = Robolectric.buildContentProvider(Provider.class).create().get();
            provider.tclFavorites = true;
            ShadowContentResolver.registerProviderInternal(TvContract.AUTHORITY, provider);
            var catalogue = new AppChannelsBridge(activity)
                    .channels(List.of("com.tcl.partnercustomizer:5"));
            assertEquals(3, catalogue.size());
            assertFalse(catalogue.get(1).containsKey("hidden"));
            assertEquals(true, catalogue.get(2).get("hidden"));
            assertTrue(((List<?>) catalogue.get(2).get("programs")).isEmpty());
            assertEquals(0, provider.programQueries);
        }
    }

    private static void installPublisher(Activity activity, String packageName) {
        var info = new PackageInfo();
        info.packageName = packageName;
        info.applicationInfo = new ApplicationInfo();
        info.applicationInfo.packageName = info.packageName;
        info.applicationInfo.enabled = false;
        Shadows.shadowOf(activity.getPackageManager()).installPackage(info);
    }

    @Test public void unreadableProviderAndResourceHideOnlyTheAffectedFeedUntilItRecovers() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            installPublisher(controller.get(), "video.app");
            Shadows.shadowOf(controller.get().getApplication()).grantPermissions("android.permission.READ_TV_LISTINGS");
            Provider provider = Robolectric.buildContentProvider(Provider.class).create().get();
            ShadowContentResolver.registerProviderInternal(TvContract.AUTHORITY, provider);
            var bridge = new AppChannelsBridge(controller.get());
            provider.brokenFeed = true;
            var catalogue = bridge.channels(List.of());
            assertEquals(true, catalogue.get(0).get("hidden"));
            assertFalse(catalogue.get(1).containsKey("hidden"));
            assertEquals(0, provider.programQueries);
            catalogue = bridge.channels(List.of("video.app:1", "video.app:2"));
            assertTrue(((List<?>) catalogue.get(0).get("programs")).isEmpty());
            assertEquals(20, ((List<?>) catalogue.get(1).get("programs")).size());
            assertEquals(1, provider.programQueries);
            provider.brokenFeed = false;
            assertFalse(bridge.channels(List.of()).get(0).containsKey("hidden"));
            provider.emptyFeed = true;
            assertEquals(true, bridge.channels(List.of()).get(0).get("hidden"));
        }
    }

    @Test public void catalogueKeepsSeparateFeedsAndReadsOnlySelectedPreviewPrograms() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            installPublisher(controller.get(), "video.app");
            Shadows.shadowOf(controller.get().getApplication()).grantPermissions("android.permission.READ_TV_LISTINGS");
            Provider provider = Robolectric.buildContentProvider(Provider.class).create().get();
            ShadowContentResolver.registerProviderInternal(TvContract.AUTHORITY, provider);
            var bridge = new AppChannelsBridge(controller.get());
            var catalogue = bridge.channels(List.of());
            assertEquals(2, catalogue.size());
            assertEquals(0, provider.programQueries);
            var selected = bridge.channels(List.of("video.app:2"));
            assertEquals(1, provider.programQueries);
            assertTrue(((List<?>) selected.get(0).get("programs")).isEmpty());
            var programs = (List<Map<String, Object>>) selected.get(1).get("programs");
            assertEquals(20, programs.size());
            assertEquals("https://images.test/thumbnail/0", programs.get(0).get("posterArtUri"));
            assertEquals("video://watch/0", programs.get(0).get("intentUri"));
            assertEquals(2.0 / 3, (Double) programs.get(0).get("posterAspectRatio"), 0.0001);
            provider.posterArt = true;
            programs = (List<Map<String, Object>>) bridge.channels(List.of("video.app:2")).get(1).get("programs");
            assertEquals("https://images.test/poster/0", programs.get(0).get("posterArtUri"));
            assertEquals("https://images.test/thumbnail/0", programs.get(0).get("thumbnailUri"));
            assertEquals(16.0 / 9, (Double) programs.get(0).get("posterAspectRatio"), 0.0001);
            provider.missingPosterProvider = true;
            programs = (List<Map<String, Object>>) bridge.channels(List.of("video.app:2")).get(1).get("programs");
            assertEquals("https://images.test/thumbnail/0", programs.get(0).get("posterArtUri"));
            assertFalse(programs.get(0).containsKey("thumbnailUri"));
            assertEquals(2.0 / 3, (Double) programs.get(0).get("posterAspectRatio"), 0.0001);
            provider.unknownAspect = true;
            programs = (List<Map<String, Object>>) bridge.channels(List.of("video.app:2")).get(1).get("programs");
            assertFalse(programs.get(0).containsKey("posterAspectRatio"));
            provider.denied = true;
            assertThrows(SecurityException.class, () -> bridge.channels(List.of()));
        }
    }

    @Test public void missingAccessMustNotLookLikeAnEmptyCatalogue() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            Shadows.shadowOf(activity.getApplication()).denyPermissions("android.permission.READ_TV_LISTINGS");
            Provider provider = Robolectric.buildContentProvider(Provider.class).create().get();
            provider.filteredEmpty = true;
            ShadowContentResolver.registerProviderInternal(TvContract.AUTHORITY, provider);
            var bridge = new AppChannelsBridge(activity);
            assertThrows(SecurityException.class, () -> bridge.channels(List.of()));
            Shadows.shadowOf(activity.getApplication()).grantPermissions("android.permission.READ_TV_LISTINGS");
            assertTrue(bridge.channels(List.of()).isEmpty());
        }
    }

    @Test public void launchTargetsPublishingAppAndRejectsForeignComponent() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var bridge = new AppChannelsBridge(activity);
            assertTrue(bridge.launch("video://watch/123", "video.app"));
            Intent launched = Shadows.shadowOf(activity).getNextStartedActivity();
            assertEquals("video.app", launched.getPackage());
            assertEquals("video://watch/123", launched.getDataString());
            assertEquals(Intent.FLAG_ACTIVITY_NEW_TASK, launched.getFlags());
            assertFalse(bridge.launch("intent://watch#Intent;component=other.app/.Player;end", "video.app"));
            assertFalse(bridge.launch("", "video.app"));
            assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
        }
    }
}
