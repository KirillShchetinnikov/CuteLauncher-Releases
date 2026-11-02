package com.leanbitlab.ltvL;
import java.util.*;

/** Conservative checks of components actually present on this firmware, before disabling HOME. */
final class HomeDependencyPolicy {
    record App(boolean enabled, List<String> providers, List<String> receivers) {}
    interface Reader { App app(String name) throws Exception; String userIds() throws Exception; }
    static String blocked(Map<String, Integer> desired, Reader reader) {
        try {
            for (var entry : desired.entrySet()) {
                if (entry.getValue() < 2) continue;
                App host = reader.app(entry.getKey());
                if (host == null) return "dependencyUnavailable";
                if (entry.getKey().equals(AdbSystemHomeOps.RECOVERY_PACKAGE)
                        && host.providers().stream().anyMatch(name -> name.endsWith(".CastInfoProvider"))
                        && active(reader.app("com.google.android.apps.mediashell"))) return "castDependency";
                if (!entry.getKey().equals("com.google.android.apps.tv.launcherx")) continue;
                if (host.receivers().stream().anyMatch(name -> name.endsWith(".GlobalButtonLaunch_Receiver"))
                        && active(reader.app("com.realtek.advancesetting"))) return "shortcutDependency";
                if (host.providers().stream().anyMatch(name -> name.endsWith(".LiveTvContentProvider"))
                        && active(reader.app("com.smartdevice.global.service"))) {
                    if (userCount(reader.userIds()) > 1) return "multiUserDependency";
                }
            }
            return "";
        } catch (Exception error) { return "dependencyUnavailable"; }
    }
    private static boolean active(App app) { return app != null && app.enabled(); }
    static int userCount(String ids) {
        if (ids == null || ids.length() > 1024) throw new IllegalStateException("Users unavailable");
        var users = new HashSet<Integer>();
        for (String line : ids.trim().split("\\s+")) {
            if (!line.matches("[0-9]{1,5}")) throw new IllegalStateException("Invalid user IDs");
            users.add(Integer.parseInt(line));
        }
        if (!users.contains(0) || users.size() > 100) throw new IllegalStateException("Owner unavailable");
        return users.size();
    }
}
