package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Resources;
import android.media.AudioDeviceCallback;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.media.MediaRoute2Info;
import android.media.MediaRouter2;
import android.media.RouteDiscoveryPreference;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.List;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

/** Engine-scoped listeners only while the Dart panel is visible. No volume control. */
final class AudioStatusBridge implements AutoCloseable {
    private final Context context;
    private final MethodChannel channel;
    private final AudioManager audio;
    private final Handler main = new Handler(Looper.getMainLooper());
    private boolean watching, deviceListening, closed;
    private LegacyHdmiRoute legacyHdmiRoute;
    private final AtomicBoolean sampling = new AtomicBoolean();
    private final AudioDeviceCallback devices = new AudioDeviceCallback() {
        @Override public void onAudioDevicesAdded(AudioDeviceInfo[] added) { changed(null); }
        @Override public void onAudioDevicesRemoved(AudioDeviceInfo[] removed) { changed(null); }
    };
    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            changed(Intent.ACTION_SCREEN_ON.equals(intent.getAction()));
        }
    };
    AudioStatusBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        audio = context.getSystemService(AudioManager.class);
        channel = new MethodChannel(messenger, "cutelauncher/audio_status");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("watch")) {
                watch(Boolean.TRUE.equals(call.arguments)); result.success(null);
            } else if (call.method.equals("snapshot")) {
                // A timed-out Dart request must not start overlapping Binder reads.
                if (!sampling.compareAndSet(false, true)) {
                    result.error("busy", "Audio status refresh in progress", null); return;
                }
                var controller = new AudioStatusController(context);
                Map<String, Object> routeDiagnostics = Boolean.TRUE.equals(call.arguments)
                    ? new HashMap<>() : null;
                var legacyRoute = Build.VERSION.SDK_INT < 33 ? controller.legacyOutput(routeDiagnostics) : null;
                boolean legacyBluetooth = "bluetooth".equals(legacyRoute);
                if (routeDiagnostics != null) {
                    routeDiagnostics.put("api", Build.VERSION.SDK_INT);
                    routeDiagnostics.put("legacyBluetooth", legacyBluetooth);
                    routeDiagnostics.put("routerAvailable", legacyHdmiRoute != null);
                }
                boolean router2HdmiSelected = Build.VERSION.SDK_INT >= 30 && Build.VERSION.SDK_INT < 33
                    && (!legacyBluetooth || routeDiagnostics != null)
                    && legacyHdmiRoute != null && legacyHdmiRoute.isSelected(routeDiagnostics);
                worker.execute(() -> {
                    try {
                        var state = controller.snapshot(legacyRoute, router2HdmiSelected, routeDiagnostics);
                        main.post(() -> { if (!closed) result.success(state); });
                    } catch (RuntimeException unavailable) {
                        main.post(() -> { if (!closed) result.error("unavailable", "Audio status unavailable", DiagnosticErrorDetails.from(unavailable)); });
                    } finally { sampling.set(false); }
                });
            } else result.notImplemented();
        });
    }
    private void changed(Boolean screenOn) {
        if (!closed && watching) channel.invokeMethod("changed", screenOn);
    }
    private void watch(boolean enabled) {
        if (closed || watching == enabled) return;
        if (enabled) {
            var filter = new IntentFilter(Intent.ACTION_SCREEN_ON);
            filter.addAction(Intent.ACTION_SCREEN_OFF);
            if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(screen, filter, Context.RECEIVER_NOT_EXPORTED);
            else context.registerReceiver(screen, filter);
            watching = true;
            if (Build.VERSION.SDK_INT >= 30 && Build.VERSION.SDK_INT < 33) {
                try { legacyHdmiRoute = new LegacyHdmiRoute(context); }
                catch (RuntimeException | LinkageError unavailable) { /* Some firmware does not expose system routes. */ }
            }
            try {
                if (audio != null) { audio.registerAudioDeviceCallback(devices, main); deviceListening = true; }
            } catch (RuntimeException unavailable) { /* Polling remains available. */ }
        } else {
            watching = false;
            if (Build.VERSION.SDK_INT >= 30 && legacyHdmiRoute != null) {
                legacyHdmiRoute.close();
                legacyHdmiRoute = null;
            }
            context.unregisterReceiver(screen);
            if (deviceListening) { audio.unregisterAudioDeviceCallback(devices); deviceListening = false; }
        }
    }
    @Override public void close() {
        watch(false); closed = true;
        channel.setMethodCallHandler(null); main.removeCallbacksAndMessages(null);
    }

    @RequiresApi(30)
    static final class LegacyHdmiRoute implements AutoCloseable {
        private final MediaRouter2 router;
        private final Resources resources;
        private final MediaRouter2.RouteCallback callback = new MediaRouter2.RouteCallback() {};

        LegacyHdmiRoute(Context context) {
            router = MediaRouter2.getInstance(context);
            resources = context.getResources();
            // Keep the local route current without requesting active discovery.
            router.registerRouteCallback(context.getMainExecutor(), callback,
                new RouteDiscoveryPreference.Builder(List.of(), false).build());
        }

        boolean isSelected(@Nullable Map<String, Object> diagnostics) {
            try {
                var routes = router.getSystemController().getSelectedRoutes();
                if (diagnostics != null) diagnostics.put("selectedRouteCount", routes.size());
                if (routes.size() != 1) return false;
                var route = routes.get(0);
                if (diagnostics != null) describeRoute(route, diagnostics);
                return isHdmiRoute(route, resources);
            } catch (RuntimeException | LinkageError unavailable) {
                if (diagnostics != null) diagnostics.put("routeReadFailed", true);
                return false;
            }
        }

        private void describeRoute(MediaRoute2Info route, Map<String, Object> diagnostics) {
            try {
                var name = route.getName().toString().toLowerCase(Locale.ROOT);
                diagnostics.put("routeNameMentionsHdmi", name.contains("hdmi"));
                diagnostics.put("routeNameMentionsArc", name.matches(".*\\b(?:e?arc)\\b.*"));
                diagnostics.put("frameworkHdmiLabelAvailable", AudioStatusController.hdmiLabel(resources) != 0);
                diagnostics.put("selectedRouteType", route.getType());
            } catch (LinkageError unavailable) {
                diagnostics.put("routeTypeUnavailable", true);
            } catch (RuntimeException unavailable) {
                diagnostics.put("routeReadFailed", true);
            }
        }

        static boolean isHdmiRoute(MediaRoute2Info route, Resources resources) {
            if (Build.VERSION.SDK_INT >= 31) {
                try { return route.getType() == MediaRoute2Info.TYPE_HDMI; }
                catch (NoSuchMethodError unavailable) { /* Some TV frameworks omit the method. */ }
            }
            // Android 11's system provider uses the framework's localized HDMI label.
            return AudioStatusController.matchesHdmiLabel(route.getName(), resources);
        }

        @Override public void close() {
            try { router.unregisterRouteCallback(callback); }
            catch (RuntimeException unavailable) { /* The platform router may already be unavailable. */ }
        }
    }
}
