package com.leanbitlab.ltvL;

import android.accessibilityservice.AccessibilityServiceInfo;
import android.os.Handler;
import android.os.SystemClock;
import android.view.accessibility.AccessibilityEvent;
import java.util.function.Consumer;
import java.util.function.Supplier;

/** Native volume owns DOWN/repeat/UP while filtering is temporarily suspended. */
final class VolumeKeyFilterPause implements AutoCloseable {
    static final long PAUSE_MS = 5000, MAX_PAUSE_MS = 60000;
    private final Handler handler;
    private final Supplier<AccessibilityServiceInfo> read;
    private final Consumer<AccessibilityServiceInfo> write;
    private final Runnable cancelHeldActions;
    private final Supplier<Boolean> visible;
    private final Runnable resume = this::resume;
    private boolean paused, closed;
    private String mode = "off";
    private long duration = PAUSE_MS, deadline;

    VolumeKeyFilterPause(Handler handler, Supplier<AccessibilityServiceInfo> read,
            Consumer<AccessibilityServiceInfo> write, Runnable cancelHeldActions) {
        this(handler, read, write, cancelHeldActions, () -> null);
    }
    VolumeKeyFilterPause(Handler handler, Supplier<AccessibilityServiceInfo> read,
            Consumer<AccessibilityServiceInfo> write, Runnable cancelHeldActions, Supplier<Boolean> visible) {
        this.handler = handler; this.read = read; this.write = write;
        this.cancelHeldActions = cancelHeldActions; this.visible = visible;
    }
    void configure(RemoteMappingConfiguration config) {
        String next = config.enabled ? config.volumeMode : "off";
        long nextDuration = config.volumePauseSeconds * 1000L;
        if (!next.equals(mode) || duration != nextDuration) {
            handler.removeCallbacks(resume); restore();
            mode = next; duration = nextDuration;
        }
    }
    boolean paused() { return paused; }
    static boolean panel(String pkg, String name, String resourceId, boolean systemPackage) {
        if (!systemPackage) return false;
        String type = name == null ? "" : name.toLowerCase(java.util.Locale.ROOT);
        String id = resourceId == null ? "" : resourceId.toLowerCase(java.util.Locale.ROOT);
        return type.contains("volume") && (type.contains("dialog") || type.contains("panel") || type.contains("overlay"))
            || id.matches(".*:id/(volume_dialog|volume_dialog_root|volume_panel|volume_panel_root)");
    }
    void event(AccessibilityEvent event) {
        event(event, event != null && panel(String.valueOf(event.getPackageName()),
            String.valueOf(event.getClassName()), null, "com.android.systemui".contentEquals(
                event.getPackageName() == null ? "" : event.getPackageName())));
    }
    void event(AccessibilityEvent event, boolean recognized) {
        if (closed || !(mode.equals("auto") || mode.equals("timed")) || event == null
                || event.getEventType() != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || !recognized) return;
        if (!paused) {
            AccessibilityServiceInfo info = read.get();
            if (info == null || (info.flags & AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS) == 0) return;
            cancelHeldActions.run();
            info.flags &= ~AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS;
            write.accept(info); paused = true;
            deadline = SystemClock.uptimeMillis() + MAX_PAUSE_MS;
        }
        schedule(duration);
    }
    private void schedule(long delay) {
        handler.removeCallbacks(resume);
        handler.postDelayed(resume, Math.max(0, Math.min(delay, deadline - SystemClock.uptimeMillis())));
    }
    private void resume() {
        boolean extend = false;
        if (!closed && mode.equals("auto") && SystemClock.uptimeMillis() < deadline) {
            try { extend = Boolean.TRUE.equals(visible.get()); } catch (RuntimeException ignored) { }
        }
        if (extend) schedule(1000); else restore();
    }
    private void restore() {
        if (!paused) return;
        AccessibilityServiceInfo info = read.get();
        if (info != null) {
            info.flags |= AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS;
            write.accept(info);
        }
        paused = false;
    }
    @Override public void close() {
        closed = true; handler.removeCallbacks(resume); restore();
    }
}
