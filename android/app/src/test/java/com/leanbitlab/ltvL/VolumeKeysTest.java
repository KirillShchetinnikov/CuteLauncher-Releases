package com.leanbitlab.ltvL;

import android.view.KeyEvent;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.Implementation;
import org.robolectric.annotation.Implements;
import org.robolectric.shadow.api.Shadow;
import org.robolectric.shadows.ShadowPhoneWindow;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 34, 36}, shadows = VolumeKeysTest.ConsumingWindow.class)
public class VolumeKeysTest {
    @Implements(className = "com.android.internal.policy.PhoneWindow", isInAndroidSdk = false)
    public static class ConsumingWindow extends ShadowPhoneWindow {
        int delivered;
        @Implementation protected boolean superDispatchKeyEvent(KeyEvent event) {
            delivered++;
            return true;
        }
    }

    @Test public void volumePressRepeatsAndReleaseBypassTheFlutterContent() {
        // Attach the real host without starting its native Flutter engine.
        var activity = Robolectric.buildActivity(LauncherActivity.class).get();
        ConsumingWindow window = Shadow.extract(activity.getWindow());
        // Prove the normal host dispatch really reaches the consuming content.
        assertTrue(activity.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DPAD_RIGHT)));
        assertEquals(1, window.delivered);
        window.delivered = 0;
        for (int key : new int[] {KeyEvent.KEYCODE_VOLUME_UP, KeyEvent.KEYCODE_VOLUME_DOWN}) {
            for (int repeat = 0; repeat < 6; repeat++) {
                assertFalse(activity.dispatchKeyEvent(new KeyEvent(100, 100 + repeat * 100,
                        KeyEvent.ACTION_DOWN, key, repeat)));
            }
            assertFalse(activity.dispatchKeyEvent(new KeyEvent(100, 800,
                    KeyEvent.ACTION_UP, key, 0)));
        }
        assertEquals(0, window.delivered);
        // Mute remains available to the remote remapper and Flutter.
        assertTrue(activity.dispatchKeyEvent(new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_MUTE)));
        assertEquals(1, window.delivered);
    }
}
