package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.ResolveInfo;
import android.os.Handler;
import android.os.Looper;
import java.io.File;
import java.lang.ref.WeakReference;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RecentAppsBridgeTest {
    @Test public void customPanelReportsMissingAccessibilityBeforeCheckingAdb() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            activity.getSharedPreferences(RecentAppsBridge.PREFS, 0).edit().putString("mode", "custom").apply();
            var result = new AtomicReference<RecentAppsBridge.OpenResult>();
            RecentAppsBridge.open(activity, task -> fail("ADB check should not run"), new Handler(Looper.getMainLooper()),
                () -> true, result::set);
            assertEquals(RecentAppsBridge.OpenResult.ACCESSIBILITY_REQUIRED, result.get());
        }
    }

    @Test public void customPanelChecksAdbBeforeOpeningAndHonorsCancellation() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
            var previous = ReflectionHelpers.getStaticField(LauncherAccessibilityService.class, "active");
            ReflectionHelpers.setStaticField(LauncherAccessibilityService.class, "active", new WeakReference<>(service));
            try {
                var result = new AtomicReference<RecentAppsBridge.OpenResult>();
                var main = new Handler(Looper.getMainLooper());
                RecentAppsBridge.open(activity, Runnable::run, main, () -> true, result::set);
                assertNull(result.get());
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertEquals(RecentAppsBridge.OpenResult.ADB_REQUIRED, result.get());
                RecentAppsBridge.open(activity, Runnable::run, main, () -> false, result::set);
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertEquals(RecentAppsBridge.OpenResult.CANCELLED, result.get());
            } finally {
                ReflectionHelpers.setStaticField(LauncherAccessibilityService.class, "active", previous);
            }
        }
    }

    @Test public void automaticModeCanOpenBuiltInPanelWithoutEitherAccess() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            var intent = RecentAppsBridge.systemIntent();
            var resolved = new ResolveInfo();
            resolved.activityInfo = new ActivityInfo();
            resolved.activityInfo.packageName = intent.getComponent().getPackageName();
            resolved.activityInfo.name = intent.getComponent().getClassName();
            resolved.activityInfo.applicationInfo = new ApplicationInfo();
            resolved.activityInfo.applicationInfo.packageName = resolved.activityInfo.packageName;
            resolved.activityInfo.applicationInfo.enabled = true;
            resolved.activityInfo.enabled = true;
            resolved.activityInfo.exported = true;
            Shadows.shadowOf(activity.getPackageManager()).addResolveInfoForIntent(intent, resolved);
            var result = new AtomicReference<RecentAppsBridge.OpenResult>();
            RecentAppsBridge.open(activity, task -> fail("ADB check should not run"), new Handler(Looper.getMainLooper()),
                () -> true, result::set);
            assertEquals(RecentAppsBridge.OpenResult.OPENED, result.get());
            assertEquals(intent.getComponent(), Shadows.shadowOf(activity).getNextStartedActivity().getComponent());
        }
    }

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
            var access = Shadows.shadowOf(activity).getNextStartedActivity();
            assertEquals(MainActivity.class.getName(), access.getComponent().getClassName());
            assertTrue(access.getBooleanExtra(LauncherActivity.OPEN_ACCESSIBILITY_SETTINGS, false));
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
