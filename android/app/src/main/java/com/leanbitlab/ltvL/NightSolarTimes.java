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
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.ZoneOffset;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Executors;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

final class NightSolarTimes {
    private static final long DAY_MS = 86_400_000L;
    private static final long HOUR_MS = 3_600_000L;
    private static boolean busy;
    private static String attemptKey = "";
    private static long lastAttempt;
    private static final java.util.concurrent.ExecutorService WORK = Executors.newSingleThreadExecutor();
    private static Resolved resolved;

    record Coordinates(double latitude, double longitude) {
        static Coordinates read(JSONObject config) {
            double latitude = config.optDouble("latitude"), longitude = config.optDouble("longitude");
            return Double.isFinite(latitude) && Math.abs(latitude) <= 90
                && Double.isFinite(longitude) && Math.abs(longitude) <= 180
                ? new Coordinates(latitude, longitude) : null;
        }

        ZoneId solarZone() {
            // Group astronomical instants by solar day until a provider gives
            // us the location's civil timezone. This never changes TV time.
            return ZoneOffset.ofHours((int) Math.round(longitude / 15));
        }
    }

    private record SolarData(ZoneId zone, Map<LocalDate, JSONObject> days) {}
    private record Resolved(String key, String history, ZoneId zone, LocalDate today, JSONArray days) {}

    private static SharedPreferences prefs(Context c) { return c.getSharedPreferences("night_solar", Context.MODE_PRIVATE); }
    static String key(JSONObject c) { return c.optString("latitude") + "," + c.optString("longitude"); }
    static JSONObject cache(Context context, JSONObject c) {
        return matchingCache(prefs(context).getString("cache", "{}"), key(c));
    }

    private static JSONObject matchingCache(String history, String key) {
        try {
            JSONObject cache = new JSONObject(history);
            return key.equals(cache.optString("key")) ? cache : new JSONObject();
        } catch (JSONException e) { return new JSONObject(); }
    }

    static synchronized JSONArray days(Context context, JSONObject config) {
        String history = prefs(context).getString("cache", "{}"), locationKey = key(config);
        Coordinates coordinates = Coordinates.read(config);
        ZoneId defaultZone = coordinates == null ? ZoneId.systemDefault() : coordinates.solarZone();
        JSONObject cache = matchingCache(history, locationKey);
        ZoneId zone = zoneOf(cache.optString("zone"), defaultZone);
        LocalDate today = LocalDate.now(zone);
        if (resolved != null && resolved.key.equals(locationKey) && resolved.history.equals(history)
                && resolved.zone.equals(zone) && resolved.today.equals(today)) {
            return resolved.days;
        }
        JSONArray days = resolvedDays(cache.optJSONArray("days"), today, zone, coordinates);
        resolved = new Resolved(locationKey, history, zone, today, days);
        return days;
    }

    private static ZoneId zoneOf(String value, ZoneId fallback) {
        if (value.isEmpty()) return fallback;
        try { return ZoneId.of(value); }
        catch (java.time.DateTimeException ignored) { return fallback; }
    }

    private static Map<LocalDate, JSONObject> datedDays(JSONArray history, ZoneId zone) {
        Map<LocalDate, JSONObject> known = new HashMap<>();
        if (history == null) return known;
        for (int i = 0; i < history.length(); i++) {
            JSONObject day = history.optJSONObject(i);
            if (day == null) continue;
            try {
                long rise = day.getLong("sunrise"), set = day.getLong("sunset");
                if (rise < 0 || set < 0) continue;
                long firstEvent = rise > 0 ? rise : set;
                LocalDate date = firstEvent > 0
                    ? Instant.ofEpochMilli(firstEvent).atZone(zone).toLocalDate()
                    : LocalDate.parse(day.getString("date"));
                if (!inDay(rise, date, zone) || !inDay(set, date, zone)) continue;
                known.put(date, solarDay(date, rise, set));
            } catch (JSONException | java.time.DateTimeException ignored) { /* Ignore malformed history. */ }
        }
        return known;
    }

