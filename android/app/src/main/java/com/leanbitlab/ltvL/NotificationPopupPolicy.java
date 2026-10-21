package com.leanbitlab.ltvL;

/** Pure policy shared by the Android renderer and local regression checks. */
public final class NotificationPopupPolicy {
    private NotificationPopupPolicy() {}

    public static boolean isTvNowPlaying(String packageName, String channelId) {
        return "com.google.android.tvrecommendations".equals(packageName) &&
                "now_playing".equals(channelId);
    }

    public static boolean shouldShow(boolean enabled, boolean blocked,
            boolean hidePersistent, boolean clearable, boolean media,
            String title, String text, String label, String packageName) {
        if (!enabled || blocked || (hidePersistent && !clearable) || media) return false;
        if (title.isEmpty() && text.isEmpty()) return false;
        if (title.equalsIgnoreCase(label) &&
                (text.isEmpty() || text.equalsIgnoreCase(label))) return false;
        return !title.equalsIgnoreCase(packageName) ||
                (!text.isEmpty() && !text.equalsIgnoreCase(packageName));
    }

}
