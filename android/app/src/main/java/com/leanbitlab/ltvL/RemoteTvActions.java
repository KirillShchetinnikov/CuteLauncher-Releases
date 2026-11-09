package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.media.tv.TvContract;
import android.provider.Settings;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

final class RemoteTvActions {
    private static final List<String> ACTIONS = List.of(
        "live_tv", "display_settings", "wifi_settings", "bluetooth_settings", "mute");

    static List<String> available(Context context) {
        var available = new ArrayList<String>();
        for (String action : ACTIONS) {
            try {
                if (action.equals("mute") ? mutableAudio(context) != null : activity(context, action) != null) {
                    available.add(action);
                }
            } catch (RuntimeException unavailable) { /* Keep other actions on this firmware. */ }
        }
        return available;
    }

    static boolean open(Context context, String action) {
        Intent intent = activity(context, action);
        if (intent == null) return false;
        context.startActivity(intent);
        return true;
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

    private static Intent activity(Context context, String action) {
        Intent intent = request(action);
        if (intent == null) return null;
        PackageManager packages = context.getPackageManager();
        return packages.queryIntentActivities(intent,
                PackageManager.MATCH_DEFAULT_ONLY | PackageManager.MATCH_SYSTEM_ONLY).stream()
            .map(result -> result.activityInfo)
            .filter(Objects::nonNull)
            .filter(info -> info.exported && (info.permission == null ||
                context.checkSelfPermission(info.permission) == PackageManager.PERMISSION_GRANTED))
            .findFirst()
            .map(info -> intent.setClassName(info.packageName, info.name).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            .orElse(null);
    }
}
