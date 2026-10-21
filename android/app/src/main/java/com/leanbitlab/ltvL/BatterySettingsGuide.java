package com.leanbitlab.ltvL;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.PixelFormat;
import android.graphics.drawable.GradientDrawable;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;
import java.util.Map;

/** Short-lived, passive instructions above the OEM Apps settings. */
final class BatterySettingsGuide {
    private static java.lang.ref.WeakReference<BatterySettingsGuide> instance = new java.lang.ref.WeakReference<>(null);
    private final Activity activity;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final WindowManager windows;
    private final LinearLayout panel;
    private boolean registered;
    private final BroadcastReceiver screenOff = new BroadcastReceiver() {
        @Override public void onReceive(Context context, Intent intent) { close(activity); }
    };

    static boolean show(Activity activity, Map<String, Object> labels) {
        close(activity);
        if (!OverlayPermission.granted(activity) || labels == null
                || !(labels.get("hint") instanceof String)) return false;
        BatterySettingsGuide guide = new BatterySettingsGuide(activity);
        try {
            guide.attach(labels);
            instance = new java.lang.ref.WeakReference<>(guide);
            return true;
        } catch (RuntimeException error) {
            guide.remove();
            return false;
        }
    }

    static void close(Activity activity) {
        BatterySettingsGuide guide = instance.get();
        if (guide != null && guide.activity == activity) {
            guide.remove();
            instance.clear();
        }
    }

    private BatterySettingsGuide(Activity activity) {
        this.activity = activity;
        windows = activity.getSystemService(WindowManager.class);
        panel = new LinearLayout(activity);
    }

    private int dp(int value) { return Math.round(value * activity.getResources().getDisplayMetrics().density); }
    private int color(Map<String, Object> labels, String key, int fallback) {
        Object value = labels.get(key);
        return value instanceof Number ? ((Number) value).intValue() : fallback;
    }
    private void text(Map<String, Object> labels, String key, int size) {
        Object value = labels.get(key);
        if (!(value instanceof String) || ((String) value).length() > 2000) throw new IllegalArgumentException();
        TextView text = new TextView(activity);
        text.setText((String) value);
        text.setTextColor(color(labels, "text", 0xffeeeeee));
        text.setTextSize(size);
        panel.addView(text);
    }
    private void attach(Map<String, Object> labels) {
        panel.setOrientation(LinearLayout.VERTICAL);
        panel.setPadding(dp(16), dp(12), dp(16), dp(12));
        GradientDrawable background = new GradientDrawable();
        background.setColor(color(labels, "surface", 0xff202530));
        background.setCornerRadius(dp(20));
        background.setStroke(dp(2), color(labels, "primary", 0xffffcc80));
        panel.setBackground(background);
        text(labels, "title", 18);
        text(labels, "hint", 14);
        var metrics = activity.getResources().getDisplayMetrics();
        var params = new WindowManager.LayoutParams(Math.min(dp(340), metrics.widthPixels / 3),
            WindowManager.LayoutParams.WRAP_CONTENT, WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
            PixelFormat.TRANSLUCENT);
        params.gravity = Gravity.END | Gravity.CENTER_VERTICAL;
        params.x = dp(24);
        params.setTitle("CuteLauncher battery settings guide");
        windows.addView(panel, params);
        if (android.os.Build.VERSION.SDK_INT >= 33) {
            activity.registerReceiver(screenOff, new IntentFilter(Intent.ACTION_SCREEN_OFF), Context.RECEIVER_NOT_EXPORTED);
        } else {
            activity.registerReceiver(screenOff, new IntentFilter(Intent.ACTION_SCREEN_OFF));
        }
        registered = true;
        main.postDelayed(() -> close(activity), 120000);
    }
    private void remove() {
        main.removeCallbacksAndMessages(null);
        if (registered) {
            activity.unregisterReceiver(screenOff);
            registered = false;
        }
        try { windows.removeView(panel); } catch (RuntimeException ignored) {}
    }
}
