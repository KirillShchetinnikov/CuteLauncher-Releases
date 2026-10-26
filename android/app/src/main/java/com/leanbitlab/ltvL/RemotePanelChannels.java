package com.leanbitlab.ltvL;

import android.content.Context;
import android.content.ContextWrapper;
import android.content.Intent;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Handler;
import android.os.Looper;
import android.provider.Settings;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

/** Service-owned adapters for the same widgets used on the launcher. */
final class RemotePanelChannels implements AutoCloseable {
    private final BinaryMessenger messenger;
    private final Context context;
    private final Handler main = new Handler(Looper.getMainLooper());
    private final ExecutorService worker = Executors.newFixedThreadPool(2);
    private final NetworkEventStreamHandler networkEvents;
    private final LauncherAppsEventStreamHandler appEvents;
    private final NotificationBridge notifications;
    private final NotificationPopupBridge notificationPopups = new NotificationPopupBridge(LauncherNotificationListenerService::transferPopups);
    private final SharedPreferences weather;
    private final RemoteMappingsBridge mappings;
    private final RemoteButtonsBridge buttons;
    private final TvInputBridge inputs;
    private SharedPreferences.OnSharedPreferenceChangeListener weatherListener;
    private boolean closed;
    RemotePanelChannels(Context service, BinaryMessenger messenger, Runnable dismiss) {
        this.messenger = messenger;
        context = new ContextWrapper(service) {
            @Override public void startActivity(Intent intent) {
                super.startActivity(new Intent(intent).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK));
                main.post(dismiss);
            }
        };
        networkEvents = new NetworkEventStreamHandler(context);
        appEvents = new LauncherAppsEventStreamHandler(context);
        notifications = new NotificationBridge(context);
        weather = context.getSharedPreferences(WeatherReceiver.PREFS_NAME, Context.MODE_PRIVATE);
        var network = new NetworkStatistics(context);
        inputs = new TvInputBridge(context, messenger);
        var applications = new ApplicationCatalog(context);
        mappings = new RemoteMappingsBridge(context, messenger, worker, LauncherAccessibilityService::connected);
        buttons = new RemoteButtonsBridge(context, messenger, LauncherAccessibilityService::connected);
        SleepTimerBridge.register(context, messenger, worker);
        NightOverlayService.register(context, messenger, worker);
        TclBlueLight.register(context, messenger, worker);
        new MethodChannel(messenger, "me.efesser.flauncher/method").setMethodCallHandler((call, result) -> {
            try {
                switch (call.method) {
                    case "getApplications" -> load(applications::getApplications, result);
                    case "getApplicationIcon" -> load(() -> applications.getApplicationIcon(call.arguments()), result);
                    case "getApplicationBanner" -> load(() -> applications.getApplicationBanner(call.arguments()), result);
                    case "getActiveNetworkInformation" -> result.success(network.getActiveNetworkInformation());
                    case "getTrafficUsage" -> load(() -> network.getTrafficUsage(call.argument("period")), result);
                    case "getDailyDataUsage" -> load(network::getDailyDataUsage, result);
                    case "getWeeklyDataUsage" -> load(network::getWeeklyDataUsage, result);
                    case "getMonthlyDataUsage" -> load(network::getMonthlyDataUsage, result);
                    case "checkUsageStatsPermission" -> result.success(network.checkUsageStatsPermission());
                    case "requestUsageStatsPermission" -> { network.requestUsageStatsPermission(); result.success(null); }
                    case "getTvInputs" -> result.success(inputs.getTvInputs());
                    case "launchTvInput" -> result.success(inputs.launchTvInput(call.arguments()));
                    case "getActiveNotifications" -> result.success(notifications.getActiveNotifications());
                    case "checkNotificationListenerPermission" -> result.success(notifications.checkNotificationListenerPermission());
                    case "requestNotificationListenerPermission" -> result.success(notifications.requestNotificationListenerPermission());
                    case "openAppNotificationSettings" -> result.success(notifications.openAppNotificationSettings());
                    case "dismissNotification" -> result.success(notifications.dismissNotification(call.argument("key")));
                    case "dismissAllNotifications" -> result.success(notifications.dismissAllNotifications());
                    case "setNotificationPopupPresentation" -> { LauncherNotificationListenerService.setPresentation(context, call.arguments()); result.success(null); }
                    case "getLatestWeatherData" -> result.success(weather.getString(WeatherReceiver.KEY_WEATHER_JSON, null));
                    case "getPackageName" -> result.success(context.getPackageName());
                    case "checkOverlayPermission" -> result.success(OverlayPermission.granted(context));
                    case "checkAccessibilityPermission" -> result.success(LauncherAccessibilityService.connected());
                    case "checkWriteSettingsPermission" -> result.success(Settings.System.canWrite(context));
                    case "requestAccessibilityPermission" -> result.success(start(new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)));
                    case "requestOverlayPermission" -> result.success(start(new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION, Uri.parse("package:" + context.getPackageName()))));
                    case "requestWriteSettingsPermission" -> result.success(start(new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS, Uri.parse("package:" + context.getPackageName()))));
                    case "openSettings" -> result.success(start(new Intent(Settings.ACTION_SETTINGS)));
                    case "openWifiSettings" -> result.success(start(new Intent(Settings.ACTION_WIFI_SETTINGS)));
                    case "openVpnSettings" -> result.success(start(new Intent(Settings.ACTION_VPN_SETTINGS)));
                    case "openDefaultLauncherSettings" -> result.success(start(new Intent(Settings.ACTION_HOME_SETTINGS)));
                    case "openBreezyWeather" -> result.success(launch("org.breezyweather"));
                    case "isBreezyWeatherInstalled" -> {
                        boolean installed;
                        try { context.getPackageManager().getPackageInfo("org.breezyweather", 0); installed = true; }
                        catch (android.content.pm.PackageManager.NameNotFoundException absent) { installed = false; }
                        result.success(installed);
                    }
                    case "isDefaultLauncher" -> {
                        var info = context.getPackageManager().resolveActivity(new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME), android.content.pm.PackageManager.MATCH_DEFAULT_ONLY);
                        result.success(info != null && info.activityInfo != null && context.getPackageName().equals(info.activityInfo.packageName));
                    }
                    case "launchApp" -> result.success(launch(call.arguments()));
                    case "launchActivityFromAction" -> result.success(Settings.ACTION_SETTINGS.equals(call.arguments()) && start(new Intent(Settings.ACTION_SETTINGS)));
                    case "openUrl" -> result.success(start(new Intent(Intent.ACTION_VIEW, Uri.parse(call.arguments()))));
                    case "playClickSound" -> {
                        context.getSystemService(android.media.AudioManager.class).playSoundEffect(android.media.AudioManager.FX_KEY_CLICK, 1f);
                        result.success(null);
                    }
                    default -> result.error("unsupported", "Open this setting from the launcher", null);
                }
            } catch (RuntimeException error) { result.error("unavailable", "Operation unavailable", DiagnosticErrorDetails.from(error)); }
        });
        new EventChannel(messenger, "me.efesser.flauncher/event_network").setStreamHandler(networkEvents);
        new EventChannel(messenger, "me.efesser.flauncher/event_apps").setStreamHandler(appEvents);
        new EventChannel(messenger, "me.efesser.flauncher/event_notifications").setStreamHandler(notifications);
        new EventChannel(messenger, "me.efesser.flauncher/event_notification_popup").setStreamHandler(notificationPopups);
        new EventChannel(messenger, "me.efesser.flauncher/event_weather").setStreamHandler(new EventChannel.StreamHandler() {
            public void onListen(Object args, EventChannel.EventSink sink) {
                onCancel(null);
                weatherListener = (prefs, key) -> {
                    if (WeatherReceiver.KEY_WEATHER_JSON.equals(key)) main.post(() -> { if (!closed) sink.success(weather.getString(key, null)); });
                };
                weather.registerOnSharedPreferenceChangeListener(weatherListener);
                sink.success(weather.getString(WeatherReceiver.KEY_WEATHER_JSON, null));
            }
            public void onCancel(Object args) {
                if (weatherListener != null) weather.unregisterOnSharedPreferenceChangeListener(weatherListener);
                weatherListener = null;
            }
        });
    }
    private boolean start(Intent intent) {
        try { context.startActivity(intent); return true; }
        catch (RuntimeException unavailable) { return false; }
    }
    private boolean launch(String name) {
        var manager = context.getPackageManager();
        var intent = manager.getLeanbackLaunchIntentForPackage(name);
        if (intent == null) intent = manager.getLaunchIntentForPackage(name);
        return intent != null && start(intent);
    }
    private <T> void load(java.util.concurrent.Callable<T> read, MethodChannel.Result result) {
        worker.execute(() -> {
            try { T value = read.call(); main.post(() -> { if (!closed) result.success(value); }); }
            catch (Exception error) { main.post(() -> { if (!closed) result.error("unavailable", "Operation unavailable", DiagnosticErrorDetails.from(error)); }); }
        });
    }
    @Override public void close() {
        closed = true;
        mappings.close(); buttons.close(); inputs.close();
        if (weatherListener != null) weather.unregisterOnSharedPreferenceChangeListener(weatherListener);
        networkEvents.onCancel(null); appEvents.onCancel(null); notifications.onCancel(null);
        notificationPopups.onCancel(null);
        NightOverlayService.detachVisibility(messenger);
        main.removeCallbacksAndMessages(null); worker.shutdownNow();
    }
}
