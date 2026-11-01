package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;

/** Confirms real VPN ownership through the app's existing local ADB authorization. No VPN commands. */
public final class VpnProbe extends Instrumentation {
    private String expected;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args);
        expected = args == null ? "" : args.getString("expectedApp", "");
        start();
    }
    @Override public void onStart() {
        var report = new Bundle();
        try {
            var vpn = new VpnController(getTargetContext());
            var state = vpn.snapshot();
            if (!Boolean.TRUE.equals(state.get("active"))) throw new AssertionError("VPN is not active");
            if (!expected.equals(state.get("owner"))) throw new AssertionError("Active VPN owner not identified");
            if (((String)state.get("activeProfile")).isEmpty()) throw new AssertionError("Active profile not identified");
            if (!expected.equals(vpn.prefs.getString("last", ""))) throw new AssertionError("Detected client not remembered");
            report.putString("stream", "\nPASS: active owner and profile detected; last client remembered; no VPN commands sent\n");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable failure) {
            report.putString("stream", "\nFAIL: " + failure.getMessage() + "\n");
            finish(Activity.RESULT_CANCELED, report);
        }
    }
}
