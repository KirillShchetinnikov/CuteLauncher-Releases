package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.graphics.Typeface;
import android.graphics.drawable.GradientDrawable;
import android.util.TypedValue;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import org.json.JSONException;
import org.json.JSONObject;

/** The appearance of a resting top panel item, resolved by Flutter Home. */
record OverlayPanelStyle(int foreground, int background, @Nullable Integer gradientEnd,
                         int border, float borderWidth, float radius, float textSize,
                         float height, float horizontalPadding, @Nullable String font) {
    private static final String PREFS = "overlay_panel_style";
    private static final String KEY = "appearance";
    private static final OverlayPanelStyle DEFAULT = new OverlayPanelStyle(
        Color.WHITE, 0xFF242935, null, Color.TRANSPARENT, 2, 16, 18, 39, 10, "sans.ttf");

    @NonNull private static SharedPreferences preferences(@NonNull Context context) {
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE);
    }

    @NonNull static OverlayPanelStyle load(@NonNull Context context) {
        return decode(preferences(context).getString(KEY, null));
    }

    static void record(@NonNull Context context, @Nullable String encoded) {
        if (encoded == null || encoded.length() > 1024) return;
        var prefs = preferences(context);
        if (encoded.equals(prefs.getString(KEY, null))) return;
        prefs.edit().putString(KEY, encoded).apply();
        LauncherAccessibilityService.overlayPanelStyleChanged(decode(encoded));
    }

    @NonNull private static OverlayPanelStyle decode(@Nullable String encoded) {
        if (encoded == null) return DEFAULT;
        try {
            var value = new JSONObject(encoded);
            return new OverlayPanelStyle(
                (int) value.getLong("foreground"), (int) value.getLong("background"),
                value.isNull("gradientEnd") ? null : (int) value.getLong("gradientEnd"),
                (int) value.getLong("border"), dimension(value, "borderWidth", 0, 16),
                dimension(value, "radius", 0, 128), dimension(value, "textSize", 1, 200),
                dimension(value, "height", 1, 352), dimension(value, "horizontalPadding", 0, 32),
                value.isNull("font") ? null : value.getString("font"));
        } catch (JSONException malformed) {
            return DEFAULT;
        }
    }

    private static float dimension(@NonNull JSONObject style, @NonNull String key, float min, float max)
            throws JSONException {
        double value = style.getDouble(key);
        if (!Double.isFinite(value)) throw new JSONException(key);
        return (float) Math.max(min, Math.min(max, value));
    }

    void apply(@NonNull TextView label) {
        float density = label.getResources().getDisplayMetrics().density;
        label.setTextColor(foreground);
        // Flutter has already applied the panel's text scaler.
        label.setTextSize(TypedValue.COMPLEX_UNIT_DIP, textSize);
        label.setTypeface(typeface(label.getContext()));
        label.setIncludeFontPadding(false);
        label.setMinimumWidth(0);
        label.setMinimumHeight(Math.round(height * density));
        var drawable = new GradientDrawable();
        if (gradientEnd == null) {
            drawable.setColor(background);
        } else {
            drawable.setOrientation(GradientDrawable.Orientation.TL_BR);
            drawable.setColors(new int[] {background, gradientEnd});
        }
        drawable.setCornerRadius(radius * density);
        drawable.setStroke(Math.round(borderWidth * density), border);
        label.setBackground(drawable);
        int padding = Math.round(horizontalPadding * density);
        label.setPadding(padding, 0, padding, 0);
    }

    @NonNull private Typeface typeface(@NonNull Context context) {
        if (font != null && font.matches("[a-z0-9-]+\\.ttf")) {
            try {
                return Typeface.createFromAsset(context.getAssets(), "flutter_assets/assets/fonts/" + font);
            } catch (RuntimeException unavailable) {
                // System font is also used for the panel's system font choice.
            }
        }
        return Typeface.DEFAULT;
    }
}
