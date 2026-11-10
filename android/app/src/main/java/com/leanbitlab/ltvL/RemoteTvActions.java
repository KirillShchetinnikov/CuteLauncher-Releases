package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.ComponentName;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.ApplicationInfo;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.media.tv.TvContract;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

final class RemoteTvActions {
    static final ComponentName TV_SETTINGS =
        new ComponentName("com.android.tv.settings", "com.android.tv.settings.MainSettings");
    static final ComponentName XIAOMI_PICTURE_SETTINGS =
        new ComponentName("com.android.tv.settings", "com.xiaomi.mitv.settings.picture.PictureActivity");
    private static final List<String> ACTIONS = List.of(
        "live_tv", "display_settings", "wifi_settings", "bluetooth_settings", "mute");

    static List<String> available(Context context) {
        var available = new ArrayList<String>();
        for (String action : ACTIONS) {
            try {
                if (action.equals("mute") ? mutableAudio(context) != null : !activities(context, action).isEmpty()) {
                    available.add(action);
                }
            } catch (RuntimeException unavailable) { /* Keep other actions on this firmware. */ }
        }
        return available;
    }

    static boolean open(Context context, String action) {
        for (Intent intent : activities(context, action)) {
            if (start(context, intent)) return true;
        }
        return false;
    }

    static boolean openSettings(Context context) {
        return start(context, new Intent(Settings.ACTION_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            || (tvSettingsActivity(context) != null
                && start(context, new Intent().setComponent(TV_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)));
    }

    static ActivityInfo tvSettingsActivity(Context context) {
        return systemActivity(context, TV_SETTINGS);
    }

    private static boolean start(Context context, Intent intent) {
        try {
            context.startActivity(intent);
            return true;
        } catch (android.content.ActivityNotFoundException | SecurityException unavailable) {
            return false;
        }
    }

    static boolean toggleMute(Context context) {
        AudioManager audio = mutableAudio(context);
        if (audio == null) return false;
        audio.adjustStreamVolume(AudioManager.STREAM_MUSIC, AudioManager.ADJUST_TOGGLE_MUTE, 0);
        return true;
    }

    private static AudioManager mutableAudio(Context context) {
        AudioManager audio = context.getSystemService(AudioManager.class);
        return audio == null || audio.isVolumeFixed() ? null : audio;
    }

    static Intent request(String action) {
        return switch (action) {
            case "display_settings" -> new Intent(Settings.ACTION_DISPLAY_SETTINGS);
            case "wifi_settings" -> new Intent(Settings.ACTION_WIFI_SETTINGS);
            case "bluetooth_settings" -> new Intent(Settings.ACTION_BLUETOOTH_SETTINGS);
            case "live_tv" -> new Intent(Intent.ACTION_VIEW).setType(TvContract.Channels.CONTENT_TYPE);
            default -> null;
        };
    }

    private static List<Intent> activities(Context context, String action) {
        Intent intent = request(action);
        if (intent == null) return List.of();
        var result = new ArrayList<Intent>();
        if ("live_tv".equals(action)) result.addAll(TvInputLaunch.tclTunerRoutes(context));
        if ("display_settings".equals(action) && systemActivity(context, XIAOMI_PICTURE_SETTINGS) != null) {
            result.add(new Intent().setComponent(XIAOMI_PICTURE_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
        }
        PackageManager packages = context.getPackageManager();
        packages.queryIntentActivities(intent,
                PackageManager.MATCH_DEFAULT_ONLY | PackageManager.MATCH_SYSTEM_ONLY).stream()
            .map(match -> match.activityInfo)
            .filter(Objects::nonNull)
            .filter(info -> accessible(context, info))
            .findFirst()
            .ifPresent(info -> result.add(intent.setClassName(info.packageName, info.name)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)));
        return result;
    }

    private static ActivityInfo systemActivity(Context context, ComponentName component) {
        try {
            ActivityInfo info = context.getPackageManager().getActivityInfo(component, 0);
            return info.enabled && info.applicationInfo.enabled
                && (info.applicationInfo.flags & (ApplicationInfo.FLAG_SYSTEM | ApplicationInfo.FLAG_UPDATED_SYSTEM_APP)) != 0
                && accessible(context, info) ? info : null;
        } catch (PackageManager.NameNotFoundException unavailable) {
            return null;
        }
    }

    private static boolean accessible(Context context, ActivityInfo info) {
        return info.exported && (info.permission == null
            || context.checkSelfPermission(info.permission) == PackageManager.PERMISSION_GRANTED);
    }
}
