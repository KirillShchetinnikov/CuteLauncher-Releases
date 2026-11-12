package com.leanbitlab.ltvL;

import android.content.Context;
import android.net.Uri;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
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
    private final NightSolarTimes.Coordinates berlin = new NightSolarTimes.Coordinates(52.52, 13.405);
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
    @Test public void missingDaysAreCalculatedAcrossDstAndHistoryIsUnchanged() throws Exception {
        JSONArray history = new JSONArray().put(day(today.minusDays(1), 7, 18));
        String original = history.toString();
        JSONArray result = NightSolarTimes.resolvedDays(history, today, zone, berlin);
        assertEquals(time(today.minusDays(1), 7, 15), result.getJSONObject(1).getLong("sunrise"));
        assertNear(1792907378, result.getJSONObject(2).getLong("sunrise"), 120);
        assertNear(1793029702, result.getJSONObject(3).getLong("sunset"), 120);
        assertEquals(original, history.toString());
        JSONObject config = new JSONObject().put("enabled", true).put("scheduled", true)
            .put("solar", true).put("transitionMinutes", 60).put("sunsetOffset", 30);
        assertEquals(1, NightSchedule.intensity(config, result, time(today, 22, 0)), .00001);
        assertEquals(0, NightSchedule.intensity(config, result, time(today, 12, 0)), .00001);
        assertTrue(NightSchedule.next(config, result, time(today, 22, 0), false) > 0);
    }
    @Test public void cachedEventsWinAndOldOrMalformedHistoryUsesCalculation() throws Exception {
        JSONObject actual = day(today, 6, 17);
        JSONArray history = new JSONArray().put(day(today.minusDays(1), 7, 18)).put(actual);
        assertEquals(time(today, 6, 15),
            NightSolarTimes.resolvedDays(history, today, zone, berlin).getJSONObject(2).getLong("sunrise"));
        for (JSONArray invalid : new JSONArray[]{new JSONArray(),
                new JSONArray().put(day(today.minusDays(2), 7, 18)),
                new JSONArray().put("broken").put(new JSONObject().put("sunrise", -1))}) {
            JSONArray result = NightSolarTimes.resolvedDays(invalid, today, zone, berlin);
            assertNear(1792907378, result.getJSONObject(2).getLong("sunrise"), 120);
            assertNear(1792943424, result.getJSONObject(2).getLong("sunset"), 120);
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
        JSONArray result = NightSolarTimes.resolvedDays(new JSONArray().put(polar), today, zone, berlin);
        assertEquals(0, result.getJSONObject(2).getLong("sunrise"));
        assertEquals(0, result.getJSONObject(2).getLong("sunset"));
    }
    @Test public void localCalculatorHandlesDateLineAndPolarSeasons() {
        LocalSolarTimes apia = new LocalSolarTimes(-13.833, -171.75);
        var samoa = apia.calculate(LocalDate.of(2026, 11, 12), ZoneId.of("Pacific/Apia"));
        assertNear(1794415771, samoa.sunrise(), 120);
        assertNear(1794461562, samoa.sunset(), 120);
        assertEquals(11, Instant.ofEpochMilli(samoa.sunrise()).atZone(ZoneId.of("UTC")).getDayOfMonth());

        LocalSolarTimes tromso = new LocalSolarTimes(69.65, 18.96);
        ZoneId oslo = ZoneId.of("Europe/Oslo");
        for (LocalDate date : List.of(LocalDate.of(2026, 6, 21), LocalDate.of(2026, 12, 21))) {
            var events = tromso.calculate(date, oslo);
            assertEquals(0, events.sunrise());
            assertEquals(0, events.sunset());
        }
        var shortDay = tromso.calculate(LocalDate.of(2026, 11, 27), oslo);
        assertNear(1795774860, shortDay.sunrise(), 300);
        assertNear(1795776107, shortDay.sunset(), 300);
    }

    @Test public void sunsetAfterMidnightUsesTheSameCivilDaysSunrise() throws Exception {
        long sunset = time(today, 0, 10), sunrise = time(today, 2, 40);
        JSONArray days = new JSONArray()
            .put(new JSONObject().put("sunset", sunset).put("sunrise", sunrise))
            .put(day(today.plusDays(1), 7, 18));
        JSONObject config = new JSONObject().put("solar", true).put("enabled", true)
            .put("scheduled", true);
        assertArrayEquals(new long[]{sunset, sunrise},
            NightSchedule.intervals(config, days, sunset).get(0));
        assertEquals(0, NightSchedule.intensity(config, days, time(today, 12, 0)), 0);
    }

    @Test public void primaryRangeUsesUnixEventsAndDoesNotQueryGeoNames() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        clearCache(context);
        JSONObject config = berlinConfig();
        var calls = new ArrayList<String>();
        awaitRefresh(context, config, url -> {
            Uri uri = Uri.parse(url);
            calls.add(uri.getHost());
            if (!"api.sunrise-sunset.org".equals(uri.getHost())) throw new IllegalArgumentException();
            assertEquals("unix", uri.getQueryParameter("time_format"));
            LocalDate start = LocalDate.parse(uri.getQueryParameter("date_start"));
            JSONArray days = new JSONArray();
            for (int i = 0; i < 12; i++) {
                LocalDate date = start.plusDays(i);
                days.put(new JSONObject().put("date", date.toString())
                    .put("sunrise", time(date, 7, 10) / 1000)
                    .put("sunset", i == 0 ? JSONObject.NULL : time(date, 17, 45) / 1000));
            }
            return new JSONObject().put("tzid", zone.getId()).put("days", days);
        });
        assertEquals(List.of("api.sunrise-sunset.org"), calls);
        JSONObject cached = NightSolarTimes.cache(context, config);
        JSONArray days = cached.getJSONArray("days");
        assertEquals(12, days.length());
        assertEquals(0, days.getJSONObject(0).getLong("sunset"));
        assertEquals(zone.getId(), cached.getString("zone"));
        assertEquals(time(LocalDate.now(zone), 7, 10),
            NightSolarTimes.days(context, config).getJSONObject(2).getLong("sunrise"));
    }

    @Test public void invalidPrimaryFallsBackToOneGeoNamesRequestUsingTheCityTimezone() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        clearCache(context);
        JSONObject config = berlinConfig();
        var calls = new ArrayList<String>();
        awaitRefresh(context, config, url -> {
            Uri uri = Uri.parse(url);
            calls.add(uri.getHost());
            if ("api.sunrise-sunset.org".equals(uri.getHost())) return new JSONObject();
            assertEquals("secure.geonames.org", uri.getHost());
            assertEquals("/timezoneJSON", uri.getPath());
            assertEquals(BuildConfig.GEONAMES_USERNAME, uri.getQueryParameter("username"));
            LocalDate requested = LocalDate.parse(uri.getQueryParameter("date"));
            LocalDate previous = requested.minusDays(1);
            JSONObject dated = new JSONObject().put("date", requested.toString())
                .put("sunrise", requested + " 07:40").put("sunset", requested + " 18:00");
            return new JSONObject().put("timezoneId", zone.getId()).put("time", previous + " 12:00")
                .put("sunrise", previous + " 07:38").put("sunset", previous + " 18:02")
                .put("dates", new JSONArray().put(dated).put(new JSONObject().put("offsetToGmt", "1.00")));
        });
        assertEquals(List.of("api.sunrise-sunset.org", "secure.geonames.org"), calls);
        JSONObject cached = NightSolarTimes.cache(context, config);
        JSONArray days = cached.getJSONArray("days");
        assertEquals(2, days.length());
        LocalDate requested = LocalDate.parse(days.getJSONObject(1).getString("date"));
        assertEquals(time(requested, 7, 40), days.getJSONObject(1).getLong("sunrise"));
        assertEquals(time(requested.minusDays(1), 18, 2), days.getJSONObject(0).getLong("sunset"));
        assertEquals(10, NightSolarTimes.days(context, config).length());
    }

    @Test public void bothServersOfflineKeepHistoryAndScheduleReadyDuringRefresh() throws Exception {
        Context context = RuntimeEnvironment.getApplication();
        LocalDate now = LocalDate.now(zone);
        JSONObject yesterday = day(now.minusDays(1), 7, 18);
        JSONObject config = berlinConfig();
        String cached = new JSONObject().put("key", NightSolarTimes.key(config)).put("updated", 1)
            .put("zone", zone.getId())
            .put("days", new JSONArray().put(yesterday)).toString();
        var expected = new LocalSolarTimes(52.52, 13.405).calculate(now, zone);
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
            assertEquals(expected.sunrise(),
                NightSolarTimes.days(context, config).getJSONObject(2).getLong("sunrise"));
        } finally { release.countDown(); }
        assertTrue(done.await(5, java.util.concurrent.TimeUnit.SECONDS));
        assertEquals(2, calls.get());
        assertFalse(NightSolarTimes.loading());
        assertEquals(cached, prefs.getString("cache", ""));
        assertEquals(expected.sunset(),
            NightSolarTimes.days(context, config).getJSONObject(2).getLong("sunset"));
    }

    private static JSONObject berlinConfig() throws Exception {
        return new JSONObject().put("solar", true).put("latitude", 52.52).put("longitude", 13.405);
    }

    private static void clearCache(Context context) {
        context.getSharedPreferences("night_solar", 0).edit().clear().commit();
    }

    private static void awaitRefresh(Context context, JSONObject config, NightSolarTimes.SunRequest request)
            throws InterruptedException {
        var done = new CountDownLatch(1);
        NightSolarTimes.refresh(context, config, true, done::countDown, request);
        assertTrue(done.await(5, TimeUnit.SECONDS));
    }

    private static void assertNear(long expectedSeconds, long actualMillis, long toleranceSeconds) {
        assertEquals(expectedSeconds, actualMillis / 1000.0, toleranceSeconds);
    }
}
