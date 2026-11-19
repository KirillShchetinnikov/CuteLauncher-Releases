package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ResolveInfo;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import java.nio.ByteBuffer;
import java.time.Duration;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.android.controller.ActivityController;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class AutoLaunchLifecycleTest {
    private static final String TV = "org.example.tv";
    private static final BinaryMessenger MESSENGER = new BinaryMessenger() {
        public void send(String channel, ByteBuffer data) { }
        public void send(String channel, ByteBuffer data, BinaryReply reply) { }
        public void setMessageHandler(String channel, BinaryMessageHandler handler) { }
    };

    private final Context context = RuntimeEnvironment.getApplication();

    public static class Home extends Activity {
        boolean focused;
        @Override public boolean hasWindowFocus() { return focused; }
    }

    @Before public void configureTarget() {
        var app = new ApplicationInfo();
        app.packageName = TV;
        app.enabled = true;
        var entry = new ActivityInfo();
        entry.packageName = TV;
        entry.name = TV + ".Main";
        entry.enabled = true;
        entry.exported = true;
        entry.applicationInfo = app;
        var pkg = new PackageInfo();
        pkg.packageName = TV;
        pkg.applicationInfo = app;
        pkg.activities = new ActivityInfo[]{entry};
        var packages = Shadows.shadowOf(context.getPackageManager());
        packages.installPackage(pkg);
        var resolved = new ResolveInfo();
        resolved.activityInfo = entry;
        packages.addResolveInfoForIntent(
            new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LEANBACK_LAUNCHER).setPackage(TV), resolved);
        context.getSharedPreferences("auto_launch", Context.MODE_PRIVATE).edit()
            .putString("mode", "app").putString("app", TV)
            .putBoolean("boot", true).putBoolean("wake", true).putInt("delay", 1).commit();
    }

    private static final class Launcher implements AutoCloseable {
        private final ActivityController<Home> controller = Robolectric.buildActivity(Home.class).setup();
        final Home home = controller.get();
        final AutoLaunchBridge bridge = new AutoLaunchBridge(home, MESSENGER);

        void resumeWithFocus() {
            home.focused = true;
            bridge.resume();
        }

        void expectOneLaunch() {
            advance(Duration.ofSeconds(1));
            Intent started = Shadows.shadowOf(home).getNextStartedActivity();
            assertNotNull("The selected TV application must be launched", started);
            assertEquals(TV, started.getComponent().getPackageName());
            bridge.pause();
            resumeWithFocus();
            advance(Duration.ofSeconds(1));
            expectNoLaunch();
        }

        void expectNoLaunch() {
            assertNull(Shadows.shadowOf(home).getNextStartedActivity());
        }

        @Override public void close() {
            bridge.close();
            controller.close();
        }
    }

    private static void advance(Duration duration) {
        Shadows.shadowOf(Looper.getMainLooper()).idleFor(duration);
    }

    private void screen(String action) {
        context.sendBroadcast(new Intent(action));
        advance(Duration.ofMillis(1));
    }

    @Test public void bootCompletedStartsTvOnceWhenLauncherGetsFocus() {
        new BootReceiver().onReceive(context, new Intent(Intent.ACTION_BOOT_COMPLETED));
        try (var launcher = new Launcher()) {
            launcher.bridge.resume();
            advance(Duration.ofSeconds(3));
            launcher.expectNoLaunch();
            launcher.resumeWithFocus();
            launcher.expectOneLaunch();
        }
    }

    @Test public void wakeBetweenActivityInstancesStartsTvAfterLongSleep() {
        try (var launcher = new Launcher()) {
            launcher.resumeWithFocus();
            screen(Intent.ACTION_SCREEN_OFF);
        }
        advance(Duration.ofHours(8));
        screen(Intent.ACTION_SCREEN_ON);
        try (var launcher = new Launcher()) {
            launcher.bridge.onEntry(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME));
            launcher.resumeWithFocus();
            launcher.expectOneLaunch();
        }
    }

    @Test public void wakeStartsTvWhenWindowFocusReturnsAfterTwoSeconds() {
        try (var launcher = new Launcher()) {
            launcher.bridge.resume();
            screen(Intent.ACTION_SCREEN_OFF);
            screen(Intent.ACTION_SCREEN_ON);
            advance(Duration.ofSeconds(5));
            launcher.expectNoLaunch();
            launcher.home.focused = true;
            launcher.bridge.focus(true);
            launcher.expectOneLaunch();
        }
    }

    @Test public void screenOnAloneStartsTvWhenAndroidDropsScreenOff() {
        try (var launcher = new Launcher()) {
            screen(Intent.ACTION_SCREEN_ON);
            launcher.resumeWithFocus();
            launcher.expectOneLaunch();
        }
    }

    @Test public void expiredWakeDoesNotStartTvOnLaterReturnToHome() {
        try (var launcher = new Launcher()) {
            screen(Intent.ACTION_SCREEN_OFF);
            screen(Intent.ACTION_SCREEN_ON);
            advance(Duration.ofSeconds(61));
            launcher.resumeWithFocus();
            advance(Duration.ofSeconds(1));
            launcher.expectNoLaunch();
        }
    }

    @Test public void homeButtonCancelsWakeThatIsWaitingForFocus() {
        try (var launcher = new Launcher()) {
            screen(Intent.ACTION_SCREEN_ON);
            launcher.bridge.onEntry(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
                .putExtra("android.intent.extra.FROM_HOME_KEY", true));
            launcher.resumeWithFocus();
            advance(Duration.ofSeconds(1));
            launcher.expectNoLaunch();
        }
    }

    @Test public void homeButtonFixCancelsWakeThatIsWaitingForFocus() {
        try (var launcher = new Launcher()) {
            screen(Intent.ACTION_SCREEN_ON);
            launcher.bridge.onEntry(new Intent().putExtra("return_home", true));
            launcher.resumeWithFocus();
            advance(Duration.ofSeconds(1));
            launcher.expectNoLaunch();
        }
    }
}
