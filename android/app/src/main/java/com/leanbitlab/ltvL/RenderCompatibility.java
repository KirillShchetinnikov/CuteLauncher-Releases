package com.leanbitlab.ltvL;

import android.content.Context;
import android.os.Build;
import java.io.IOException;

/** Device-local preference: deliberately outside Flutter backup/sync settings. */
final class RenderCompatibility {
    private static final String PREFS = "render_compatibility";

    static boolean automatic() {
        return "SEI Robotics".equals(Build.MANUFACTURER) && "KP1".equals(Build.MODEL)
                && "amlogic".equals(Build.HARDWARE);
    }

    static boolean enabled(Context context) {
        return automatic() || context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getBoolean("enabled", false);
    }

    // Called on the IO worker; report a failed durable save instead of restarting.
    @android.annotation.SuppressLint("ApplySharedPref")
    static void save(Context context, boolean enabled) throws IOException {
        if (automatic()) return;
        if (!context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putBoolean("enabled", enabled).commit()) {
            throw new IOException("Unable to save render compatibility");
        }
    }
}
