package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.res.Resources;
import android.media.AudioAttributes;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.media.MediaRouter;
import android.os.Build;
import android.os.PowerManager;
import android.text.TextUtils;
import androidx.annotation.MainThread;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.TreeSet;

/** Read-only media state. Connected devices are never substituted for a selected route. */
final class AudioStatusController {
    static final AudioAttributes MEDIA = new AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA).build();
    private final Context context;
    AudioStatusController(Context context) { this.context = context; }

    @MainThread
    @Nullable String legacyOutput(@Nullable Map<String, Object> diagnostics) {
        try {
            var router = context.getSystemService(MediaRouter.class);
            var route = router == null ? null : router.getSelectedRoute(MediaRouter.ROUTE_TYPE_LIVE_AUDIO);
            if (route == null) return null;
            if (diagnostics != null) {
                diagnostics.put("legacyRouteType", route.getDeviceType());
            }
            if (route.getDeviceType() == MediaRouter.RouteInfo.DEVICE_TYPE_BLUETOOTH) return "bluetooth";
            boolean hdmi = Build.VERSION.SDK_INT >= 30
                && matchesHdmiLabel(route.getName(), context.getResources());
            if (diagnostics != null) diagnostics.put("legacyRouteMatchesHdmiLabel", hdmi);
            return hdmi ? "hdmi" : null;
        } catch (RuntimeException unavailable) {
            if (diagnostics != null) diagnostics.put("legacyRouteReadFailed", true);
            return null;
        }
    }

    static int hdmiLabel(Resources resources) {
        return resources.getIdentifier("default_audio_route_name_hdmi", "string", "android");
    }

    static boolean matchesHdmiLabel(CharSequence name, Resources resources) {
        int label = hdmiLabel(resources);
        return label != 0 && TextUtils.equals(name, resources.getText(label));
    }

    @Nullable static Integer mediaVolumePercent(@NonNull AudioManager audio) {
        int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
        int level = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
        return max > 0 && level >= 0 && level <= max ? Math.round(100f * level / max) : null;
    }

    @NonNull Map<String, Object> snapshot(@Nullable String legacyRoute, boolean router2HdmiSelected,
                                         @Nullable Map<String, Object> routeDiagnostics) {
        var state = new HashMap<String, Object>();
        var power = context.getSystemService(PowerManager.class);
        state.put("screenOn", power != null && power.isInteractive());
        if (!Boolean.TRUE.equals(state.get("screenOn"))) return state;
        var audio = context.getSystemService(AudioManager.class);
        boolean legacyBluetooth = "bluetooth".equals(legacyRoute);
        boolean hdmiSelected = router2HdmiSelected || "hdmi".equals(legacyRoute);
        if (routeDiagnostics != null) {
            routeDiagnostics.put("hdmiSelected", hdmiSelected);
            state.put("routeDiagnostics", routeDiagnostics);
        }
        if (audio == null) return state;
        // Each field can be unavailable independently on an OEM implementation.
        try { state.put("muted", audio.isStreamMute(AudioManager.STREAM_MUSIC)); }
        catch (RuntimeException unavailable) { /* Unknown is distinct from false. */ }
        try {
            boolean fixed = audio.isVolumeFixed();
            state.put("fixed", fixed);
            if (!fixed) {
                var percent = mediaVolumePercent(audio);
                if (percent != null) state.put("percent", percent);
            }
        } catch (RuntimeException unavailable) { /* Keep level unknown. */ }
        String legacyArc = null;
        if ((hdmiSelected && !legacyBluetooth) || routeDiagnostics != null) {
            try {
                var devices = audio.getDevices(AudioManager.GET_DEVICES_OUTPUTS);
                if (routeDiagnostics != null) {
                    var types = new TreeSet<Integer>();
                    for (var device : devices) types.add(device.getType());
                    routeDiagnostics.put("availableOutputTypes", List.copyOf(types));
                }
                if (hdmiSelected && !legacyBluetooth) legacyArc = legacyArcOutput(devices);
            } catch (RuntimeException unavailable) {
                if (routeDiagnostics != null) routeDiagnostics.put("outputsReadFailed", true);
            }
        }
        if (Build.VERSION.SDK_INT >= 33) {
            try { state.put("outputs", outputs(audio.getAudioDevicesForAttributes(MEDIA))); }
            catch (RuntimeException unavailable) { /* No permission or unsupported OEM route query. */ }
        } else if (legacyBluetooth) {
            state.put("outputs", List.of("bluetooth"));
        } else if (legacyArc != null) {
            state.put("outputs", List.of(legacyArc));
        }
        return state;
    }

    @Nullable private static String legacyArcOutput(@NonNull AudioDeviceInfo[] devices) {
        String output = null;
        for (var device : devices) {
            switch (device.getType()) {
                case AudioDeviceInfo.TYPE_HDMI -> { return null; }
                case AudioDeviceInfo.TYPE_HDMI_ARC, AudioDeviceInfo.TYPE_HDMI_EARC -> {
                    String type = kind(device.getType());
                    if (output != null && !output.equals(type)) return null;
                    output = type;
                }
                default -> { }
            }
        }
        return output;
    }

    static List<String> outputs(List<AudioDeviceInfo> devices) {
        var result = new LinkedHashSet<String>();
        for (var device : devices) result.add(kind(device.getType()));
        return List.copyOf(result);
    }
    static String kind(int type) {
        return switch (type) {
            case AudioDeviceInfo.TYPE_BUILTIN_SPEAKER, AudioDeviceInfo.TYPE_BUILTIN_SPEAKER_SAFE -> "tv";
            case AudioDeviceInfo.TYPE_HDMI_ARC -> "arc";
            case AudioDeviceInfo.TYPE_HDMI_EARC -> "earc";
            case AudioDeviceInfo.TYPE_HDMI -> "hdmi";
            case AudioDeviceInfo.TYPE_BLUETOOTH_A2DP, AudioDeviceInfo.TYPE_BLUETOOTH_SCO,
                 AudioDeviceInfo.TYPE_BLE_HEADSET, AudioDeviceInfo.TYPE_BLE_SPEAKER,
                 AudioDeviceInfo.TYPE_BLE_BROADCAST -> "bluetooth";
            case AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "headphones";
            case AudioDeviceInfo.TYPE_USB_DEVICE, AudioDeviceInfo.TYPE_USB_ACCESSORY,
                 AudioDeviceInfo.TYPE_USB_HEADSET -> "usb";
            case AudioDeviceInfo.TYPE_LINE_DIGITAL -> "spdif";
            case AudioDeviceInfo.TYPE_LINE_ANALOG, AudioDeviceInfo.TYPE_AUX_LINE -> "line";
            default -> "unknown";
        };
    }
}
