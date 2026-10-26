package com.leanbitlab.ltvL;

/** Candidate workaround for the exact device/API combination in the supplied decoder report. */
final class VideoSurfacePolicy {
    static boolean useGlTexture(int sdk, String manufacturer, String model, boolean impellerDisabled) {
        return impellerDisabled && sdk == 30
            && "Droidlogic".equalsIgnoreCase(manufacturer)
            && "X98Q".equalsIgnoreCase(model);
    }

    static boolean canRetryWithGlTexture(int sdk, boolean impellerDisabled, boolean alreadyGl) {
        // API 28 already uses SurfaceTexture. Never enable this Skia workaround with Impeller.
        return sdk >= 29 && impellerDisabled && !alreadyGl;
    }
}
