package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Build;
import android.os.Bundle;
import java.io.File;
import java.nio.file.Files;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.json.JSONArray;
import org.json.JSONObject;

/** Emulator-only offline fixtures; run the normal launcher between prepare and inspect. */
public final class OfflineStartupProbe extends Instrumentation {
    private Bundle arguments;
    private static final String[] STORES = {"FlutterSharedPreferences", "night_overlay", "night_solar"};
    @Override public void onCreate(Bundle args) { super.onCreate(args); arguments = args; start(); }
    private static void require(boolean value, String message) { if (!value) throw new AssertionError(message); }
    private String shell(String command) throws Exception {
        try (var descriptor = getUiAutomation().executeShellCommand(command);
             var input = new android.os.ParcelFileDescriptor.AutoCloseInputStream(descriptor)) {
            return new String(input.readAllBytes(), java.nio.charset.StandardCharsets.UTF_8);
        }
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            require(Build.HARDWARE.contains("ranchu") || Build.HARDWARE.contains("goldfish"), "Emulator required");
            Context context = getTargetContext();
            File backup = new File(context.getNoBackupFilesDir(), "offline-startup-original.json");
            String phase = arguments.getString("phase", "inspect");
            if (phase.equals("restore")) {
                JSONObject original = new JSONObject(new String(Files.readAllBytes(backup.toPath()), java.nio.charset.StandardCharsets.UTF_8));
                context.stopService(new Intent(context, NightOverlayService.class));
                for (String store : STORES) {
                    SharedPreferences.Editor edit = context.getSharedPreferences(store, 0).edit().clear();
                    JSONObject values = original.getJSONObject(store);
                    for (var keys = values.keys(); keys.hasNext();) {
                        String key = keys.next(); JSONObject entry = values.getJSONObject(key);
                        switch (entry.getString("type")) {
                            case "String": edit.putString(key, entry.getString("value")); break;
                            case "Boolean": edit.putBoolean(key, entry.getBoolean("value")); break;
                            case "Integer": edit.putInt(key, entry.getInt("value")); break;
                            case "Long": edit.putLong(key, entry.getLong("value")); break;
                            case "Float": edit.putFloat(key, (float)entry.getDouble("value")); break;
                            default: throw new AssertionError("Unsupported preference type");
                        }
                    }
                    require(edit.commit(), "Restore failed: " + store);
                }
                Files.delete(backup.toPath());
            } else {
                require(shell("cmd connectivity get-chain3-enabled").contains("chain:enabled")
                    && shell("cmd connectivity get-package-networking-enabled " + context.getPackageName()).contains(":deny"),
                    "Launcher internet must be blocked inside Android");
                if (phase.startsWith("prepare-")) {
                    if (!backup.exists()) {
                        JSONObject original = new JSONObject();
                        for (String store : STORES) {
                            JSONObject values = new JSONObject();
                            for (var entry : context.getSharedPreferences(store, 0).getAll().entrySet()) {
                                Object value = entry.getValue();
                                require(value instanceof String || value instanceof Number || value instanceof Boolean,
                                    "Unsupported preference type");
                                values.put(entry.getKey(), new JSONObject().put("type", value.getClass().getSimpleName()).put("value", value));
                            }
                            original.put(store, values);
                        }
                        Files.write(backup.toPath(), original.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8));
                    }
                    JSONObject config = new JSONObject().put("enabled", true).put("scheduled", true).put("solar", true)
                        .put("latitude", 55.75).put("longitude", 37.62).put("city", "Offline test")
                        .put("dim", 30).put("warmth", 10).put("transitionMinutes", 60).put("tclScheduled", false);
                    require(NightOverlayService.valid(config), "Invalid fixture configuration");
                    context.getSharedPreferences("FlutterSharedPreferences", 0).edit()
                        .putString("flutter.night_mode_configuration", config.toString()).putString("flutter.app_language", "ru").commit();
                    context.getSharedPreferences("night_overlay", 0).edit().putString("configuration", config.toString()).commit();
                    var solar = context.getSharedPreferences("night_solar", 0).edit().clear();
                    if (phase.equals("prepare-history")) {
                        LocalDate yesterday = LocalDate.now().minusDays(1); ZoneId zone = ZoneId.systemDefault();
                        JSONObject day = new JSONObject().put("sunrise", yesterday.atTime(7, 15).atZone(zone).toInstant().toEpochMilli())
                            .put("sunset", yesterday.atTime(18, 45).atZone(zone).toInstant().toEpochMilli());
                        solar.putString("cache", new JSONObject().put("key", NightSolarTimes.key(config))
                            .put("updated", System.currentTimeMillis()-172800000L).put("days", new JSONArray().put(day)).toString());
                    }
                    require(solar.commit(), "Fixture cache write failed");
                } else if (phase.equals("inspect")) {
                    JSONObject config = new JSONObject(context.getSharedPreferences("night_overlay", 0).getString("configuration", "{}"));
                    var prefs = context.getSharedPreferences("night_solar", 0);
                    String history = prefs.getString("cache", null);
                    boolean cached = "history".equals(arguments.getString("scenario"));
                    long now = System.currentTimeMillis();
                    JSONArray days = NightSolarTimes.days(context, config);
                    var today = days.getJSONObject(2); ZoneId zone = ZoneId.systemDefault(); LocalDate date = LocalDate.now();
                    require(today.getLong("sunrise") == date.atTime(cached?7:8, cached?15:0).atZone(zone).toInstant().toEpochMilli(), "Wrong sunrise");
                    require(today.getLong("sunset") == date.atTime(cached?18:20, cached?45:0).atZone(zone).toInstant().toEpochMilli(), "Wrong sunset");
                    require(NightSchedule.next(config, days, now, true) > now, "No next night start");
                    require(NightSchedule.next(config, days, now, false) > now, "No next night end");
                    require(NightSchedule.intensity(config, days, date.atTime(22,0).atZone(zone).toInstant().toEpochMilli()) == 1, "Night inactive");
                    require(NightSchedule.intensity(config, days, date.atTime(12,0).atZone(zone).toInstant().toEpochMilli()) == 0, "Day active");
                    CountDownLatch completed = new CountDownLatch(1);
                    NightSolarTimes.refresh(context, config, true, completed::countDown);
                    require(completed.await(45, TimeUnit.SECONDS), "Real offline request did not finish");
                    require(java.util.Objects.equals(history, prefs.getString("cache", null)), "Network error replaced history");
                    report.putString("solar", today.toString());
                    report.putString("status", new JSONObject(NightOverlayService.status(context, config)).toString());
                } else throw new IllegalArgumentException("Unknown phase");
            }
            report.putString("stream", "\nPASS offline " + phase + "\n"); finish(Activity.RESULT_OK, report);
        } catch (Throwable error) {
            report.putString("stream", "\nFAIL offline: " + error + "\n"); finish(Activity.RESULT_CANCELED, report);
        }
    }
}
