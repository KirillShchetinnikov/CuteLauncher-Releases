package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.media.AudioDeviceCallback;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodChannel;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.atomic.AtomicBoolean;

/** Engine-scoped listeners only while the Dart panel is visible. No volume control. */
final class AudioStatusBridge implements AutoCloseable {
    private final Context context;
    private final MethodChannel channel;
    private final AudioManager audio;
    private final Handler main = new Handler(Looper.getMainLooper());
    private boolean watching, deviceListening, closed;
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
                worker.execute(() -> {
                    try {
                        var state = new AudioStatusController(context).snapshot();
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
            try {
                if (audio != null) { audio.registerAudioDeviceCallback(devices, main); deviceListening = true; }
            } catch (RuntimeException unavailable) { /* Polling remains available. */ }
        } else {
            watching = false;
            context.unregisterReceiver(screen);
            if (deviceListening) { audio.unregisterAudioDeviceCallback(devices); deviceListening = false; }
        }
    }
    @Override public void close() {
        watch(false); closed = true;
        channel.setMethodCallHandler(null); main.removeCallbacksAndMessages(null);
    }
}
