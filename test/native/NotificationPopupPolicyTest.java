import com.leanbitlab.ltvL.NotificationPopupPolicy;
import com.leanbitlab.ltvL.NotificationPopupEntries;

public class NotificationPopupPolicyTest {
    private static void check(boolean condition) {
        if (!condition) throw new AssertionError("Popup filtering regression");
    }
    private static boolean show(boolean enabled, boolean blocked, boolean hide,
            boolean clearable, boolean media, String title, String text) {
        return NotificationPopupPolicy.shouldShow(enabled, blocked, hide, clearable,
                media, title, text, "Example", "example.app");
    }
    public static void main(String[] args) {
        check(show(true, false, false, true, false, "Message", "Text"));
        check(!show(false, false, false, true, false, "Message", "Text"));
        check(!show(true, true, false, true, false, "Message", "Text"));
        check(!show(true, false, true, false, false, "Message", "Text"));
        check(show(true, false, false, false, false, "Message", "Text"));
        check(!show(true, false, false, true, true, "Message", "Text"));
        check(!show(true, false, false, true, false, "", ""));
        check(!show(true, false, false, true, false, "Example", ""));
        check(show(true, false, false, true, false, "Example", "Message"));
        check(!show(true, false, false, true, false, "example.app", "example.app"));
        check(NotificationPopupPolicy.isTvNowPlaying("com.google.android.tvrecommendations", "now_playing"));
        check(!NotificationPopupPolicy.isTvNowPlaying("com.google.android.tvrecommendations", "other"));
        check(!NotificationPopupPolicy.isTvNowPlaying("example.app", "now_playing"));
        check(!NotificationPopupPolicy.isTvNowPlaying("com.google.android.tvrecommendations", null));
        NotificationPopupEntries<Object> entries = new NotificationPopupEntries<>();
        Object first = new Object(), updated = new Object(), other = new Object();
        check(entries.replace("same-key", first) == null);
        check(entries.replace("other-key", other) == null);
        check(entries.replace("same-key", updated) == first);
        check(!entries.expire("same-key", first)); // An old timer cannot remove its replacement.
        check(entries.expire("same-key", updated));
        check(entries.expire("other-key", other));
        entries.replace("same-key", first);
        entries.clear();
        check(!entries.expire("same-key", first));
        check(entries.replace("same-key", updated) == null);
        System.out.println("22 popup policy and replacement checks passed");
    }
}
