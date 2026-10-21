package com.leanbitlab.ltvL;

import android.os.Handler;
import android.content.Context;
import android.os.Looper;
import android.os.SystemClock;
import android.view.KeyEvent;

import java.util.LinkedHashMap;
import java.util.Map;
import java.util.function.BooleanSupplier;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.io.File;
import java.util.List;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/** Explicit, bounded diagnostics. Only the latest completed session is saved as text. */
final class RemoteButtonsBridge implements AutoCloseable {
    private static final RemoteButtonCapture capture = new RemoteButtonCapture();
    static boolean capturing() { return capture.active(SystemClock.elapsedRealtime()); }
    private static RemoteButtonsBridge observer;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private final BooleanSupplier permission;
    private final MethodChannel methods;
    private final EventChannel events;
    private final Runnable timeout = this::stop;
    private final ExecutorService reportWriter = Executors.newSingleThreadExecutor();
    private final Context context;
    private boolean sessionRequested;
    private String sessionStarted = "";
    private EventChannel.EventSink sink;

    RemoteButtonsBridge(Context context, BinaryMessenger messenger, BooleanSupplier permission) {
        this.context = context.getApplicationContext();
        this.permission = permission;
        methods = new MethodChannel(messenger, "cutelauncher/remote_buttons");
        events = new EventChannel(messenger, "cutelauncher/remote_button_events");
        methods.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "info": result.success(snapshot()); break;
                case "start":
                    if (!permission.getAsBoolean() || !LauncherAccessibilityService.connected()) {
                        result.error("permission_denied", "Accessibility service is not connected", null);
                        break;
                    }
                    capture.start(SystemClock.elapsedRealtime());
                    sessionRequested = true;
                    sessionStarted = java.time.Instant.now().toString();
                    handler.removeCallbacks(timeout);
                    handler.postDelayed(timeout, RemoteButtonCapture.DURATION_MS);
                    publish();
                    result.success(snapshot());
                    break;
                case "stop":
                    stop(); result.success(snapshot()); break;
                default: result.notImplemented();
            }
        });
        events.setStreamHandler(new EventChannel.StreamHandler() {
            @Override public void onListen(Object arguments, EventChannel.EventSink events) {
                observer = RemoteButtonsBridge.this;
                sink = events;
                publish();
            }
            @Override public void onCancel(Object arguments) {
                sink = null;
                if (observer == RemoteButtonsBridge.this) observer = null;
            }
        });
    }

    private Map<String, Object> snapshot() {
        long now = SystemClock.elapsedRealtime();
        return Map.of("permission", permission.getAsBoolean(),
            "connected", LauncherAccessibilityService.connected(),
            "active", capture.active(now), "remainingMs", capture.remaining(now),
            "events", capture.snapshot(), "dropped", capture.dropped(),
            "reportPath", context.getExternalFilesDir(null) == null ? "" :
                new File(context.getExternalFilesDir(null), "remote-buttons-last.txt").getAbsolutePath());
    }

    private void publish() { if (sink != null) sink.success(snapshot()); }
    private void stop() {
        handler.removeCallbacks(timeout);
        capture.stop();
        if (sessionRequested) {
            sessionRequested = false;
            List<Map<String, Object>> history = capture.snapshot();
            int dropped = capture.dropped();
            String started = sessionStarted;
            reportWriter.execute(() -> saveReport(history, dropped, started));
        }
        publish();
    }

    private void saveReport(List<Map<String, Object>> history, int dropped, String started) {
        try {
            File directory = context.getExternalFilesDir(null);
            if (directory == null) return;
            RemoteButtonReport.write(directory, history, dropped, started);
        } catch (java.io.IOException | RuntimeException ignored) {
            // Diagnostic key data and file paths must not leak into general logs.
        }
    }

    static void observe(KeyEvent event) {
        if (!capture.active(SystemClock.elapsedRealtime())) return;
        Map<String, Object> value = new LinkedHashMap<>();
        value.put("keyCode", event.getKeyCode());
        value.put("keyName", KeyEvent.keyCodeToString(event.getKeyCode()));
        value.put("scanCode", event.getScanCode());
        value.put("deviceId", event.getDeviceId());
        value.put("source", event.getSource());
        value.put("action", event.getAction());
        value.put("repeat", event.getRepeatCount());
        value.put("elapsedMs", Math.max(0L, event.getEventTime() - event.getDownTime()));
        value.put("cancelled", event.isCanceled());
        if (capture.record(SystemClock.elapsedRealtime(), value) && observer != null) observer.publish();
    }

    static void serviceChanged() {
        if (!LauncherAccessibilityService.connected()) capture.stop();
        if (observer != null) {
            if (!LauncherAccessibilityService.connected()) observer.stop();
            else observer.publish();
        }
    }

    @Override public void close() {
        stop();
        if (observer == this) observer = null;
        sink = null;
        methods.setMethodCallHandler(null);
        events.setStreamHandler(null);
        reportWriter.shutdown();
    }
}
