package com.leanbitlab.ltvL;

import android.app.Activity;
import android.app.Instrumentation;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.ColorFilter;
import android.graphics.PixelFormat;
import android.graphics.drawable.Drawable;
import android.os.Build;
import android.os.Bundle;
import java.util.HashSet;

/** Read-only contract checks on an isolated emulator; no permission or HOME changes. */
public final class NativeModulesProbe extends Instrumentation {
    private String module;
    @Override public void onCreate(Bundle args) {
        super.onCreate(args); module = args.getString("module", "apps"); start();
    }
    static void require(boolean condition, String message) {
        if (!condition) throw new AssertionError(message);
    }
    @Override public void onStart() {
        Bundle result = new Bundle();
        try {
            require(Build.HARDWARE.equals("ranchu") || Build.HARDWARE.equals("goldfish"), "Emulator only");
            switch (module) {
                case "apps" -> checkApps();
                case "network" -> checkNetwork();
                case "tv" -> checkTvInputs();
                case "notifications" -> checkNotifications();
                case "watch" -> checkWatchNext();
                default -> throw new AssertionError("Unknown module " + module);
            }
            result.putString("stream", "\nPASS native module: " + module + "\n");
            finish(Activity.RESULT_OK, result);
        } catch (Throwable error) {
            result.putString("stream", "\nFAIL " + error + "\n");
            finish(Activity.RESULT_CANCELED, result);
        }
    }
    private void checkWatchNext() throws Exception {
        var cursorHolder = new android.database.MatrixCursor[1];
        var deletion = new android.net.Uri[1];
        android.content.ContentProvider provider = new android.content.ContentProvider() {
            public boolean onCreate() { return true; }
            public String getType(android.net.Uri uri) { return "vnd.android.cursor.dir/test"; }
            public android.net.Uri insert(android.net.Uri uri, android.content.ContentValues values) { return null; }
            public int update(android.net.Uri uri, android.content.ContentValues values, String where, String[] args) { return 0; }
            public int delete(android.net.Uri uri, String where, String[] args) { deletion[0] = uri; return 1; }
            public android.database.Cursor query(android.net.Uri uri, String[] projection, String where, String[] args, String sort) {
                require(uri.equals(android.media.tv.TvContract.WatchNextPrograms.CONTENT_URI), "Watch Next query URI");
                var cursor = new android.database.MatrixCursor(projection);
                cursorHolder[0] = cursor;
                for (int id = 1; id <= 101; id++) {
                    Object[] row = new Object[projection.length];
                    for (int column = 0; column < projection.length; column++) {
                        row[column] = switch (projection[column]) {
                            case "_id" -> (long) id;
                            case "package_name" -> "io.cutelauncher.fixture";
                            case "title" -> id == 100 ? "" : "Title " + id;
                            case "short_description" -> id == 100 ? "Episode 100" : "Description " + id;
                            case "long_description" -> "Long description " + id;
                            case "episode_title" -> "Episode " + id;
                            case "watch_next_type" -> 0;
                            case "last_engagement_time_utc_millis" -> (long) (id == 98 ? 99 : id);
                            case "last_playback_position_millis" -> 120L;
                            case "duration_millis" -> 600L;
                            case "intent_uri" -> "intent:#Intent;action=android.intent.action.VIEW;end";
                            case "poster_art_uri" -> null;
                            case "thumbnail_uri" -> "content://fixture/thumbnail";
                            default -> throw new AssertionError("Unexpected column " + projection[column]);
                        };
                    }
                    cursor.addRow(row);
                }
                return cursor;
            }
        };
        provider.attachInfo(getTargetContext(), new android.content.pm.ProviderInfo());
        var resolver = android.content.ContentResolver.wrap(provider);
        final android.content.Intent[] launched = {null};
        var isolated = new android.content.ContextWrapper(getTargetContext()) {
            @Override public android.content.ContentResolver getContentResolver() { return resolver; }
            @Override public void startActivity(android.content.Intent intent) { launched[0] = intent; }
        };
        WatchNextBridge bridge = new WatchNextBridge(isolated);
        var programs = bridge.getWatchNextPrograms();
        require(cursorHolder[0].isClosed(), "Watch Next cursor leak");
        require(programs.size() == 20 && programs.get(0).get("id").equals(100L)
            && programs.get(1).get("id").equals(99L) && programs.get(2).get("id").equals(98L), "Watch Next limits/sort changed");
        var first = programs.get(0);
        require(first.get("title").equals("Episode 100") && first.get("description").equals("Long description 100")
            && first.get("lastEngagementTime").equals(100000L) && first.get("posterArtUri").equals("content://fixture/thumbnail"),
            "Watch Next field fallbacks changed");
        require(bridge.deleteWatchNextProgram(7) && deletion[0].equals(android.media.tv.TvContract.buildWatchNextProgramUri(7)),
            "Watch Next deletion URI changed");
        require(!bridge.launchWatchNextProgram(null) && !bridge.launchWatchNextProgram(""), "Empty launch fallback");
        require(bridge.launchWatchNextProgram("intent:#Intent;action=android.intent.action.VIEW;end")
            && launched[0].getAction().equals(android.content.Intent.ACTION_VIEW)
            && (launched[0].getFlags() & android.content.Intent.FLAG_ACTIVITY_NEW_TASK) != 0, "Watch Next launch intent changed");
        require(bridge.getWatchNextPoster("https://example.invalid/image.png") == null
            && bridge.getWatchNextPoster(null) == null, "Remote/empty poster rejection");
        java.io.File poster = java.io.File.createTempFile("module-probe-", ".png", getTargetContext().getCacheDir());
        try {
            var image = android.graphics.Bitmap.createBitmap(16, 8, android.graphics.Bitmap.Config.ARGB_8888);
            try (var output = new java.io.FileOutputStream(poster)) { image.compress(android.graphics.Bitmap.CompressFormat.PNG, 100, output); }
            finally { image.recycle(); }
            require(bridge.getWatchNextPoster(poster.getPath()) != null
                && bridge.getWatchNextPoster(android.net.Uri.fromFile(poster).toString()) != null, "Local poster failed");
            try (var output = new java.io.FileOutputStream(poster)) { output.write(new byte[]{1, 2, 3}); }
            require(bridge.getWatchNextPoster(poster.getPath()) == null, "Corrupt poster accepted");
        } finally { require(poster.delete(), "Probe poster cleanup"); }
        WatchNextBridge subscription = new WatchNextBridge(getTargetContext());
        var field = WatchNextBridge.class.getDeclaredField("observer");
        field.setAccessible(true);
        var count = new java.util.concurrent.atomic.AtomicInteger();
        var sink = new io.flutter.plugin.common.EventChannel.EventSink() {
            public void success(Object value) { require(Boolean.TRUE.equals(value), "Watch Next event payload"); count.incrementAndGet(); }
            public void error(String code, String message, Object details) { throw new AssertionError(code); }
            public void endOfStream() { }
        };
        runOnMainSync(() -> subscription.onListen(null, sink));
        var observer = (android.database.ContentObserver) field.get(subscription);
        runOnMainSync(() -> { observer.onChange(false, android.media.tv.TvContract.WatchNextPrograms.CONTENT_URI); observer.onChange(false, null); });
        android.os.SystemClock.sleep(650);
        waitForIdleSync();
        require(count.get() == 1, "Watch Next debounce changed");
        runOnMainSync(() -> {
            observer.onChange(false, null);
            subscription.onCancel(null);
            observer.onChange(false, null);
        });
        android.os.SystemClock.sleep(650);
        waitForIdleSync();
        require(count.get() == 1 && field.get(subscription) == null, "Late Watch Next event or observer leak");
    }
    private void checkNotifications() throws Exception {
        NotificationBridge bridge = new NotificationBridge(getTargetContext());
        require(LauncherNotificationListenerService.getInstance() == null, "Probe requires an unbound listener");
        require(bridge.getActiveNotifications().isEmpty(), "Missing notification service fallback");
        require(!bridge.dismissNotification("missing") && !bridge.dismissAllNotifications(), "Missing dismissal fallback");
        var listenerField = LauncherNotificationListenerService.class.getDeclaredField("listeners");
        listenerField.setAccessible(true);
        var listeners = (java.util.List<?>) listenerField.get(null);
        int baseline = listeners.size();
        var received = new java.util.concurrent.atomic.AtomicInteger();
        io.flutter.plugin.common.EventChannel.EventSink sink = new io.flutter.plugin.common.EventChannel.EventSink() {
            public void success(Object value) {
                require(value instanceof java.util.List<?>, "Notification event payload changed");
                received.incrementAndGet();
            }
            public void error(String code, String message, Object details) { throw new AssertionError(code); }
            public void endOfStream() { }
        };
        runOnMainSync(() -> bridge.onListen(null, sink));
        waitForIdleSync();
        require(received.get() == 1 && listeners.size() == baseline + 1, "Initial notification subscription");
        runOnMainSync(() -> {
            bridge.onListen(null, sink);
            bridge.onCancel(null);
        });
        waitForIdleSync();
        require(received.get() == 1 && listeners.size() == baseline, "Late event or leaked notification listener");
        final android.content.Intent[] launched = {null};
        NotificationBridge captured = new NotificationBridge(new android.content.ContextWrapper(getTargetContext()) {
            @Override public void startActivity(android.content.Intent intent) { launched[0] = intent; }
        });
        require(captured.openAppNotificationSettings() && launched[0] != null, "Notification settings dispatch");
        require((launched[0].getFlags() & android.content.Intent.FLAG_ACTIVITY_NEW_TASK) != 0, "Notification settings flags");
        NotificationBridge unsupported = new NotificationBridge(new android.content.ContextWrapper(getTargetContext()) {
            @Override public void startActivity(android.content.Intent intent) { throw new android.content.ActivityNotFoundException(); }
        });
        require(!unsupported.openAppNotificationSettings(), "Notification settings unsupported handler fallback");
    }
    private void checkTvInputs() {
        TvInputBridge bridge = new TvInputBridge(getTargetContext());
        for (var input : bridge.getTvInputs()) {
            require(input.get("id") instanceof String && input.get("label") instanceof String
                && input.get("type") instanceof Integer, "TV input payload changed");
        }
        final android.content.Intent[] launched = {null};
        android.content.Context isolated = new android.content.ContextWrapper(getTargetContext()) {
            @Override public Object getSystemService(String name) {
                if (name.equals(android.content.Context.TV_INPUT_SERVICE)) return null;
                return super.getSystemService(name);
            }
            @Override public void startActivity(android.content.Intent intent) { launched[0] = intent; }
        };
        TvInputBridge captured = new TvInputBridge(isolated);
        require(captured.getTvInputs().isEmpty(), "Missing TV input service fallback");
        String id = "io.cutelauncher.fixture/.InputService/HW1";
        require(captured.launchTvInput(id), "TV input dispatch failed");
        require(launched[0].getAction().equals(android.content.Intent.ACTION_VIEW)
            && launched[0].getData().equals(android.media.tv.TvContract.buildChannelUriForPassthroughInput(id))
            && (launched[0].getFlags() & android.content.Intent.FLAG_ACTIVITY_NEW_TASK) != 0, "TV input intent changed");
        TvInputBridge unsupported = new TvInputBridge(new android.content.ContextWrapper(isolated) {
            @Override public void startActivity(android.content.Intent intent) {
                throw new android.content.ActivityNotFoundException();
            }
        });
        require(!unsupported.launchTvInput(id), "Unsupported TV input handler fallback");
    }
    private void checkNetwork() {
        NetworkStatistics statistics = new NetworkStatistics(getTargetContext());
        var network = statistics.getActiveNetworkInformation();
        require(network.containsKey(NetworkUtils.KEY_NETWORK_TYPE)
            && network.get(NetworkUtils.KEY_NETWORK_ACCESS) instanceof Boolean
            && network.get(NetworkUtils.KEY_INTERNET_ACCESS) instanceof Boolean,
            "Network payload changed");
        if (!statistics.checkUsageStatsPermission()) {
            require(statistics.getDailyDataUsage() == -1, "Daily permission sentinel");
            require(statistics.getWeeklyDataUsage() == -1, "Weekly permission sentinel");
            require(statistics.getMonthlyDataUsage() == -1, "Monthly permission sentinel");
        }
        NetworkStatistics unavailable = new NetworkStatistics(new android.content.ContextWrapper(getTargetContext()) {
            @Override public Object getSystemService(String name) {
                if (name.equals(android.content.Context.CONNECTIVITY_SERVICE)) return null;
                return super.getSystemService(name);
            }
        });
        var fallback = unavailable.getActiveNetworkInformation();
        require(fallback.get(NetworkUtils.KEY_NETWORK_TYPE).equals(NetworkUtils.NETWORK_TYPE_UNKNOWN)
            && fallback.get(NetworkUtils.KEY_NETWORK_ACCESS).equals(false)
            && fallback.get(NetworkUtils.KEY_INTERNET_ACCESS).equals(false)
            && fallback.get(NetworkUtils.KEY_WIRELESS_SIGNAL_LEVEL).equals(0), "Network fallback changed");
    }
    private void checkApps() {
        ApplicationCatalog catalog = new ApplicationCatalog(getTargetContext());
        var applications = catalog.getApplications();
        require(!applications.isEmpty(), "Launcher activities missing");
        var packages = new HashSet<String>();
        for (var app : applications) {
            require(packages.add((String) app.get("packageName")), "Duplicate package");
            require(app.containsKey("name") && app.containsKey("version") && app.get("sideloaded") instanceof Boolean,
                "Application payload changed");
        }
        require(catalog.getApplication("io.cutelauncher.missing").isEmpty(), "Missing package result");
        require(catalog.getApplicationIcon("io.cutelauncher.missing").length == 0, "Missing icon result");
        require(catalog.getApplicationBanner("io.cutelauncher.missing").length == 0, "Missing banner result");
        byte[] bytes = catalog.getApplicationIcon(getTargetContext().getPackageName());
        var icon = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        require(icon != null && icon.getWidth() <= 960 && icon.getHeight() <= 960, "Icon PNG/size");
        icon.recycle();
        Drawable large = new Drawable() {
            public void draw(Canvas canvas) { canvas.drawColor(0xff123456); }
            public void setAlpha(int alpha) { }
            public void setColorFilter(ColorFilter filter) { }
            public int getOpacity() { return PixelFormat.OPAQUE; }
            public int getIntrinsicWidth() { return 4000; }
            public int getIntrinsicHeight() { return 2000; }
        };
        var scaled = catalog.drawableToBitmap(large);
        require(scaled.getWidth() == 960 && scaled.getHeight() == 480, "Bounded decoding changed");
        scaled.recycle();
    }
}
