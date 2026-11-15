package com.leanbitlab.ltvL;

import android.content.Context;
import android.view.KeyEvent;
import java.util.List;
import java.util.Map;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemoteNightModeTest {
    private static final int KEY = 4137;
    private static final String ACTION = "toggle_night_mode";

    @Test public void remoteKeyTogglesPersistedModeWithoutOpeningLauncher() throws Exception {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var ui = service.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        var nativePrefs = service.getSharedPreferences("night_overlay", Context.MODE_PRIVATE);
        var uiKey = "flutter.night_mode_configuration";
        // Start from valid saved settings before a Flutter engine is created.
        ui.edit().putString(uiKey, new JSONObject()
            .put("enabled", false).put("scheduled", true)
            .put("startHour", 20).put("endHour", 6).put("dim", 47)
            .put("overrideMode", "off").put("overrideUntil", 4102444800000L)
            .put("tclOverrideMode", "on").put("tclOverrideUntil", 4102444800000L)
            .toString()).apply();
        var config = mapping("");
        assertThrows(IllegalArgumentException.class, () -> mapping("unexpected"));
        var application = Shadows.shadowOf(RuntimeEnvironment.getApplication());
        try (var remapper = new RemoteButtonRemapper(service)) {
            RemoteButtonRemapper.editing = false;
            RemoteButtonRemapper.updated(config);
            press(remapper, 100);
            assertEquals("success", RemoteButtonRemapper.status);
            var start = application.getNextStartedService();
            assertNotNull(start);
            assertEquals(NightOverlayService.class.getName(), start.getComponent().getClassName());
            assertConfiguration(ui.getString(uiKey, ""), nativePrefs.getString("configuration", ""), true);

            press(remapper, 200);
            assertEquals("success", RemoteButtonRemapper.status);
            assertConfiguration(ui.getString(uiKey, ""), nativePrefs.getString("configuration", ""), false);
            assertNull(application.getNextStartedActivity());
        }
    }

    private static RemoteMappingConfiguration mapping(String target) {
        var row = Map.of("keyCode", KEY, "enabled", true, "action", ACTION, "target", target);
        return RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", List.of(row)));
    }

    private static void assertConfiguration(String ui, String nativeConfig, boolean enabled) throws Exception {
        assertEquals(ui, nativeConfig);
        var saved = new JSONObject(ui);
        assertEquals(enabled, saved.getBoolean("enabled"));
        assertTrue(saved.getBoolean("scheduled"));
        assertEquals(20, saved.getInt("startHour"));
        assertEquals(6, saved.getInt("endHour"));
        assertEquals(47, saved.getInt("dim"));
        assertEquals("none", saved.getString("overrideMode"));
        assertEquals("none", saved.getString("tclOverrideMode"));
        assertEquals(0, saved.getLong("overrideUntil"));
        assertEquals(0, saved.getLong("tclOverrideUntil"));
    }

    private static void press(RemoteButtonRemapper remapper, long time) {
        assertTrue(remapper.event(new KeyEvent(time, time, KeyEvent.ACTION_DOWN, KEY, 0)));
        assertTrue(remapper.event(new KeyEvent(time, time + 10, KeyEvent.ACTION_UP, KEY, 0)));
    }
}
