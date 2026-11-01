package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicBoolean;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class BackgroundStartupTest {
    public static class HomeActivity extends Activity {
        @Override public boolean hasWindowFocus() { return true; }
    }
    private static final class Messenger implements io.flutter.plugin.common.BinaryMessenger {
        public void send(String channel, java.nio.ByteBuffer message) { }
        public void send(String channel, java.nio.ByteBuffer message, BinaryReply reply) { }
        public void setMessageHandler(String channel, BinaryMessageHandler handler) { }
    }
    private static final String APP = "org.example.client";
    private void install(Activity activity, int flags, int mode, int document) {
        var application = new ApplicationInfo();
        application.packageName = APP; application.enabled = true; application.flags = flags;
        application.nonLocalizedLabel = "Example";
        var entry = new ActivityInfo();
        entry.packageName = APP; entry.name = APP + ".Main"; entry.applicationInfo = application;
        entry.enabled = true; entry.exported = true; entry.launchMode = mode; entry.documentLaunchMode = document;
        var pkg = new PackageInfo(); pkg.packageName = APP; pkg.applicationInfo = application;
        pkg.activities = new ActivityInfo[]{entry};
        var pm = Shadows.shadowOf(activity.getPackageManager());
        pm.installPackage(pkg);
        var resolved = new android.content.pm.ResolveInfo(); resolved.activityInfo = entry;
        pm.addResolveInfoForIntent(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER).setPackage(APP), resolved);
        pm.addResolveInfoForIntent(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
            .setComponent(new android.content.ComponentName(APP, entry.name)), resolved);
    }
    private static final class Reply implements MethodChannel.Result {
        volatile Object value;
        volatile boolean done;
        public void success(Object value) { this.value = value; done = true; }
        public void error(String code, String message, Object details) { value = code; done = true; }
        public void notImplemented() { throw new AssertionError(); }
    }
    private void await(java.util.function.BooleanSupplier done) throws Exception {
        long until = System.nanoTime() + 5_000_000_000L;
        while (!done.getAsBoolean() && System.nanoTime() < until) {
            Shadows.shadowOf(Looper.getMainLooper()).idle(); Thread.sleep(10);
        }
        assertTrue("Worker did not finish", done.getAsBoolean());
    }
    private Reply request(BackgroundStartup startup, String method, Object args) throws Exception {
        var reply = new Reply(); assertTrue(startup.handle(method, args, reply)); await(() -> reply.done); return reply;
    }
    @Test public void launchesDocumentBehindAndOnlyAtBootWithSelection() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, 0);
            var startup = new BackgroundStartup(activity);
            try {
                assertFalse(BackgroundStartup.enabled(activity));
                assertEquals("success", ((Map<?, ?>) request(startup, "backgroundSave", List.of(APP)).value).get("status"));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
                AutoLaunchBridge.boot(activity);
                assertTrue(activity.getSharedPreferences("auto_launch", 0).contains("boot_at"));
                var done = new AtomicBoolean(); startup.launch(() -> true, () -> done.set(true));
                await(() -> Shadows.shadowOf(activity).peekNextStartedActivity() != null);
                Intent launched = Shadows.shadowOf(activity).getNextStartedActivity();
                assertEquals(APP, launched.getComponent().getPackageName());
                assertTrue((launched.getFlags() & Intent.FLAG_ACTIVITY_NEW_DOCUMENT) != 0);
                assertTrue((launched.getFlags() & Intent.FLAG_ACTIVITY_MULTIPLE_TASK) != 0);
                Shadows.shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofMillis(400));
                assertTrue(done.get());
                var info = (Map<?, ?>) request(startup, "backgroundInfo", null).value;
                assertEquals("requested", ((Map<?, ?>) info.get("outcomes")).get(APP));
            } finally { startup.close(); }
        }
    }
    @Test public void rejectsSystemAndUnsupportedActivitiesWithoutForegroundFallback() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); var startup = new BackgroundStartup(activity);
            try {
                for (int mode : new int[]{ActivityInfo.LAUNCH_SINGLE_TASK, ActivityInfo.LAUNCH_SINGLE_INSTANCE, 4}) {
                    install(activity, 0, mode, 0); assertNull(startup.target(APP));
                }
                install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, ActivityInfo.DOCUMENT_LAUNCH_NEVER);
                assertNull(startup.target(APP));
                install(activity, ApplicationInfo.FLAG_SYSTEM, ActivityInfo.LAUNCH_MULTIPLE, 0);
                assertNull(startup.target(APP));
                assertEquals("unavailable", ((Map<?, ?>) request(startup, "backgroundSave", List.of(APP)).value).get("status"));
                assertFalse(BackgroundStartup.enabled(activity));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { startup.close(); }
        }
    }
    @Test public void preservesUnavailableSelectionAndAllowsRemoval() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get();
            activity.getSharedPreferences("background_startup", 0).edit().putStringSet("apps", Set.of(APP)).commit();
            var startup = new BackgroundStartup(activity);
            try {
                var info = (Map<?, ?>) request(startup, "backgroundInfo", null).value;
                var apps = (List<?>) info.get("apps");
                assertEquals(1, apps.size());
                assertEquals(true, ((Map<?, ?>) apps.get(0)).get("selected"));
                assertEquals(false, ((Map<?, ?>) apps.get(0)).get("available"));
                assertEquals("success", ((Map<?, ?>) request(startup, "backgroundSave", List.of(APP)).value).get("status"));
                assertEquals("success", ((Map<?, ?>) request(startup, "backgroundSave", List.of()).value).get("status"));
                assertFalse(BackgroundStartup.enabled(activity));
            } finally { startup.close(); }
        }
    }
    @Test public void cancellationAndMissingForegroundPreventLaunches() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, 0);
            var startup = new BackgroundStartup(activity);
            try {
                request(startup, "backgroundSave", List.of(APP));
                startup.launch(() -> true, () -> fail("Cancelled launch completed")); startup.cancel();
                // Queue barrier waits for launch preparation, then the main callback is drained.
                request(startup, "backgroundInfo", null);
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
                startup.launch(() -> false, () -> fail("Background launch completed"));
                request(startup, "backgroundInfo", null);
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { startup.close(); }
        }
    }
    @Test public void malformedPackagesAndOwnPackageCannotBeSaved() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); var startup = new BackgroundStartup(activity);
            try {
                for (Object invalid : List.of(List.of("org.example;bad"), List.of(activity.getPackageName()), List.of(42), "wrong"))
                    assertEquals("invalid", ((Map<?, ?>) request(startup, "backgroundSave", invalid).value).get("status"));
                assertFalse(BackgroundStartup.enabled(activity));
                AutoLaunchBridge.boot(activity);
                assertFalse(activity.getSharedPreferences("auto_launch", Context.MODE_PRIVATE).contains("boot_at"));
            } finally { startup.close(); }
        }
    }
    @Test public void bootIsConsumedOnceAndHomeReturnDoesNotRepeatIt() throws Exception {
        try (var controller = Robolectric.buildActivity(HomeActivity.class).setup()) {
            var activity = controller.get(); install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, 0);
            activity.getSharedPreferences("background_startup", 0).edit().putStringSet("apps", Set.of(APP)).commit();
            AutoLaunchBridge.boot(activity);
            var bridge = new AutoLaunchBridge(activity, new Messenger());
            try {
                bridge.resume();
                await(() -> Shadows.shadowOf(activity).peekNextStartedActivity() != null);
                assertEquals(APP, Shadows.shadowOf(activity).getNextStartedActivity().getComponent().getPackageName());
                assertFalse(activity.getSharedPreferences("auto_launch", 0).contains("boot_at"));
                bridge.pause(); bridge.resume();
                Shadows.shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { bridge.close(); }
        }
    }
    @Test public void staleBootAndManualCancellationDoNotLaunchApps() throws Exception {
        try (var controller = Robolectric.buildActivity(HomeActivity.class).setup()) {
            var activity = controller.get(); install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, 0);
            activity.getSharedPreferences("background_startup", 0).edit().putStringSet("apps", Set.of(APP)).commit();
            android.os.SystemClock.sleep(61000);
            activity.getSharedPreferences("auto_launch", 0).edit().putLong("boot_at", 0).commit();
            var bridge = new AutoLaunchBridge(activity, new Messenger());
            try {
                bridge.resume();
                assertFalse(activity.getSharedPreferences("auto_launch", 0).contains("boot_at"));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
                AutoLaunchBridge.boot(activity); bridge.cancel();
                Shadows.shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(1));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { bridge.close(); }
        }
    }
    @Test public void singleAppUpdatePreservesOtherSelectionsAndUsesBootPreferences() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); install(activity, 0, ActivityInfo.LAUNCH_MULTIPLE, 0);
            var prefs = activity.getSharedPreferences("background_startup", 0);
            prefs.edit().putStringSet("apps", Set.of("org.example.other")).commit();
            var startup = new BackgroundStartup(activity);
            try {
                var enabled = (Map<?, ?>) request(startup, "backgroundSetApp", Map.of("app", APP, "enabled", true)).value;
                assertEquals("success", enabled.get("status"));
                assertEquals(Set.of(APP, "org.example.other"), new java.util.HashSet<>((List<?>) enabled.get("selected")));
                assertEquals(Set.of(APP, "org.example.other"), prefs.getStringSet("apps", Set.of()));
                var disabled = (Map<?, ?>) request(startup, "backgroundSetApp", Map.of("app", APP, "enabled", false)).value;
                assertEquals("success", disabled.get("status"));
                assertEquals(Set.of("org.example.other"), prefs.getStringSet("apps", Set.of()));
                assertNull(Shadows.shadowOf(activity).getNextStartedActivity());
            } finally { startup.close(); }
        }
    }
    @Test public void singleAppUpdateRejectsUnsupportedButCanRemoveMissingSelection() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var activity = controller.get(); var startup = new BackgroundStartup(activity);
            try {
                assertEquals("unavailable", ((Map<?, ?>) request(startup, "backgroundSetApp", Map.of("app", APP, "enabled", true)).value).get("status"));
                activity.getSharedPreferences("background_startup", 0).edit().putStringSet("apps", Set.of(APP)).commit();
                assertEquals("success", ((Map<?, ?>) request(startup, "backgroundSetApp", Map.of("app", APP, "enabled", false)).value).get("status"));
                assertFalse(BackgroundStartup.enabled(activity));
                for (Object args : List.of(Map.of("app", APP), Map.of("app", "org.example;bad", "enabled", true),
                        Map.of("app", activity.getPackageName(), "enabled", true), Map.of("app", APP, "enabled", "true"))) {
                    assertEquals("invalid", ((Map<?, ?>) request(startup, "backgroundSetApp", args).value).get("status"));
                }
            } finally { startup.close(); }
        }
    }
}
