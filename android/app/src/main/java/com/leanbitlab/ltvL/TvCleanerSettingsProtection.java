package com.leanbitlab.ltvL;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

/** Read-only shell queries: Android 14 denies app-UID reads of enabled IMEs and VPN. */
final class TvCleanerSettingsProtection {
    interface Reader { String execute(String command) throws Exception; }
    static Set<String> collect(Reader reader) throws Exception {
        Set<String> names = new LinkedHashSet<>();
        for (String key : List.of("default_input_method", "enabled_input_methods",
                "enabled_accessibility_services", "enabled_notification_listeners",
                "screensaver_components", "always_on_vpn_app")) {
            String value = reader.execute("settings --user 0 get secure '" + key + "'");
            if (value == null) throw new IllegalStateException("Protection query unavailable");
            value = value.trim();
            if (value.isEmpty() || value.equals("null")) continue;
            for (String component : value.split("[:,]")) {
                int slash = component.indexOf('/');
                String name = slash > 0 ? component.substring(0, slash) : component;
                if (!TvCleanerPolicy.packageId(name))
                    throw new IllegalStateException("Invalid protection data");
                names.add(name);
            }
        }
        return names;
    }
}
