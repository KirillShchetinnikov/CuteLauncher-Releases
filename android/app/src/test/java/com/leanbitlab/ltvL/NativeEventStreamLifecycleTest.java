package com.leanbitlab.ltvL;

import android.content.Intent;
import android.net.ConnectivityManager;
import android.os.Handler;
import android.os.Looper;
import io.flutter.plugin.common.EventChannel;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.embedding.engine.FlutterJNI;
import io.flutter.embedding.engine.dart.DartExecutor;
import java.util.ArrayList;
import java.util.List;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Robolectric;
import org.robolectric.RuntimeEnvironment;
import org.robolectric.annotation.Config;
import org.robolectric.annotation.LooperMode;
import org.robolectric.annotation.Implements;
import org.robolectric.annotation.Implementation;
import org.robolectric.util.ReflectionHelpers;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36}, shadows = NativeEventStreamLifecycleTest.EngineWithoutNativeRuntime.class)
@LooperMode(LooperMode.Mode.PAUSED)
public class NativeEventStreamLifecycleTest {
    @Implements(FlutterEngine.class)
    public static class EngineWithoutNativeRuntime {
        private final DartExecutor executor = new DartExecutor(new FlutterJNI(),
            RuntimeEnvironment.getApplication().getAssets());
        @Implementation protected void __constructor__(android.content.Context context,
                io.flutter.embedding.engine.loader.FlutterLoader loader, FlutterJNI jni,
                io.flutter.plugin.platform.PlatformViewsController views, String[] args,
                boolean plugins, boolean restoration, io.flutter.embedding.engine.FlutterEngineGroup group) { }
        @Implementation protected DartExecutor getDartExecutor() { return executor; }
    }
    private static class Sink implements EventChannel.EventSink {
        final List<Object> events = new ArrayList<>();
        public void success(Object value) { events.add(value); }
        public void error(String code, String message, Object details) { fail(code); }
        public void endOfStream() { fail("Unexpected end"); }
    }

    @Test public void launcherEngineCleanupClosesSubscribedNativeStreamsWithoutDartCancel() {
        var host = Robolectric.buildActivity(LauncherActivity.class).get();
        var context = RuntimeEnvironment.getApplication();
        var manager = shadowOf(context.getSystemService(ConnectivityManager.class));
        int baseline = manager.getNetworkCallbacks().size();
        var network = new NetworkEventStreamHandler(host);
        var weather = new WeatherEventStreamHandler(host);
        ReflectionHelpers.setField(host, "networkEvents", network);
        ReflectionHelpers.setField(host, "weatherEvents", weather);
        var sink = new Sink();
        try {
            network.onListen(null, sink);
            weather.onListen(null, sink);
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", "{\"currentTemp\":280}"));
            host.cleanUpFlutterEngine(new FlutterEngine(context));
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(baseline, manager.getNetworkCallbacks().size());
            assertTrue(sink.events.isEmpty());
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", "{\"currentTemp\":281}"));
            shadowOf(Looper.getMainLooper()).idle();
            assertTrue(sink.events.isEmpty());
        } finally { network.close(); weather.close(); }
    }

    @Test public void nativeCloseUnregistersWithoutDartCancelAndLateCallbacksCannotReachReconnectedSink() {
        var context = RuntimeEnvironment.getApplication();
        var manager = shadowOf(context.getSystemService(ConnectivityManager.class));
        manager.clearAllNetworks();
        int baseline = manager.getNetworkCallbacks().size();
        var bridge = new NetworkEventStreamHandler(context);
        var first = new Sink(); var second = new Sink();
        try {
            bridge.onListen(null, first);
            assertEquals(baseline + 1, manager.getNetworkCallbacks().size());
            var old = manager.getNetworkCallbacks().iterator().next();
            old.onLost(null);
            assertEquals(1, first.events.size());
            new Handler(Looper.getMainLooper()).post(() -> old.onLost(null));
            bridge.close(); // Native host teardown, not EventChannel/Dart cancel.
            assertEquals(baseline, manager.getNetworkCallbacks().size());
            bridge.onListen(null, second);
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(1, first.events.size());
            assertTrue(second.events.isEmpty());
            var current = manager.getNetworkCallbacks().iterator().next();
            current.onLost(null);
            assertEquals(1, second.events.size());
            bridge.onListen(null, new Sink());
            assertEquals(baseline + 1, manager.getNetworkCallbacks().size());
            bridge.close(); bridge.close();
            assertEquals(baseline, manager.getNetworkCallbacks().size());
        } finally { bridge.close(); }
    }

    @Test public void weatherCloseDropsQueuedEventsAndCannotClearNewHostsListener() {
        var context = RuntimeEnvironment.getApplication();
        context.getSharedPreferences(WeatherReceiver.PREFS_NAME, 0).edit().clear().commit();
        var oldHost = new WeatherEventStreamHandler(context);
        var newHost = new WeatherEventStreamHandler(context);
        var first = new Sink(); var second = new Sink(); var reconnected = new Sink();
        try {
            oldHost.onListen(null, first);
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", "{\"currentTemp\":280}"));
            newHost.onListen(null, second);
            oldHost.close(); // Must not clear the newer owner's listener.
            shadowOf(Looper.getMainLooper()).idle();
            assertTrue(first.events.isEmpty());
            assertEquals(List.of("{\"currentTemp\":280}"), second.events);
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", "{\"currentTemp\":281}"));
            newHost.close();
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(1, second.events.size());
            newHost.onListen(null, reconnected);
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(List.of("{\"currentTemp\":281}"), reconnected.events);
            newHost.onCancel(null);
            new WeatherReceiver().onReceive(context, new Intent(WeatherReceiver.ACTION_GENERIC_WEATHER)
                .putExtra("WeatherJson", "{\"currentTemp\":282}"));
            shadowOf(Looper.getMainLooper()).idle();
            assertEquals(1, reconnected.events.size());
        } finally { oldHost.close(); newHost.close(); }
    }
}
