package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.app.UiAutomation;
import android.media.AudioManager;
import android.os.Bundle;
import android.content.Intent;
import android.accessibilityservice.AccessibilityServiceInfo;
import java.util.concurrent.CopyOnWriteArrayList;

/** Identify OEM panel events; restore the original media volume in all cases. */
public final class VolumePanelEventProbe extends Instrumentation {
    private boolean filtering() throws Exception {
        var manager = getTargetContext().getSystemService(android.view.accessibility.AccessibilityManager.class);
        for (var info : manager.getEnabledAccessibilityServiceList(AccessibilityServiceInfo.FEEDBACK_ALL_MASK)) {
            if (info.getId().endsWith("/com.leanbitlab.ltvL.LauncherAccessibilityService"))
                return (info.flags & AccessibilityServiceInfo.FLAG_REQUEST_FILTER_KEY_EVENTS) != 0;
        }
        throw new AssertionError("Service disconnected");
    }
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        var audio = getTargetContext().getSystemService(AudioManager.class);
        int before = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
        int resultCode = -1;
        try {
            getTargetContext().startActivity(new Intent(getTargetContext(), MainActivity.class).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
            for (int i = 0; i < 40 && !LauncherAccessibilityService.connected(); i++) Thread.sleep(250);
            if (!filtering()) throw new AssertionError("Initial filter must be enabled");
            var observed = new CopyOnWriteArrayList<String>();
            var automation = getUiAutomation(UiAutomation.FLAG_DONT_SUPPRESS_ACCESSIBILITY_SERVICES);
            automation.setOnAccessibilityEventListener(event -> {
                if ("com.android.systemui".contentEquals(event.getPackageName() == null ? "" : event.getPackageName()))
                    observed.add(event.getEventType() + ":" + event.getClassName());
            });
            Thread.sleep(500);
            audio.adjustStreamVolume(AudioManager.STREAM_MUSIC,
                    before < audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                        ? AudioManager.ADJUST_RAISE : AudioManager.ADJUST_LOWER, AudioManager.FLAG_SHOW_UI);
            Thread.sleep(1000);
            automation.setOnAccessibilityEventListener(null);
            if (observed.isEmpty()) throw new AssertionError("No accessibility events");
            report.putString("events", observed.toString());
            if (filtering()) throw new AssertionError("Volume panel did not pause filtering");
            Thread.sleep(5500);
            if (!filtering()) throw new AssertionError("Filter did not recover");
            report.putString("result", "PASS: real TCL panel pauses native service filter and restores it");
        } catch (Throwable error) {
            resultCode = 0;
            report.putString("result", "FAIL: " + error);
        } finally {
            audio.setStreamVolume(AudioManager.STREAM_MUSIC, before, 0);
        }
        if (audio.getStreamVolume(AudioManager.STREAM_MUSIC) != before) {
            resultCode = 0; report.putString("result", "FAIL: original volume was not restored");
        }
        finish(resultCode, report);
    }
}
