package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.media.AudioManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.util.Log;
import androidx.annotation.NonNull;
import java.util.function.BooleanSupplier;

/** An event-driven media volume readout owned by the connected accessibility service. */
final class VolumeOverlay implements AutoCloseable {
    static final String ENABLED = "flutter.show_volume_overlay";
    static final String POSITION = "flutter.volume_overlay_position";
    static final String APPEARANCE = "flutter.volume_overlay_appearance";
    // AudioService sends this protected broadcast from system_server.
    static final String VOLUME_CHANGED = "android.media.VOLUME_CHANGED_ACTION";
    static final String STREAM_TYPE = "android.media.EXTRA_VOLUME_STREAM_TYPE";
    private static final long HIDE_DELAY_MS = 2_000;

    private final Context context;
    private final BooleanSupplier blocked;
    private final SharedPreferences preferences;
    private final OverlayReadoutWindow window;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable timeout = this::hide;
    private final SharedPreferences.OnSharedPreferenceChangeListener listener = (prefs, key) -> {
        if (key == null || ENABLED.equals(key)) updateWatching();
        if (key == null || POSITION.equals(key)) updatePosition();
        if (key == null || APPEARANCE.equals(key)) updateAppearance();
    };
    private final BroadcastReceiver events = new BroadcastReceiver() {
        @Override public void onReceive(Context unused, Intent intent) {
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) {
                hide();
            } else if (watching && VOLUME_CHANGED.equals(intent.getAction())
                    && intent.getIntExtra(STREAM_TYPE, -1) == AudioManager.STREAM_MUSIC) {
                volumeChanged();
            }
        }
    };
    private boolean watching, closed;

    VolumeOverlay(@NonNull Context context, @NonNull BooleanSupplier blocked, @NonNull OverlayReadoutWindow window) {
        this.context = context;
        this.blocked = blocked;
        this.window = window;
        preferences = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        preferences.registerOnSharedPreferenceChangeListener(listener);
        updatePosition();
        updateAppearance();
        updateWatching();
    }

    private void updatePosition() {
        if (!closed) window.setPosition(preferences.getString(POSITION, null));
    }

    private void updateAppearance() {
        if (!closed) window.setAppearance(preferences.getString(APPEARANCE, null));
    }

    private void updateWatching() {
        if (closed) return;
        if (!preferences.getBoolean(ENABLED, false)) {
            stopWatching();
            return;
        }
        if (watching) return;
        var filter = new IntentFilter(VOLUME_CHANGED);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                context.registerReceiver(events, filter, Context.RECEIVER_NOT_EXPORTED);
            } else {
                context.registerReceiver(events, filter);
            }
            watching = true;
        } catch (SecurityException denied) {
            Log.w("VolumeOverlay", "Unable to receive media volume changes", denied);
        }
    }

    private void volumeChanged() {
        var power = context.getSystemService(PowerManager.class);
        if (blocked.getAsBoolean() || power == null || !power.isInteractive()) {
            hide();
            return;
        }
        var audio = context.getSystemService(AudioManager.class);
        try {
            var percent = audio == null || audio.isVolumeFixed()
                ? null : AudioStatusController.mediaVolumePercent(audio);
            if (percent == null) {
                hide();
                return;
            }
            window.show(percent + "%");
            main.removeCallbacks(timeout);
            main.postDelayed(timeout, HIDE_DELAY_MS);
        } catch (RuntimeException unavailable) {
            hide();
            Log.w("VolumeOverlay", "Unable to display media volume", unavailable);
        }
    }

    void hide() {
        main.removeCallbacks(timeout);
        window.hide();
    }

    private void stopWatching() {
        hide();
        if (!watching) return;
        watching = false;
        context.unregisterReceiver(events);
    }

    @Override public void close() {
        if (closed) return;
        closed = true;
        preferences.unregisterOnSharedPreferenceChangeListener(listener);
        stopWatching();
    }
}
