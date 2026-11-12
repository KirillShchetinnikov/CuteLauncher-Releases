package com.leanbitlab.ltvL;

import android.content.Context;
import android.graphics.PointF;
import android.view.WindowManager;
import androidx.annotation.Nullable;
import io.flutter.embedding.android.FlutterActivity;
import java.util.HashMap;
import java.util.Map;

/** Centers reported by Home, kept in memory until Home leaves the screen. */
final class OverlayWidgetAnchors {
    static final String VOLUME = "volume";
    static final String TIMER = "sleepTimer";
    private static final Map<String, PointF> latest = new HashMap<>();

    static void record(FlutterActivity activity, String id, int x, int y) {
        if (!VOLUME.equals(id) && !TIMER.equals(id)) return;
        var view = activity.findViewById(FlutterActivity.FLUTTER_VIEW_ID);
        if (view == null || x < 0 || y < 0 || x >= view.getWidth() || y >= view.getHeight()) return;
        var screen = OverlayReadoutLayout.displaySize(activity.getSystemService(WindowManager.class));
        if (screen.x <= 0 || screen.y <= 0) return;
        var origin = new int[2];
        view.getLocationOnScreen(origin);
        float horizontal = (float) (origin[0] + x) / screen.x;
        float vertical = (float) (origin[1] + y) / screen.y;
        if (horizontal < 0 || horizontal > 1 || vertical < 0 || vertical > 1) return;
        var point = new PointF(horizontal, vertical);
        if (!point.equals(latest.put(id, point))) LauncherAccessibilityService.overlayAnchorsChanged();
    }

    @Nullable static PointF center(Context context, String id) {
        var point = latest.get(id);
        if (point != null) return point;
        var prefs = context.getSharedPreferences("overlay_widget_anchors", Context.MODE_PRIVATE);
        float x = prefs.getFloat(id + ".x", -1);
        float y = prefs.getFloat(id + ".y", -1);
        return x >= 0 && x <= 1 && y >= 0 && y <= 1 ? new PointF(x, y) : null;
    }

    static void persist(Context context) {
        if (latest.isEmpty()) return;
        var edit = context.getSharedPreferences("overlay_widget_anchors", Context.MODE_PRIVATE).edit();
        latest.forEach((id, point) -> edit.putFloat(id + ".x", point.x).putFloat(id + ".y", point.y));
        edit.apply();
    }
}
