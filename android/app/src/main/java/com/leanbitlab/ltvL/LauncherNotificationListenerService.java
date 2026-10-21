package com.leanbitlab.ltvL;

import android.app.Notification;
import android.content.pm.PackageManager;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.WindowManager;
import android.service.notification.NotificationListenerService;
import android.service.notification.StatusBarNotification;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import org.json.JSONArray;
import android.widget.LinearLayout;
import android.view.View;

public class LauncherNotificationListenerService extends NotificationListenerService {
    public interface NotificationListener {
        void onNotificationChanged();
    }

    private static final List<NotificationListener> listeners = new ArrayList<>();
    private static LauncherNotificationListenerService instance = null;
    private static boolean leftCorner;
    private static int surfaceColor = 0xFF1C2029, foregroundColor = 0xFFF4F5F8,
            borderColor = 0x1FF4F5F8;
    private static float radius = 24, textSize = 16, popupWidth = 360;
    private final Handler popupHandler = new Handler(Looper.getMainLooper());
    private LinearLayout popupStack;
    private WindowManager popupWindow;
    private WindowManager.LayoutParams popupParams;
    private final NotificationPopupEntries<View> popupEntries = new NotificationPopupEntries<>();
    private final java.util.Set<String> ownNightNotices = new java.util.HashSet<>();

    static void refreshNightFilter() {
        LauncherNotificationListenerService service=instance;
        if (service != null) service.popupHandler.post(() -> {
            if (service.popupStack == null) return;
            for (int i=0;i<service.popupStack.getChildCount();i++)
                service.applyNightFilter(service.popupStack.getChildAt(i));
        });
    }

    static void raiseAboveNightFilter() {
        LauncherNotificationListenerService service=instance;
        if (service != null) service.popupHandler.post(() -> {
            if (service.popupStack == null) return;
            try {
                service.popupWindow.removeViewImmediate(service.popupStack);
                service.popupWindow.addView(service.popupStack,service.popupParams);
            } catch (RuntimeException ignored) { service.clearPopups(); }
        });
    }

    private void applyNightFilter(View card) {
        try {
            org.json.JSONObject c=new org.json.JSONObject(getSharedPreferences("night_overlay",MODE_PRIVATE)
                .getString("configuration","{}"));
            double intensity=NightSchedule.intensity(c,NightSolarTimes.days(this,c),System.currentTimeMillis());
            if (NightOverlayService.popupExcluded()) intensity=0;
            android.graphics.Paint paint=null;
            if (intensity > 0) {
                paint=new android.graphics.Paint();
                paint.setColorFilter(new android.graphics.ColorMatrixColorFilter(NightPopupFilter.matrix(
                    c.optInt("dim",30),c.optInt("warmth",10),c.optInt("temperature",2700),intensity)));
            }
            card.setLayerType(paint == null ? View.LAYER_TYPE_NONE : View.LAYER_TYPE_HARDWARE,paint);
        } catch (RuntimeException | org.json.JSONException ignored) { card.setLayerType(View.LAYER_TYPE_NONE,null); }
    }

    public static void setPresentation(android.content.Context context, Map<String, Object> values) {
        leftCorner = Boolean.TRUE.equals(values.get("left"));
        surfaceColor = ((Number) values.get("background")).intValue();
        foregroundColor = ((Number) values.get("foreground")).intValue();
        borderColor = ((Number) values.get("border")).intValue();
        radius = ((Number) values.get("radius")).floatValue();
        textSize = ((Number) values.get("textSize")).floatValue();
        if (values.get("width") instanceof Number) popupWidth = Math.max(240, Math.min(600, ((Number) values.get("width")).floatValue()));
        context.getSharedPreferences("notification_popup_style", MODE_PRIVATE).edit()
                .putInt("surface", surfaceColor).putInt("foreground", foregroundColor)
                .putInt("border", borderColor).putFloat("radius", radius)
                .putFloat("textSize", textSize).putFloat("width", popupWidth).apply();
        updatePlacement();
    }

