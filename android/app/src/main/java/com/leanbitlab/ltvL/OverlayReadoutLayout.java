package com.leanbitlab.ltvL;

import android.content.Context;
import android.graphics.Point;
import android.graphics.PointF;
import android.graphics.Rect;
import android.os.Build;
import android.util.Log;
import android.view.WindowManager;
import androidx.annotation.Nullable;

/** Positions both readouts in screen coordinates and resolves their overlap. */
final class OverlayReadoutLayout implements AutoCloseable {
    enum Position {
        widget, topLeft, topRight, bottomLeft, bottomRight;

        static Position parse(@Nullable String value, Position fallback) {
            for (var position : values()) if (position.name().equals(value)) return position;
            return fallback;
        }
    }

    private final Context context;
    private final WindowManager windows;
    final OverlayReadoutWindow volume;
    final OverlayReadoutWindow timer;
    private Point screen;
    private boolean closed;

    OverlayReadoutLayout(Context context) {
        this.context = context;
        windows = context.getSystemService(WindowManager.class);
        volume = new OverlayReadoutWindow(context, windows, "CuteLauncher Volume", Position.topRight, 0, this::refresh);
        timer = new OverlayReadoutWindow(context, windows, "CuteLauncher Sleep Timer",
            Position.topLeft, R.drawable.ic_sleep_timer, this::refresh);
        setPanelStyle(OverlayPanelStyle.load(context));
    }

    void setPanelStyle(OverlayPanelStyle style) {
        volume.setPanelStyle(style);
        timer.setPanelStyle(style);
        refresh();
    }

    void refresh() {
        if (closed || windows == null || !volume.visible() && !timer.visible()) return;
        if (screen == null) screen = displaySize(windows);
        if (screen.x <= 0 || screen.y <= 0) return;
        int gap = dp(12);
        int width = volume.visible() && timer.visible() ? Math.max(1, (screen.x - gap) / 2) : screen.x;
        var volumeBounds = bounds(volume, OverlayWidgetAnchors.VOLUME, screen, width);
        int timerWidth = timer.showsFullLabel() ? screen.x : width;
        var timerBounds = bounds(timer, OverlayWidgetAnchors.TIMER, screen, timerWidth);
        if (volumeBounds != null && timerBounds != null && Rect.intersects(volumeBounds, timerBounds)) {
            if (volumeBounds.width() + timerBounds.width() + gap <= screen.x) {
                separate(volumeBounds, timerBounds, screen.x, gap);
            } else {
                int below = volumeBounds.bottom + gap;
                int above = volumeBounds.top - gap - timerBounds.height();
                int top = below + timerBounds.height() <= screen.y ? below : Math.max(0, above);
                timerBounds.offsetTo(timerBounds.left, top);
            }
        }
        try {
            if (volumeBounds != null) volume.place(volumeBounds);
            if (timerBounds != null) timer.place(timerBounds);
        } catch (RuntimeException unavailable) {
            Log.w("OverlayReadoutLayout", "Unable to place readouts", unavailable);
        }
    }

    @Nullable private Rect bounds(OverlayReadoutWindow window, String id, Point screen, int maxWidth) {
        if (!window.visible()) return null;
        var anchor = window.position() == Position.widget ? OverlayWidgetAnchors.center(context, id) : null;
        var position = window.position() == Position.widget ? window.defaultPosition : window.position();
        return bounds(position, anchor, screen, window.measure(maxWidth, screen.y), dp(48), dp(27));
    }

    static Rect bounds(Position position, @Nullable PointF anchor, Point screen, Point size, int side, int vertical) {
        int x = switch (position) {
            case topRight, bottomRight -> screen.x - side - size.x;
            default -> side;
        };
        int y = switch (position) {
            case bottomLeft, bottomRight -> screen.y - vertical - size.y;
            default -> vertical;
        };
        if (anchor != null) {
            x = Math.round(anchor.x * screen.x - size.x / 2f);
            y = Math.round(anchor.y * screen.y - size.y / 2f);
        }
        x = Math.max(0, Math.min(x, screen.x - size.x));
        y = Math.max(0, Math.min(y, screen.y - size.y));
        return new Rect(x, y, x + size.x, y + size.y);
    }

    static void separate(Rect volume, Rect timer, int screenWidth, int gap) {
        int left = volume.left - gap - timer.width();
        int right = volume.right + gap;
        boolean moveRight = timer.centerX() < screenWidth / 2;
        boolean fitsLeft = left >= 0;
        boolean fitsRight = right + timer.width() <= screenWidth;
        if (fitsLeft || fitsRight) {
            timer.offsetTo(fitsRight && (moveRight || !fitsLeft) ? right : left, timer.top);
        } else if (moveRight) {
            volume.offsetTo(screenWidth - volume.width() - gap - timer.width(), volume.top);
            timer.offsetTo(volume.right + gap, timer.top);
        } else {
            volume.offsetTo(timer.width() + gap, volume.top);
            timer.offsetTo(0, timer.top);
        }
    }

    private int dp(int value) {
        return Math.round(value * context.getResources().getDisplayMetrics().density);
    }

    void configurationChanged() {
        screen = null;
        refresh();
    }

    @SuppressWarnings("deprecation")
    static Point displaySize(@Nullable WindowManager windows) {
        var size = new Point();
        if (windows == null) return size;
        if (Build.VERSION.SDK_INT >= 30) {
            var bounds = windows.getMaximumWindowMetrics().getBounds();
            size.set(bounds.width(), bounds.height());
        } else {
            windows.getDefaultDisplay().getRealSize(size);
        }
        return size;
    }

    @Override public void close() {
        closed = true;
        volume.hide();
        timer.hide();
    }
}
