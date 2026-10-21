package com.leanbitlab.ltvL;

import android.os.SystemClock;
import android.view.KeyEvent;
import java.util.function.Consumer;

/** One explicit learning request; consume its entire press without launching OEM actions. */
final class RemoteButtonLearning {
    private static Consumer<Integer> listener;
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
    static void reset() { cancel(); code = 0; }
    static boolean event(KeyEvent event) {
        if (code != 0 && code == event.getKeyCode() && device == event.getDeviceId() && downTime == event.getDownTime()) {
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
                && RemoteMappingConfiguration.assignable(event.getKeyCode()) && code == 0) {
            code = event.getKeyCode(); device = event.getDeviceId(); downTime = event.getDownTime(); return true;
        }
        return false;
    }
}
