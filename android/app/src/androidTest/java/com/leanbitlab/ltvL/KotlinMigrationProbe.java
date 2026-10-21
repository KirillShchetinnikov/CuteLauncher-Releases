package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.sharedpreferences.LegacySharedPreferencesPlugin;
import io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin;
import com.aaassseee.screen_brightness_android.ScreenBrightnessAndroidPlugin;
import java.util.List;
import java.util.Map;

/** Emulator-only plugin smoke test; preferences use a separate disposable file. */
public final class KotlinMigrationProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        MainActivity activity = null;
        try {
            if (!Build.HARDWARE.contains("ranchu") && !Build.HARDWARE.contains("goldfish"))
                throw new IllegalStateException("Emulator required");
            activity = (MainActivity) startActivitySync(new Intent(getTargetContext(), MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            var accessor = io.flutter.embedding.android.FlutterActivity.class.getDeclaredMethod("getFlutterEngine");
            accessor.setAccessible(true);
            var engine = (io.flutter.embedding.engine.FlutterEngine) accessor.invoke(activity);
            if (engine == null || engine.getPlugins().get(SharedPreferencesPlugin.class) == null)
                throw new AssertionError("Kotlin preferences plugin not registered");
            var prefs = getTargetContext().getSharedPreferences("KotlinMigrationProbe", Context.MODE_PRIVATE);
            var legacy = new LegacySharedPreferencesPlugin();
            var field = LegacySharedPreferencesPlugin.class.getDeclaredField("preferences");
            field.setAccessible(true); field.set(legacy, prefs);
            try {
                legacy.setBool("flutter.probe.bool", false);
                legacy.setInt("flutter.probe.int", 19L);
                legacy.setDouble("flutter.probe.double", .42);
                legacy.setString("flutter.probe.string", "Привет");
                String encoded = "VGhpcyBpcyB0aGUgcHJlZml4IGZvciBhIGxpc3Qu![\"a\",\"б\"]";
                legacy.setEncodedStringList("flutter.probe.list", encoded);
                legacy.setDeprecatedStringList("flutter.probe.legacyList", new java.util.ArrayList<>(List.of("old", "список")));
                var restored = legacy.getAll("flutter.probe.", null);
                if (!Boolean.FALSE.equals(restored.get("flutter.probe.bool")) ||
                    !Long.valueOf(19).equals(restored.get("flutter.probe.int")) ||
                    !Double.valueOf(.42).equals(restored.get("flutter.probe.double")) ||
                    !"Привет".equals(restored.get("flutter.probe.string")) ||
                    !encoded.equals(restored.get("flutter.probe.list")) ||
                    !List.of("old", "список").equals(restored.get("flutter.probe.legacyList")))
                    throw new AssertionError("Preference round trip");
            } finally { getTargetContext().deleteSharedPreferences("KotlinMigrationProbe"); }
            var brightness = (ScreenBrightnessAndroidPlugin) engine.getPlugins().get(ScreenBrightnessAndroidPlugin.class);
            if (brightness == null) throw new AssertionError("Brightness plugin not registered");
            MainActivity launched = activity;
            final Throwable[] failure = {null};
            runOnMainSync(() -> {
                float baseline = launched.getWindow().getAttributes().screenBrightness;
                try {
                    Result set = new Result();
                    brightness.onMethodCall(new MethodCall("setApplicationScreenBrightness", Map.of("brightness", .42)), set);
                    if (set.error != null || Math.abs(launched.getWindow().getAttributes().screenBrightness - .42) > .01)
                        throw new AssertionError("Window brightness write");
                    Result reset = new Result();
                    brightness.onMethodCall(new MethodCall("resetApplicationScreenBrightness", null), reset);
                    if (reset.error != null || launched.getWindow().getAttributes().screenBrightness != -1)
                        throw new AssertionError("Window brightness reset");
                } catch (Throwable error) { failure[0] = error; }
                finally {
                    var attributes = launched.getWindow().getAttributes();
                    attributes.screenBrightness = baseline; launched.getWindow().setAttributes(attributes);
                }
            });
            if (failure[0] != null) throw new AssertionError(failure[0]);
            report.putString("stream", "\nPASS: Kotlin plugins registered; preferences round trip; window brightness set/reset\n");
            finish(Activity.RESULT_OK, report);
        } catch (Exception | AssertionError error) {
            report.putString("stream", "\nFAIL: " + error.getClass().getSimpleName() + ": " + error.getMessage() + "\n");
            finish(Activity.RESULT_CANCELED, report);
        } finally {
            if (activity != null) { MainActivity launched = activity; runOnMainSync(launched::finish); }
        }
    }
    private static final class Result implements MethodChannel.Result {
        String error;
        public void success(Object value) { }
        public void error(String code, String message, Object details) { error = code; }
        public void notImplemented() { error = "notImplemented"; }
    }
}
