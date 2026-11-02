package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.view.accessibility.AccessibilityEvent;
import java.time.Duration;
import java.util.ArrayList;
import java.util.Map;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 34, 36})
public class VolumeWorkaroundTest {
    private static RemoteMappingConfiguration config(String mode) {
        return new RemoteMappingConfiguration(true, Map.of(), mode, 3);
    }
    private static void advance(long millis) { shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(millis)); }
    private static AccessibilityEvent panel() {
        var event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
        event.setPackageName("com.android.systemui"); event.setClassName("com.tcl.volume.view.TclVolumeDialog"); return event;
    }
    @Test public void autoExtendsOnlyVisibleWindowsAndRestoresAtClosureOrHardLimit() {
        var info = new AccessibilityServiceInfo(); info.flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS;
        Boolean[] visible = {true};
        var pause = new VolumeKeyFilterPause(new Handler(Looper.getMainLooper()), () -> info, v -> {}, () -> {}, () -> visible[0]);
        pause.configure(config("auto")); pause.event(panel()); advance(3100); assertTrue(pause.paused());
        visible[0] = false; advance(1000); assertFalse(pause.paused());
        visible[0] = true; pause.event(panel()); advance(60000); assertFalse(pause.paused());
        pause.close();
    }
    @Test public void unknownVisibilityFallsBackToTimerAndConfigurationChangesRestore() {
        var info = new AccessibilityServiceInfo(); info.flags = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS;
        var pause = new VolumeKeyFilterPause(new Handler(Looper.getMainLooper()), () -> info, v -> {}, () -> {}, () -> null);
        pause.configure(config("auto")); pause.event(panel()); advance(3000); assertFalse(pause.paused());
        pause.event(panel()); pause.configure(config("off")); assertFalse(pause.paused());
        assertTrue((info.flags & AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS) != 0);
        pause.event(panel()); assertFalse(pause.paused()); pause.close();
    }
    @Test public void vendorDetectionRequiresSystemOwnershipAndVolumeIdentity() {
        assertTrue(VolumeKeyFilterPause.panel("vendor.ui", "vendor.sound.VolumePanel", null, true));
        assertTrue(VolumeKeyFilterPause.panel("vendor.ui", "android.app.Dialog", "vendor.ui:id/volume_dialog", true));
        assertFalse(VolumeKeyFilterPause.panel("fake.app", "VolumeDialog", null, false));
        assertFalse(VolumeKeyFilterPause.panel("vendor.ui", "BrightnessDialog", "vendor.ui:id/container", true));
    }
    @Test public void repeatStartsOnceRepeatsAndStopsOnMatchingReleaseAndDisable() {
        var changes = new ArrayList<Integer>();
        var repeat = new VolumeKeyRepeater(new Handler(Looper.getMainLooper()), changes::add);
        repeat.configure(config("repeat"));
        var down = new KeyEvent(100, 100, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_UP, 0);
        assertTrue(repeat.event(down)); assertEquals(java.util.List.of(1), changes);
        advance(499); assertEquals(1, changes.size()); advance(1); assertEquals(2, changes.size());
        repeat.event(new KeyEvent(100, 600, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_UP, 1));
        advance(60); assertEquals(3, changes.size());
        repeat.event(new KeyEvent(100, 660, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_VOLUME_UP, 0));
        advance(1000); assertEquals(3, changes.size());
        repeat.event(new KeyEvent(200, 200, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_DOWN, 0));
        assertEquals(Integer.valueOf(-1), changes.get(3));
        repeat.configure(config("off")); advance(1000); assertEquals(4, changes.size());
        assertFalse(repeat.event(down)); repeat.close();
    }
    @Test public void lostReleaseCannotRepeatForever() {
        int[] count = {0};
        var repeat = new VolumeKeyRepeater(new Handler(Looper.getMainLooper()), ignored -> count[0]++);
        repeat.configure(config("repeat")); repeat.event(new KeyEvent(0, 0, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_DOWN, 0));
        advance(31000); int stopped = count[0]; assertTrue(stopped > 1);
        advance(1000); assertEquals(stopped, count[0]); repeat.close();
    }
    @Test public void storageDefaultsAndValidationPreserveExplicitOptOut() throws Exception {
        var defaults = RemoteMappingConfiguration.fromMap(Map.of("enabled", true, "bindings", java.util.List.of()));
        assertEquals("auto", defaults.volumeMode); assertEquals(5, defaults.volumePauseSeconds);
        var restored = RemoteMappingStore.decode(new org.json.JSONObject(config("off").toMap()));
        assertEquals("off", restored.volumeMode); assertEquals(3, restored.volumePauseSeconds);
        assertThrows(IllegalArgumentException.class, () -> RemoteMappingConfiguration.fromMap(Map.of(
            "enabled", true, "bindings", java.util.List.of(), "volumeMode", "wrong")));
        assertThrows(IllegalArgumentException.class, () -> RemoteMappingConfiguration.fromMap(Map.of(
            "enabled", true, "bindings", java.util.List.of(), "volumePauseSeconds", 4.5)));
    }
}