    static JSONArray resolvedDays(JSONArray history, LocalDate today, ZoneId zone, Coordinates coordinates) {
        Map<LocalDate, JSONObject> known = datedDays(history, zone);
        LocalSolarTimes calculator = coordinates == null ? null
            : new LocalSolarTimes(coordinates.latitude, coordinates.longitude);
        JSONArray result = new JSONArray();
        for (int offset = -2; offset <= 7; offset++) {
            LocalDate date = today.plusDays(offset);
            JSONObject day = known.get(date);
            if (day == null && calculator != null) {
                LocalSolarTimes.Events events = calculator.calculate(date, zone);
                day = solarDay(date, events.sunrise(), events.sunset());
            }
            if (day == null) {
                day = solarDay(date, date.atTime(8, 0).atZone(zone).toInstant().toEpochMilli(),
                    date.atTime(20, 0).atZone(zone).toInstant().toEpochMilli());
            }
            result.put(day);
        }
        return result;
    }

    private static JSONObject solarDay(LocalDate date, long rise, long set) {
        try {
            return new JSONObject().put("date", date.toString()).put("sunrise", rise).put("sunset", set);
        } catch (JSONException impossible) { throw new IllegalStateException(impossible); }
    }

    static synchronized boolean loading() { return busy; }
    interface SunRequest { JSONObject fetch(String url) throws Exception; }
    static void refresh(Context context, JSONObject c, boolean force, Runnable done) {
        refresh(context, c, force, done, NightSolarTimes::request);
    }
    static synchronized void refresh(Context context, JSONObject c, boolean force, Runnable done, SunRequest request) {
        boolean brightnessSolar = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            .getBoolean("flutter.brightness_solar", false);
        Coordinates coordinates = Coordinates.read(c);
        if ((!c.optBoolean("solar") && !brightnessSolar) || coordinates == null) return;
        long now = System.currentTimeMillis();
        JSONObject cached = cache(context, c);
        String requestedKey = key(c);
        if (busy || (!force && now - cached.optLong("updated") < DAY_MS)
                || (!force && requestedKey.equals(attemptKey) && now - lastAttempt < HOUR_MS)) return;
        busy = true; attemptKey = requestedKey; lastAttempt = now;
        WORK.execute(() -> {
            try {
                LocalDate today = LocalDate.now(ZoneOffset.UTC);
                SolarData data;
                try {
                    data = sunriseSunset(coordinates, today, request);
                } catch (Exception primaryFailure) {
                    data = geoNames(coordinates, today.plusDays(1), request);
                    Map<LocalDate, JSONObject> history = datedDays(cached.optJSONArray("days"), data.zone);
                    // Keep already known events for the same city and date.
                    history.forEach(data.days::put);
                }
                JSONArray days = new JSONArray();
                for (LocalDate date = today.minusDays(3); !date.isAfter(today.plusDays(8)); date = date.plusDays(1)) {
                    JSONObject day = data.days.get(date);
                    if (day != null) days.put(day);
                }
                JSONObject value = new JSONObject().put("key", requestedKey).put("zone", data.zone.getId())
                    .put("days", days).put("updated", System.currentTimeMillis());
                prefs(context).edit().putString("cache", value.toString()).apply();
            } catch (Exception failure) {
                android.util.Log.w("CuteLauncherNight", "Sun refresh failed: " + failure.getClass().getSimpleName());
            }
            finally { synchronized (NightSolarTimes.class) { busy = false; } done.run(); }
        });
    }

