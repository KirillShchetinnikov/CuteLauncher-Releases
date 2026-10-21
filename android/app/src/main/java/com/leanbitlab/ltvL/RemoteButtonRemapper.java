package com.leanbitlab.ltvL;

import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import java.util.concurrent.*;

/** Service-owned executor. No action depends on the Flutter engine being alive. */
final class RemoteButtonRemapper implements AutoCloseable {
    private static RemoteButtonRemapper current;
    static boolean editing;
    static volatile String status = "idle";
    private final LauncherAccessibilityService service;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService storage = Executors.newSingleThreadExecutor();
    private final ThreadPoolExecutor network = new ThreadPoolExecutor(1, 1, 30, TimeUnit.SECONDS,
        new ArrayBlockingQueue<>(2), new ThreadPoolExecutor.AbortPolicy());
    private final RemoteMappingPolicy policy = new RemoteMappingPolicy();
    private volatile RemoteMappingConfiguration configuration = RemoteMappingConfiguration.empty();
    private volatile boolean closed;
    private int generation;
    private record HeldKey(int device, int code) {}
    private final java.util.Map<HeldKey, Runnable> holdTimers = new java.util.HashMap<>();

    RemoteButtonRemapper(LauncherAccessibilityService service) {
        this.service = service; current = this;
        network.allowCoreThreadTimeOut(true);
        int expected = ++generation;
        storage.execute(() -> {
            try {
                RemoteMappingConfiguration loaded = new RemoteMappingStore(service).load();
                main.post(() -> { if (!closed && generation == expected) configuration = loaded; });
            } catch (Exception ignored) { if (!closed) status = "storage_error"; }
        });
        storage.shutdown();
    }
    static void updated(RemoteMappingConfiguration configuration) {
        if (current != null) { current.generation++; current.configuration = configuration; }
        status = "idle";
    }
    boolean event(KeyEvent event) {
        boolean suspended = editing || RemoteButtonsBridge.capturing() || RemoteButtonLearning.active();
        RemoteMappingConfiguration.Binding binding = suspended ? null : configuration.binding(event.getKeyCode());
        RemoteMappingConfiguration.Binding hold = suspended ? null : configuration.binding(event.getKeyCode(), "hold");
        RemoteMappingPolicy.Decision decision = policy.event(event.getDeviceId(), event.getKeyCode(),
            event.getAction(), event.getRepeatCount(), event.getDownTime(), event.getEventTime(), event.isCanceled(), binding, hold);
        HeldKey key = new HeldKey(event.getDeviceId(), event.getKeyCode());
        if (event.getAction() == KeyEvent.ACTION_UP || event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            Runnable old = holdTimers.remove(key); if (old != null) main.removeCallbacks(old);
        }
        if (decision.consume() && hold != null && event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            long downTime = event.getDownTime();
            Runnable timer = () -> {
                holdTimers.remove(key);
                boolean paused = closed || editing || RemoteButtonsBridge.capturing() || RemoteButtonLearning.active();
                var action = policy.hold(key.device, key.code, downTime, android.os.SystemClock.uptimeMillis(),
                    paused ? null : configuration.binding(key.code), paused ? null : configuration.binding(key.code, "hold"));
                if (action != null) execute(action);
            };
            holdTimers.put(key, timer);
            main.postAtTime(timer, downTime + RemoteMappingPolicy.HOLD_MS);
        }
        if (decision.fire() != null) execute(decision.fire());
        return decision.consume();
    }
    private void execute(RemoteMappingConfiguration.Binding binding) {
        try {
            switch (binding.action()) {
                case "panel":
                    status = service.togglePanel() ? "success" : "unavailable"; break;
                case "home":
                    service.dismissPanel();
                    Intent home = new Intent(service, MainActivity.class);
                    home.putExtra("return_home", true);
                    home.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                    service.startActivity(home); status = "success"; break;
                case "back":
                    status = service.performGlobalAction(android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK)
                        ? "success" : "unavailable"; break;
                case "app":
                    service.dismissPanel();
                    Intent app = service.getPackageManager().getLeanbackLaunchIntentForPackage(binding.target());
                    if (app == null) app = service.getPackageManager().getLaunchIntentForPackage(binding.target());
                    if (app == null) { status = "unavailable"; break; }
                    app.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    service.startActivity(app); status = "success"; break;
                case "webhook":
                    status = "busy";
                    network.execute(() -> webhook(binding)); break;
                default: status = "unavailable";
            }
        } catch (RejectedExecutionException busy) { status = "busy"; }
        catch (RuntimeException unavailable) { status = "unavailable"; }
    }
    private void webhook(RemoteMappingConfiguration.Binding binding) {
        if (closed || !binding.equals(configuration.binding(binding.keyCode(), binding.trigger()))) return;
        try {
            boolean success = RemoteWebhookClient.post(binding.target(), 5000);
            if (!closed) status = success ? "success" : "network_error";
        } catch (Exception ignored) { if (!closed) status = "network_error"; }
    }
    void interrupt() {
        policy.cancelActions(); holdTimers.values().forEach(main::removeCallbacks); holdTimers.clear();
    }
    @Override public void close() {
        closed = true; policy.clear(); holdTimers.values().forEach(main::removeCallbacks); holdTimers.clear(); storage.shutdownNow(); network.shutdownNow();
        if (current == this) current = null;
    }
}
