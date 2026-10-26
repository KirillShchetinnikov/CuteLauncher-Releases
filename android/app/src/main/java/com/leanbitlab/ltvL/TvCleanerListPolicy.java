package com.leanbitlab.ltvL;

import java.util.*;

/** List scopes are enforced again by Android, independently of the Flutter preview. */
final class TvCleanerListPolicy {
    record App(boolean system, boolean preinstalled, boolean enabled, boolean protectedApp) { }
    static List<String> select(List<String> names, Map<String, App> installed, String scope, boolean enable) {
        if (names == null || names.isEmpty() || names.size() > 2000
                || (scope != null && !scope.equals("system") && !scope.equals("preinstalled")))
            throw new IllegalArgumentException("Invalid list");
        for (String name : names) if (!TvCleanerPolicy.packageId(name)) throw new IllegalArgumentException("Invalid package");
        var selected = new ArrayList<String>();
        for (String name : new LinkedHashSet<>(names)) {
            App app = installed.get(name);
            if (app == null || app.enabled() == enable || (!enable && app.protectedApp())) continue;
            if ("system".equals(scope) && (!app.system() || app.preinstalled())) continue;
            if ("preinstalled".equals(scope) && !app.preinstalled()) continue;
            selected.add(name);
        }
        return selected;
    }
}
