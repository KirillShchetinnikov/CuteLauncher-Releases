package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;

public class WeatherReceiver extends BroadcastReceiver {
    public static final String ACTION_GENERIC_WEATHER = "nodomain.freeyourgadget.gadgetbridge.ACTION_GENERIC_WEATHER";
    public static final String ACTION_BREEZY_UPDATE_NOTIFIER = "org.breezyweather.ACTION_UPDATE_NOTIFIER";
    public static final String ACTION_BREEZY_UPDATE_NOTIFIER_DEBUG = "org.breezyweather.debug.ACTION_UPDATE_NOTIFIER";
    public static final String PREFS_NAME = "lwidget_breezy_weather_data";
    public static final String KEY_WEATHER_JSON = "weather_json";

    public interface WeatherListener {
        void onWeatherUpdated(String weatherJson);
    }

    private static WeatherListener sListener;

    public static void setListener(WeatherListener listener) {
        sListener = listener;
    }

    static boolean isListener(WeatherListener listener) { return sListener == listener; }
    static void clearListener(WeatherListener listener) {
        if (sListener == listener) sListener = null;
    }

    // Match the nullable casts in WeatherData; optional/unknown fields remain supported.
    private static String validated(String raw) {
        try {
            var parser = new org.json.JSONTokener(raw);
            Object value = parser.nextValue();
            if (!(value instanceof org.json.JSONObject data) || parser.nextClean() != 0) return null;
            if (!integers(data, "timestamp", "currentConditionCode", "currentHumidity")
                    || !nullable(data, "location", String.class)
                    || !nullable(data, "currentCondition", String.class)
                    || !nullable(data, "forecasts", org.json.JSONArray.class)) return null;
            long seconds = data.isNull("timestamp") ? System.currentTimeMillis() / 1000 : data.getLong("timestamp");
            if (seconds < -8640000000000L || seconds > 8640000000000L) return null;
            Object offset = data.opt("utcOffsetSeconds");
            if (offset instanceof Integer || offset instanceof Long) {
                long valueSeconds = ((Number) offset).longValue();
                if (valueSeconds < -8640000000000L - seconds || valueSeconds > 8640000000000L - seconds) return null;
            }
            var forecasts = data.optJSONArray("forecasts");
            if (forecasts != null) for (int i = 0; i < forecasts.length(); i++) {
                var forecast = forecasts.optJSONObject(i);
                if (forecast != null && !integers(forecast, "conditionCode", "humidity", "precipProbability")) return null;
            }
            // JSONTokener accepts some non-JSON syntax; serialize to strict JSON for Dart.
            return data.toString();
        } catch (org.json.JSONException | RuntimeException invalid) { return null; }
    }

    private static boolean nullable(org.json.JSONObject data, String key, Class<?> type) {
        return data.isNull(key) || type.isInstance(data.opt(key));
    }

    private static boolean integers(org.json.JSONObject data, String... keys) {
        for (String key : keys) {
            Object value = data.opt(key);
            if (!data.isNull(key) && !(value instanceof Integer) && !(value instanceof Long)) return false;
        }
        return true;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null) return;
        String action = intent.getAction();
        boolean notifier = ACTION_BREEZY_UPDATE_NOTIFIER.equals(action) || ACTION_BREEZY_UPDATE_NOTIFIER_DEBUG.equals(action);
        if (!notifier && !ACTION_GENERIC_WEATHER.equals(action)) return;
        String weatherJson = intent.getStringExtra("WeatherJson");
        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        if (weatherJson != null && !weatherJson.isEmpty()) {
            weatherJson = validated(weatherJson);
            if (weatherJson == null) return;
            prefs.edit().putString(KEY_WEATHER_JSON, weatherJson).apply();
        } else if (notifier) {
            weatherJson = prefs.getString(KEY_WEATHER_JSON, null);
        }
        if (sListener != null && weatherJson != null && !weatherJson.isEmpty()) sListener.onWeatherUpdated(weatherJson);
    }
}
