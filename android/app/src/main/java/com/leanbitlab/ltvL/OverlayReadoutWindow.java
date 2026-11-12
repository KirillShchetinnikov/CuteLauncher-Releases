package com.leanbitlab.ltvL;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.graphics.PixelFormat;
import android.graphics.Point;
import android.graphics.Rect;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.os.Build;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.TextView;
import androidx.annotation.DrawableRes;
import androidx.annotation.NonNull;

/** A compact accessibility overlay that leaves input with the current app. */
final class OverlayReadoutWindow {
    private final Context context;
    private final WindowManager windows;
    private final String title;
    private final int panelIcon;
    final OverlayReadoutLayout.Position defaultPosition;
    private final Runnable changed;
    private OverlayReadoutLayout.Position position;
    private TextView label;
    private WindowManager.LayoutParams params;
    private OverlayPanelStyle panelStyle;
    private boolean dark;

    OverlayReadoutWindow(@NonNull Context context, WindowManager windows, @NonNull String title,
                         OverlayReadoutLayout.Position defaultPosition, @DrawableRes int panelIcon,
                         Runnable changed) {
        this.context = context;
        this.windows = windows;
        this.title = title;
        this.panelIcon = panelIcon;
        this.defaultPosition = defaultPosition;
        this.position = defaultPosition;
        this.changed = changed;
    }

    OverlayReadoutLayout.Position position() { return position; }

    void setPosition(String value) {
        var next = OverlayReadoutLayout.Position.parse(value, defaultPosition);
        if (next == position) return;
        position = next;
        if (visible()) changed.run();
    }

    boolean visible() { return label != null; }

    boolean showsFullLabel() { return !dark && panelIcon != 0; }

    void setPanelStyle(@NonNull OverlayPanelStyle style) {
        if (style.equals(panelStyle)) return;
        panelStyle = style;
        if (visible() && !dark) applyStyle(label);
    }

    void setAppearance(String value) {
        boolean nextDark = "dark".equals(value);
        if (nextDark == dark) return;
        dark = nextDark;
        if (visible()) {
            applyStyle(label);
            changed.run();
        }
    }

    void show(@NonNull String text) {
        if (windows == null) return;
        if (label == null) label = createLabel();
        else if (params != null && text.contentEquals(label.getText())) return;
        label.setText(text);
        changed.run();
    }

    private TextView createLabel() {
        var view = new TextView(context);
        view.setSingleLine(true);
        view.setGravity(Gravity.CENTER);
        view.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO);
        applyStyle(view);
        return view;
    }

    private void applyStyle(@NonNull TextView view) {
        boolean fullLabel = showsFullLabel();
        view.setEllipsize(fullLabel ? null : TextUtils.TruncateAt.END);
        if (!dark) {
            panelStyle.apply(view);
            if (fullLabel) {
                var icon = context.getDrawable(panelIcon).mutate();
                int size = Math.round(view.getTextSize());
                icon.setBounds(0, 0, size, size);
                icon.setTint(view.getCurrentTextColor());
                view.setCompoundDrawablesRelative(null, null, icon, null);
                view.setCompoundDrawablePadding(dp(4));
            }
            return;
        }
        view.setCompoundDrawablesRelative(null, null, null, null);
        view.setTextColor(Color.WHITE);
        view.setTextSize(20);
        view.setTypeface(Typeface.DEFAULT, Typeface.BOLD);
        view.setIncludeFontPadding(true);
        view.setMinimumWidth(dp(64));
        view.setMinimumHeight(0);
        var background = new GradientDrawable();
        background.setColor(0xF2252525);
        background.setCornerRadius(dp(10));
        view.setBackground(background);
        view.setPadding(dp(12), dp(6), dp(12), dp(6));
    }

    Point measure(int width, int height) {
        label.measure(View.MeasureSpec.makeMeasureSpec(width, View.MeasureSpec.AT_MOST),
            View.MeasureSpec.makeMeasureSpec(height, View.MeasureSpec.AT_MOST));
        return new Point(label.getMeasuredWidth(), label.getMeasuredHeight());
    }

    @SuppressLint("RtlHardcoded") // A corner selection is relative to the physical TV screen.
    void place(@NonNull Rect bounds) {
        if (params != null) {
            if (params.x == bounds.left && params.y == bounds.top &&
                    params.width == bounds.width() && params.height == bounds.height()) return;
            params.x = bounds.left;
            params.y = bounds.top;
            params.width = bounds.width();
            params.height = bounds.height();
            windows.updateViewLayout(label, params);
            return;
        }
        var layout = new WindowManager.LayoutParams(bounds.width(), bounds.height(),
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT);
        layout.gravity = Gravity.TOP | Gravity.LEFT;
        layout.x = bounds.left;
        layout.y = bounds.top;
        layout.setTitle(title);
        if (Build.VERSION.SDK_INT >= 30) layout.setFitInsetsTypes(0);
        windows.addView(label, layout);
        params = layout;
    }

    private int dp(int value) {
        return Math.round(value * context.getResources().getDisplayMetrics().density);
    }

    void hide() {
        if (label == null) return;
        var view = label;
        label = null;
        if (params != null) {
            params = null;
            try {
                windows.removeViewImmediate(view);
            } catch (IllegalArgumentException alreadyRemoved) {
                // The system can remove accessibility windows when the service disconnects.
            }
        }
        changed.run();
    }
}
