package com.leanbitlab.ltvL;

import android.content.Intent;
import android.os.Build;
import io.flutter.embedding.android.RenderMode;
import io.flutter.embedding.android.TransparencyMode;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 34, 36})
public class LauncherRenderModeTest {
    private static LauncherActivity launcher(String manufacturer, String model, String hardware) {
        ReflectionHelpers.setStaticField(Build.class, "MANUFACTURER", manufacturer);
        ReflectionHelpers.setStaticField(Build.class, "MODEL", model);
        ReflectionHelpers.setStaticField(Build.class, "HARDWARE", hardware);
        // Do not start an engine: exercise the real host's render selection before onCreate.
        var activity = Robolectric.buildActivity(LauncherActivity.class).get();
        activity.setIntent(new Intent());
        return activity;
    }

    @Test public void kp1UsesTextureWithoutMakingTheWindowTransparent() {
        var activity = launcher("SEI Robotics", "KP1", "amlogic");
        assertEquals(RenderMode.texture, activity.getRenderMode());
        assertEquals(TransparencyMode.opaque, activity.getTransparencyMode());
    }

    @Test public void otherDevicesKeepSurfaceRendering() {
        assertEquals(RenderMode.surface, launcher("TCL", "TCL TV", "amlogic").getRenderMode());
        assertEquals(RenderMode.surface, launcher("SEI Robotics", "Other", "amlogic").getRenderMode());
        assertEquals(RenderMode.surface, launcher("Other", "KP1", "amlogic").getRenderMode());
        assertEquals(RenderMode.surface, launcher("SEI Robotics", "KP1", "other").getRenderMode());
    }

    @Test public void explicitTransparentLaunchStillUsesFlutterDefault() {
        var activity = launcher("TCL", "TCL TV", "amlogic");
        activity.setIntent(new Intent().putExtra("background_mode", "transparent"));
        assertEquals(RenderMode.texture, activity.getRenderMode());
        assertEquals(TransparencyMode.transparent, activity.getTransparencyMode());
    }

    @Test public void manualChoicePersistsButDoesNotChangeAnExistingSurface() throws Exception {
        var activity = launcher("Other", "TV", "amlogic");
        assertEquals(RenderMode.surface, activity.getRenderMode());
        RenderCompatibility.save(activity, true);
        assertTrue(RenderCompatibility.enabled(activity));
        assertEquals(RenderMode.surface, activity.getRenderMode());
        var restarted = launcher("Other", "TV", "amlogic");
        assertEquals(RenderMode.texture, restarted.getRenderMode());
        RenderCompatibility.save(restarted, false);
        assertEquals(RenderMode.texture, restarted.getRenderMode());
        assertEquals(RenderMode.surface, launcher("Other", "TV", "amlogic").getRenderMode());
        assertFalse(activity.getSharedPreferences("FlutterSharedPreferences", 0)
                .contains("flutter.render_compatibility"));
    }

    @Test public void automaticWorkaroundDoesNotNeedAManualPreference() throws Exception {
        var activity = launcher("SEI Robotics", "KP1", "amlogic");
        RenderCompatibility.save(activity, false);
        assertTrue(RenderCompatibility.enabled(activity));
        assertEquals(RenderMode.texture, activity.getRenderMode());
        assertTrue(activity.getSharedPreferences("render_compatibility", 0).getAll().isEmpty());
    }
}
