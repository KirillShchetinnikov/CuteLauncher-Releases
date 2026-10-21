package com.leanbitlab.ltvL;

import android.content.ComponentName;
import android.content.Context;
import android.graphics.Bitmap;
import android.media.MediaMetadata;
import android.media.session.MediaController;
import android.media.session.MediaSessionManager;
import android.media.session.PlaybackState;
import android.os.Handler;
import android.os.Looper;
import android.view.KeyEvent;
import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Executor;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/** Foreground-only media controls. Never requests access or starts playback automatically. */
final class MediaBridge implements EventChannel.StreamHandler {
    private final MediaSessionManager manager;
    private final ComponentName listener;
    private final Executor worker;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final List<MediaController> watched = new ArrayList<>();
    private EventChannel.EventSink sink;
    private MediaController selected;
    private String selectedId;
    private boolean registered;
    private int generation;
    private long revision;
    private final MediaSessionManager.OnActiveSessionsChangedListener sessions = ignored -> changed();
    private final MediaController.Callback callback = new MediaController.Callback() {
        @Override public void onPlaybackStateChanged(PlaybackState state) { changed(); }
        @Override public void onMetadataChanged(MediaMetadata metadata) { changed(); }
        @Override public void onSessionDestroyed() { changed(); }
    };
    private final Runnable update = () -> {
        final EventChannel.EventSink target = sink;
        final int subscription = generation;
        snapshot(value -> { if (target != null && target == sink && subscription == generation) target.success(value); });
    };
    interface Reply { void accept(Map<String, Object> value); }

