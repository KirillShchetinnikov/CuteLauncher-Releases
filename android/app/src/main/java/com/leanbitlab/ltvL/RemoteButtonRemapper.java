package com.leanbitlab.ltvL;

import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import android.widget.Toast;
import java.util.concurrent.*;

/** Service-owned executor. No action depends on the Flutter engine being alive. */
final class RemoteButtonRemapper implements AutoCloseable {
    private static RemoteButtonRemapper current;
    static boolean editing;
    static volatile String status = "idle";
    private final LauncherAccessibilityService service;
    private final BlackScreenWindow blackScreen;
    private final TvPowerConfirmation powerConfirmation;
    private Toast errorToast;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService storage = Executors.newSingleThreadExecutor();
    private final ThreadPoolExecutor power = new ThreadPoolExecutor(1, 1, 30, TimeUnit.SECONDS,
        new SynchronousQueue<>(), new ThreadPoolExecutor.AbortPolicy());
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
        blackScreen = new BlackScreenWindow(service, service::blackScreenVisibilityChanged);
        powerConfirmation = new TvPowerConfirmation(service);
        network.allowCoreThreadTimeOut(true);
        power.allowCoreThreadTimeOut(true);
        int expected = ++generation;
        storage.execute(() -> {
            try {
                RemoteMappingConfiguration loaded = new RemoteMappingStore(service).load();
                main.post(() -> { if (!closed && generation == expected) { configuration = loaded; LauncherAccessibilityService.volumeConfigured(loaded); } });
            } catch (Exception ignored) { if (!closed) status = "storage_error"; }
        });
        storage.shutdown();
    }
    static void updated(RemoteMappingConfiguration configuration) {
        if (current != null) {
            current.generation++;
            current.configuration = configuration;
            current.cancelPowerConfirmation();
            if (!configuration.enabled || configuration.bindings.values().stream()
                    .noneMatch(binding -> binding.enabled() && binding.action().equals("black_overlay"))) {
                current.blackScreen.close();
            }
            LauncherAccessibilityService.volumeConfigured(configuration);
        }
        status = "idle";
    }
    boolean dismissBlackScreenOnBack(KeyEvent event) { return blackScreen.back(event); }
    boolean confirmingPower() { return powerConfirmation.isOpen(); }
    void cancelPowerConfirmation() { powerConfirmation.close(); }
    boolean blackScreenVisible() { return blackScreen.isVisible(); }
    private RemoteMappingConfiguration.Binding shortBinding(int code, boolean suspended) {
        if (suspended) return null;
        return configuration.pressBinding(code);
    }
    private boolean assignmentsPaused() {
        return confirmingPower() || editing || RemoteButtonsBridge.capturing() || RemoteButtonLearning.active();
    }
    boolean event(KeyEvent event) {
        boolean suspended = assignmentsPaused();
        RemoteMappingConfiguration.Binding binding = shortBinding(event.getKeyCode(), suspended);
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
                boolean paused = closed || assignmentsPaused();
                var action = policy.hold(key.device, key.code, downTime, android.os.SystemClock.uptimeMillis(),
                    shortBinding(key.code, paused), paused ? null : configuration.binding(key.code, "hold"));
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
            String result = dispatch(binding);
            if (result != null) complete(binding, result);
        } catch (RejectedExecutionException busy) {
            complete(binding, "busy");
        } catch (SecurityException denied) {
            finish("unavailable", R.string.remap_error_permission);
        } catch (RuntimeException unavailable) {
            complete(binding, "unavailable");
        }
    }

    /** A null result means the action reports completion through its callback. */
    private String dispatch(RemoteMappingConfiguration.Binding binding) {
        return switch (binding.action()) {
            case "ignore" -> "success";
            case "recents" -> {
                service.dismissPanel();
                yield availability(RecentAppsBridge.open(service));
            }
            case "panel" -> availability(service.togglePanel());
            case "home" -> {
                service.dismissPanel();
                Intent home = new Intent(service, MainActivity.class);
                home.putExtra("return_home", true);
                home.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
                service.startActivity(home);
                yield "success";
            }
            case "back" -> availability(service.performGlobalAction(
                android.accessibilityservice.AccessibilityService.GLOBAL_ACTION_BACK));
            case "black_overlay" -> {
                service.hideVolumeOverlay();
                blackScreen.toggle();
                yield "success";
            }
            case "tcl_screen_off" -> {
                if (!TclScreenOff.available(service)) yield "unavailable";
                try {
                    yield availability(service.startService(TclScreenOff.intent()) != null);
                } catch (IllegalStateException backgroundStartDenied) {
                    status = "busy";
                    TvPowerBridge.requestTclScreenOff(service, power, result -> complete(binding, result));
                    yield null;
                }
            }
            case "app" -> {
                service.dismissPanel();
                Intent app = service.getPackageManager().getLeanbackLaunchIntentForPackage(binding.target());
                if (app == null) app = service.getPackageManager().getLaunchIntentForPackage(binding.target());
                if (app == null) yield "unavailable";
                app.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                service.startActivity(app);
                yield "success";
            }
            case "hdmi" -> {
                service.dismissPanel();
                yield availability(TvInputLaunch.openHdmi(service, binding.target()));
            }
            case "live_tv", "display_settings", "wifi_settings", "bluetooth_settings" -> {
                service.dismissPanel();
                yield availability(RemoteTvActions.open(service, binding.action()));
            }
            case "mute" -> availability(RemoteTvActions.toggleMute(service));
            case "sleep", "reboot" -> {
                boolean reboot = binding.action().equals("reboot");
                if (powerConfirmation.show(reboot, () -> {
                    if (closed || assignmentsPaused()
                            || !binding.equals(configuration.binding(binding.keyCode(), binding.trigger()))) return;
                    requestPower(binding, reboot);
                })) cancelPendingActions();
                yield null;
            }
            case "sleep_immediate", "reboot_immediate" -> {
                requestPower(binding, binding.action().equals("reboot_immediate"));
                yield null;
            }
            case "webhook" -> {
                status = "busy";
                network.execute(() -> webhook(binding));
                yield null;
            }
            default -> "unavailable";
        };
    }

    private void requestPower(RemoteMappingConfiguration.Binding binding, boolean reboot) {
        status = "busy";
        TvPowerBridge.request(service, reboot, power, result -> complete(binding, result));
    }

    private static String availability(boolean available) {
        return available ? "success" : "unavailable";
    }

    private void complete(RemoteMappingConfiguration.Binding binding, String result) {
        int message = switch (result) {
            case "success" -> 0;
            case "busy" -> R.string.remap_error_busy;
            default -> switch (binding.action()) {
                case "app" -> R.string.remap_error_app;
                case "hdmi" -> R.string.remap_error_hdmi;
                case "sleep", "sleep_immediate", "reboot", "reboot_immediate" -> R.string.remap_error_power;
                default -> R.string.remap_error_unavailable;
            };
        };
        finish(result, message);
    }

    /** Called on the service main thread, including asynchronous results. */
    private void finish(String result, int message, Object... arguments) {
        if (closed) return;
        status = result;
        if (message == 0) return;
        if (errorToast != null) errorToast.cancel();
        errorToast = Toast.makeText(service, service.getString(message, arguments), Toast.LENGTH_LONG);
        errorToast.show();
    }

    private void webhook(RemoteMappingConfiguration.Binding binding) {
        if (closed || !binding.equals(configuration.binding(binding.keyCode(), binding.trigger()))) return;
        try {
            int code = RemoteWebhookClient.post(binding.target(), 5000);
            main.post(() -> {
                if (code >= 200 && code < 300) finish("success", 0);
                else finish("network_error", R.string.remap_error_webhook_http, code);
            });
        } catch (java.net.SocketTimeoutException timeout) {
            main.post(() -> finish("network_error", R.string.remap_error_webhook_timeout));
        } catch (Exception ignored) {
            main.post(() -> finish("network_error", R.string.remap_error_webhook));
        }
    }
    void interrupt() {
        blackScreen.close();
        cancelPowerConfirmation();
        cancelPendingActions();
    }
    private void cancelPendingActions() {
        policy.cancelActions(); holdTimers.values().forEach(main::removeCallbacks); holdTimers.clear();
    }
    void filterPaused() {
        interrupt();
        policy.clear(); // UP may pass outside the service while filtering is disabled.
    }
    @Override public void close() {
        if (errorToast != null) errorToast.cancel();
        blackScreen.close();
        cancelPowerConfirmation();
        // Allow an accepted bounded power request to finish and release the shared busy guard.
        power.shutdown();
        closed = true; policy.clear(); holdTimers.values().forEach(main::removeCallbacks); holdTimers.clear(); storage.shutdownNow(); network.shutdownNow();
        if (current == this) current = null;
    }
}
