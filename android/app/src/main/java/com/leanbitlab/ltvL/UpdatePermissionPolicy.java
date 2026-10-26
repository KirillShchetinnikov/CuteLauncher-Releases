package com.leanbitlab.ltvL;

import java.util.LinkedHashSet;
import java.util.Set;

/** Only permissions observed in the previous installation may be restored. */
final class UpdatePermissionPolicy {
    static final Set<String> ACTIONS = Set.of("accessibility", "notifications", "overlay",
        "usage", "writeSettings", "watchNext");

    static Set<String> missing(Set<String> previous, Set<String> current,
                               boolean accessibilityConnected) {
        Set<String> result = new LinkedHashSet<>();
        for (String action : ACTIONS) {
            if (previous.contains(action) && (!current.contains(action)
                || (action.equals("accessibility") && !accessibilityConnected))) result.add(action);
        }
        return result;
    }

    static boolean replaced(long previous, long current) {
        return previous > 0 && previous != current;
    }

    static String serviceList(String current, String own, boolean include) {
        if (current.equals("null")) current = "";
        if (!current.matches("[a-zA-Z0-9_./:]*") || !own.matches("[a-zA-Z0-9_.]+/[a-zA-Z0-9_.]+"))
            throw new IllegalArgumentException("Invalid service list");
        Set<String> services = new LinkedHashSet<>();
        for (String item : current.split(":")) {
            String normalized = item;
            int slash = item.indexOf("/");
            if (slash >= 0 && item.substring(slash + 1).startsWith("."))
                normalized = item.substring(0, slash + 1) + item.substring(0, slash) + item.substring(slash + 1);
            if (!item.isEmpty() && !normalized.equals(own)) services.add(item);
        }
        if (include) services.add(own);
        return String.join(":", services);
    }
}
