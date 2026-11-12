package com.leanbitlab.ltvL;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.os.Build;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowManager;

/** A temporary black layer that leaves the current activity focused. */
final class BlackScreenWindow implements AutoCloseable {
    private final Context service;
    private final Runnable visibilityChanged;
    private View window;
    private boolean watchingScreen;
    private record BackPress(int device, long downTime) {}
    private BackPress backPress;
    private final BroadcastReceiver screenOff = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) { close(); }
    };

    BlackScreenWindow(Context service, Runnable visibilityChanged) {
        this.service = service;
        this.visibilityChanged = visibilityChanged;
    }

    boolean isVisible() { return window != null; }

    void toggle() {
        if (window != null) { close(); return; }
        var manager = service.getSystemService(WindowManager.class);
        var view = new View(service);
        view.setBackgroundColor(Color.BLACK);
        view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
        var params = new WindowManager.LayoutParams(WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT, WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN, PixelFormat.OPAQUE);
        if (Build.VERSION.SDK_INT >= 30) {
            params.setFitInsetsTypes(0);
            params.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS;
        } else if (Build.VERSION.SDK_INT >= 28) {
            params.layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
        }
        params.setTitle("CuteLauncher Black Screen");
        service.registerReceiver(screenOff, new IntentFilter(Intent.ACTION_SCREEN_OFF));
        watchingScreen = true;
        try {
            manager.addView(view, params);
            window = view;
        } catch (RuntimeException failure) {
            close();
            throw failure;
        }
        visibilityChanged.run();
    }

    boolean back(KeyEvent event) {
        if (event.getKeyCode() != KeyEvent.KEYCODE_BACK) return false;
        var press = new BackPress(event.getDeviceId(), event.getDownTime());
        if (window != null && event.getAction() == KeyEvent.ACTION_DOWN && event.getRepeatCount() == 0) {
            backPress = press;
        }
        if (!press.equals(backPress)) return false;
        if (event.getAction() == KeyEvent.ACTION_UP) {
            backPress = null;
            if (!event.isCanceled()) close();
        }
        return true;
    }

    @Override public void close() {
        if (watchingScreen) {
            watchingScreen = false;
            service.unregisterReceiver(screenOff);
        }
        if (window != null) {
            View view = window;
            window = null;
            try { service.getSystemService(WindowManager.class).removeViewImmediate(view); }
            catch (IllegalArgumentException alreadyRemoved) { }
            visibilityChanged.run();
        }
    }
}
