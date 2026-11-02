package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Handler;
import android.os.Looper;
import android.view.accessibility.AccessibilityEvent;
import java.time.Duration;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 34, 36})
public class VolumeKeyFilterPauseTest {
    private static final int FILTER = AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS;
    private final AccessibilityServiceInfo info = new AccessibilityServiceInfo();
    private int cancelled, writes;
    private final VolumeKeyFilterPause pause = new VolumeKeyFilterPause(new Handler(Looper.getMainLooper()),
        () -> info, value -> { writes++; info.flags = value.flags; }, () -> cancelled++);

    { pause.configure(new RemoteMappingConfiguration(true, java.util.Map.of(), "timed", 5)); }

    private static AccessibilityEvent event(String pkg, String name) {
        var event = AccessibilityEvent.obtain(AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED);
        event.setPackageName(pkg); event.setClassName(name); return event;
    }
    private void show() { pause.event(event("com.android.systemui", "com.tcl.volume.view.TclVolumeDialog")); }
    private static void advance(long millis) { shadowOf(Looper.getMainLooper()).idleFor(Duration.ofMillis(millis)); }

    @Test public void restoresAfterFiveSecondsAndPreservesOtherCurrentFlags() {
        info.flags = FILTER | AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
        show();
        assertTrue(pause.paused()); assertEquals(1, cancelled);
        assertEquals(AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS, info.flags);
        advance(4999); assertTrue(pause.paused());
        info.flags |= AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS;
        advance(1);
        assertFalse(pause.paused()); assertTrue((info.flags & FILTER) != 0);
        assertTrue((info.flags & AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS) != 0);
        assertEquals(2, writes); pause.close(); assertEquals(2, writes);
    }
    @Test public void repeatedPanelEventsExtendOneTimerAndCloseRestoresImmediately() {
        info.flags = FILTER;
        show(); advance(4000); show(); advance(1001);
        assertTrue(pause.paused()); assertEquals(1, cancelled); assertEquals(1, writes);
        pause.close(); assertEquals(FILTER, info.flags); assertFalse(pause.paused());
        advance(6000); show(); assertEquals(2, writes);
    }
    @Test public void unrelatedWindowsAndAppImpersonationCannotPauseFiltering() {
        info.flags = FILTER;
        pause.event(event("other.app", "com.tcl.volume.view.TclVolumeDialog"));
        pause.event(event("com.android.systemui", "android.app.Dialog"));
        pause.event(event("com.android.systemui", "com.android.systemui.brightness.BrightnessDialog"));
        var wrongType = event("com.android.systemui", "com.tcl.volume.view.TclVolumeDialog");
        wrongType.setEventType(AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED); pause.event(wrongType);
        pause.event(null); assertFalse(pause.paused()); assertEquals(0, writes); pause.close();
    }
    @Test public void doesNotEnableFilteringThatWasAlreadyDisabled() {
        info.flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS;
        show(); advance(6000); pause.close();
        assertEquals(0, writes); assertEquals(0, cancelled); assertFalse(pause.paused());
        assertEquals(AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS, info.flags);
    }
}
