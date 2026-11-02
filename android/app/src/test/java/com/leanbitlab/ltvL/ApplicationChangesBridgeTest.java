package com.leanbitlab.ltvL;

import android.content.Context;
import io.flutter.plugin.common.EventChannel;
import java.util.*;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class ApplicationChangesBridgeTest {
    @Test public void missedChangesArriveOnlyOnForegroundAndStopWithSubscription() {
        Context context = RuntimeEnvironment.getApplication();
        var pm = Shadows.shadowOf(context.getPackageManager());
        Queue<Runnable> worker = new ArrayDeque<>(), callbacks = new ArrayDeque<>();
        List<Object> events = new ArrayList<>();
        EventChannel.EventSink sink = new EventChannel.EventSink() {
            public void success(Object event) { events.add(event); }
            public void error(String code, String message, Object details) { fail(code); }
            public void endOfStream() { fail("Unexpected end"); }
        };
        var bridge = new LauncherAppsEventStreamHandler(context, worker::add, callbacks::add);
        try {
            bridge.foreground(true);
            bridge.onListen(null, sink);
            worker.remove().run(); callbacks.remove().run();
            assertTrue(events.isEmpty());
            bridge.foreground(false);
            pm.addChangedPackage(0, "org.example.missed");
            assertTrue(worker.isEmpty());
            bridge.foreground(true);
            worker.remove().run();
            assertTrue(events.isEmpty());
            callbacks.remove().run();
            assertEquals(List.of(Map.of("action", "CATALOG_CHANGED",
                    "packages", List.of("org.example.missed"))), events);
            bridge.foreground(false); bridge.foreground(true);
            worker.remove().run(); callbacks.remove().run();
            assertEquals(1, events.size()); // Cursor advanced; no unchanged notification.
            pm.addChangedPackage(1, "org.example.late");
            bridge.foreground(false); bridge.foreground(true);
            worker.remove().run();
            bridge.close(); callbacks.remove().run();
            assertEquals(1, events.size());
            bridge.foreground(false); bridge.foreground(true);
            assertTrue(worker.isEmpty());
        } finally { bridge.close(); }
    }
}
