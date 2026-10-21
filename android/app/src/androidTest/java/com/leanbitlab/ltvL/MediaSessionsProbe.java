package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.media.MediaMetadata;
import android.media.session.MediaSession;
import android.media.session.PlaybackState;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import io.flutter.plugin.common.EventChannel;

/** Exercises a disposable local player on an isolated emulator; no real playback/access changes. */
public final class MediaSessionsProbe extends Instrumentation {
    @Override public void onCreate(Bundle args) { super.onCreate(args); start(); }
    private static void require(boolean condition, String message) { if (!condition) throw new AssertionError(message); }
    private Map<String, Object> snapshot(MediaBridge bridge) throws Exception {
        @SuppressWarnings("unchecked") Map<String, Object>[] result = new Map[1];
        CountDownLatch ready = new CountDownLatch(1);
        runOnMainSync(() -> bridge.snapshot(value -> { result[0] = value; ready.countDown(); }));
        require(ready.await(10, TimeUnit.SECONDS), "Snapshot timeout");
        return result[0];
    }
    @Override public void onStart() {
        Bundle report = new Bundle();
        var worker = Executors.newSingleThreadExecutor();
        MediaSession session = null;
        MediaBridge bridge = new MediaBridge(getTargetContext(), worker);
        Bitmap cover = null;
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"), "Emulator only");
            // Only this test process gets temporary shell identity; listener settings are untouched.
            getUiAutomation().adoptShellPermissionIdentity("android.permission.MEDIA_CONTENT_CONTROL");
            session = new MediaSession(getTargetContext(), "CuteLauncher test player");
            MediaSession player = session;
            CountDownLatch paused = new CountDownLatch(1), resumed = new CountDownLatch(1), next = new CountDownLatch(1);
            session.setCallback(new MediaSession.Callback() {
                public void onPause() {
                    player.setPlaybackState(new PlaybackState.Builder().setState(PlaybackState.STATE_PAUSED, 10, 0)
                        .setActions(PlaybackState.ACTION_PLAY).build()); paused.countDown();
                }
                public void onPlay() {
                    player.setPlaybackState(new PlaybackState.Builder().setState(PlaybackState.STATE_PLAYING, 10, 1)
                        .setActions(PlaybackState.ACTION_PAUSE | PlaybackState.ACTION_SKIP_TO_NEXT).build()); resumed.countDown();
                }
                public void onSkipToNext() { next.countDown(); }
            }, new Handler(Looper.getMainLooper()));
            cover = Bitmap.createBitmap(700, 300, Bitmap.Config.ARGB_8888); cover.eraseColor(0xff334455);
            session.setMetadata(new MediaMetadata.Builder().putString(MediaMetadata.METADATA_KEY_TITLE, "Probe track")
                .putString(MediaMetadata.METADATA_KEY_ARTIST, "Probe artist").putBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART, cover).build());
            session.setPlaybackState(new PlaybackState.Builder().setState(PlaybackState.STATE_PLAYING, 0, 1)
                .setActions(PlaybackState.ACTION_PAUSE | PlaybackState.ACTION_SKIP_TO_NEXT).build());
            session.setActive(true);
            Map<String, Object> packet = snapshot(bridge);
            require(packet.get("allowed").equals(true), "Media access not available to test identity");
            @SuppressWarnings("unchecked") Map<String, Object> item = (Map<String, Object>) packet.get("item");
            require(item != null && item.get("title").equals("Probe track") && item.get("artist").equals("Probe artist"), "Metadata payload");
            require(item.get("canPause").equals(true) && item.get("canPlay").equals(false) && item.get("canNext").equals(true), "Playing actions");
            byte[] bytes = (byte[]) item.get("artwork");
            require(bytes != null && bytes.length <= 512 * 1024, "Artwork bytes");
            var decoded = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
            require(decoded.getWidth() == 256 && decoded.getHeight() <= 256, "Artwork bounds"); decoded.recycle();
            String id = (String) item.get("id");
            require(!bridge.action("obsolete-session", "pause"), "Stale control accepted");
            require(bridge.action(id, "pause") && paused.await(3, TimeUnit.SECONDS), "Pause callback");
            @SuppressWarnings("unchecked") Map<String, Object> pausedItem = (Map<String, Object>) snapshot(bridge).get("item");
            require(pausedItem.get("canPlay").equals(true) && pausedItem.get("canNext").equals(false), "Paused actions");
            require(!bridge.action(id, "next"), "Unsupported next accepted");
            require(bridge.action(id, "play") && resumed.await(3, TimeUnit.SECONDS), "Resume callback");
            require(bridge.action(id, "next") && next.await(3, TimeUnit.SECONDS), "Next callback");
            CountDownLatch subscribed = new CountDownLatch(1);
            runOnMainSync(() -> bridge.onListen(null, new EventChannel.EventSink() {
                public void success(Object value) { subscribed.countDown(); }
                public void error(String code, String message, Object details) { }
                public void endOfStream() { }
            }));
            require(subscribed.await(3, TimeUnit.SECONDS), "Initial event");
            runOnMainSync(() -> bridge.onCancel(null));
            var watched = MediaBridge.class.getDeclaredField("watched"); watched.setAccessible(true);
            require(((java.util.List<?>) watched.get(bridge)).isEmpty(), "Controller callback leak");
            var registered = MediaBridge.class.getDeclaredField("registered"); registered.setAccessible(true);
            require(!registered.getBoolean(bridge), "Session listener leak");
            session.release(); session = null;
            require(snapshot(bridge).get("item") == null, "Destroyed session remains visible");
            getUiAutomation().dropShellPermissionIdentity();
            require(snapshot(bridge).get("allowed").equals(false), "Missing notification access fallback");
            report.putString("stream", "\nPASS metadata, bounded artwork, pause/resume/next, stale/unsupported commands, disposal, permission denial\n");
            finish(Activity.RESULT_OK, report);
        } catch (Throwable failure) {
            report.putString("stream", "\nFAIL " + failure + "\n"); finish(Activity.RESULT_CANCELED, report);
        } finally {
            runOnMainSync(() -> bridge.onCancel(null));
            if (session != null) session.release();
            if (cover != null) cover.recycle();
            getUiAutomation().dropShellPermissionIdentity(); worker.shutdownNow();
        }
    }
}
