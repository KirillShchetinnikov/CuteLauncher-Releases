package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import java.lang.ref.WeakReference;
import java.lang.reflect.Field;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.TimeUnit;
import org.json.JSONArray;
import org.json.JSONObject;

/** Emulator-only regression: pending picture-mode reads must not remove an existing window. */
public final class NightFilterContinuityProbe extends Instrumentation {
    private Bundle names;
    private static void require(boolean value, String message) {
        if (!value) throw new AssertionError(message);
    }
    private Field field(String name) throws Exception {
        Field value = NightOverlayService.class.getDeclaredField(names.getString(name, name));
        value.setAccessible(true);
        return value;
    }
    private NightOverlayService service() throws Exception {
        return (NightOverlayService)((WeakReference<?>)field("activeService").get(null)).get();
    }
    private Object window(NightOverlayService service) throws Exception {
        Object[] value = new Object[1];
        Field overlay = field("overlay");
        runOnMainSync(() -> {
            try { value[0] = overlay.get(service); }
            catch (Exception error) { throw new AssertionError(error); }
        });
        return value[0];
    }
    private void configure(NightOverlayService service, JSONObject config) throws Exception {
        Field configuration = field("config");
        var refresh = NightOverlayService.class.getDeclaredMethod(names.getString("refresh", "refresh"));
        refresh.setAccessible(true);
        runOnMainSync(() -> {
            try { configuration.set(service, config); refresh.invoke(service); }
            catch (Exception error) { throw new AssertionError(error); }
        });
    }
    // Release runners supply reflected member names from this APK's R8 mapping.
    @Override public void onCreate(Bundle args) { super.onCreate(args); names = args; start(); }
    @Override public void onStart() {
        Bundle result = new Bundle();
        Context context = getTargetContext();
        var nativePrefs = context.getSharedPreferences("night_overlay", Context.MODE_PRIVATE);
        var flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE);
        String previous = nativePrefs.getString("configuration", null);
        String previousFlutter = flutterPrefs.getString("flutter.night_mode_configuration", null);
        CountDownLatch releaseWorker = new CountDownLatch(1);
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"), "Emulator only");
            require(OverlayPermission.granted(context), "Runner must grant overlay app-op");
            JSONObject config = new JSONObject().put("enabled", true).put("scheduled", false)
                .put("dim", 30).put("warmth", 0).put("tclScheduled", false)
                .put("ignoreHdmiInputs", false).put("ignoredPictureModes", new JSONArray().put(255));
            nativePrefs.edit().putString("configuration", config.toString()).commit();
            flutterPrefs.edit().putString("flutter.night_mode_configuration", config.toString()).commit();
            // HOME may already have created this singleTask activity before instrumentation starts.
            context.startActivity(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            context.startForegroundService(new Intent(context, NightOverlayService.class));
            long deadline = System.currentTimeMillis() + 15000;
            NightOverlayService service;
            do {
                Thread.sleep(100);
                service = service();
            } while ((service == null || window(service) == null) && System.currentTimeMillis() < deadline);
            require(service != null && window(service) != null, "Initial picture read enables filter");
            Object originalWindow = window(service);
            ExecutorService worker = (ExecutorService)field("worker").get(service);
            CountDownLatch blocked = new CountDownLatch(1);
            worker.execute(() -> {
                blocked.countDown();
                try { releaseWorker.await(20, TimeUnit.SECONDS); }
                catch (InterruptedException error) { Thread.currentThread().interrupt(); }
            });
            require(blocked.await(5, TimeUnit.SECONDS), "Worker blocked for deterministic pending read");
            // Home/resume sends the same values in a new JSONObject.
            configure(service, new JSONObject(config.toString()));
            require(window(service) == originalWindow, "Home resync must retain existing window");
            config.put("ignoredPictureModes", new JSONArray().put(254).put(255));
            configure(service, new JSONObject(config.toString()));
            require(window(service) == originalWindow, "Changing unrelated picture exclusions must retain window");
            Thread.sleep(250);
            require(window(service) == originalWindow, "Pending worker must not cause a bright gap");
            releaseWorker.countDown();
            Thread.sleep(2500);
            require(window(service) == originalWindow, "Completed read updates the same window");
            for (String key : new String[]{"KEYCODE_HOME", "KEYCODE_BACK"}) {
                try (var command = getUiAutomation().executeShellCommand("input keyevent " + key);
                     var output = new java.io.FileInputStream(command.getFileDescriptor())) {
                    output.readAllBytes();
                }
                Thread.sleep(750);
                require(window(service) == originalWindow, key + " must retain the same filter window");
            }
            config.put("enabled", false);
            configure(service, config);
            require(window(service) == null, "Manual disable still removes filter immediately");
            result.putString("stream", "\nPASS Home resync, picture exclusions, pending/completed reads, Home/Back keys, manual disable\n");
        } catch (Throwable error) {
            result.putString("stream", "\nFAIL " + error + "\n");
        } finally {
            releaseWorker.countDown();
            context.stopService(new Intent(context, NightOverlayService.class));
            if (previous == null) nativePrefs.edit().remove("configuration").commit();
            else nativePrefs.edit().putString("configuration", previous).commit();
            if (previousFlutter == null) flutterPrefs.edit().remove("flutter.night_mode_configuration").commit();
            else flutterPrefs.edit().putString("flutter.night_mode_configuration", previousFlutter).commit();
        }
        finish(result.getString("stream").contains("PASS") ? Activity.RESULT_OK : Activity.RESULT_CANCELED, result);
    }
}
