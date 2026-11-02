package com.leanbitlab.ltvL;

import android.content.Intent;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import java.util.*;

/** Package-owned permission declarations and TV-input services, not shared-UID permissions. */
final class TvCleanerHardware {
    static Set<String> collect(PackageManager pm, List<PackageInfo> installed) {
        if (installed == null) throw new IllegalStateException("Package permissions unavailable");
        var names = new LinkedHashSet<String>();
        for (var info : installed) {
            if (info == null) throw new IllegalStateException("Invalid package metadata");
            if (info.requestedPermissions != null && Arrays.asList(info.requestedPermissions)
                    .contains("android.permission.TV_INPUT_HARDWARE")) {
                if (!TvCleanerPolicy.packageId(info.packageName)) throw new IllegalStateException("Invalid hardware package");
                names.add(info.packageName);
            }
        }
        var services = pm.queryIntentServices(new Intent("android.media.tv.TvInputService"), PackageManager.MATCH_DISABLED_COMPONENTS);
        if (services == null) throw new IllegalStateException("Input services unavailable");
        for (var info : services) {
            if (info == null || info.serviceInfo == null || !TvCleanerPolicy.packageId(info.serviceInfo.packageName))
                throw new IllegalStateException("Invalid input service metadata");
            names.add(info.serviceInfo.packageName);
        }
        return names;
    }
}
