package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.PowerManager;
import android.os.SystemClock;
import android.text.format.DateFormat;
import android.text.format.DateUtils;
import android.util.Log;
import androidx.annotation.NonNull;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.function.BooleanSupplier;
import org.json.JSONException;
import org.json.JSONObject;

/** Paints the current Android alarm deadline while the screen is visible. */
final class SleepTimerOverlay implements AutoCloseable {
    private static final String CONFIG = "flutter.sleep_timer_configuration";
    private final Context context;
    private final BooleanSupplier blocked;
    private final SharedPreferences settings;
    private final SharedPreferences timer;
    private final OverlayReadoutWindow window;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final Runnable tick = this::refresh;
    private final SharedPreferences.OnSharedPreferenceChangeListener settingsListener = (prefs, key) -> {
        if (key == null || CONFIG.equals(key)) loadSettings();
    };
    private final SharedPreferences.OnSharedPreferenceChangeListener timerListener = (prefs, key) -> {
        if (key == null || "deadline".equals(key)) loadDeadline();
    };
    private final BroadcastReceiver events = new BroadcastReceiver() {
        @Override public void onReceive(@NonNull Context unused, @NonNull Intent intent) {
            if (!watching) return;
            if (Intent.ACTION_SCREEN_OFF.equals(intent.getAction())) screenOn = false;
            if (Intent.ACTION_SCREEN_ON.equals(intent.getAction())) screenOn = true;
            endLabel = null;
            refresh();
        }
    };
    private boolean enabled, showSeconds, screenOn, watching, closed;
    private String display, endLabel;
    private long deadline;

    SleepTimerOverlay(@NonNull Context context, @NonNull BooleanSupplier blocked, @NonNull OverlayReadoutWindow window) {
        this.context = context;
        this.blocked = blocked;
        settings = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        timer = SleepTimerBridge.prefs(context);
        this.window = window;
        settings.registerOnSharedPreferenceChangeListener(settingsListener);
        timer.registerOnSharedPreferenceChangeListener(timerListener);
        loadSettings();
    }

    private void loadSettings() {
        if (closed) return;
        try {
            var config = new JSONObject(settings.getString(CONFIG, "{}"));
            enabled = Boolean.TRUE.equals(config.opt("showOverApps"));
            showSeconds = config.optBoolean("showSeconds", true);
            display = config.optString("display", "remaining");
            window.setPosition(config.optString("overlayPosition", null));
            window.setAppearance(config.optString("overlayAppearance", null));
        } catch (JSONException | ClassCastException malformed) {
            enabled = false;
        }
        loadDeadline();
    }

    private void loadDeadline() {
        if (closed) return;
        deadline = enabled ? SleepTimerBridge.activeDeadline(context) : 0;
        endLabel = null;
        refresh();
    }

    void refresh() {
        main.removeCallbacks(tick);
        long remaining = deadline - SystemClock.elapsedRealtime();
        if (closed || remaining <= 0) {
            stopWatching();
            return;
        }
        if (!watching) watch();
        if (!watching || !screenOn || blocked.getAsBoolean()) {
            window.hide();
            return;
        }
        try {
            String label = switch (display) {
                case "end" -> endTime(remaining);
                case "both" -> countdown(remaining) + " · " + endTime(remaining);
                default -> countdown(remaining);
            };
            window.show(label);
            long unit = showSeconds ? 1_000 : 60_000;
            main.postDelayed(tick, display.equals("end") ? remaining : (remaining - 1) % unit + 1);
        } catch (RuntimeException unavailable) {
            window.hide();
            Log.w("SleepTimerOverlay", "Unable to display sleep timer", unavailable);
        }
    }

    @NonNull private String countdown(long millis) {
        long units = (millis - 1) / (showSeconds ? 1_000 : 60_000) + 1;
        long seconds = showSeconds ? units : units * 60;
        long hours = seconds / 3600;
        long minutes = seconds / 60 % 60;
        if (!showSeconds) return String.format(Locale.ROOT, "%d:%02d", hours, minutes);
        String shortTime = String.format(Locale.ROOT, "%02d:%02d", minutes, seconds % 60);
        return hours > 0 ? hours + ":" + shortTime : shortTime;
    }

    @NonNull private String endTime(long remaining) {
        if (endLabel != null) return endLabel;
        var end = new Date(System.currentTimeMillis() + remaining);
        var locale = context.getResources().getConfiguration().getLocales().get(0);
        var format = showSeconds ? new SimpleDateFormat(DateFormat.getBestDateTimePattern(locale,
            DateFormat.is24HourFormat(context) ? "Hms" : "hms"), locale) : DateFormat.getTimeFormat(context);
        String time = format.format(end);
        endLabel = DateUtils.isToday(end.getTime()) ? time : DateFormat.getDateFormat(context).format(end) + " " + time;
        return endLabel;
    }

    private void watch() {
        var filter = new IntentFilter(Intent.ACTION_SCREEN_ON);
        filter.addAction(Intent.ACTION_SCREEN_OFF);
        filter.addAction(Intent.ACTION_TIME_CHANGED);
        filter.addAction(Intent.ACTION_TIMEZONE_CHANGED);
        filter.addAction(Intent.ACTION_DATE_CHANGED);
        try {
            if (Build.VERSION.SDK_INT >= 33) {
                context.registerReceiver(events, filter, Context.RECEIVER_NOT_EXPORTED);
            } else {
                context.registerReceiver(events, filter);
            }
            watching = true;
            var power = context.getSystemService(PowerManager.class);
            screenOn = power != null && power.isInteractive();
        } catch (SecurityException denied) {
            Log.w("SleepTimerOverlay", "Unable to observe screen state", denied);
        }
    }

    private void stopWatching() {
        window.hide();
        if (!watching) return;
        watching = false;
        context.unregisterReceiver(events);
    }

    @Override public void close() {
        if (closed) return;
        closed = true;
        settings.unregisterOnSharedPreferenceChangeListener(settingsListener);
        timer.unregisterOnSharedPreferenceChangeListener(timerListener);
        refresh();
    }
}
