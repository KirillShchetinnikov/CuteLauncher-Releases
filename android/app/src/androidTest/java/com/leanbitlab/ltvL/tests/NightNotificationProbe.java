package com.leanbitlab.ltvL.tests;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.ComponentName;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.SystemClock;
import android.service.notification.StatusBarNotification;
import org.json.JSONObject;

/** Sends the real PendingIntent and restores configuration; no operator is needed. */
public final class NightNotificationProbe extends Instrumentation {
    @Override public void onCreate(Bundle arguments) { super.onCreate(arguments); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        Context target = getTargetContext();
        SharedPreferences nativePrefs = target.getSharedPreferences("night_overlay", Context.MODE_PRIVATE);
        SharedPreferences flutterPrefs = target.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        String previousNative = nativePrefs.getString("configuration", null);
        String previousFlutter = flutterPrefs.getString("flutter.night_mode_configuration", null);
        boolean passed = false;
        try {
            JSONObject testConfig = new JSONObject().put("enabled", true).put("scheduled", false)
                .put("tclScheduled", false).put("dim", 20).put("warmth", 0)
                .put("temperature", 2700).put("startHour", 22).put("endHour", 7);
            nativePrefs.edit().putString("configuration", testConfig.toString()).commit();
            flutterPrefs.edit().putString("flutter.night_mode_configuration", testConfig.toString()).commit();
            NotificationManager manager = target.getSystemService(NotificationManager.class);
            target.startForegroundService(new Intent().setComponent(new ComponentName(
                target.getPackageName(), "com.leanbitlab.ltvL.NightOverlayService")));
            StatusBarNotification night = null;
            for (int attempt = 0; attempt < 50 && night == null; attempt++) {
                SystemClock.sleep(100);
                for (StatusBarNotification item : manager.getActiveNotifications()) {
                    if (item.getId() == 2401 && item.getPackageName().equals(target.getPackageName())) night = item;
                }
            }
            if (night == null || night.getNotification().actions == null
                    || night.getNotification().actions.length != 1) throw new AssertionError("Night notification/action missing");
            night.getNotification().actions[0].actionIntent.send();
            boolean removed = false;
            for (int i = 0; i < 50; i++) {
                SystemClock.sleep(100);
                removed = true;
                for (StatusBarNotification item : manager.getActiveNotifications()) {
                    if (item.getId() == 2401) removed = false;
                }
                if (removed) break;
            }
            if (!removed) throw new AssertionError("Foreground notification retained after Stop");
            JSONObject nativeConfig = new JSONObject(target.getSharedPreferences("night_overlay", Context.MODE_PRIVATE)
                .getString("configuration", "{}"));
            JSONObject flutterConfig = new JSONObject(target.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getString("flutter.night_mode_configuration", "{}"));
            if (nativeConfig.getBoolean("enabled") || flutterConfig.getBoolean("enabled"))
                throw new AssertionError("Stop did not persist disabled state in both stores");
            report.putString("stream", "\nPASS: real night notification action stopped service and persisted disabled state.\n");
            passed = true;
        } catch (Throwable failure) {
            report.putString("stream", "\nFAIL: " + failure + "\n");
        } finally {
            try {
                target.stopService(new Intent().setComponent(new ComponentName(
                    target.getPackageName(), "com.leanbitlab.ltvL.NightOverlayService")));
                SystemClock.sleep(500);
                restore(nativePrefs, "configuration", previousNative);
                restore(flutterPrefs, "flutter.night_mode_configuration", previousFlutter);
                if (previousNative != null && new JSONObject(previousNative).optBoolean("enabled")) {
                    target.startForegroundService(new Intent().setComponent(new ComponentName(
                        target.getPackageName(), "com.leanbitlab.ltvL.NightOverlayService")));
                }
            } catch (Throwable failure) {
                passed = false;
                report.putString("stream", report.getString("stream") + "RESTORE FAILED: " + failure + "\n");
            }
        }
        finish(passed ? Activity.RESULT_OK : Activity.RESULT_CANCELED, report);
    }

    private static void restore(SharedPreferences prefs, String key, String value) {
        if (value == null) prefs.edit().remove(key).commit();
        else prefs.edit().putString(key, value).commit();
    }
}
