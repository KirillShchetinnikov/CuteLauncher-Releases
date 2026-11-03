package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.Intent;
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
        boolean unknownAspect;
        public boolean onCreate() { return true; }
        public Cursor query(Uri uri, String[] projection, String selection, String[] args, String sort) {
            if (denied) throw new SecurityException("denied");
            MatrixCursor c = new MatrixCursor(projection);
            if (filteredEmpty) return c;
            if (uri.equals(TvContract.Channels.CONTENT_URI)) {
                c.addRow(new Object[]{1L, "video.app", "New", TvContract.Channels.TYPE_PREVIEW});
                c.addRow(new Object[]{2L, "video.app", "Saved", TvContract.Channels.TYPE_PREVIEW});
                c.addRow(new Object[]{3L, "tv.app", "Live", TvContract.Channels.TYPE_DVB_T});
            } else {
                assertEquals(TvContract.buildPreviewProgramsUriForChannel(2), uri);
                programQueries++;
                c.addRow(new Object[]{1L, "other.app", "Wrong owner", "", "video://wrong", "", "", null, null});
                c.addRow(new Object[]{2L, "video.app", "No intent", "", "", "", "", null, null});
                for (int i = 0; i < 30; i++) {
                    c.addRow(new Object[]{10L + i, "video.app", "Item " + i, "Description",
                            "video://watch/" + i, posterArt ? "content://poster/" + i : "",
                            "content://thumbnail/" + i, unknownAspect ? 99 : 0, unknownAspect ? 99 : 4});
                }
            }
            return c;
        }
        public String getType(Uri uri) { return null; }
        public Uri insert(Uri uri, ContentValues values) { throw new AssertionError("read only"); }
        public int delete(Uri uri, String selection, String[] args) { throw new AssertionError("read only"); }
        public int update(Uri uri, ContentValues values, String selection, String[] args) { throw new AssertionError("read only"); }
    }

    @Test public void catalogueKeepsSeparateFeedsAndReadsOnlySelectedPreviewPrograms() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
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
            assertEquals("content://thumbnail/0", programs.get(0).get("posterArtUri"));
            assertEquals("video://watch/0", programs.get(0).get("intentUri"));
            assertEquals(2.0 / 3, (Double) programs.get(0).get("posterAspectRatio"), 0.0001);
            provider.posterArt = true;
            programs = (List<Map<String, Object>>) bridge.channels(List.of("video.app:2")).get(1).get("programs");
            assertEquals("content://poster/0", programs.get(0).get("posterArtUri"));
            assertEquals(16.0 / 9, (Double) programs.get(0).get("posterAspectRatio"), 0.0001);
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
