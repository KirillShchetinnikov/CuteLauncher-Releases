package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.TrafficStats;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

/** Lightweight device counters; no NetworkStats history, ADB or usage permission. */
final class NetworkSpeedBridge implements AutoCloseable {
    private final Context context;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final AtomicBoolean sampling = new AtomicBoolean();
    private boolean watching, closed;
    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!closed && watching) channel.invokeMethod("changed", Intent.ACTION_SCREEN_ON.equals(intent.getAction()));
        }
    };

    NetworkSpeedBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        channel = new MethodChannel(messenger, "cutelauncher/network_speed");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("watch")) {
                watch(Boolean.TRUE.equals(call.arguments));
                result.success(null);
            } else if (call.method.equals("snapshot")) {
                if (!sampling.compareAndSet(false, true)) {
                    result.error("busy", "Network sampling in progress", null); return;
                }
                worker.execute(() -> {
                    try {
                        var state = snapshot(context);
                        main.post(() -> { if (!closed) result.success(state); });
                    } catch (RuntimeException unavailable) {
                        main.post(() -> { if (!closed) result.error("unavailable", "Network counters unavailable", null); });
                    } finally { sampling.set(false); }
                });
            } else result.notImplemented();
        });
    }

    static Map<String, Object> snapshot(Context context) {
        var power = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
        boolean screenOn = power != null && power.isInteractive();
        Map<String, Object> state = new HashMap<>();
        state.put("screenOn", screenOn);
        if (screenOn) {
            state.put("rxBytes", TrafficStats.getTotalRxBytes());
            state.put("txBytes", TrafficStats.getTotalTxBytes());
            state.put("elapsedMs", SystemClock.elapsedRealtime());
        }
        return state;
    }

    private void watch(boolean enabled) {
        if (closed || watching == enabled) return;
        if (enabled) {
            IntentFilter filter = new IntentFilter(Intent.ACTION_SCREEN_ON);
            filter.addAction(Intent.ACTION_SCREEN_OFF);
            if (Build.VERSION.SDK_INT >= 33) context.registerReceiver(screen, filter, Context.RECEIVER_NOT_EXPORTED);
            else context.registerReceiver(screen, filter);
            watching = true;
        } else {
            watching = false;
            context.unregisterReceiver(screen);
        }
    }

    @Override public void close() {
        watch(false); closed = true;
        channel.setMethodCallHandler(null);
        main.removeCallbacksAndMessages(null);
    }
}
