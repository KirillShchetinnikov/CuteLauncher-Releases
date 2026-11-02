package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.ActivityManager;
import android.content.Intent;
import android.os.Looper;
import android.os.PowerManager;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.StandardMethodCodec;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.Robolectric;
import org.robolectric.RobolectricTestRunner;
import org.robolectric.annotation.Config;
import static org.junit.Assert.*;
import static org.robolectric.Shadows.shadowOf;

@RunWith(RobolectricTestRunner.class)
@Config(sdk = {28, 36})
public class RemotePanelChannelsTest {
    private static final String SYSTEM = "cutelauncher/system_status";

    private static final class Messenger implements BinaryMessenger {
        final Map<String, BinaryMessageHandler> handlers = new HashMap<>();
        final ArrayList<MethodCall> events = new ArrayList<>();
        @Override public void send(String channel, ByteBuffer message) {
            if (SYSTEM.equals(channel)) {
                message.flip();
                events.add(StandardMethodCodec.INSTANCE.decodeMethodCall(message));
            }
        }
        @Override public void send(String channel, ByteBuffer message, BinaryReply reply) {
            send(channel, message);
            if (reply != null) reply.reply(null);
        }
        @Override public void setMessageHandler(String channel, BinaryMessageHandler handler) {
            if (handler == null) handlers.remove(channel);
            else handlers.put(channel, handler);
        }
        CompletableFuture<Object> call(String method, Object arguments) {
            var handler = handlers.get(SYSTEM);
            assertNotNull("The overlay engine must register system status", handler);
            var reply = new CompletableFuture<Object>();
            var request = StandardMethodCodec.INSTANCE.encodeMethodCall(new MethodCall(method, arguments));
            request.flip();
            handler.onMessage(request, response -> {
                if (response == null) {
                    reply.completeExceptionally(new AssertionError("Missing system status method"));
                    return;
                }
                response.flip();
                try { reply.complete(StandardMethodCodec.INSTANCE.decodeEnvelope(response)); }
                catch (RuntimeException error) { reply.completeExceptionally(error); }
            });
            return reply;
        }
    }

    private static Object await(CompletableFuture<Object> reply) throws Exception {
        long deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5);
        while (!reply.isDone() && System.nanoTime() < deadline) {
            shadowOf(Looper.getMainLooper()).idle();
            Thread.sleep(5);
        }
        return reply.get(1, TimeUnit.SECONDS);
    }

    @Test public void overlayReadsRamAndReleasesSystemChannelAndScreenReceiverOnClose() throws Exception {
        try (var activity = Robolectric.buildActivity(Activity.class).setup()) {
            var context = activity.get();
            var memory = new ActivityManager.MemoryInfo();
            memory.totalMem = 4096;
            memory.availMem = 1024;
            shadowOf(context.getSystemService(ActivityManager.class)).setMemoryInfo(memory);
            var power = shadowOf(context.getSystemService(PowerManager.class));
            var messenger = new Messenger();
            // Closing and reopening uses fresh engine-scoped handlers and receivers.
            for (int i = 0; i < 2; i++) {
                power.setIsInteractive(true);
                try (var channels = new RemotePanelChannels(context, messenger, () -> {})) {
                    await(messenger.call("watch", true));
                    var state = (Map<?, ?>) await(messenger.call("snapshot", true));
                    assertEquals(4096L, state.get("ramTotalBytes"));
                    assertEquals(1024L, state.get("ramAvailableBytes"));
                    assertTrue(state.containsKey("cpuPercent"));
                    assertTrue(state.containsKey("uptimeMinutes"));
                    power.setIsInteractive(false);
                    context.sendBroadcast(new Intent(Intent.ACTION_SCREEN_OFF));
                    shadowOf(Looper.getMainLooper()).idle();
                    assertEquals("changed", messenger.events.get(messenger.events.size() - 1).method);
                    assertEquals(false, messenger.events.get(messenger.events.size() - 1).arguments);
                    state = (Map<?, ?>) await(messenger.call("snapshot", false));
                    assertEquals(false, state.get("screenOn"));
                    assertFalse(state.containsKey("ramTotalBytes"));
                }
                assertFalse(messenger.handlers.containsKey(SYSTEM));
                int events = messenger.events.size();
                context.sendBroadcast(new Intent(Intent.ACTION_SCREEN_ON));
                shadowOf(Looper.getMainLooper()).idle();
                assertEquals("Closed overlays must not receive screen events", events, messenger.events.size());
            }
        }
    }
}
