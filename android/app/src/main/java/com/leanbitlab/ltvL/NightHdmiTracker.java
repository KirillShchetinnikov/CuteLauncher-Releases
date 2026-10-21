package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.tv.TvContract;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.os.SystemClock;
import android.provider.Settings;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/** Worker-only detection. A connected cable or a remembered input alone is not playback. */
final class NightHdmiTracker {
    private final Map<String, Set<String>> viewers = new HashMap<>();
    private final Map<String, String> inputIds = new HashMap<>();
    private long discoverAfter;

    void reset() { viewers.clear(); inputIds.clear(); discoverAfter = 0; }

    boolean read(Context context, String foregroundPackage) {
        return read(context, foregroundPackage, null);
    }

    boolean read(Context context, String foregroundPackage, Set<String> selectedInputs) {
        if (foregroundPackage == null || foregroundPackage.equals(context.getPackageName())) return false;
        try {
            // TCL keeps this value after leaving TV, so also require the actual TV viewer.
            String device = Settings.Secure.getString(context.getContentResolver(),
                "tcl_sys_tv_input_current_device_id");
            if (device == null) return false;
            long now = SystemClock.elapsedRealtime();
            if (now >= discoverAfter) {
                viewers.clear();
                inputIds.clear();
                discoverAfter = now + 60000;
                TvInputManager manager = context.getSystemService(TvInputManager.class);
                if (manager != null) for (TvInputInfo input : manager.getTvInputList()) {
                    if (input.getType() != TvInputInfo.TYPE_HDMI || !input.isPassthroughInput()) continue;
                    String id = input.getId();
                    int marker = id.lastIndexOf("/HW");
                    if (marker < 0) continue;
                    String hardwareId = id.substring(marker + 3);
                    if (!hardwareId.matches("[0-9]+")) continue;
                    inputIds.put(hardwareId, id);
                    Intent intent = new Intent(Intent.ACTION_VIEW).setDataAndType(
                        TvContract.buildChannelUriForPassthroughInput(id), TvContract.Channels.CONTENT_ITEM_TYPE);
                    Set<String> packages = viewers.computeIfAbsent(hardwareId, key -> new HashSet<>());
                    var candidate = context.getPackageManager().resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY);
                    var activity = candidate == null ? null : candidate.activityInfo;
                    if (activity != null && activity.enabled && activity.exported)
                        packages.add(activity.packageName);
                }
            }
            return matches(foregroundPackage, device, viewers)
                && selected(inputIds.get(device), selectedInputs);
        } catch (RuntimeException ignored) {
            // Unknown/unsupported OEM state must not disable the filter in unrelated apps.
            return false;
        }
    }

    static boolean matches(String foregroundPackage, String device, Map<String, Set<String>> viewers) {
        if (foregroundPackage == null || device == null) return false;
        Set<String> packages = viewers.get(device);
        return packages != null && packages.contains(foregroundPackage);
    }

    static boolean selected(String inputId, Set<String> selectedInputs) {
        return inputId != null && (selectedInputs == null || selectedInputs.contains(inputId));
    }
}
