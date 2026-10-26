package com.leanbitlab.ltvL;

import java.util.Map;
import io.flutter.plugin.common.EventChannel;

public final class NotificationPopupBridgeTest {
    private static final class Sink implements EventChannel.EventSink {
        int count;
        boolean detached;
        @Override public void success(Object event) {
            if (detached) throw new IllegalStateException("detached");
            count++;
        }
        @Override public void error(String code, String message, Object details) {}
        @Override public void endOfStream() {}
    }
    private static void check(boolean value) {
        if (!value) throw new AssertionError("Popup delivery regression");
    }
    public static void main(String[] args) {
        var launcher = new NotificationPopupBridge();
        int[] replayed = {0};
        var remote = new NotificationPopupBridge(() -> replayed[0]++);
        var first = new Sink();
        var second = new Sink();
        Map<String, Object> popup = Map.of("key", "message");
        check(!NotificationPopupBridge.deliver(popup));
        launcher.onListen("launcher", first);
        NotificationPopupBridge.presentation(Map.of("host", "launcher", "active", true));
        check(NotificationPopupBridge.deliver(popup));
        check(first.count == 1);
        NotificationPopupBridge.paused();
        check(!NotificationPopupBridge.deliver(popup));
        remote.onListen("remote", second);
        NotificationPopupBridge.presentation(Map.of("host", "remote", "active", true, "avoidPanels", false));
        // A late inactive update/cancellation from the launcher must not steal delivery.
        NotificationPopupBridge.presentation(Map.of("host", "launcher", "active", false));
        launcher.onCancel(null);
        NotificationPopupBridge.paused();
        check(NotificationPopupBridge.deliver(popup));
        check(first.count == 1 && second.count == 1);
        second.detached = true;
        check(!NotificationPopupBridge.deliver(popup));
        second.detached = false;
        check(!NotificationPopupBridge.deliver(popup));
        NotificationPopupBridge.presentation(Map.of("host", "remote", "active", true));
        check(NotificationPopupBridge.deliver(popup));
        remote.onCancel(null);
        check(!NotificationPopupBridge.deliver(popup));
        // Activation can race the EventChannel subscription during engine startup.
        NotificationPopupBridge.presentation(Map.of("host", "late", "active", true));
        check(!NotificationPopupBridge.deliver(popup));
        remote.onListen("late", second);
        check(replayed[0] == 1);
        check(NotificationPopupBridge.deliver(popup));
        remote.onCancel(null);
        System.out.println("Popup routing, lifecycle, detached engine and multi-host checks passed");
    }
}
