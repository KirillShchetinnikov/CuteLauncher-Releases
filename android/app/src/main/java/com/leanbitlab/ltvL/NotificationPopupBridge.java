package com.leanbitlab.ltvL;

import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.EventChannel;

/** Main-thread delivery to the visible Flutter host, otherwise native fallback. */
final class NotificationPopupBridge implements EventChannel.StreamHandler {
    private static final Map<String, EventChannel.EventSink> hosts = new HashMap<>();
    private static String activeHost;
    private static boolean activeLauncher;
    private String host;
    private final Runnable ready;

    NotificationPopupBridge() { this(() -> {}); }
    NotificationPopupBridge(Runnable ready) { this.ready = ready; }

    @Override public void onListen(Object arguments, EventChannel.EventSink sink) {
        onCancel(null);
        if (arguments instanceof String) {
            host = (String) arguments;
            hosts.put(host, sink);
            if (host.equals(activeHost)) ready.run();
        }
    }

    @Override public void onCancel(Object arguments) {
        if (host != null) {
            hosts.remove(host);
            if (host.equals(activeHost)) activeHost = null;
            host = null;
        }
    }

    static void presentation(Map<String, Object> values) {
        Object host = values.get("host");
        if (!(host instanceof String)) return;
        if (Boolean.TRUE.equals(values.get("active"))) {
            activeHost = (String) host;
            activeLauncher = !Boolean.FALSE.equals(values.get("avoidPanels"));
        }
        else if (host.equals(activeHost)) activeHost = null;
    }

    static void paused() { if (activeLauncher) activeHost = null; }

    static boolean deliver(Map<String, Object> popup) {
        EventChannel.EventSink sink = hosts.get(activeHost);
        if (sink == null) return false;
        try { sink.success(popup); return true; }
        catch (RuntimeException detached) { activeHost = null; return false; }
    }
}
