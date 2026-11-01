package com.leanbitlab.ltvL;

import android.content.Context;
import java.time.LocalDate;
import java.time.ZoneId;
import org.json.JSONArray;
import org.json.JSONObject;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class NightSolarTimesTest {
    private final ZoneId zone = ZoneId.of("Europe/Berlin");
    private final LocalDate today = LocalDate.of(2026, 10, 25); // DST ends today.
    private long time(LocalDate date, int hour, int minute) {
        return date.atTime(hour, minute).atZone(zone).toInstant().toEpochMilli();
    }
    private JSONObject day(LocalDate date, int rise, int set) throws Exception {
        return new JSONObject().put("sunrise", time(date, rise, 15))
            .put("sunset", time(date, set, 45));
    }
    @Test public void coldStartUsesDefaultsWithoutNetworkOrCoordinates() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        context.getSharedPreferences("night_solar", 0).edit().clear().commit();
        JSONArray result = NightSolarTimes.days(context, new JSONObject());
        assertEquals(10, result.length());
        var local = java.time.Instant.ofEpochMilli(result.getJSONObject(2).getLong("sunrise"))
            .atZone(ZoneId.systemDefault());
        assertEquals(8, local.getHour()); assertEquals(0, local.getMinute());
        assertEquals(0, NightSolarTimes.cache(context, new JSONObject()).optLong("updated"));
    }
    @Test public void yesterdayIsProjectedInLocalTimeAcrossDstAndHistoryIsUnchanged() throws Exception {
        JSONArray history = new JSONArray().put(day(today.minusDays(1), 7, 18));
        String original = history.toString();
        JSONArray result = NightSolarTimes.resolvedDays(history, today, zone);
        assertEquals(time(today, 7, 15), result.getJSONObject(2).getLong("sunrise"));
        assertEquals(time(today.plusDays(1), 18, 45), result.getJSONObject(3).getLong("sunset"));
        assertEquals(original, history.toString());
        JSONObject config = new JSONObject().put("enabled", true).put("scheduled", true)
            .put("solar", true).put("transitionMinutes", 60).put("sunsetOffset", 30);
        assertEquals(1, NightSchedule.intensity(config, result, time(today, 22, 0)), .00001);
        assertEquals(0, NightSchedule.intensity(config, result, time(today, 12, 0)), .00001);
        assertTrue(NightSchedule.next(config, result, time(today, 22, 0), false) > 0);
    }
    @Test public void actualForecastWinsAndOldOrMalformedHistoryUsesDefaults() throws Exception {
        JSONObject actual = day(today, 6, 17);
        JSONArray history = new JSONArray().put(day(today.minusDays(1), 7, 18)).put(actual);
        assertEquals(actual.toString(), NightSolarTimes.resolvedDays(history, today, zone).getJSONObject(2).toString());
        for (JSONArray invalid : new JSONArray[]{new JSONArray(),
                new JSONArray().put(day(today.minusDays(2), 7, 18)),
                new JSONArray().put("broken").put(new JSONObject().put("sunrise", -1))}) {
            JSONArray result = NightSolarTimes.resolvedDays(invalid, today, zone);
            assertEquals(time(today, 8, 0), result.getJSONObject(2).getLong("sunrise"));
            assertEquals(time(today, 20, 0), result.getJSONObject(2).getLong("sunset"));
        }
    }
    @Test public void cachedLocationMustMatchAndSyntheticDaysAreNeverSaved() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        JSONObject config = new JSONObject().put("latitude", 55).put("longitude", 37);
        JSONObject cache = new JSONObject().put("key", NightSolarTimes.key(config))
            .put("updated", 123).put("days", new JSONArray().put(day(today.minusDays(1), 7, 18)));
        var prefs = context.getSharedPreferences("night_solar", 0);
        prefs.edit().putString("cache", cache.toString()).commit();
        NightSolarTimes.days(context, config);
        assertEquals(cache.toString(), prefs.getString("cache", ""));
        config.put("latitude", 56);
        assertEquals(0, NightSolarTimes.cache(context, config).optLong("updated"));
    }
    @Test public void explicitPolarDayIsNotReplacedByFictionalEvents() throws Exception {
        JSONObject polar = new JSONObject().put("date", today.toString()).put("sunrise", 0).put("sunset", 0);
        JSONArray result = NightSolarTimes.resolvedDays(new JSONArray().put(polar), today, zone);
        assertEquals(0, result.getJSONObject(2).getLong("sunrise"));
        assertEquals(0, result.getJSONObject(2).getLong("sunset"));
    }
    @Test public void bothServersOfflineKeepHistoryAndScheduleReadyDuringRefresh() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        ZoneId local = ZoneId.systemDefault();
        LocalDate now = LocalDate.now();
        JSONObject yesterday = new JSONObject()
            .put("sunrise", now.minusDays(1).atTime(7, 10).atZone(local).toInstant().toEpochMilli())
            .put("sunset", now.minusDays(1).atTime(18, 40).atZone(local).toInstant().toEpochMilli());
        JSONObject config = new JSONObject().put("solar", true).put("latitude", 55).put("longitude", 37);
        String cached = new JSONObject().put("key", NightSolarTimes.key(config)).put("updated", 1)
            .put("days", new JSONArray().put(yesterday)).toString();
        var prefs = context.getSharedPreferences("night_solar", 0);
        prefs.edit().putString("cache", cached).commit();
        var entered = new java.util.concurrent.CountDownLatch(1);
        var release = new java.util.concurrent.CountDownLatch(1);
        var done = new java.util.concurrent.CountDownLatch(1);
        var calls = new java.util.concurrent.atomic.AtomicInteger();
        NightSolarTimes.refresh(context, config, true, done::countDown, url -> {
            calls.incrementAndGet(); entered.countDown();
            if (!release.await(5, java.util.concurrent.TimeUnit.SECONDS)) throw new AssertionError("Timed out");
            throw new java.net.UnknownHostException("offline");
        });
        try {
            assertTrue(entered.await(5, java.util.concurrent.TimeUnit.SECONDS));
            assertTrue(NightSolarTimes.loading());
            assertEquals(now.atTime(7, 10).atZone(local).toInstant().toEpochMilli(),
                NightSolarTimes.days(context, config).getJSONObject(2).getLong("sunrise"));
        } finally { release.countDown(); }
        assertTrue(done.await(5, java.util.concurrent.TimeUnit.SECONDS));
        assertEquals(2, calls.get());
        assertFalse(NightSolarTimes.loading());
        assertEquals(cached, prefs.getString("cache", ""));
        assertEquals(now.atTime(18, 40).atZone(local).toInstant().toEpochMilli(),
            NightSolarTimes.days(context, config).getJSONObject(2).getLong("sunset"));
    }
}
