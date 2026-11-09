package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.media.tv.TvContract;
import android.media.tv.TvInputInfo;
import android.media.tv.TvInputManager;
import android.os.Build;
import java.util.*;

/** Fixed input routes shared with cleaner protection; no shell commands or guessed source numbers. */
final class TvInputLaunch {
    static boolean supportsDirectHdmi() {
        return !"MiTV-NSOP0".equals(Build.MODEL);
    }

    static boolean openHdmi(Context context, String id) {
        if (!supportsDirectHdmi()) return false;
        TvInputManager manager = context.getSystemService(TvInputManager.class);
        TvInputInfo input = manager == null ? null : manager.getTvInputInfo(id);
        return input != null && input.getType() == TvInputInfo.TYPE_HDMI && open(context, id);
    }

    static List<Intent> candidates(String id, String model) {
        if (id == null || id.isEmpty() || id.length() > 512) throw new IllegalArgumentException("Invalid input");
        var uri = TvContract.buildChannelUriForPassthroughInput(id);
        var result = new ArrayList<Intent>();
        // This firmware accepts the generic URI but displays "unsupported". Open its source picker.
        if ("MiTV-NSOP0".equals(model)) result.add(new Intent().setComponent(
                new ComponentName("com.xiaomi.mitv.tvplayer", "com.xiaomi.mitv.tvplayer.ExternalSourceActivity")));
        // Explicit YaOS player, only tried when it actually declares this URI handler.
        result.add(new Intent(Intent.ACTION_VIEW).setData(uri.buildUpon().scheme("live-tv").build())
                .setPackage("com.yandex.tv.live"));
        String owner = id.contains("/") ? id.substring(0, id.indexOf('/')) : "";
        var typed = new Intent(Intent.ACTION_VIEW).setDataAndType(uri, "vnd.android.cursor.item/channel");
        var untyped = new Intent(Intent.ACTION_VIEW).setData(uri);
        if (TvCleanerPolicy.packageId(owner)) result.add(new Intent(typed).setPackage(owner));
        result.add(typed);
        if (TvCleanerPolicy.packageId(owner)) result.add(new Intent(untyped).setPackage(owner));
        result.add(untyped);
        result.add(new Intent("com.xgimi.action.hdmiPlayer").setDataAndType(uri, "vnd.android.cursor.item/channel"));
        for (var intent : result) intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        return result;
    }
    static boolean open(Context context, String id) {
        try {
            for (var intent : candidates(id, Build.MODEL)) {
                try {
                    if ("com.yandex.tv.live".equals(intent.getPackage()) && context.getPackageManager()
                            .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY).isEmpty()) continue;
                    context.startActivity(intent);
                    return true; // Accepted by Android, not proof of an actual HDMI signal.
                } catch (RuntimeException unavailable) { /* Try the next fixed route, including permission denials. */ }
            }
        } catch (RuntimeException unavailable) { /* Missing firmware services or malformed input. */ }
        return false;
    }
}
