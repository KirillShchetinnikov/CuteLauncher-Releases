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
    private static final String TCL_G03 = "G03_4K_GB";
    private static final String TCL_PLAYER = "com.tcl.tv";
    private static final String TCL_G03_TUNER = "com.tcl.tvinput/.TDTVInputService/HW1413742848";

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
        return candidates(id, model, Build.PRODUCT);
    }

    static List<Intent> candidates(String id, String model, String product) {
        if (id == null || id.isEmpty() || id.length() > 512) throw new IllegalArgumentException("Invalid input");
        var uri = TvContract.buildChannelUriForPassthroughInput(id);
        var result = new ArrayList<Intent>();
        Intent source = xiaomiSource(id, model);
        if (source != null) result.add(source);
        // This firmware accepts the generic URI but displays "unsupported". Open its source picker.
        if ("MiTV-NSOP0".equals(model)) result.add(new Intent().setComponent(
                new ComponentName("com.xiaomi.mitv.tvplayer", "com.xiaomi.mitv.tvplayer.ExternalSourceActivity")));
        // Explicit YaOS player, only tried when it actually declares this URI handler.
        result.add(new Intent(Intent.ACTION_VIEW).setData(uri.buildUpon().scheme("live-tv").build())
                .setPackage("com.yandex.tv.live"));
        String owner = id.contains("/") ? id.substring(0, id.indexOf('/')) : "";
        var typed = new Intent(Intent.ACTION_VIEW).setDataAndType(uri, "vnd.android.cursor.item/channel");
        var untyped = new Intent(Intent.ACTION_VIEW).setData(uri);
        if (TCL_G03.equals(product) && "com.tcl.tvinput".equals(owner)) {
            result.add(new Intent(typed).setPackage(TCL_PLAYER));
            result.add(new Intent(untyped).setPackage(TCL_PLAYER));
        }
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
            if ("MiTV-MTEQ0".equals(Build.MODEL) && id != null) {
                TvInputManager manager = context.getSystemService(TvInputManager.class);
                TvInputInfo input = manager == null ? null : manager.getTvInputInfo(id);
                if (input != null && input.getType() == TvInputInfo.TYPE_HDMI && input.getParentId() != null
                        && tryStart(context, xiaomiSource(input.getParentId(), Build.MODEL))) return true;
            }
            for (var intent : candidates(id, Build.MODEL)) {
                String target = intent.getPackage();
                if (TCL_PLAYER.equals(target) && !hasTclHandler(context, intent)) continue;
                if ("com.yandex.tv.live".equals(target) && context.getPackageManager()
                        .queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY).isEmpty()) continue;
                if (tryStart(context, intent)) return true;
            }
        } catch (RuntimeException unavailable) { /* Missing firmware services or malformed input. */ }
        return false;
    }

    static List<Intent> tclTunerRoutes(Context context) {
        if (!TCL_G03.equals(Build.PRODUCT)) return List.of();
        try {
            TvInputManager manager = context.getSystemService(TvInputManager.class);
            if (manager == null || manager.getTvInputInfo(TCL_G03_TUNER) == null) return List.of();
            var routes = new ArrayList<Intent>();
            for (Intent candidate : tclTunerCandidates()) {
                if (hasTclHandler(context, candidate)) routes.add(candidate);
            }
            return routes;
        } catch (RuntimeException unavailable) {
            return List.of();
        }
    }

    static List<Intent> tclTunerCandidates() {
        if (!TCL_G03.equals(Build.PRODUCT)) return List.of();
        var routes = new ArrayList<Intent>();
        for (Intent candidate : candidates(TCL_G03_TUNER, Build.MODEL)) {
            if (TCL_PLAYER.equals(candidate.getPackage())) routes.add(candidate);
        }
        return routes;
    }

    private static boolean hasTclHandler(Context context, Intent intent) {
        return !context.getPackageManager().queryIntentActivities(intent,
            PackageManager.MATCH_DEFAULT_ONLY | PackageManager.MATCH_SYSTEM_ONLY).isEmpty();
    }

    private static Intent xiaomiSource(String id, String model) {
        if (!"MiTV-MTEQ0".equals(model)) return null;
        Integer source = switch (id) {
            case "com.mediatek.tvinput/.hdmi.HDMIInputService/HW5" -> 23;
            case "com.mediatek.tvinput/.hdmi.HDMIInputService/HW6" -> 24;
            case "com.mediatek.tvinput/.hdmi.HDMIInputService/HW7" -> 25;
            case "com.mediatek.tvinput/.composite.CompositeInputService/HW2" -> 2;
            default -> null;
        };
        return source == null ? null : new Intent("com.xiaomi.mitv.tvplayer.EXTSRC_PLAY")
            .setClassName("com.xiaomi.mitv.tvplayer", "com.xiaomi.mitv.tvplayer.ExternalSourceActivity")
            .putExtra("input", source.intValue()).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
    }

    private static boolean tryStart(Context context, Intent intent) {
        if (intent == null) return false;
        try {
            context.startActivity(intent);
            return true; // Accepted by Android, not proof of an actual HDMI signal.
        } catch (RuntimeException unavailable) {
            return false;
        }
    }
}
