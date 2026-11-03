package com.leanbitlab.ltvL;

import android.content.Context;
import android.hardware.display.DisplayManager;
import android.media.AudioManager;
import android.media.MediaCodecList;
import android.os.Build;
import android.view.Display;
import java.util.*;

/** Bounded, on-demand metadata. Never creates a decoder or changes display/audio routing. */
final class TvMediaCapabilities {
    static Map<String, Object> collect(Context context) {
        var result = new LinkedHashMap<String, Object>();
        result.put("scope", "reportedCapabilitiesOnly");
        result.put("display", section(() -> display(context)));
        result.put("decoders", section(TvMediaCapabilities::decoders));
        result.put("audioOutputs", section(() -> audio(context)));
        return result;
    }
    interface Reader { Object read(); }
    private static Map<String, Object> section(Reader reader) {
        try { return Map.of("status", "available", "data", reader.read()); }
        catch (RuntimeException | LinkageError error) { return Map.of("status", "unavailable"); }
    }
    @SuppressWarnings("deprecation")
    private static Map<String, Object> display(Context context) {
        var manager = context.getSystemService(DisplayManager.class);
        Display display = manager == null ? null : manager.getDisplay(Display.DEFAULT_DISPLAY);
        if (display == null) throw new IllegalStateException("Display unavailable");
        var modes = new ArrayList<Map<String, Object>>();
        for (var mode : display.getSupportedModes()) {
            if (modes.size() == 64) break;
            modes.add(mode(mode));
        }
        var hdr = new ArrayList<Integer>();
        var caps = display.getHdrCapabilities();
        if (caps != null) for (int type : caps.getSupportedHdrTypes()) {
            if (hdr.size() == 16) break;
            hdr.add(type);
        }
        return Map.of("currentMode", mode(display.getMode()), "modes", modes, "hdrTypes", hdr);
    }
    private static Map<String, Object> mode(Display.Mode mode) {
        return Map.of("width", mode.getPhysicalWidth(), "height", mode.getPhysicalHeight(),
                "refreshRateHz", mode.getRefreshRate());
    }
    private static List<Map<String, Object>> decoders() {
        var rows = new ArrayList<Map<String, Object>>();
        for (var info : new MediaCodecList(MediaCodecList.REGULAR_CODECS).getCodecInfos()) {
            if (info.isEncoder()) continue;
            for (String type : info.getSupportedTypes()) {
                if (rows.size() == 128) return rows;
                if (!type.startsWith("video/") && !type.startsWith("audio/")) continue;
                var row = new LinkedHashMap<String, Object>();
                row.put("name", info.getName()); row.put("mime", type);
                row.put("acceleration", Build.VERSION.SDK_INT < 29 ? "unknown"
                        : info.isHardwareAccelerated() ? "hardware" : info.isSoftwareOnly() ? "software" : "unknown");
                try {
                    var caps = info.getCapabilitiesForType(type);
                    var profiles = new ArrayList<Map<String, Integer>>();
                    if (caps.profileLevels != null) for (var profile : caps.profileLevels) {
                        if (profiles.size() == 32) break;
                        profiles.add(Map.of("profile", profile.profile, "level", profile.level));
                    }
                    row.put("profileLevels", profiles);
                    var video = caps.getVideoCapabilities();
                    if (video != null) {
                        // Independent bounds, not a promise that the maximum width/height/rate work together.
                        row.put("maxWidth", video.getSupportedWidths().getUpper());
                        row.put("maxHeight", video.getSupportedHeights().getUpper());
                        row.put("maxFrameRateHz", video.getSupportedFrameRates().getUpper());
                    }
                    var audio = caps.getAudioCapabilities();
                    if (audio != null) row.put("maxChannels", audio.getMaxInputChannelCount());
                    row.put("status", "available");
                } catch (RuntimeException | LinkageError error) { row.put("status", "unavailable"); }
                rows.add(row);
            }
        }
        return rows;
    }
    private static List<Map<String, Object>> audio(Context context) {
        var manager = context.getSystemService(AudioManager.class);
        if (manager == null) throw new IllegalStateException("Audio unavailable");
        var rows = new ArrayList<Map<String, Object>>();
        for (var device : manager.getDevices(AudioManager.GET_DEVICES_OUTPUTS)) {
            if (rows.size() == 32) break;
            rows.add(Map.of("type", device.getType(), "encodings", numbers(device.getEncodings()),
                    "channelCounts", numbers(device.getChannelCounts()), "sampleRatesHz", numbers(device.getSampleRates())));
        }
        return rows;
    }
    static List<Integer> numbers(int[] values) {
        var result = new ArrayList<Integer>(Math.min(values.length, 64));
        for (int i = 0; i < values.length && i < 64; i++) result.add(values[i]);
        return result;
    }
}
