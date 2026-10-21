package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.os.Bundle;
import java.util.Map;

/** Read-only probe of installed firmware resources and accessible system activities. */
public final class ScreensaverCapabilitiesProbe extends Instrumentation {
    private Bundle arguments;
    @Override public void onCreate(Bundle arguments) {
        this.arguments = arguments;
        start();
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        try {
            Map<String, Boolean> capabilities = new ScreensaverBridge(getContext()).capabilities();
            boolean expectedChoose = Boolean.parseBoolean(arguments.getString("canChoose"));
            boolean expectedStart = Boolean.parseBoolean(arguments.getString("canStart"));
            if (capabilities.get("canChoose") != expectedChoose
                    || capabilities.get("canStart") != expectedStart) {
                throw new AssertionError("Unexpected capabilities: " + capabilities);
            }
            if (Boolean.parseBoolean(arguments.getString("startDream"))
                    && !new ScreensaverBridge(getContext()).startAmbientMode()) {
                throw new AssertionError("System dream launch failed");
            }
            report.putString("stream", "\nPASS screensaver capabilities: " + capabilities + "\n");
            finish(Activity.RESULT_OK, report);
        } catch (Exception | AssertionError error) {
            report.putString("stream", "\nFAIL " + error.getClass().getSimpleName() + ": " + error.getMessage() + "\n");
            finish(Activity.RESULT_CANCELED, report);
        }
    }
}
