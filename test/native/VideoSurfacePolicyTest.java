package com.leanbitlab.ltvL;

public final class VideoSurfacePolicyTest {
    public static void main(String[] args) {
        check(true, 30, "Droidlogic", "X98Q", true);
        check(true, 30, "droidlogic", "x98q", true);
        check(false, 30, "Droidlogic", "X98Q", false);
        check(false, 29, "Droidlogic", "X98Q", true);
        check(false, 31, "Droidlogic", "X98Q", true);
        check(false, 30, "TCL", "Smart TV Pro", true);
        check(false, 30, "Droidlogic", "Other", true);
        check(false, 30, null, null, true);
        retry(true, 29, true, false);
        retry(true, 30, true, false);
        retry(true, 36, true, false);
        retry(false, 28, true, false);
        retry(false, 30, false, false);
        retry(false, 30, true, true);
        System.out.println("VideoSurfacePolicy: 14 cases passed");
    }
    static void check(boolean expected, int sdk, String maker, String model, boolean disabled) {
        if (VideoSurfacePolicy.useGlTexture(sdk, maker, model, disabled) != expected)
            throw new AssertionError(sdk + ":" + maker + ":" + model);
    }
    static void retry(boolean expected, int sdk, boolean disabled, boolean alreadyGl) {
        if (VideoSurfacePolicy.canRetryWithGlTexture(sdk, disabled, alreadyGl) != expected)
            throw new AssertionError("retry:" + sdk + ":" + disabled + ":" + alreadyGl);
    }
}
