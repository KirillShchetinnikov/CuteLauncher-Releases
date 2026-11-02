package com.leanbitlab.ltvL;

import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.provider.Settings;
import java.util.*;

/** Preserve the firmware's actual Settings/input handlers, including disabled recovery routes. */
final class TvCleanerHandlers {
    static Set<String> collect(PackageManager pm, List<String> passthroughIds) {
        var settings = new LinkedHashSet<String>();
        collect(pm, new Intent(Settings.ACTION_SETTINGS), settings);
        collect(pm, new Intent("android.settings.TV_SETTINGS"), settings);
        if (settings.isEmpty()) throw new IllegalStateException("Settings handlers unavailable");
        var names = new LinkedHashSet<>(settings);
        for (String id : passthroughIds) {
            var handlers = new LinkedHashSet<String>();
            for (var intent : TvInputLaunch.candidates(id, android.os.Build.MODEL)) collect(pm, intent, handlers);
            if (handlers.isEmpty()) throw new IllegalStateException("Input handlers unavailable");
            names.addAll(handlers);
        }
        return names;
    }
    private static void collect(PackageManager pm, Intent intent, Set<String> names) {
        List<ResolveInfo> matches = pm.queryIntentActivities(intent, PackageManager.MATCH_DISABLED_COMPONENTS);
        if (matches == null) throw new IllegalStateException("Handler query unavailable");
        for (var match : matches) {
            if (match == null || match.activityInfo == null || !TvCleanerPolicy.packageId(match.activityInfo.packageName))
                throw new IllegalStateException("Invalid handler metadata");
            names.add(match.activityInfo.packageName);
        }
    }
}
