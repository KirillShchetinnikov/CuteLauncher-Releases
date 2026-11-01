package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import java.net.HttpURLConnection;
import java.net.URL;
import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import org.json.JSONArray;
import org.json.JSONObject;

final class NightSolarTimes {
    private static boolean busy;
    private static String attemptKey = "";
    private static long lastAttempt;
    private static final java.util.concurrent.ExecutorService WORK = Executors.newSingleThreadExecutor();
    private static SharedPreferences prefs(Context c) { return c.getSharedPreferences("night_solar", Context.MODE_PRIVATE); }
    static String key(JSONObject c) { return c.optString("latitude") + "," + c.optString("longitude"); }
    static JSONObject cache(Context context, JSONObject c) {
        try {
            JSONObject cache = new JSONObject(prefs(context).getString("cache", "{}"));
            return key(c).equals(cache.optString("key")) ? cache : new JSONObject();
        } catch (Exception e) { return new JSONObject(); }
    }
    static JSONArray days(Context context, JSONObject c) {
        JSONArray days = cache(context, c).optJSONArray("days");
        return resolvedDays(days, LocalDate.now(), ZoneId.systemDefault());
    }
    /** Resolve locally before any network work; synthetic events never replace history. */
    static JSONArray resolvedDays(JSONArray history, LocalDate today, ZoneId zone) {
        Map<LocalDate, JSONObject> known = new HashMap<>();
        if (history != null) for (int i = 0; i < history.length(); i++) {
            JSONObject day = history.optJSONObject(i);
            if (day == null) continue;
            long rise = day.optLong("sunrise"), set = day.optLong("sunset");
            if (rise < 0 || set < 0 || (rise > 0 && set > 0 && set <= rise)) continue;
            try {
                LocalDate date = rise == 0 && set == 0 ? LocalDate.parse(day.getString("date"))
                    : Instant.ofEpochMilli(rise > 0 ? rise : set).atZone(zone).toLocalDate();
                known.put(date, day);
            } catch (Exception ignored) { /* Ignore malformed history. */ }
        }
        JSONObject yesterday = known.get(today.minusDays(1));
        if (yesterday != null && (yesterday.optLong("sunrise") <= 0 || yesterday.optLong("sunset") <= 0)) yesterday = null;
        LocalTime rise = yesterday == null ? LocalTime.of(8, 0)
            : Instant.ofEpochMilli(yesterday.optLong("sunrise")).atZone(zone).toLocalTime();
        LocalTime set = yesterday == null ? LocalTime.of(20, 0)
            : Instant.ofEpochMilli(yesterday.optLong("sunset")).atZone(zone).toLocalTime();
        JSONArray result = new JSONArray();
        for (int offset = -2; offset <= 7; offset++) {
            LocalDate date = today.plusDays(offset);
            JSONObject day = known.get(date);
            if (day == null) try {
                day = new JSONObject().put("sunrise", date.atTime(rise).atZone(zone).toInstant().toEpochMilli())
                    .put("sunset", date.atTime(set).atZone(zone).toInstant().toEpochMilli());
            } catch (org.json.JSONException impossible) { throw new IllegalStateException(impossible); }
            result.put(day);
        }
        return result;
    }
    static synchronized boolean loading() { return busy; }
    interface SunRequest { JSONObject fetch(String url) throws Exception; }
    static void refresh(Context context, JSONObject c, boolean force, Runnable done) {
        refresh(context, c, force, done, NightSolarTimes::request);
    }
    static synchronized void refresh(Context context, JSONObject c, boolean force, Runnable done, SunRequest request) {
        boolean brightnessSolar = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.brightness_solar", false);
        if ((!c.optBoolean("solar") && !brightnessSolar) || c.isNull("latitude") || c.isNull("longitude")) return;
        long now = System.currentTimeMillis();
        JSONObject cached = cache(context, c);
        String requestedKey = key(c);
        if (busy || (!force && now - cached.optLong("updated") < 86400000L)
                || (!force && requestedKey.equals(attemptKey) && now - lastAttempt < 3600000L)) return;
        busy = true; attemptKey = requestedKey; lastAttempt = now;
        WORK.execute(() -> {
            try {
                JSONArray days;
                try {
                    java.time.LocalDate date=java.time.LocalDate.now();
                    String url="https://api.sunrise-sunset.org/v2?lat="+c.optDouble("latitude")+"&lng="+c.optDouble("longitude")
                        +"&date_start="+date.minusDays(2)+"&date_end="+date.plusDays(7)+"&time_format=unix";
                    JSONArray events=request.fetch(url).getJSONArray("days");
                    if(events.length()<2 || events.length()>16) throw new IllegalStateException();
                    days=new JSONArray();
                    for(int i=0;i<events.length();i++) {
                        JSONObject event=events.getJSONObject(i);
                        days.put(new JSONObject().put("date", date.minusDays(2).plusDays(i).toString())
                            .put("sunrise",event.isNull("sunrise")?0:event.getLong("sunrise")*1000L)
                            .put("sunset",event.isNull("sunset")?0:event.getLong("sunset")*1000L));
                    }
                } catch(Exception primaryFailure) {
                    String url = "https://api.open-meteo.com/v1/forecast?latitude=" + c.optDouble("latitude")
                        + "&longitude=" + c.optDouble("longitude")
                        + "&daily=sunrise,sunset&timezone=auto&timeformat=unixtime&past_days=1&forecast_days=7";
                    JSONObject daily = request.fetch(url).getJSONObject("daily");
                    JSONArray rises = daily.getJSONArray("sunrise"), sets = daily.getJSONArray("sunset");
                    days=new JSONArray();
                    if (rises.length() < 2 || rises.length() > 16 || rises.length() != sets.length()) throw new IllegalStateException();
                    for (int i = 0; i < rises.length(); i++) {
                        days.put(new JSONObject().put("date", java.time.LocalDate.now().minusDays(1).plusDays(i).toString())
                            .put("sunrise", rises.isNull(i) ? 0 : rises.getLong(i) * 1000L)
                            .put("sunset", sets.isNull(i) ? 0 : sets.getLong(i) * 1000L));
                    }
                }
                JSONObject value = new JSONObject().put("key", requestedKey).put("days", days).put("updated", System.currentTimeMillis());
                prefs(context).edit().putString("cache", value.toString()).apply();
            } catch (Exception failure) {
                android.util.Log.w("CuteLauncherNight", "Sun refresh failed: " + failure.getClass().getSimpleName());
                /* Keep history; days() supplies yesterday's times or local 08:00/20:00. */
            }
            finally { synchronized (NightSolarTimes.class) { busy = false; } done.run(); }
        });
    }
    static List<Map<String, Object>> cities(String query, String language) throws Exception {
        if (query == null || query.trim().length() < 2 || query.length() > 100) return new ArrayList<>();
        if (language == null || !language.matches("[a-z]{2}")) language = "en";
        JSONObject data = request("https://geocoding-api.open-meteo.com/v1/search?name=" + Uri.encode(query.trim())
            + "&count=8&language=" + language + "&format=json");
        JSONArray results = data.optJSONArray("results");
        List<Map<String, Object>> cities = new ArrayList<>();
        if (results != null) for (int i = 0; i < results.length(); i++) {
            JSONObject city = results.getJSONObject(i);
            double lat = city.getDouble("latitude"), lon = city.getDouble("longitude");
            if (!Double.isFinite(lat) || !Double.isFinite(lon) || Math.abs(lat)>90 || Math.abs(lon)>180) continue;
            String label = city.getString("name") + ", " + city.optString("admin1") + ", " + city.optString("country");
            cities.add(Map.of("city", label, "latitude", lat, "longitude", lon));
        }
        return cities;
    }
    static List<Map<String, Object>> list(JSONArray array) {
        List<Map<String, Object>> output = new ArrayList<>();
        for (int i = 0; i < array.length(); i++) {
            JSONObject day = array.optJSONObject(i);
            if (day != null) output.add(Map.of("sunrise", day.optLong("sunrise"), "sunset", day.optLong("sunset")));
        }
        return output;
    }
    private static JSONObject request(String url) throws Exception {
        HttpURLConnection connection = (HttpURLConnection) new URL(url).openConnection();
        connection.setConnectTimeout(10000); connection.setReadTimeout(10000);
        connection.setInstanceFollowRedirects(false);
        try {
            int code=connection.getResponseCode();
            if (code != 200) {
                android.util.Log.w("CuteLauncherNight", "Sun/city service HTTP " + code);
                throw new IllegalStateException();
            }
            try (InputStream in = connection.getInputStream(); ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[8192]; int size;
                while ((size = in.read(buffer)) != -1) {
                    if (bytes.size() + size > 128 * 1024) throw new IllegalStateException();
                    bytes.write(buffer, 0, size);
                }
                return new JSONObject(bytes.toString(StandardCharsets.UTF_8.name()));
            }
        } finally { connection.disconnect(); }
    }
}
