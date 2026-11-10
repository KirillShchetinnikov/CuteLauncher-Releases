package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageInfo;
import android.content.pm.ServiceInfo;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Looper;
import android.os.SystemClock;
import android.view.KeyEvent;
import android.view.WindowManager;
import java.util.List;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowBuild;
import org.robolectric.shadows.ShadowToast;
import org.robolectric.shadows.ShadowWindowManagerImpl;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemoteBlackScreenTest {
    private static final int KEY = 4137;

    @Test public void eachPressLaunchesTheSameToggle() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var activities = Shadows.shadowOf(RuntimeEnvironment.getApplication());
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure();
            for (long time : new long[] {100, 200}) {
                press(remapper, time);
                Intent intent = activities.getNextStartedActivity();
                assertNotNull(intent);
                assertEquals(new ComponentName("io.japp.blackscreen",
                    "io.japp.blackscreen.ui.ToggleBlackScreenActivity"), intent.getComponent());
                assertEquals(Intent.FLAG_ACTIVITY_NEW_TASK, intent.getFlags());
                assertNull(intent.getAction());
                assertNull(activities.getNextStartedActivity());
                assertEquals("success", RemoteButtonRemapper.status);
                assertNull(ShadowToast.getTextOfLatestToast());
            }
        }
    }

    @Test public void missingActivityShowsAnErrorNotice() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        Shadows.shadowOf(RuntimeEnvironment.getApplication()).checkActivities(true);
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure();
            press(remapper, 100);
            assertEquals("unavailable", RemoteButtonRemapper.status);
            assertEquals(service.getString(R.string.remap_error_black_screen),
                ShadowToast.getTextOfLatestToast());
        }
    }

    @Test public void missingAssignedAppShowsAnErrorNotice() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        try (var remapper = new RemoteButtonRemapper(service)) {
            var binding = new RemoteMappingConfiguration.Binding(KEY, true, "app", "com.example.missing");
            RemoteButtonRemapper.editing = false;
            RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
            press(remapper, 100);
            assertEquals("unavailable", RemoteButtonRemapper.status);
            assertEquals(service.getString(R.string.remap_error_app), ShadowToast.getTextOfLatestToast());
        }
    }

    @Test public void activeButtonDiagnosticsPausesAssignedActionsUntilStopped() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var activities = Shadows.shadowOf(RuntimeEnvironment.getApplication());
        RemoteButtonCapture capture = ReflectionHelpers.getStaticField(RemoteButtonsBridge.class, "capture");
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure();
            press(remapper, 100);
            assertNotNull(activities.getNextStartedActivity());

            capture.start(SystemClock.elapsedRealtime());
            var down = new KeyEvent(200, 200, KeyEvent.ACTION_DOWN, KEY, 0);
            var up = new KeyEvent(200, 210, KeyEvent.ACTION_UP, KEY, 0);
            RemoteButtonsBridge.observe(down);
            assertFalse(remapper.event(down));
            RemoteButtonsBridge.observe(up);
            assertFalse(remapper.event(up));
            assertEquals(2, capture.snapshot().size());
            assertNull(activities.getNextStartedActivity());

            capture.stop();
            press(remapper, 300);
            assertNotNull(activities.getNextStartedActivity());
        } finally {
            capture.stop();
        }
    }

    @Test public void onlyEmptyTargetIsAccepted() {
        for (String action : List.of("black_screen", "black_overlay", "tcl_screen_off")) {
            var row = Map.of("keyCode", KEY, "enabled", true, "action", action, "target", "");
            var config = RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(row)));
            assertEquals(action, RemoteMappingConfiguration.fromMap(config.toMap()).binding(KEY).action());
            var invalid = Map.of("keyCode", KEY, "enabled", true, "action", action, "target", "other.app");
            assertThrows(IllegalArgumentException.class, () -> RemoteMappingConfiguration.fromMap(
                Map.of("enabled", true, "bindings", List.of(invalid))));
        }
    }

    @Test public void tclActionStartsTheFirmwareCountdownOnlyWhenAvailable() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var application = Shadows.shadowOf(RuntimeEnvironment.getApplication());
        ShadowBuild.setManufacturer("TCL");
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure("tcl_screen_off");
            press(remapper, 100);
            assertEquals("unavailable", RemoteButtonRemapper.status);
            assertNull(application.getNextStartedService());

            var info = new ServiceInfo();
            info.packageName = "com.android.tv.settings";
            info.name = "com.tcl.settings.ShowWindowService";
            info.exported = true;
            info.applicationInfo = new ApplicationInfo();
            info.applicationInfo.packageName = info.packageName;
            info.applicationInfo.flags = ApplicationInfo.FLAG_SYSTEM;
            var settings = new PackageInfo();
            settings.packageName = info.packageName;
            settings.applicationInfo = info.applicationInfo;
            settings.services = new ServiceInfo[] {info};
            Shadows.shadowOf(service.getPackageManager()).installPackage(settings);
            assertTrue(TclScreenOff.available(service));
            press(remapper, 200);
            assertEquals("success", RemoteButtonRemapper.status);
            Intent intent = application.getNextStartedService();
            assertNotNull(intent);
            assertEquals(new ComponentName(info.packageName, info.name), intent.getComponent());
            assertEquals("com.tcl.settings.SHOW_WINDOW", intent.getAction());
            assertEquals("AudioOnly", intent.getStringExtra("Type"));
        }
    }

    @Test public void builtInBlackScreenKeepsFocusAndClosesOnSecondPressOrBack() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        ShadowWindowManagerImpl windows = Shadow.extract(service.getSystemService(WindowManager.class));
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure("black_overlay");
            press(remapper, 100);
            assertEquals("success", RemoteButtonRemapper.status);
            assertEquals(1, windows.getViews().size());
            var view = windows.getViews().get(0);
            assertEquals(Color.BLACK, ((ColorDrawable) view.getBackground()).getColor());
            var params = (WindowManager.LayoutParams) view.getLayoutParams();
            assertEquals(WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY, params.type);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE) != 0);
            assertTrue((params.flags & WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE) != 0);
            press(remapper, 200);
            assertTrue(windows.getViews().isEmpty());

            press(remapper, 300);
            var backDown = new KeyEvent(400, 400, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_BACK, 0);
            var backUp = new KeyEvent(400, 410, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_BACK, 0);
            assertTrue(remapper.dismissBlackScreenOnBack(backDown));
            assertTrue(remapper.dismissBlackScreenOnBack(backUp));
            assertTrue(windows.getViews().isEmpty());
            assertFalse(remapper.dismissBlackScreenOnBack(backDown));
        }
    }

    @Test public void builtInBlackScreenClosesOnScreenOffAndRemapperDisable() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        ShadowWindowManagerImpl windows = Shadow.extract(service.getSystemService(WindowManager.class));
        try (var remapper = new RemoteButtonRemapper(service)) {
            configure("black_overlay");
            press(remapper, 100);
            service.sendBroadcast(new Intent(Intent.ACTION_SCREEN_OFF));
            Shadows.shadowOf(Looper.getMainLooper()).idle();
            assertTrue(windows.getViews().isEmpty());

            press(remapper, 200);
            RemoteButtonRemapper.updated(RemoteMappingConfiguration.empty());
            assertTrue(windows.getViews().isEmpty());

            configure("black_overlay");
            press(remapper, 300);
        }
        assertTrue(windows.getViews().isEmpty());
    }

    private static void configure() {
        configure("black_screen");
    }

    private static void configure(String action) {
        var binding = new RemoteMappingConfiguration.Binding(KEY, true, action, "");
        RemoteButtonRemapper.editing = false;
        RemoteButtonRemapper.updated(new RemoteMappingConfiguration(true, Map.of(binding.slot(), binding)));
    }

    private static void press(RemoteButtonRemapper remapper, long time) {
        assertTrue(remapper.event(new KeyEvent(time, time, KeyEvent.ACTION_DOWN, KEY, 0)));
        assertTrue(remapper.event(new KeyEvent(time, time + 10, KeyEvent.ACTION_UP, KEY, 0)));
    }
}