    private static SolarData sunriseSunset(Coordinates coordinates, LocalDate today, SunRequest request) throws Exception {
        LocalDate first = today.minusDays(3), last = today.plusDays(8);
        String url = "https://api.sunrise-sunset.org/v2?lat=" + coordinates.latitude + "&lng=" + coordinates.longitude
            + "&date_start=" + first + "&date_end=" + last + "&time_format=unix";
        JSONObject response = request.fetch(url);
        ZoneId zone = zoneOf(response.getString("tzid"), coordinates.solarZone());
        JSONArray events = response.getJSONArray("days");
        if (events.length() != 12) throw new JSONException("Incomplete solar range");
        Map<LocalDate, JSONObject> days = new HashMap<>();
        for (int i = 0; i < events.length(); i++) {
            JSONObject event = events.getJSONObject(i);
            LocalDate date = LocalDate.parse(event.getString("date"));
            long rise = unixTime(event, "sunrise"), set = unixTime(event, "sunset");
            String status = event.optString("sun_status");
            boolean polar = status.equals("midnight_sun") || status.equals("polar_night");
            if (date.isBefore(first) || date.isAfter(last) || days.containsKey(date)
                    || !inDay(rise, date, zone) || !inDay(set, date, zone)
                    || (rise == 0 && set == 0 && !polar)) {
                throw new JSONException("Invalid solar date");
            }
            days.put(date, solarDay(date, rise, set));
        }
        return new SolarData(zone, days);
    }

    private static long unixTime(JSONObject day, String name) throws JSONException {
        if (!day.has(name)) throw new JSONException("Missing solar event");
        if (day.isNull(name)) return 0;
        long seconds = day.getLong(name);
        if (seconds <= 0 || seconds > Long.MAX_VALUE / 1000L) throw new JSONException("Invalid solar time");
        return seconds * 1000L;
    }

    private static SolarData geoNames(Coordinates coordinates, LocalDate date, SunRequest request) throws Exception {
        if (BuildConfig.GEONAMES_USERNAME.isEmpty()) throw new IllegalStateException("GeoNames is not configured");
        String url = "https://secure.geonames.org/timezoneJSON?lat=" + coordinates.latitude
            + "&lng=" + coordinates.longitude + "&date=" + date
            + "&username=" + Uri.encode(BuildConfig.GEONAMES_USERNAME);
        JSONObject response = request.fetch(url);
        if (response.has("status")) throw new JSONException("GeoNames error");
        ZoneId zone = ZoneId.of(response.getString("timezoneId"));
        Map<LocalDate, JSONObject> days = new HashMap<>();
        LocalDate localToday = parseLocalTime(response.getString("time")).toLocalDate();
        addGeoNamesDay(days, response, localToday, zone);
        JSONArray dated = response.getJSONArray("dates");
        for (int i = 0; i < dated.length(); i++) {
            JSONObject event = dated.optJSONObject(i);
            if (event != null && date.toString().equals(event.optString("date"))) {
                addGeoNamesDay(days, event, date, zone);
            }
        }
        // GeoNames omits both times during polar conditions. Compute these
        // dates locally rather than assuming a missing API field is an event.
        if (days.isEmpty()) throw new JSONException("Missing GeoNames solar events");
        return new SolarData(zone, days);
    }

    private static void addGeoNamesDay(Map<LocalDate, JSONObject> days, JSONObject data, LocalDate date, ZoneId zone)
            throws JSONException {
        long rise = localTime(data, "sunrise", zone), set = localTime(data, "sunset", zone);
        if (!inDay(rise, date, zone) || !inDay(set, date, zone)) throw new JSONException("Invalid GeoNames solar date");
        if (rise > 0 || set > 0) days.put(date, solarDay(date, rise, set));
    }

    private static long localTime(JSONObject data, String field, ZoneId zone) {
        return data.isNull(field) ? 0
            : parseLocalTime(data.optString(field)).atZone(zone).toInstant().toEpochMilli();
    }

    private static LocalDateTime parseLocalTime(String value) {
        return LocalDateTime.parse(value.replace(' ', 'T'));
    }

    private static boolean inDay(long event, LocalDate date, ZoneId zone) {
        return event == 0 || Instant.ofEpochMilli(event).atZone(zone).toLocalDate().equals(date);
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
                android.util.Log.w("CuteLauncherNight", "Sun service HTTP " + code);
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
