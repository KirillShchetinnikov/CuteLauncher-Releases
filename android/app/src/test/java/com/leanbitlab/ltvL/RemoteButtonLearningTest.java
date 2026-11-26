package com.leanbitlab.ltvL;

import android.os.SystemClock;
import android.view.InputDevice;
import android.view.KeyEvent;
import java.util.ArrayList;
import java.util.List;
import org.junit.After;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;

import static org.junit.Assert.assertEquals;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemoteButtonLearningTest {
    private static final int REMOTE = 20;
    private static final int REMOTE_SOURCE = InputDevice.SOURCE_KEYBOARD | InputDevice.SOURCE_DPAD;
    private static final int CONFIRM_SCAN = 353;
    private static final int SKIP_SCAN = 240;
    private static final int LIVE_TV_SCAN = 377;

    @After public void resetLearning() {
        RemoteButtonLearning.reset();
    }

    @Test public void learnsLiveTvInsteadOfTheEventAfterConfirm() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var learned = new ArrayList<Integer>();

        press(service, KeyEvent.KEYCODE_DPAD_CENTER, CONFIRM_SCAN, 100);
        RemoteButtonLearning.start(learned::add);
        SystemClock.sleep(2);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, SKIP_SCAN, 1);
        SystemClock.sleep(4782);
        press(service, KeyEvent.KEYCODE_FEATURED_APP_1, LIVE_TV_SCAN, 175);
        SystemClock.sleep(1);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, SKIP_SCAN, 1);

        assertEquals(List.of(KeyEvent.KEYCODE_FEATURED_APP_1), learned);
    }

    @Test public void learnsGuideImmediatelyWhenCaptureStartedBeforeConfirmWasReleased() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var learned = new ArrayList<Integer>();

        RemoteButtonLearning.start(learned::add);
        press(service, KeyEvent.KEYCODE_DPAD_CENTER, CONFIRM_SCAN, 100);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, SKIP_SCAN, 1);
        press(service, KeyEvent.KEYCODE_GUIDE, 138, 175);

        assertEquals(List.of(KeyEvent.KEYCODE_GUIDE), learned);
    }

    @Test public void learnsSeparateMediaSkipFromTheSameRemote() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var learned = new ArrayList<Integer>();

        press(service, KeyEvent.KEYCODE_DPAD_CENTER, CONFIRM_SCAN, 100);
        RemoteButtonLearning.start(learned::add);
        SystemClock.sleep(150);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, SKIP_SCAN, 1);

        assertEquals(List.of(KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD), learned);
    }

    @Test public void learnsMediaSkipFromAnotherDeviceRightAfterConfirm() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var learned = new ArrayList<Integer>();

        press(service, KeyEvent.KEYCODE_DPAD_CENTER, CONFIRM_SCAN, 100);
        RemoteButtonLearning.start(learned::add);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, SKIP_SCAN, REMOTE + 1, 1);

        assertEquals(List.of(KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD), learned);
    }

    @Test public void learnsMediaSkipWithDifferentHardwareCodeRightAfterConfirm() {
        var service = Robolectric.buildService(LauncherAccessibilityService.class).get();
        var learned = new ArrayList<Integer>();

        press(service, KeyEvent.KEYCODE_DPAD_CENTER, CONFIRM_SCAN, 100);
        RemoteButtonLearning.start(learned::add);
        press(service, KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD, 163, 1);

        assertEquals(List.of(KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD), learned);
    }

    private static void press(LauncherAccessibilityService service, int code, int scan, long heldMs) {
        press(service, code, scan, REMOTE, heldMs);
    }

    private static void press(LauncherAccessibilityService service, int code, int scan, int device, long heldMs) {
        long downTime = SystemClock.uptimeMillis();
        service.onKeyEvent(new KeyEvent(downTime, downTime, KeyEvent.ACTION_DOWN, code, 0, 0,
            device, scan, 0, REMOTE_SOURCE));
        SystemClock.sleep(heldMs);
        service.onKeyEvent(new KeyEvent(downTime, SystemClock.uptimeMillis(), KeyEvent.ACTION_UP,
            code, 0, 0, device, scan, 0, REMOTE_SOURCE));
    }
}
