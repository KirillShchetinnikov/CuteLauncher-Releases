package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.provider.Settings;
import java.io.File;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RecentAppsBridgeTest {
    @Test public void missingAdbAuthorizationIsReportedWithoutCreatingKeys() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            File keys = new File(activity.getNoBackupFilesDir(), "adb");
            assertFalse(keys.exists());
            var access = RecentAppsBridge.access(activity);
            assertEquals(false, access.get("adb"));
            assertEquals(false, access.get("accessibility"));
            assertFalse(keys.exists());
        }
    }

    @Test public void setupLinksUseRecoveryEntryAndExactAccessibilityPage() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            assertTrue(RecentAppsBridge.setup(activity, "adb"));
            var adb = Shadows.shadowOf(activity).getNextStartedActivity();
            assertEquals(MainActivity.class.getName(), adb.getComponent().getClassName());
            assertTrue(adb.getBooleanExtra(LauncherActivity.OPEN_ADB_SETTINGS, false));
            assertEquals(Intent.ACTION_MAIN, adb.getAction());
            assertTrue(adb.hasCategory(Intent.CATEGORY_LAUNCHER));
            assertTrue((adb.getFlags() & Intent.FLAG_ACTIVITY_NEW_TASK) != 0);
            assertTrue(RecentAppsBridge.setup(activity, "accessibility"));
            assertEquals(Settings.ACTION_ACCESSIBILITY_SETTINGS,
                Shadows.shadowOf(activity).getNextStartedActivity().getAction());
            assertFalse(RecentAppsBridge.setup(activity, "arbitrary"));
            assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
        }
    }

    @Test public void missingSettingsActivityIsNotReportedAsOpened() {
        Context denied = new ContextWrapper(org.robolectric.RuntimeEnvironment.getApplication()) {
            @Override public void startActivity(Intent intent) { throw new SecurityException("Unavailable"); }
        };
        assertFalse(RecentAppsBridge.setup(denied, "accessibility"));
    }
}