    public static void launcherPaused() {
        leftCorner = false;
        updatePlacement();
    }

    private static void updatePlacement() {
        LauncherNotificationListenerService service = instance;
        if (service != null && service.popupStack != null) {
            service.popupParams.width = service.dpToPx(Math.round(popupWidth));
            for (int i = 0; i < service.popupStack.getChildCount(); i++) {
                service.stylePopup(service.popupStack.getChildAt(i));
            }
            service.popupParams.gravity = Gravity.BOTTOM | (leftCorner ? Gravity.LEFT : Gravity.RIGHT);
            try { service.popupWindow.updateViewLayout(service.popupStack, service.popupParams); }
            catch (RuntimeException ignored) { service.clearPopups(); }
        }
    }

    private void clearPopups() {
        popupHandler.removeCallbacksAndMessages(null);
        popupEntries.clear();
        if (popupStack != null && popupWindow != null) {
            try { popupWindow.removeView(popupStack); } catch (RuntimeException ignored) {}
        }
        popupStack = null;
        popupParams = null;
    }

    private void addPopup(String key, View card) {
        try {
            applyNightFilter(card);
            if (popupStack == null) {
                popupWindow = (WindowManager) getSystemService(WINDOW_SERVICE);
                if (popupWindow == null) return;
                popupStack = new LinearLayout(this);
                popupStack.setOrientation(LinearLayout.VERTICAL);
                popupStack.setGravity(Gravity.BOTTOM);
                popupParams = new WindowManager.LayoutParams(dpToPx(Math.round(popupWidth)),
                        WindowManager.LayoutParams.WRAP_CONTENT,
                        WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
                        WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE |
                        WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE,
                        PixelFormat.TRANSLUCENT);
                popupParams.gravity = Gravity.BOTTOM | (leftCorner ? Gravity.LEFT : Gravity.RIGHT);
                popupParams.x = dpToPx(24);
                popupParams.y = dpToPx(24);
                popupWindow.addView(popupStack, popupParams);
            }
            LinearLayout.LayoutParams layout = new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT);
            layout.topMargin = dpToPx(8);
            View previous = popupEntries.replace(key, card);
            int index = previous == null ? -1 : popupStack.indexOfChild(previous);
            if (previous != null) {
                popupHandler.removeCallbacks((Runnable) previous.getTag());
                popupStack.removeView(previous);
            }
            popupStack.addView(card, index, layout);
            Runnable expiry = () -> {
                if (!popupEntries.expire(key, card) || popupStack == null) return;
                popupStack.removeView(card);
                if (popupStack.getChildCount() == 0) clearPopups();
            };
            card.setTag(expiry);
            popupHandler.postDelayed(expiry, 5000);
        } catch (RuntimeException ignored) { clearPopups(); }
    }

    private void stylePopup(View card) {
        android.graphics.drawable.GradientDrawable background = new android.graphics.drawable.GradientDrawable();
        background.setColor(surfaceColor);
        background.setCornerRadius(dpToPx(Math.round(radius)));
        background.setStroke(dpToPx(1), borderColor);
        card.setBackground(background);
        card.setElevation(dpToPx(8));
        stylePopupText(card);
    }

    private void stylePopupText(View view) {
        if (view instanceof android.widget.TextView) {
            android.widget.TextView text = (android.widget.TextView) view;
            text.setTextColor(foregroundColor);
            text.setTextSize(textSize);
        } else if (view instanceof android.view.ViewGroup) {
            android.view.ViewGroup group = (android.view.ViewGroup) view;
            for (int i = 0; i < group.getChildCount(); i++) stylePopupText(group.getChildAt(i));
        }
    }

    private boolean packageBlocked(String packageName, android.content.SharedPreferences prefs) {
        if (!prefs.contains("flutter.notification_popup_blocked_packages") &&
                prefs.contains("flutter.blocked_notification_packages")) return true;
        try {
            JSONArray packages = new JSONArray(prefs.getString(
                    "flutter.notification_popup_blocked_packages", "[]"));
            for (int i = 0; i < packages.length(); i++) {
                if (packageName.equals(packages.optString(i))) return true;
            }
        } catch (org.json.JSONException ignored) {
            return true; // Never reveal notifications when a saved filter is unreadable.
        }
        return false;
    }

    public static void registerListener(NotificationListener listener) {
        synchronized (listeners) {
            listeners.add(listener);
        }
    }

    public static void unregisterListener(NotificationListener listener) {
        synchronized (listeners) {
            listeners.remove(listener);
        }
    }

    public static LauncherNotificationListenerService getInstance() {
        return instance;
    }

    @Override
    public void onCreate() {
        super.onCreate();
        android.content.SharedPreferences style = getSharedPreferences("notification_popup_style", MODE_PRIVATE);
        surfaceColor = style.getInt("surface", surfaceColor);
        foregroundColor = style.getInt("foreground", foregroundColor);
        borderColor = style.getInt("border", borderColor);
        radius = style.getFloat("radius", radius);
        textSize = style.getFloat("textSize", textSize);
        popupWidth = style.getFloat("width", 360);
        instance = this;
        notifyListeners();
    }

    @Override
    public void onDestroy() {
        clearPopups();
        super.onDestroy();
        if (instance == this) {
            instance = null;
        }
        notifyListeners();
    }

    @Override
    public void onNotificationPosted(StatusBarNotification sbn) {
        notifyListeners();
        if (getPackageName().equals(sbn.getPackageName()) &&
                "night_mode".equals(sbn.getNotification().getChannelId()) &&
                !ownNightNotices.add(sbn.getKey())) return;
        showNotificationPopup(sbn);
    }

    @Override public void onListenerConnected() {
        super.onListenerConnected();
        ownNightNotices.clear();
        try {
            for (StatusBarNotification sbn : getActiveNotifications())
                if (getPackageName().equals(sbn.getPackageName()) &&
                    "night_mode".equals(sbn.getNotification().getChannelId())) ownNightNotices.add(sbn.getKey());
        } catch (RuntimeException ignored) {}
    }

    @Override
    public void onNotificationRemoved(StatusBarNotification sbn) {
        ownNightNotices.remove(sbn.getKey());
        notifyListeners();
    }

    private void notifyListeners() {
        synchronized (listeners) {
            for (NotificationListener listener : listeners) {
                listener.onNotificationChanged();
            }
        }
    }

    private boolean canShowPopup() {
        return android.provider.Settings.canDrawOverlays(this);
    }

    private int dpToPx(int dp) {
        return (int) (dp * getResources().getDisplayMetrics().density);
    }

    private void showNotificationPopup(StatusBarNotification sbn) {
        if (sbn == null) {
            return;
        }

        android.content.SharedPreferences prefs = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE);
        boolean enabled = prefs.getBoolean("flutter.system_notifications_popup", false);
        if (!enabled) {
            return;
        }

        if (!canShowPopup()) {
            return;
        }

        android.app.Notification notification = sbn.getNotification();
        if (notification == null) return;
        if (NotificationPopupPolicy.isTvNowPlaying(sbn.getPackageName(),
                notification.getChannelId())) return;

        // Media/service traffic remains excluded from passive popups.
        String category = notification.category;

        Bundle extras = notification.extras;
        if (extras == null) return;

        boolean media = android.app.Notification.CATEGORY_SERVICE.equals(category) ||
                android.app.Notification.CATEGORY_TRANSPORT.equals(category) ||
                extras.containsKey(android.app.Notification.EXTRA_MEDIA_SESSION);

        CharSequence titleChar = extras.getCharSequence(Notification.EXTRA_TITLE);
        CharSequence textChar = extras.getCharSequence(Notification.EXTRA_TEXT);

        final String title = titleChar != null ? titleChar.toString().trim() : "";
        final String text = textChar != null ? textChar.toString().trim() : "";

        if (title.isEmpty() && text.isEmpty()) {
            return;
        }

        final String packageName = sbn.getPackageName();
        boolean blocked = packageBlocked(packageName, prefs);
        boolean hidePersistent = prefs.getBoolean("flutter.hide_persistent_notifications", false);
        final PackageManager pm = getPackageManager();
        String appLabel = packageName;
        Drawable appIcon = null;
        try {
            android.content.pm.ApplicationInfo appInfo = pm.getApplicationInfo(packageName, 0);
            appLabel = pm.getApplicationLabel(appInfo).toString().trim();
            appIcon = pm.getApplicationIcon(appInfo);
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (!NotificationPopupPolicy.shouldShow(enabled, blocked, hidePersistent,
                sbn.isClearable(), media, title, text, appLabel, packageName)) return;

        final String finalAppLabel = appLabel;
        final Drawable finalAppIcon = appIcon;

        popupHandler.post(new Runnable() {
            @Override
            public void run() {
                try {
                    android.widget.LinearLayout container = new android.widget.LinearLayout(LauncherNotificationListenerService.this);
                    container.setOrientation(android.widget.LinearLayout.HORIZONTAL);
                    container.setGravity(Gravity.TOP);
                    int pad = dpToPx(16);
                    container.setPadding(pad, pad, pad, pad);

                    container.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_YES);
                    container.setAccessibilityLiveRegion(View.ACCESSIBILITY_LIVE_REGION_POLITE);

                    android.widget.ImageView iconView = new android.widget.ImageView(LauncherNotificationListenerService.this);
                    if (finalAppIcon != null) {
                        iconView.setImageDrawable(finalAppIcon);
                    }
                    android.widget.LinearLayout.LayoutParams iconParams = new android.widget.LinearLayout.LayoutParams(dpToPx(24), dpToPx(24));
                    iconParams.rightMargin = dpToPx(12);
                    iconView.setLayoutParams(iconParams);
                    container.addView(iconView);

                    android.widget.LinearLayout textContainer = new android.widget.LinearLayout(LauncherNotificationListenerService.this);
                    textContainer.setOrientation(android.widget.LinearLayout.VERTICAL);
                    android.widget.LinearLayout.LayoutParams textContainerParams = new android.widget.LinearLayout.LayoutParams(
                            0,
                            android.widget.LinearLayout.LayoutParams.WRAP_CONTENT, 1
                    );
                    textContainer.setLayoutParams(textContainerParams);

                    android.widget.TextView titleView = new android.widget.TextView(LauncherNotificationListenerService.this);
                    String headerText = finalAppLabel;
                    if (title != null && !title.isEmpty()) {
                        headerText += " • " + title;
                    }
                    titleView.setText(headerText);
                    titleView.setTextColor(foregroundColor);
                    titleView.setTextSize(textSize);
                    titleView.setTypeface(android.graphics.Typeface.DEFAULT_BOLD);
                    textContainer.addView(titleView);

                    if (text != null && !text.isEmpty()) {
                        android.widget.TextView bodyView = new android.widget.TextView(LauncherNotificationListenerService.this);
                        bodyView.setText(text);
                        bodyView.setTextColor(foregroundColor);
                        bodyView.setTextSize(textSize);
                        android.widget.LinearLayout.LayoutParams bodyParams = new android.widget.LinearLayout.LayoutParams(
                                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT,
                                android.widget.LinearLayout.LayoutParams.WRAP_CONTENT
                        );
                        bodyParams.topMargin = dpToPx(4);
                        bodyView.setLayoutParams(bodyParams);
                        textContainer.addView(bodyView);
                    }

                    container.addView(textContainer);

                    stylePopup(container);
                    addPopup(sbn.getKey(), container);

                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        });
    }
}
