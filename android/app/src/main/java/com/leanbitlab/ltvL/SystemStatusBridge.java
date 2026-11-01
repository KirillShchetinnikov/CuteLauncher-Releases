package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

final class SystemStatusBridge implements AutoCloseable {
    private final Context context;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final SystemStatusController controller = new SystemStatusController();
    private final AtomicBoolean sampling = new AtomicBoolean();
    private boolean watching, closed;
    private final BroadcastReceiver screen = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!closed && watching) channel.invokeMethod("changed", Intent.ACTION_SCREEN_ON.equals(intent.getAction()));
        }
    };

    SystemStatusBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        channel = new MethodChannel(messenger, "cutelauncher/system_status");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("watch")) {
                watch(Boolean.TRUE.equals(call.arguments));
                result.success(null);
            } else if (call.method.equals("snapshot")) {
                if (!sampling.compareAndSet(false, true)) {
                    result.error("busy", "System status refresh in progress", null); return;
                }
                worker.execute(() -> {
                    try {
                        if (Boolean.TRUE.equals(call.arguments)) controller.resetCpu();
                        var state = controller.snapshot(context);
                        main.post(() -> { if (!closed) result.success(state); });
                    } catch (RuntimeException unavailable) {
                        main.post(() -> { if (!closed) result.error("unavailable", "System status unavailable", null); });
                    } finally { sampling.set(false); }
                });
            } else result.notImplemented();
        });
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
