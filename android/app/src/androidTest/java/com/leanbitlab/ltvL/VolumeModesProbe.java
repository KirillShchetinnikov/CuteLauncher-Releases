package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.app.UiAutomation;
import android.accessibilityservice.AccessibilityServiceInfo;
import android.content.Intent;
import android.media.AudioManager;
import android.os.Bundle;
import android.os.ParcelFileDescriptor;
import android.os.SystemClock;
import android.provider.Settings;
import android.view.KeyEvent;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;

/** Emulator-only production service test. Restores mappings, volume and accessibility settings. */
public final class VolumeModesProbe extends Instrumentation {
    private UiAutomation automation;
    private int panelId = -1;
    private String shell(String command) throws Exception {
        try (var input = new ParcelFileDescriptor.AutoCloseInputStream(automation.executeShellCommand(command))) {
            return new String(input.readAllBytes(), StandardCharsets.UTF_8).trim();
        }
    }
    private String quote(String value) {
        if (!value.matches("[A-Za-z0-9_./:$-]+")) throw new IllegalArgumentException("Unsafe settings value");
        return value; // UiAutomation executes argv directly, without shell quote processing.
    }
    private boolean filter() {
        var manager = getTargetContext().getSystemService(android.view.accessibility.AccessibilityManager.class);
        for (var info : manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)) {
            if (info.getId().endsWith("/com.leanbitlab.ltvL.LauncherAccessibilityService"))
                return (info.flags & AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS) != 0;
        }
        throw new AssertionError("Service disconnected");
    }
    private LauncherAccessibilityService liveService() throws Exception {
        for (var field : LauncherAccessibilityService.class.getDeclaredFields()) {
            if (java.lang.reflect.Modifier.isStatic(field.getModifiers()) && java.lang.ref.WeakReference.class.isAssignableFrom(field.getType())) {
                field.setAccessible(true);
                Object value = ((java.lang.ref.WeakReference<?>) field.get(null)).get();
                if (value instanceof LauncherAccessibilityService service) return service;
            }
        }
        throw new AssertionError("No live service");
    }
    private void mode(String mode) throws Exception {
        var config = new RemoteMappingConfiguration(true, Map.of(), mode, 3);
        new RemoteMappingStore(getTargetContext()).save(config);
        runOnMainSync(() -> RemoteButtonRemapper.updated(config));
        Thread.sleep(300);
    }
    private boolean visible() { return automation.getWindows().stream().anyMatch(w -> w.getId() == panelId); }
    private static void check(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle(); int result = -1;
        var context = getTargetContext();
        var audio = context.getSystemService(AudioManager.class);
        int originalVolume = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
        String services = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES);
        String enabled = Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ACCESSIBILITY_ENABLED);
        var file = new java.io.File(context.getNoBackupFilesDir(), "remote-mappings");
        byte[] original = null; boolean captured = false;
        var events = new CopyOnWriteArrayList<String>();
        try {
            check(android.os.Build.HARDWARE.contains("ranchu") || android.os.Build.HARDWARE.contains("goldfish"), "Emulator required");
            original = file.exists() ? Files.readAllBytes(file.toPath()) : null; captured = true;
            automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            var automationInfo = automation.getServiceInfo();
            automationInfo.flags |= AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS;
            automation.setServiceInfo(automationInfo);
            automation.setOnAccessibilityEventListener(event -> {
                if ("com.android.systemui".contentEquals(event.getPackageName() == null ? "" : event.getPackageName())
) {
                    panelId = event.getWindowId();
                    var source = event.getSource();
                    events.add(event.getEventType() + ":" + event.getClassName() + " id=" + panelId + " root=" + (source == null ? null : source.getViewIdResourceName()));
                    if (source != null) source.recycle();
                }
            });
            String service = context.getPackageName() + "/com.leanbitlab.ltvL.LauncherAccessibilityService";
            shell("settings put secure enabled_accessibility_services " + quote(service));
            shell("settings put secure accessibility_enabled 1");
            context.startActivity(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            for (int i = 0; i < 60 && !LauncherAccessibilityService.connected(); i++) Thread.sleep(250);
            check(LauncherAccessibilityService.connected(), "Service did not connect");
            mode("auto"); check(filter(), "Initial filter off");
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI);
            Thread.sleep(2200); check(!filter(), "Auto did not recognize panel: " + events);
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI);
            Thread.sleep(1200);
            boolean windowVisible = visible();
            if (windowVisible) check(!filter(), "Auto resumed while volume window still visible");
            shell("am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS");
            for (int i = 0; i < 25 && visible(); i++) Thread.sleep(200);
            Thread.sleep(1200);
            check(!visible(), "Volume panel did not close");
            if (!filter()) {
                var serviceDebug = liveService();
                runOnMainSync(() -> {
                    events.add("SERVICE flags=" + serviceDebug.getServiceInfo().flags + " types=" + serviceDebug.getServiceInfo().eventTypes);
                    for (var window : serviceDebug.getWindows()) events.add("SERVICE window=" + window.getId() + ":" + window.getTitle());
                });
                for (var window : automation.getWindows()) events.add("AUTOMATION window=" + window.getId() + ":" + window.getTitle());
                throw new AssertionError("Auto did not resume after panel closed");
            }
            mode("timed");
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI);
            Thread.sleep(800); check(!filter(), "Timed pause did not start");
            Thread.sleep(2700); check(filter(), "Timed pause did not expire");
            shell("am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"); Thread.sleep(500);
            mode("off");
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_RAISE, AudioManager.FLAG_SHOW_UI);
            Thread.sleep(500); check(filter(), "Off mode paused filter");
            shell("am broadcast -a android.intent.action.CLOSE_SYSTEM_DIALOGS"); Thread.sleep(500);
            mode("repeat");
            boolean fixed = audio.isVolumeFixed();
            if (!fixed) {
                int start = Math.max(1, audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC) / 2);
                audio.setStreamVolume(AudioManager.STREAM_MUSIC, start, 0); Thread.sleep(200);
                // Direct production callback avoids injected events bypassing the accessibility filter.
                var serviceInstance = liveService();
                long directDown = SystemClock.uptimeMillis();
                boolean[] consumed = {false};
                runOnMainSync(() -> consumed[0] = serviceInstance.onKeyEvent(new KeyEvent(directDown, directDown,
                    KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_VOLUME_UP, 0)));
                check(consumed[0], "Repeat mode did not consume DOWN");
                Thread.sleep(700);
                runOnMainSync(() -> serviceInstance.onKeyEvent(new KeyEvent(directDown, SystemClock.uptimeMillis(),
                    KeyEvent.ACTION_UP, KeyEvent.KEYCODE_VOLUME_UP, 0)));
                Thread.sleep(500); // AudioService processes volume adjustments asynchronously.
                int after = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
                check(after > start + 1, "Custom service callback did not repeat volume");
                Thread.sleep(250); check(audio.getStreamVolume(AudioManager.STREAM_MUSIC) == after, "Repeat continued after UP");
            }
            shell("input keyevent KEYCODE_HOME");
            context.startActivity(new Intent(context, MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            boolean launched = false;
            for (int i = 0; i < 50; i++) {
                var root = automation.getRootInActiveWindow();
                if (root != null && context.getPackageName().contentEquals(root.getPackageName())) { launched = true; break; }
                Thread.sleep(200);
            }
            check(launched, "Launcher did not return after Home/Back");
            report.putString("result", "PASS: auto visibility=" + windowVisible + ", timed, off, repeat fixedVolume=" + fixed + ", repeat via production callback, Home/Back/relaunch");
        } catch (Throwable error) { result = 0; report.putString("result", "FAIL: " + error + " events=" + events); }
        finally {
            try {
                if (captured) {
                    if (original == null) new android.util.AtomicFile(file).delete(); else Files.write(file.toPath(), original);
                    var restored = new RemoteMappingStore(context).load();
                    runOnMainSync(() -> RemoteButtonRemapper.updated(restored));
                }
                audio.setStreamVolume(AudioManager.STREAM_MUSIC, originalVolume, 0);
                if (automation != null) {
                    automation.setOnAccessibilityEventListener(null);
                    shell(services == null ? "settings delete secure enabled_accessibility_services" :
                        "settings put secure enabled_accessibility_services " + quote(services));
                    shell(enabled == null ? "settings delete secure accessibility_enabled" :
                        "settings put secure accessibility_enabled " + quote(enabled));
                }
            } catch (Throwable error) { result = 0; report.putString("cleanup", "FAIL: " + error); }
        }
        finish(result, report);
    }
}
