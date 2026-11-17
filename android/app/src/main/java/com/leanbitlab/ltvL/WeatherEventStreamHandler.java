package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.EventChannel;

/** Owns only this host's weather subscription, including already queued deliveries. */
final class WeatherEventStreamHandler implements EventChannel.StreamHandler, AutoCloseable {
    private final Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private WeatherReceiver.WeatherListener listener;
    private int generation;

    WeatherEventStreamHandler(Context context) { this.context = context.getApplicationContext(); }

    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        close();
        int subscription = generation;
        listener = json -> main.post(() -> {
            if (subscription == generation && WeatherReceiver.isListener(listener)) events.success(json);
        });
        WeatherReceiver.setListener(listener);
        String latest = context.getSharedPreferences(WeatherReceiver.PREFS_NAME, 0)
            .getString(WeatherReceiver.KEY_WEATHER_JSON, null);
        if (latest != null) listener.onWeatherUpdated(latest);
    }

    @Override public void onCancel(Object arguments) { close(); }

    @Override public void close() {
        generation++;
        WeatherReceiver.clearListener(listener);
        listener = null;
        main.removeCallbacksAndMessages(null);
    }
}
