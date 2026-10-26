package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.pm.PackageManager;
import android.os.Build;
import android.os.Bundle;
import io.flutter.embedding.engine.renderer.FlutterRenderer;

final class VideoSurfaceCompatibility {
    static void configure(Context context) {
        if (VideoSurfacePolicy.useGlTexture(Build.VERSION.SDK_INT, Build.MANUFACTURER,
                Build.MODEL, impellerDisabled(context))) {
            FlutterRenderer.debugForceSurfaceProducerGlTextures = true;
        }
    }

    /** Affects new surfaces only; Dart must dispose the failed player before calling. */
    static boolean enableAfterFailure(Context context) {
        if (!VideoSurfacePolicy.canRetryWithGlTexture(Build.VERSION.SDK_INT,
                impellerDisabled(context), FlutterRenderer.debugForceSurfaceProducerGlTextures)) {
            return false;
        }
        // Process-local, monotonic fallback, shared by validation and wallpaper playback.
        // Experimental Flutter 3.47.6 switch; revisit when updating the engine.
        FlutterRenderer.debugForceSurfaceProducerGlTextures = true;
        return true;
    }

    private static boolean impellerDisabled(Context context) {
        try {
            Bundle metadata = context.getPackageManager().getApplicationInfo(
                context.getPackageName(), PackageManager.GET_META_DATA).metaData;
            return metadata != null
                && metadata.containsKey("io.flutter.embedding.android.EnableImpeller")
                && !metadata.getBoolean("io.flutter.embedding.android.EnableImpeller");
        } catch (PackageManager.NameNotFoundException ignored) { return false; }
    }
}
