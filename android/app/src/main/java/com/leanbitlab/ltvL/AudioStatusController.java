package com.leanbitlab.ltvL;

import android.content.Context;
import android.media.AudioAttributes;
import android.media.AudioDeviceInfo;
import android.media.AudioManager;
import android.os.Build;
import android.os.PowerManager;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/** Read-only media state. Connected devices are never substituted for a selected route. */
final class AudioStatusController {
    static final AudioAttributes MEDIA = new AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_MEDIA).build();
    private final Context context;
    AudioStatusController(Context context) { this.context = context; }

    Map<String, Object> snapshot() {
        var state = new HashMap<String, Object>();
        var power = context.getSystemService(PowerManager.class);
        state.put("screenOn", power != null && power.isInteractive());
        if (!Boolean.TRUE.equals(state.get("screenOn"))) return state;
        var audio = context.getSystemService(AudioManager.class);
        if (audio == null) return state;
        // Each field can be unavailable independently on an OEM implementation.
        try { state.put("muted", audio.isStreamMute(AudioManager.STREAM_MUSIC)); }
        catch (RuntimeException unavailable) { /* Unknown is distinct from false. */ }
        try {
            boolean fixed = audio.isVolumeFixed();
            state.put("fixed", fixed);
            if (!fixed) {
                int max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC);
                int level = audio.getStreamVolume(AudioManager.STREAM_MUSIC);
                if (max > 0 && level >= 0 && level <= max) {
                    state.put("percent", Math.round(100f * level / max));
                }
            }
        } catch (RuntimeException unavailable) { /* Keep level unknown. */ }
        if (Build.VERSION.SDK_INT >= 33) {
            try { state.put("outputs", outputs(audio.getAudioDevicesForAttributes(MEDIA))); }
            catch (RuntimeException unavailable) { /* No permission or unsupported OEM route query. */ }
        }
        return state;
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
