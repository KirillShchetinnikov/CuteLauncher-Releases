package com.leanbitlab.ltvL;

import java.util.HashMap;
import java.util.Map;

/** Visible popup identities; accessed only on the popup handler thread. */
public final class NotificationPopupEntries<T> {
    private final Map<String, T> entries = new HashMap<>();

    public T replace(String key, T entry) {
        return entries.put(key, entry);
    }

    public boolean expire(String key, T entry) {
        if (!isCurrent(key, entry)) return false;
        entries.remove(key);
        return true;
    }

    public boolean isCurrent(String key, T entry) {
        return entries.get(key) == entry;
    }

    public void clear() {
        entries.clear();
    }
}
