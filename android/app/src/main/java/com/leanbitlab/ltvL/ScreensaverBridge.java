package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.content.res.Resources;
import android.content.res.XmlResourceParser;
import android.os.Build;
import android.os.UserManager;
import android.provider.Settings;
import java.util.Map;
import org.xmlpull.v1.XmlPullParser;

/** System selection and system launch are independent capabilities. */
final class ScreensaverBridge {
    private static final String TV_SETTINGS = "com.android.tv.settings";
    private static final String DREAM_ACTIVITY =
            "com.android.tv.settings.device.display.daydream.DaydreamActivity";
    private static final String START_DREAM = "com.google.android.pano.action.SLEEP";
    private final Context context;

    ScreensaverBridge(Context context) { this.context = context; }

    Map<String, Boolean> capabilities() {
        return Map.of("canChoose", selectionIntent() != null,
                "canStart", launchIntent() != null && dreamsEnabled());
    }

    boolean openSettings() { return start(selectionIntent()); }

    boolean startAmbientMode() {
        return dreamsEnabled() && start(launchIntent());
    }

    private boolean dreamsEnabled() {
        try {
            return Settings.Secure.getInt(context.getContentResolver(), "screensaver_enabled", 1) != 0;
        } catch (SecurityException ignored) { return false; }
    }

    // TV Settings uses this hidden restriction key; there is no public SDK constant.
    @android.annotation.SuppressLint("WrongConstant")
    private Intent selectionIntent() {
        UserManager users = context.getSystemService(UserManager.class);
        if (users != null && users.hasUserRestriction("no_config_screen_timeout")) return null;
        Intent tv = new Intent(Intent.ACTION_MAIN).setClassName(TV_SETTINGS, DREAM_ACTIVITY);
        if (accessible(tv)) {
            // The same exported activity exists on Google TV but uses a menu without a picker.
            // Read the live resources, including OEM overlays, rather than the launcher brand.
            return tvMenuHasPicker() ? tv : null;
        }
        Intent standard = new Intent(Settings.ACTION_DREAM_SETTINGS);
        return accessible(standard) ? standard : null;
    }

    // Resource IDs belong to the installed TV Settings package and its OEM overlays.
    @android.annotation.SuppressLint("DiscouragedApi")
    private boolean tvMenuHasPicker() {
        try {
            Resources resources = context.getPackageManager().getResourcesForApplication(TV_SETTINGS);
            int flavorId = resources.getIdentifier("config_tvSettingsFlavor", "string", TV_SETTINGS);
            if (flavorId == 0) return false;
            String flavor = resources.getString(flavorId);
            String menu;
            if ("Classic".equals(flavor) || "TwoPanel".equals(flavor)) menu = "daydream";
            else if ("X".equals(flavor) || "Vendor".equals(flavor)) menu = "daydream_x";
            else return false;
            int menuId = resources.getIdentifier(menu, "xml", TV_SETTINGS);
            if (menuId == 0) return false;
            try (XmlResourceParser parser = resources.getXml(menuId)) {
                while (parser.next() != XmlPullParser.END_DOCUMENT) {
                    if (parser.getEventType() == XmlPullParser.START_TAG
                            && "activeDream".equals(parser.getAttributeValue(
                                    "http://schemas.android.com/apk/res/android", "key"))) return true;
                }
            }
        } catch (Exception ignored) { /* Unknown OEM menus stay unavailable. */ }
        return false;
    }

    private Intent launchIntent() {
        Intent voice = new Intent(START_DREAM).setPackage(TV_SETTINGS);
        if (accessible(voice)) return voice;
        // Android 13 removed Somnambulator's dream-starting implementation.
        if (Build.VERSION.SDK_INT <= 32) {
            Intent legacy = new Intent(Intent.ACTION_MAIN)
                    .setClassName("com.android.systemui", "com.android.systemui.Somnambulator");
            if (accessible(legacy)) return legacy;
        }
        return null;
    }

    private boolean accessible(Intent intent) {
        try {
            ResolveInfo resolved = context.getPackageManager().resolveActivity(intent, 0);
            ActivityInfo activity = resolved == null ? null : resolved.activityInfo;
            return activity != null && activity.enabled && activity.applicationInfo.enabled
                    && activity.exported && (activity.permission == null
                    || context.checkSelfPermission(activity.permission) == PackageManager.PERMISSION_GRANTED);
        } catch (RuntimeException ignored) { return false; }
    }

    private boolean start(Intent intent) {
        if (intent == null) return false;
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
            return true;
        } catch (RuntimeException ignored) { return false; }
    }
}
