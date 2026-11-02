package com.leanbitlab.ltvL;

import android.os.Handler;
import android.os.SystemClock;
import android.view.KeyEvent;
import java.util.function.IntConsumer;

/** Optional full-pair volume handler for firmware that delivers physical keys. */
final class VolumeKeyRepeater implements AutoCloseable {
    static final long DELAY_MS = 500, INTERVAL_MS = 60, MAX_HOLD_MS = 30000;
    private final Handler handler;
    private final IntConsumer adjust;
    private boolean enabled, held;
    private int code, device;
    private long downTime, deadline;
    private final Runnable step = this::step;
    VolumeKeyRepeater(Handler handler, IntConsumer adjust) { this.handler = handler; this.adjust = adjust; }
    void configure(RemoteMappingConfiguration config) {
        stop(); enabled = config.enabled && config.volumeMode.equals("repeat");
    }
    boolean event(KeyEvent event) {
        if (!enabled || (event.getKeyCode() != KeyEvent.KEYCODE_VOLUME_UP
                && event.getKeyCode() != KeyEvent.KEYCODE_VOLUME_DOWN)) return false;
        if (event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            if (held && code == event.getKeyCode() && device == event.getDeviceId() && downTime == event.getDownTime()) return true;
            stop();
            if (event.isCanceled()) return true;
            code = event.getKeyCode(); device = event.getDeviceId(); downTime = event.getDownTime();
            held = true; deadline = SystemClock.uptimeMillis() + MAX_HOLD_MS;
            change(); if (held) handler.postDelayed(step, DELAY_MS);
        } else if (event.getAction() == KeyEvent.ACTION_UP && code == event.getKeyCode()
                && device == event.getDeviceId() && downTime == event.getDownTime()) stop();
        return true;
    }
    private void change() {
        try { adjust.accept(code == KeyEvent.KEYCODE_VOLUME_UP ? 1 : -1); }
        catch (RuntimeException unavailable) { stop(); }
    }
    private void step() {
        if (!held || SystemClock.uptimeMillis() >= deadline) { stop(); return; }
        change(); if (held) handler.postDelayed(step, INTERVAL_MS);
    }
    void stop() { held = false; handler.removeCallbacks(step); }
    @Override public void close() { stop(); enabled = false; }
}
