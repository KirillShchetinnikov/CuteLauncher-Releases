package com.leanbitlab.ltvL;

import android.Manifest;
import android.app.Activity;
import android.content.pm.PackageManager;
import android.net.NetworkCapabilities;
import android.os.Build;
import android.os.Looper;
import io.flutter.plugin.common.MethodChannel;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.Shadows;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;

/** Execute real platform branches against API 28, 29 and 30 on the JVM. */
@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 29, 30, 36})
public class AndroidCompatibilityTest {
    @Test public void coldStartCrashGuardDoesNotRequireExitHistory() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            assertFalse(CrashLoopGuard.inspect(controller.get()));
            assertFalse(CrashLoopGuard.dartFailure(controller.get()));
        }
    }

    @Test public void wifiCapabilitiesCanBeReadWithoutTransportInfo() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            var caps = org.robolectric.shadows.ShadowNetworkCapabilities.newInstance();
            Shadows.shadowOf(caps).addTransportType(NetworkCapabilities.TRANSPORT_WIFI);
            Shadows.shadowOf(caps).addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
            var info = NetworkUtils.getNetworkCapabilitiesInformation(controller.get(), caps);
            assertEquals(NetworkUtils.NETWORK_TYPE_WIFI, info.get("networkType"));
            assertEquals(true, info.get("networkAccess"));
            assertEquals(false, info.get("internetAccess"));
        }
    }

    @Test public void overlayAndReadOnlyDiagnosticsDoNotRequireNewAppOpsMethods() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            assertFalse(OverlayPermission.granted(controller.get()));
            var report = TvCompatibilityDiagnostics.collect(controller.get(), () -> false);
            var checks = (java.util.Map<?, ?>) report.get("checks");
            assertEquals("available", checks.get("androidVersion"));
            assertNotEquals("unknown", checks.get("usageStats"));
            assertEquals(Integer.toString(Build.VERSION.SDK_INT), ((java.util.Map<?, ?>) report.get("identity")).get("sdk"));
        }
    }

    @Test @Config(sdk = {28, 29})
    @SuppressWarnings("deprecation")
    public void updaterReadsInstallerBeforeInstallSourceInfoExisted() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            activity.getPackageManager().setInstallerPackageName(activity.getPackageName(), "com.android.vending");
            assertEquals("com.android.vending", UpdateBridge.installer(activity));
        }
    }

    @Test public void imeObserverEmitsInitialStateAndDetaches() throws Exception {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            var constructor = ImeVisibilityBridge.class.getDeclaredConstructor(Activity.class);
            constructor.setAccessible(true);
            var bridge = constructor.newInstance(activity);
            var root = (android.view.ViewGroup) activity.getWindow().getDecorView();
            int before = root.getChildCount();
            java.util.List<Object> events = new java.util.ArrayList<>();
            bridge.onListen(null, new io.flutter.plugin.common.EventChannel.EventSink() {
                @Override public void success(Object event) { events.add(event); }
                @Override public void error(String code, String message, Object details) { fail(code); }
                @Override public void endOfStream() { }
            });
            assertEquals(before + 1, root.getChildCount());
            var observer = root.getChildAt(before);
            var insets = new androidx.core.view.WindowInsetsCompat.Builder().build();
            androidx.core.view.ViewCompat.dispatchApplyWindowInsets(observer, insets);
            androidx.core.view.ViewCompat.dispatchApplyWindowInsets(observer, insets);
            assertEquals(java.util.List.of(false), events);
            if (Build.VERSION.SDK_INT >= 30) {
                var floating = new androidx.core.view.WindowInsetsCompat.Builder()
                        .setVisible(androidx.core.view.WindowInsetsCompat.Type.ime(), true).build();
                androidx.core.view.ViewCompat.dispatchApplyWindowInsets(observer, floating);
                assertEquals(java.util.List.of(false, true), events);
            }
            bridge.onCancel(null);
            bridge.onCancel(null);
            assertEquals(before, root.getChildCount());
        }
    }

    @Test public void weatherFreshLocationAndTimeoutReleaseSubscriptions() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            Shadows.shadowOf(activity.getApplication()).grantPermissions(Manifest.permission.ACCESS_COARSE_LOCATION);
            var manager = activity.getSystemService(android.location.LocationManager.class);
            var locations = Shadows.shadowOf(manager);
            locations.setLocationEnabled(true);
            locations.setProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER, true);
            var messenger = new Messenger();
            var bridge = new WeatherLocationBridge(activity, messenger);
            try {
                messenger.locate();
                assertEquals(0, messenger.replies.size());
                var fix = new android.location.Location(android.location.LocationManager.NETWORK_PROVIDER);
                fix.setLatitude(55.75); fix.setLongitude(37.62); fix.setAccuracy(1000);
                fix.setElapsedRealtimeNanos(android.os.SystemClock.elapsedRealtimeNanos());
                locations.simulateLocation(fix);
                Shadows.shadowOf(Looper.getMainLooper()).idle();
                assertEquals(1, messenger.replies.size());
                assertEquals(55.75, ((java.util.Map<?, ?>)messenger.replies.get(0)).get("latitude"));
                assertTrue(locations.getRequestLocationUpdateListeners().isEmpty());
                locations.setLastKnownLocation(android.location.LocationManager.NETWORK_PROVIDER, null);
                messenger.locate();
                Shadows.shadowOf(Looper.getMainLooper()).idleFor(java.time.Duration.ofSeconds(21));
                assertEquals(2, messenger.replies.size());
                assertEquals("LOCATION_UNAVAILABLE", messenger.replies.get(1));
                assertTrue(locations.getRequestLocationUpdateListeners().isEmpty());
            } finally { bridge.dispose(); }
            assertNull(messenger.handler);
        }
    }

    private static final class Messenger implements io.flutter.plugin.common.BinaryMessenger {
        BinaryMessageHandler handler;
        final java.util.List<Object> replies = new java.util.ArrayList<>();
        @Override public void send(String channel, java.nio.ByteBuffer message) { }
        @Override public void send(String channel, java.nio.ByteBuffer message, BinaryReply reply) { }
        @Override public void setMessageHandler(String channel, BinaryMessageHandler handler) { this.handler = handler; }
        void locate() {
            var codec = io.flutter.plugin.common.StandardMethodCodec.INSTANCE;
            var request = codec.encodeMethodCall(new io.flutter.plugin.common.MethodCall("locate", null));
            request.flip();
            handler.onMessage(request, response -> {
                response.flip();
                try { replies.add(codec.decodeEnvelope(response)); }
                catch (io.flutter.plugin.common.FlutterException error) { replies.add(error.code); }
            });
        }
    }

    @Test public void backgroundStorageAccessNeverPromptsAndDeniedRequestCanBeRetried() {
        try (var controller = Robolectric.buildActivity(Activity.class).setup()) {
            Activity activity = controller.get();
            var access = new LegacyStorageAccess(activity);
            var reply = new Reply();
            int[] runs = {0};
            access.run(false, reply, () -> runs[0]++);
            if (Build.VERSION.SDK_INT == 28) {
                assertEquals("document_failed", reply.error);
                assertEquals(0, runs[0]);
                assertNull(Shadows.shadowOf(activity).getLastRequestedPermission());
                access.run(true, new Reply(), () -> runs[0]++);
                assertEquals(1, Shadows.shadowOf(activity).getLastRequestedPermission().requestedPermissions.length);
                access.complete(); // Denial must release the pending operation.
                Shadows.shadowOf(activity.getApplication()).grantPermissions(Manifest.permission.WRITE_EXTERNAL_STORAGE);
                access.run(false, new Reply(), () -> runs[0]++);
            }
            assertEquals(1, runs[0]);
            access.close();
        }
    }

    private static final class Reply implements MethodChannel.Result {
        String error;
        @Override public void success(Object value) { fail("Unexpected reply"); }
        @Override public void error(String code, String message, Object details) { error = code; }
        @Override public void notImplemented() { fail("Unexpected reply"); }
    }
}
