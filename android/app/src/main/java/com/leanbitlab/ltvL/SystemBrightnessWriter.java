package com.leanbitlab.ltvL;

/** Reports success only after both standard Android brightness settings are written. */
final class SystemBrightnessWriter {
    interface Operation {
        boolean run() throws Exception;
    }

    static boolean apply(int brightness, Operation permission, Operation manualMode, Operation value) {
        if (brightness < 0 || brightness > 255) return false;
        try {
            return permission.run() && manualMode.run() && value.run();
        } catch (Exception error) {
            return false;
        }
    }
}
