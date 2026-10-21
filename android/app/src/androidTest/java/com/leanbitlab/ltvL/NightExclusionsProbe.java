package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.app.usage.UsageEvents;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import java.util.HashMap;
import java.util.Map;
import org.json.JSONArray;
import org.json.JSONObject;

/** Isolated emulator only; external runner preserves settings before any mutation. */
public final class NightExclusionsProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
    private Map<String,Object> status(Context context, JSONObject config) {
        Map<String,Object> value = new HashMap<>();
        runOnMainSync(() -> value.putAll(NightOverlayService.status(context, config)));
        return value;
    }
    private void await(Context context, JSONObject config, boolean visible, boolean excluded) throws Exception {
        long deadline = System.currentTimeMillis() + 12000;
        do {
            var value = status(context, config);
            if (Boolean.valueOf(visible).equals(value.get("visible")) && Boolean.valueOf(excluded).equals(value.get("excluded"))) return;
            Thread.sleep(200);
        } while (System.currentTimeMillis() < deadline);
        throw new AssertionError("Overlay state " + status(context, config));
    }
    @Override public void onStart() {
        Bundle result = new Bundle();
        Context context = getTargetContext();
        var preferences = context.getSharedPreferences("night_overlay", Context.MODE_PRIVATE);
        String previous = preferences.getString("configuration", null);
        var flutter = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        String previousFlutter = flutter.getString("flutter.night_mode_configuration", null);
        Activity launcher = null;
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"), "Emulator only");
            var tracker = new NightForegroundTracker();
            tracker.accept(UsageEvents.Event.ACTIVITY_RESUMED, "com.example.a");
            tracker.accept(UsageEvents.Event.ACTIVITY_RESUMED, "com.example.b");
            require("com.example.b".equals(tracker.current()), "Latest resumed package");
            tracker.accept(UsageEvents.Event.SCREEN_NON_INTERACTIVE, null);
            require(tracker.current() == null, "Sleep clears foreground");
            require(NightForegroundTracker.allowed(context), "Runner must temporarily grant usage app-op");
            require(OverlayPermission.granted(context), "Runner must temporarily grant overlay app-op");
            launcher = startActivitySync(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            Thread.sleep(1500);
            String settingsPackage = context.getPackageManager().resolveActivity(new Intent(Settings.ACTION_SETTINGS), 0).activityInfo.packageName;
            JSONObject config = new JSONObject().put("enabled", true).put("scheduled", false).put("dim", 30).put("warmth", 0)
                .put("excludedPackages", new JSONArray().put(settingsPackage));
            require(NightOverlayService.valid(config), "Valid exclusions");
            require(!NightOverlayService.valid(new JSONObject(config.toString()).put("excludedPackages", new JSONArray().put("bad-package"))), "Reject malformed package");
            preferences.edit().putString("configuration", config.toString()).commit();
            flutter.edit().putString("flutter.night_mode_configuration", config.toString()).commit();
            context.startForegroundService(new Intent(context, NightOverlayService.class));
            await(context, config, true, false);
            context.startActivity(new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            await(context, config, false, true);
            context.startActivity(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            await(context, config, true, false);
            config.put("enabled", false);
            preferences.edit().putString("configuration", config.toString()).commit();
            context.startForegroundService(new Intent(context, NightOverlayService.class));
            await(context, config, false, false);
            require(!NightSchedule.active(config, new JSONArray(), System.currentTimeMillis(), false), "Manual stop wins");
            result.putString("stream", "\nPASS exclusions, real foreground transitions, restoration, manual stop, validation\n");
        } catch (Throwable error) { result.putString("stream", "\nFAIL " + error + "\n"); }
        finally {
            context.stopService(new Intent(context, NightOverlayService.class));
            if (previous == null) preferences.edit().remove("configuration").commit();
            else preferences.edit().putString("configuration", previous).commit();
            if (previousFlutter == null) flutter.edit().remove("flutter.night_mode_configuration").commit();
            else flutter.edit().putString("flutter.night_mode_configuration", previousFlutter).commit();
            Activity activity = launcher;
            if (activity != null) runOnMainSync(activity::finish);
        }
        finish(result.getString("stream").contains("PASS") ? Activity.RESULT_OK : Activity.RESULT_CANCELED, result);
    }
}
