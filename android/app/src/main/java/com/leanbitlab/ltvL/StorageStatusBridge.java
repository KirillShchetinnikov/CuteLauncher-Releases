package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Handler;
import android.os.Looper;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

final class StorageStatusBridge implements AutoCloseable {
    private final Context context;
    private final MethodChannel channel;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final AtomicBoolean sampling = new AtomicBoolean();
    private boolean watching, closed;
    private boolean mediaWatching;
    private final BroadcastReceiver media = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!closed && watching) channel.invokeMethod("changed", null);
        }
    };
    private final BroadcastReceiver changes = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (!closed && watching) channel.invokeMethod("changed", Intent.ACTION_SCREEN_OFF.equals(intent.getAction()) ? false : null);
        }
    };
    StorageStatusBridge(Context context, BinaryMessenger messenger, ExecutorService worker) {
        this.context = context;
        channel = new MethodChannel(messenger, "cutelauncher/storage_status");
        channel.setMethodCallHandler((call, result) -> {
            if (call.method.equals("watch")) {
                watch(Boolean.TRUE.equals(call.arguments)); result.success(null);
            } else if (call.method.equals("snapshot")) {
                if (!sampling.compareAndSet(false, true)) { result.error("busy", "Storage refresh in progress", null); return; }
                worker.execute(() -> {
                    try {
                        var snapshot = new StorageStatusController(context).snapshot();
                        main.post(() -> { if (!closed) result.success(snapshot); });
                    } catch (RuntimeException error) {
                        main.post(() -> { if (!closed) result.error("unavailable", "Storage status unavailable", DiagnosticErrorDetails.from(error)); });
                    } finally { sampling.set(false); }
                });
            } else if (call.method.equals("openNas") || call.method.equals("openUsb")) {
                result.success(new StorageStatusController(context).open(call.method.equals("openNas")));
            } else result.notImplemented();
        });
    }
    private void watch(boolean enabled) {
        if (closed || watching == enabled) return;
        if (enabled) {
            var filter = new IntentFilter();
            filter.addAction(Intent.ACTION_SCREEN_ON); filter.addAction(Intent.ACTION_SCREEN_OFF);
            filter.addAction("aloys.intent.action.STORAGE_MOUNTED");
            filter.addAction("aloys.intent.action.STORAGE_BAD_REMOVAL");
            filter.addAction("android.hardware.usb.action.USB_DEVICE_ATTACHED");
            filter.addAction("android.hardware.usb.action.USB_DEVICE_DETACHED");
            // OEM broadcasts may come from a different process. They only request
            // a bounded fresh snapshot and cannot supply a path or launch anything.
            try {
                ContextCompat.registerReceiver(context, changes, filter, ContextCompat.RECEIVER_EXPORTED);
                watching = true;
                var mounted = new IntentFilter();
                mounted.addAction(Intent.ACTION_MEDIA_MOUNTED);
                mounted.addAction(Intent.ACTION_MEDIA_UNMOUNTED);
                mounted.addAction(Intent.ACTION_MEDIA_REMOVED);
                mounted.addAction(Intent.ACTION_MEDIA_BAD_REMOVAL);
                mounted.addAction(Intent.ACTION_MEDIA_EJECT);
                mounted.addDataScheme("file");
                try {
                    ContextCompat.registerReceiver(context, media, mounted, ContextCompat.RECEIVER_EXPORTED);
                    mediaWatching = true;
                } catch (RuntimeException unavailable) { /* Polling remains available. */ }
            } catch (RuntimeException unavailable) { /* Bounded polling remains available. */ }
        } else {
            watching = false;
            try { context.unregisterReceiver(changes); } catch (RuntimeException ignored) { }
            if (mediaWatching) {
                mediaWatching = false;
                try { context.unregisterReceiver(media); } catch (RuntimeException ignored) { }
            }
        }
    }
    @Override public void close() {
        watch(false); closed = true;
        channel.setMethodCallHandler(null); main.removeCallbacksAndMessages(null);
    }
}
