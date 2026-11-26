package com.leanbitlab.ltvL;

import android.os.SystemClock;
import android.view.KeyEvent;
import java.util.function.Consumer;

/** One explicit learning request; consume its entire press without launching OEM actions. */
final class RemoteButtonLearning {
    private static final int CONFIRM_SCAN_CODE = 353;
    private static final int MEDIA_SKIP_SCAN_CODE = 240;
    private static final long COMPANION_WINDOW_MS = 20;
    private record ConfirmRelease(long observedAt, int deviceId, int source) {}

    private static Consumer<Integer> listener;
    private static ConfirmRelease lastConfirmRelease;
    private static long deadline, downTime;
    private static int code, device;
    static boolean active() { return listener != null && SystemClock.elapsedRealtime() < deadline; }
    static void start(Consumer<Integer> result) {
        if (SystemClock.elapsedRealtime() >= deadline) code = 0;
        cancel(); listener = result; deadline = SystemClock.elapsedRealtime() + 30_000;
    }
    static void cancel() {
        Consumer<Integer> callback = listener; listener = null;
        if (callback != null) callback.accept(null);
    }
    static void reset() { cancel(); code = 0; lastConfirmRelease = null; }
    static boolean event(KeyEvent event) {
        int keyCode = event.getKeyCode();
        if (keyCode == KeyEvent.KEYCODE_DPAD_CENTER && event.getAction() == KeyEvent.ACTION_UP
                && event.getScanCode() == CONFIRM_SCAN_CODE) {
            lastConfirmRelease = new ConfirmRelease(SystemClock.elapsedRealtime(), event.getDeviceId(), event.getSource());
        }
        if (code != 0 && code == keyCode && device == event.getDeviceId() && downTime == event.getDownTime()) {
            if (event.getAction() == KeyEvent.ACTION_UP) {
                int learned = code; code = 0;
                Consumer<Integer> callback = active() && !event.isCanceled() ? listener : null;
                Consumer<Integer> cancelled = listener; listener = null;
                if (callback != null) callback.accept(learned);
                else if (cancelled != null) cancelled.accept(null);
            }
            return true;
        }
        if (active() && event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0
                && code == 0 && (RemoteMappingConfiguration.assignable(keyCode) || keyCode == KeyEvent.KEYCODE_HOME)
                && !isConfirmCompanion(event)) {
            code = keyCode; device = event.getDeviceId(); downTime = event.getDownTime(); return true;
        }
        return false;
    }

    private static boolean isConfirmCompanion(KeyEvent event) {
        // The DEXP remote emits this extra key as soon as OK is released, including when OK starts learning.
        return event.getKeyCode() == KeyEvent.KEYCODE_MEDIA_SKIP_FORWARD && event.getScanCode() == MEDIA_SKIP_SCAN_CODE
            && lastConfirmRelease != null && lastConfirmRelease.deviceId() == event.getDeviceId()
            && lastConfirmRelease.source() == event.getSource()
            && SystemClock.elapsedRealtime() - lastConfirmRelease.observedAt() <= COMPANION_WINDOW_MS;
    }
}
