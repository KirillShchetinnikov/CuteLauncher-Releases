package com.leanbitlab.ltvL;

import android.app.Instrumentation;
import android.os.Bundle;
import android.provider.Settings;

/** Read-only probe: run with HDMI already playing; never launches UI or changes TV settings. */
public final class NightHdmiDetectionProbe extends Instrumentation {
    private boolean expectedHdmi;
    @Override public void onCreate(Bundle arguments) {
        super.onCreate(arguments);
        expectedHdmi = !"false".equals(arguments == null ? null : arguments.getString("expectedHdmi"));
        start();
    }

    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            var context = getTargetContext();
            String foreground = new NightForegroundTracker().read(context, System.currentTimeMillis());
            String device = Settings.Secure.getString(context.getContentResolver(),
                "tcl_sys_tv_input_current_device_id");
            var hdmi = new NightHdmiTracker();
            boolean detected = hdmi.read(context, foreground);
            if (detected != expectedHdmi) throw new AssertionError("Unexpected HDMI state; foreground="
                + foreground + ", device=" + device);
            if (hdmi.read(context, context.getPackageName()) || hdmi.read(context, "com.example.player")
                    || hdmi.read(context, null)) throw new AssertionError("Stale input suppressed another app");
            result.putString("result", "PASS: foreground=" + foreground + ", device=" + device
                + ", HDMI=" + detected + ", unrelated apps not excluded");
            finish(-1, result);
        } catch (Throwable error) {
            result.putString("error", error.toString());
            finish(1, result);
        }
    }
}