    MediaBridge(Context context, Executor worker) {
        manager = (MediaSessionManager) context.getSystemService(Context.MEDIA_SESSION_SERVICE);
        listener = new ComponentName(context, LauncherNotificationListenerService.class);
        this.worker = worker;
    }
    void register(BinaryMessenger messenger, NotificationBridge notifications) {
        new EventChannel(messenger, "cutelauncher/media_events").setStreamHandler(this);
        new MethodChannel(messenger, "cutelauncher/media").setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "snapshot" -> snapshot(result::success);
                case "action" -> result.success(action(call.argument("id"), call.argument("action")));
                case "permission" -> result.success(notifications.requestNotificationListenerPermission());
                default -> result.notImplemented();
            }
        });
    }
    private void changed() {
        main.removeCallbacks(update);
        if (sink != null) main.postDelayed(update, 50);
    }
    @Override public void onListen(Object arguments, EventChannel.EventSink events) {
        onCancel(null);
        sink = events;
        try {
            if (manager != null) {
                manager.addOnActiveSessionsChangedListener(sessions, listener, main);
                registered = true;
            }
        } catch (RuntimeException ignored) { }
        update.run();
    }
    @Override public void onCancel(Object arguments) {
        generation++;
        main.removeCallbacksAndMessages(null);
        if (registered) {
            try { manager.removeOnActiveSessionsChangedListener(sessions); } catch (RuntimeException ignored) { }
            registered = false;
        }
        for (MediaController controller : watched) controller.unregisterCallback(callback);
        watched.clear();
        selected = null;
        selectedId = null;
        sink = null;
    }
    private List<MediaController> controllers() {
        if (manager == null) throw new SecurityException();
        List<MediaController> result = manager.getActiveSessions(listener);
        return result.size() > 16 ? result.subList(0, 16) : result;
    }
    private void select(List<MediaController> controllers) {
        MediaController candidate = null;
        for (MediaController controller : controllers) {
            PlaybackState state = controller.getPlaybackState();
            if (state == null || state.getState() == PlaybackState.STATE_NONE || state.getState() == PlaybackState.STATE_STOPPED
                    || state.getState() == PlaybackState.STATE_ERROR) continue;
            if (candidate == null) candidate = controller;
            if (playing(state)) { candidate = controller; break; }
        }
        if (candidate == null) { selected = null; selectedId = null; }
        else if (selected == null || !selected.getSessionToken().equals(candidate.getSessionToken())) {
            selected = candidate;
            selectedId = UUID.randomUUID().toString();
        } else selected = candidate;
    }
    private static boolean playing(PlaybackState state) {
        return state.getState() == PlaybackState.STATE_PLAYING || state.getState() == PlaybackState.STATE_BUFFERING
            || state.getState() == PlaybackState.STATE_FAST_FORWARDING || state.getState() == PlaybackState.STATE_REWINDING;
    }
    private static boolean supported(PlaybackState state, String action) {
        long bits = state.getActions();
        return switch (action) {
            case "play" -> !playing(state) && (bits & (PlaybackState.ACTION_PLAY | PlaybackState.ACTION_PLAY_PAUSE)) != 0;
            case "pause" -> playing(state) && (bits & (PlaybackState.ACTION_PAUSE | PlaybackState.ACTION_PLAY_PAUSE)) != 0;
            case "next" -> (bits & PlaybackState.ACTION_SKIP_TO_NEXT) != 0;
            default -> false;
        };
    }
    void snapshot(Reply reply) {
        final Map<String, Object> packet = new HashMap<>();
        packet.put("revision", ++revision);
        Bitmap artwork = null;
        try {
            List<MediaController> controllers = controllers();
            select(controllers);
            packet.put("allowed", true);
            if (sink != null) {
                for (MediaController controller : watched) controller.unregisterCallback(callback);
                watched.clear();
                for (MediaController controller : controllers) { controller.registerCallback(callback, main); watched.add(controller); }
            }
            if (selected != null) {
                PlaybackState state = selected.getPlaybackState();
                MediaMetadata metadata = selected.getMetadata();
                if (state != null) {
                    Map<String, Object> item = new HashMap<>();
                    item.put("id", selectedId);
                    item.put("packageName", selected.getPackageName());
                    item.put("title", text(metadata, MediaMetadata.METADATA_KEY_DISPLAY_TITLE, MediaMetadata.METADATA_KEY_TITLE));
                    item.put("artist", text(metadata, MediaMetadata.METADATA_KEY_DISPLAY_SUBTITLE, MediaMetadata.METADATA_KEY_ARTIST));
                    item.put("playing", playing(state));
                    item.put("canPlay", supported(state, "play"));
                    item.put("canPause", supported(state, "pause"));
                    item.put("canNext", supported(state, "next"));
                    packet.put("item", item);
                    if (metadata != null) {
                        artwork = metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON);
                        if (artwork == null) artwork = metadata.getBitmap(MediaMetadata.METADATA_KEY_ART);
                        if (artwork == null) artwork = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART);
                    }
                }
            }
        } catch (RuntimeException ignored) {
            packet.put("allowed", false);
            selected = null; selectedId = null;
            for (MediaController controller : watched) controller.unregisterCallback(callback);
            watched.clear();
        }
        final Bitmap image = artwork;
        worker.execute(() -> {
            byte[] bytes = artwork(image);
            if (bytes != null && packet.get("item") instanceof Map) {
                @SuppressWarnings("unchecked") Map<String, Object> item = (Map<String, Object>) packet.get("item");
                item.put("artwork", bytes);
            }
            main.post(() -> reply.accept(packet));
        });
    }
    private static String text(MediaMetadata metadata, String first, String second) {
        if (metadata == null) return "";
        CharSequence value = metadata.getText(first);
        if (value == null || value.length() == 0) value = metadata.getText(second);
        if (value == null) return "";
        return value.subSequence(0, Math.min(value.length(), 512)).toString();
    }
    static byte[] artwork(Bitmap original) {
        if (original == null || original.isRecycled() || (long) original.getWidth() * original.getHeight() > 48L * 1024 * 1024) return null;
        Bitmap scaled = null;
        try {
            double factor = Math.min(1.0, 256.0 / Math.max(original.getWidth(), original.getHeight()));
            scaled = Bitmap.createScaledBitmap(original, Math.max(1, (int) (original.getWidth() * factor)),
                Math.max(1, (int) (original.getHeight() * factor)), true);
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            if (!scaled.compress(Bitmap.CompressFormat.PNG, 100, output) || output.size() > 512 * 1024) return null;
            return output.toByteArray();
        } catch (RuntimeException ignored) { return null; }
        finally { if (scaled != null && scaled != original) scaled.recycle(); }
    }
    boolean action(String id, String action) {
        try {
            select(controllers());
            if (selected == null || id == null || !id.equals(selectedId)) return false;
            PlaybackState state = selected.getPlaybackState();
            if (state == null || !supported(state, action)) return false;
            if (action.equals("next")) selected.getTransportControls().skipToNext();
            else if ((state.getActions() & (action.equals("play") ? PlaybackState.ACTION_PLAY : PlaybackState.ACTION_PAUSE)) != 0) {
                if (action.equals("play")) selected.getTransportControls().play();
                else selected.getTransportControls().pause();
            } else {
                selected.dispatchMediaButtonEvent(new KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE));
                selected.dispatchMediaButtonEvent(new KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE));
            }
            return true;
        } catch (RuntimeException ignored) { return false; }
    }
}
