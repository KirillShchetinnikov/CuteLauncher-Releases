package com.leanbitlab.ltvL;

import android.app.Activity;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowInsets;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;

/** IME visibility also covers floating TV keyboards with zero bottom inset. */
final class ImeVisibilityBridge implements EventChannel.StreamHandler {
    private final Activity activity;
    private View observer;
    private Boolean lastVisible;

    private ImeVisibilityBridge(Activity activity) { this.activity = activity; }

    static void register(Activity activity, BinaryMessenger messenger) {
        new EventChannel(messenger, "cutelauncher/ime_visibility")
            .setStreamHandler(new ImeVisibilityBridge(activity));
    }

    @Override public void onListen(Object arguments, EventChannel.EventSink sink) {
        onCancel(null);
        observer = new View(activity);
        observer.setOnApplyWindowInsetsListener((view, insets) -> {
            boolean visible = insets.isVisible(WindowInsets.Type.ime());
            if (lastVisible == null || lastVisible != visible) {
                lastVisible = visible;
                sink.success(visible);
            }
            return insets;
        });
        ((ViewGroup) activity.getWindow().getDecorView()).addView(observer,
            new ViewGroup.LayoutParams(0, 0));
        observer.requestApplyInsets();
    }

    @Override public void onCancel(Object arguments) {
        if (observer != null) {
            observer.setOnApplyWindowInsetsListener(null);
            ((ViewGroup) observer.getParent()).removeView(observer);
            observer = null;
        }
        lastVisible = null;
    }
}
