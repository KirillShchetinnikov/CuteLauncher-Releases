package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.os.Bundle;
import android.os.PowerManager;
import org.json.JSONObject;

/** Read-only OEM check: never changes the exemption, HOME, or night configuration. */
public final class BatteryOptimizationProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            var context = getTargetContext();
            var power = context.getSystemService(PowerManager.class);
            boolean expected = power.isIgnoringBatteryOptimizations(context.getPackageName());
            Object actual = NightOverlayService.status(context, new JSONObject()).get("batteryExempt");
            if (!Boolean.valueOf(expected).equals(actual)) throw new AssertionError("Exemption mismatch");
            report.putString("result", "PASS: exempt=" + actual
                + ", settingsAvailable=" + NightOverlayService.batterySettingsAvailable(context));
            finish(-1, report);
        } catch (Throwable error) {
            report.putString("result", "FAIL: " + error);
            finish(0, report);
        }
    }
}
