/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package com.leanbitlab.ltvL;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.content.pm.*;
import android.net.Uri;
import android.os.Build;
import android.provider.Settings;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import java.util.Map;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodChannel;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


public class MainActivity extends FlutterActivity {
    private final String METHOD_CHANNEL = "me.efesser.flauncher/method";
    private final String APPS_EVENT_CHANNEL = "me.efesser.flauncher/event_apps";
    private final String NETWORK_EVENT_CHANNEL = "me.efesser.flauncher/event_network";
    private final String NOTIFICATIONS_EVENT_CHANNEL = "me.efesser.flauncher/event_notifications";
    private final String WEATHER_EVENT_CHANNEL = "me.efesser.flauncher/event_weather";
    private final String WATCH_NEXT_EVENT_CHANNEL = "me.efesser.flauncher/event_watch_next";
    private MethodChannel.Result pendingPermissionResult;
    private WeatherLocationBridge weatherLocationBridge;
    private EventChannel.EventSink homeSink;
    private static java.lang.ref.WeakReference<MainActivity> panelHost = new java.lang.ref.WeakReference<>(null);
    static void panelClosed() {
        MainActivity host = panelHost.get();
        if (host != null && host.homeSink != null) host.homeSink.success("preferences_changed");
    }
    static void panelBlocked() {
        MainActivity host = panelHost.get();
        if (host != null && host.homeSink != null) host.homeSink.success("remote_panel_blocked");
    }
    static final RemotePanelLaunchPolicy remotePanelPolicy = new RemotePanelLaunchPolicy();
    @Override protected void onStart() {
        super.onStart();
        remotePanelPolicy.started(this);
    }
    @Override protected void onStop() {
        remotePanelPolicy.stopped(this);
        super.onStop();
    }
    private boolean pendingHome;
    private ApplicationCatalog applicationCatalog;
    private NetworkStatistics networkStatistics;
    private TvInputBridge tvInputBridge;
    private NotificationBridge notificationBridge;
    private WatchNextBridge watchNextBridge;
    private MediaBridge mediaBridge;
    private DocumentFiles documentFiles;
    private WallpaperFolder wallpaperFolder;
    private BackupFolder backupFolder;
    private AutoLaunchBridge autoLaunch;
    private TvImeEditorBridge tvImeEditorBridge;
    private RemoteButtonsBridge remoteButtons;
    private RemoteMappingsBridge remoteMappings;

    @Override public void cleanUpFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        if (tvInputBridge != null) { tvInputBridge.close(); tvInputBridge = null; }
        if (remoteMappings != null) { remoteMappings.close(); remoteMappings = null; }
        if (remoteButtons != null) { remoteButtons.close(); remoteButtons = null; }
        if (tvImeEditorBridge != null) { tvImeEditorBridge.dispose(); tvImeEditorBridge = null; }
        NightOverlayService.detachVisibility(flutterEngine.getDartExecutor().getBinaryMessenger());
        if (weatherLocationBridge != null) { weatherLocationBridge.dispose(); weatherLocationBridge = null; }
        BatterySettingsGuide.close(this);
        if (autoLaunch != null) { autoLaunch.close(); autoLaunch=null; }
        if (notificationBridge != null) notificationBridge.onCancel(null);
        if (watchNextBridge != null) watchNextBridge.onCancel(null);
        if (mediaBridge != null) mediaBridge.onCancel(null);
        if (panelHost.get() == this) panelHost.clear();
        super.cleanUpFlutterEngine(flutterEngine);
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == DocumentFiles.REQUEST && documentFiles != null) documentFiles.complete(resultCode, data);
        if (requestCode == BackupFolder.REQUEST && backupFolder != null) backupFolder.complete(resultCode, data);
        if (requestCode == WallpaperFolder.REQUEST && wallpaperFolder != null) wallpaperFolder.complete(resultCode, data);
    }

    @Override
    public void onNewIntent(@NonNull Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        if (autoLaunch != null && manualLaunch(intent)) autoLaunch.cancel();
        if ((Intent.ACTION_MAIN.equals(intent.getAction()) && intent.hasCategory(Intent.CATEGORY_HOME))
                || intent.getBooleanExtra("return_home", false)) {
            if (homeSink != null) homeSink.success(true);
            else pendingHome = true;
        }
    }
    private static final ExecutorService sIoExecutor = Executors.newFixedThreadPool(4);
    private boolean manualLaunch(Intent intent) {
        return intent.getBooleanExtra("return_home",false) || Intent.ACTION_MAIN.equals(intent.getAction())
            && (intent.hasCategory(Intent.CATEGORY_HOME) || intent.hasCategory(Intent.CATEGORY_LAUNCHER)
                || intent.hasCategory(Intent.CATEGORY_LEANBACK_LAUNCHER));
    }
    @Override protected void onResume() { super.onResume(); BatterySettingsGuide.close(this); if(autoLaunch!=null) autoLaunch.resume(); }
    @Override protected void onPause() { RemoteButtonRemapper.editing = false; RemoteButtonLearning.cancel(); LauncherNotificationListenerService.launcherPaused(); if(autoLaunch!=null) autoLaunch.pause(); super.onPause(); }
    @Override public void onUserInteraction() { if(autoLaunch!=null) autoLaunch.cancel(); super.onUserInteraction(); }
    @Override public void onWindowFocusChanged(boolean focused) { super.onWindowFocusChanged(focused); if(autoLaunch!=null) autoLaunch.focus(focused); }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        panelHost = new java.lang.ref.WeakReference<>(this);
        weatherLocationBridge = new WeatherLocationBridge(this, flutterEngine.getDartExecutor().getBinaryMessenger());

        BinaryMessenger messenger = flutterEngine.getDartExecutor().getBinaryMessenger();
        new MethodChannel(messenger, "cutelauncher/remote_panel").setMethodCallHandler((call, result) -> {
            if (call.method.equals("show")) result.success(LauncherAccessibilityService.showPanel());
            else result.notImplemented();
        });
        remoteButtons = new RemoteButtonsBridge(this, messenger, this::isAccessibilityServiceEnabled);
        remoteMappings = new RemoteMappingsBridge(this, messenger, sIoExecutor, this::isAccessibilityServiceEnabled);
        autoLaunch = new AutoLaunchBridge(this, messenger);
        Intent initial=getIntent();
        if (initial!=null && Intent.ACTION_MAIN.equals(initial.getAction())
            && (initial.hasCategory(Intent.CATEGORY_LAUNCHER) || initial.hasCategory(Intent.CATEGORY_LEANBACK_LAUNCHER))) autoLaunch.cancel();
        UpdateBridge.register(this, messenger, sIoExecutor);
        ImeVisibilityBridge.register(this, messenger);
        tvImeEditorBridge = new TvImeEditorBridge(this, messenger);
        AdbBridge.register(this, messenger, sIoExecutor);
        SleepTimerBridge.register(this, messenger, sIoExecutor);
        CloudAccountBridge.register(this, messenger, sIoExecutor);
        DriveAccountBridge.register(this, messenger, sIoExecutor);
        NightOverlayService.register(this, messenger, sIoExecutor);
        TclBlueLight.register(this, messenger, sIoExecutor);
        applicationCatalog = new ApplicationCatalog(this);
        networkStatistics = new NetworkStatistics(this);
        tvInputBridge = new TvInputBridge(this, messenger);
        notificationBridge = new NotificationBridge(this);
        mediaBridge = new MediaBridge(this, sIoExecutor);
        mediaBridge.register(messenger, notificationBridge);
        watchNextBridge = new WatchNextBridge(this);
        documentFiles = new DocumentFiles(this, sIoExecutor);
        wallpaperFolder = new WallpaperFolder(this, sIoExecutor);
        backupFolder = new BackupFolder(this, sIoExecutor);
        new EventChannel(messenger, "me.efesser.flauncher/event_home").setStreamHandler(new EventChannel.StreamHandler() {
            public void onListen(Object arguments, EventChannel.EventSink events) {
                homeSink = events;
                if (pendingHome) { pendingHome = false; events.success(true); }
            }
            public void onCancel(Object arguments) { homeSink = null; }
        });

        new MethodChannel(messenger, METHOD_CHANNEL).setMethodCallHandler((call, result) -> {
            try {
            switch (call.method) {
                case "getTvCompatibilityDiagnostics" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        () -> TvCompatibilityDiagnostics.collect(this, this::isAccessibilityServiceEnabled), result::success,
                        error -> result.error("diagnostics_unavailable", "Unable to read compatibility metadata", null));
                case "getDiagnosticEnvironment" -> result.success(Map.of(
                    "androidApi", Build.VERSION.SDK_INT,
                    "defaultHome", isDefaultLauncher(),
                    "overlayAllowed", checkOverlayPermission(),
                    "notificationsAllowed", getSystemService(android.app.NotificationManager.class).areNotificationsEnabled(),
                    "notificationListenerAllowed", notificationBridge.checkNotificationListenerPermission(),
                    "accessibilityEnabled", isAccessibilityServiceEnabled(),
                    "writeSettingsAllowed", checkWriteSettingsPermission(),
                    "watchNextAllowed", watchNextBridge.checkWatchNextPermission()));
                case "pickImageDocument" -> documentFiles.open("image/*", 8L * 1024 * 1024, result);
                case "pickWallpaperFolder" -> wallpaperFolder.pick(result);
                case "listWallpaperFolder" -> wallpaperFolder.list(call.argument("uri"), Boolean.TRUE.equals(call.argument("recursive")), result);
                case "readWallpaperFolderImage" -> wallpaperFolder.read(call.argument("uri"), result);
                case "releaseWallpaperFolder" -> wallpaperFolder.release(call.argument("uri"), result);
                case "pickBackupFolder" -> backupFolder.pick(result);
                case "backupFolderOperation" -> backupFolder.operate(call.argument("operation"), call.argument("uri"), call.argument("name"), call.argument("path"), result);
                case "pickBackupDocument" -> documentFiles.open("*/*", 64L * 1024 * 1024, result);
                case "pickCleanerDocument" -> documentFiles.open("*/*", 256L * 1024, result);
                case "saveBackupDocument" -> documentFiles.save(call.argument("path"), call.argument("name"), result);
                case "saveDiagnosticsDocument" -> documentFiles.saveReport(call.argument("path"), call.argument("name"), result);
                case "saveBackupDownloads" -> documentFiles.saveDownloads(call.argument("path"), result);
                case "getProcessMemoryUsage" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        () -> MemoryDiagnostics.snapshot(getApplicationContext()), result::success,
                        error -> result.error("memory_unavailable", "Unable to measure process memory", null));
                case "getApplications" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task), applicationCatalog::getApplications,
                        result::success,
                        error -> result.error("applications_unavailable", "Unable to query installed applications", null));
                case "getApplicationBanner" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        () -> applicationCatalog.getApplicationBanner(call.arguments()), result::success,
                        error -> result.success(new byte[0]));
                case "getApplicationIcon" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        () -> applicationCatalog.getApplicationIcon(call.arguments()), result::success,
                        error -> result.success(new byte[0]));
                case "launchActivityFromAction" -> { if(autoLaunch!=null) autoLaunch.cancel(); result.success(launchActivityFromAction(call.arguments())); }
                case "launchApp" -> { if(autoLaunch!=null) autoLaunch.cancel(); result.success(launchApp(call.arguments())); }
                case "openUrl" -> result.success(openUrl(call.arguments()));
                case "openSettings" -> result.success(openSettings());
                case "openScreensaverSettings" -> result.success(openScreensaverSettings());
                case "getScreensaverCapabilities" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        () -> new ScreensaverBridge(this).capabilities(), result::success,
                        error -> result.error("unavailable", "Screensaver capabilities unavailable", null));
                case "openAppInfo" -> result.success(openAppInfo(call.arguments()));
                case "uninstallApp" -> result.success(uninstallApp(call.arguments()));
                case "isDefaultLauncher" -> result.success(isDefaultLauncher());
                case "checkForGetContentAvailability" -> result.success(checkForGetContentAvailability());
                case "startAmbientMode" -> result.success(startAmbientMode());
                case "getActiveNetworkInformation" -> result.success(networkStatistics.getActiveNetworkInformation());
                case "getDailyDataUsage", "getWeeklyDataUsage", "getMonthlyDataUsage" -> {
                    java.util.concurrent.Callable<Long> query = switch (call.method) {
                        case "getWeeklyDataUsage" -> networkStatistics::getWeeklyDataUsage;
                        case "getMonthlyDataUsage" -> networkStatistics::getMonthlyDataUsage;
                        default -> networkStatistics::getDailyDataUsage;
                    };
                    ApplicationLoader.load(sIoExecutor,
                            task -> new Handler(Looper.getMainLooper()).post(task), query,
                            usage -> {
                                if (usage == -1) result.error("PERMISSION_DENIED", "Usage stats permission not granted", null);
                                else result.success(usage);
                            },
                            error -> result.error("usage_unavailable", "Unable to query data usage", null));
                }
                case "checkUsageStatsPermission" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        networkStatistics::checkUsageStatsPermission, result::success,
                        error -> result.error("usage_unavailable", "Unable to check usage permission", null));
                case "requestUsageStatsPermission" -> {
                    networkStatistics.requestUsageStatsPermission();
                    result.success(null);
                }
                case "checkWriteSettingsPermission" -> result.success(checkWriteSettingsPermission());
                case "requestWriteSettingsPermission" -> result.success(requestWriteSettingsPermission());
                case "restoreSystemBrightness" -> sIoExecutor.execute(() -> {
                    boolean restored = restoreSystemBrightness();
                    runOnUiThread(() -> result.success(restored));
                });
                case "setSystemBrightness" -> {
                    int brightness = call.argument("brightness");
                    sIoExecutor.execute(() -> {
                        boolean applied = setSystemBrightness(brightness);
                        runOnUiThread(() -> result.success(applied));
                    });
                }
                case "openDefaultLauncherSettings" -> result.success(openDefaultLauncherSettings());
                case "openWifiSettings" -> result.success(openWifiSettings());
                case "openVpnSettings" -> result.success(openVpnSettings());
                case "getTvInputs" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        tvInputBridge::getTvInputs, result::success,
                        error -> result.error("inputs_unavailable", "Unable to query TV inputs", null));
                case "launchTvInput" -> { if(autoLaunch!=null) autoLaunch.cancel(); result.success(tvInputBridge.launchTvInput(call.arguments())); }
                case "checkNotificationListenerPermission" -> result.success(notificationBridge.checkNotificationListenerPermission());
                case "requestNotificationListenerPermission" -> result.success(notificationBridge.requestNotificationListenerPermission());
                case "openAppNotificationSettings" -> result.success(notificationBridge.openAppNotificationSettings());
                case "getActiveNotifications" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        notificationBridge::getActiveNotifications, result::success,
                        error -> result.error("notifications_unavailable", "Unable to query notifications", null));
                case "setNotificationPopupPresentation" -> {
                    LauncherNotificationListenerService.setPresentation(this, call.arguments());
                    result.success(null);
                }
                case "dismissNotification" -> {
                    String key = call.argument("key");
                    result.success(notificationBridge.dismissNotification(key));
                }
                case "dismissAllNotifications" -> result.success(notificationBridge.dismissAllNotifications());
                case "checkOverlayPermission" -> result.success(checkOverlayPermission());
                case "requestOverlayPermission" -> result.success(requestOverlayPermission());
                case "checkAccessibilityPermission" -> result.success(isAccessibilityServiceEnabled());
                case "requestAccessibilityPermission" -> result.success(openAccessibilitySettings());
                case "checkWatchNextPermission" -> result.success(watchNextBridge.checkWatchNextPermission());
                case "requestWatchNextPermission" -> {
                    if (watchNextBridge.checkWatchNextPermission()) {
                        result.success(true);
                    } else {
                        if (pendingPermissionResult != null) {
                            result.error("ALREADY_REQUESTING", "A permission request is already in progress", null);
                        } else {
                            pendingPermissionResult = result;
                            requestPermissions(new String[]{"android.permission.READ_TV_LISTINGS"}, 1002);
                        }
                    }
                }
                case "getWatchNextPrograms" -> ApplicationLoader.load(sIoExecutor,
                        task -> new Handler(Looper.getMainLooper()).post(task),
                        watchNextBridge::getWatchNextPrograms, result::success,
                        error -> result.error("watch_next_unavailable", "Unable to query Watch Next", null));
                case "deleteWatchNextProgram" -> {
                    Number id = call.argument("id");
                    if (id != null) {
                        result.success(watchNextBridge.deleteWatchNextProgram(id.longValue()));
                    } else {
                        result.error("INVALID_ARGUMENT", "Missing id", null);
                    }
                }
                case "getWatchNextPoster" -> {
                    String posterArtUri = call.argument("posterArtUri");
                    sIoExecutor.execute(() -> {
                        byte[] posterBytes = watchNextBridge.getWatchNextPoster(posterArtUri);
                        runOnUiThread(() -> result.success(posterBytes));
                    });
                }
                case "launchWatchNextProgram" -> {
                    String intentUri = call.argument("intentUri");
                    result.success(watchNextBridge.launchWatchNextProgram(intentUri));
                }
                case "getLatestWeatherData" -> result.success(getLatestWeatherData());
                case "isBreezyWeatherInstalled" -> result.success(isBreezyWeatherInstalled());
                case "openBreezyWeather" -> result.success(openBreezyWeather());
                case "getPackageName" -> result.success(getPackageName());
                case "playClickSound" -> {
                    ((android.media.AudioManager) getSystemService(AUDIO_SERVICE))
                            .playSoundEffect(android.media.AudioManager.FX_KEY_CLICK, 1.0f);
                    result.success(null);
                }
                default -> result.notImplemented();
            }
            } catch (SecurityException error) {
                result.error("PERMISSION_DENIED", "Permission denied", null);
            } catch (android.content.ActivityNotFoundException error) {
                result.error("unsupported", "No compatible handler", null);
            } catch (IllegalArgumentException error) {
                result.error("INVALID_ARGUMENT", "Invalid argument", null);
            } catch (Exception error) {
                result.error("operation_failed", "Operation failed", null);
            }
        });

        new EventChannel(messenger, APPS_EVENT_CHANNEL).setStreamHandler(
                new LauncherAppsEventStreamHandler(this));

        new EventChannel(messenger, NETWORK_EVENT_CHANNEL).setStreamHandler(
                new NetworkEventStreamHandler(this));

        new EventChannel(messenger, NOTIFICATIONS_EVENT_CHANNEL).setStreamHandler(notificationBridge);

        new EventChannel(messenger, WEATHER_EVENT_CHANNEL).setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object arguments, EventChannel.EventSink events) {
                        WeatherReceiver.setListener(weatherJson -> {
                            runOnUiThread(() -> {
                                try {
                                    events.success(weatherJson);
                                } catch (Exception e) {
                                    e.printStackTrace();
                                }
                            });
                        });
                        String latest = getLatestWeatherData();
                        if (latest != null) {
                            events.success(latest);
                        }
                    }

                    @Override
                    public void onCancel(Object arguments) {
                        WeatherReceiver.setListener(null);
                    }
                }
        );

        new EventChannel(messenger, WATCH_NEXT_EVENT_CHANNEL).setStreamHandler(watchNextBridge);
    }

    private boolean launchActivityFromAction(String action) {
        // Prevent Intent Action Injection by only allowing known actions
        if (Settings.ACTION_SETTINGS.equals(action)) {
            return tryStartActivity(new Intent(action));
        }
        return false;
    }

    private boolean launchApp(String packageName) {
        PackageManager packageManager = getPackageManager();
        Intent intent = packageManager.getLeanbackLaunchIntentForPackage(packageName);

        if (intent == null) {
            intent = packageManager.getLaunchIntentForPackage(packageName);
        }

        return tryStartActivity(intent);
    }

    private boolean openUrl(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            return tryStartActivity(intent);
        } catch (Exception e) {
            return false;
        }
    }

    private boolean openSettings() {
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openAppInfo(String packageName) {
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean uninstallApp(String packageName) {
        Intent intent = new Intent(Intent.ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null));

        return tryStartActivity(intent);
    }

    private boolean checkForGetContentAvailability() {
        return documentFiles != null && documentFiles.imageAvailable();
    }

    private boolean isDefaultLauncher() {
        Intent intent = new Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME);
        ResolveInfo defaultLauncher = getPackageManager().resolveActivity(intent, 0);

        if (defaultLauncher != null && defaultLauncher.activityInfo != null) {
            return defaultLauncher.activityInfo.packageName.equals(getPackageName());
        }

        return false;
    }

    private boolean startAmbientMode() {
        return new ScreensaverBridge(this).startAmbientMode();
    }

    private boolean tryStartActivity(Intent intent) {
        boolean success = true;

        try {
            startActivity(intent);
        } catch (Exception ignored) {
            success = false;
        }

        return success;
    }

    private boolean checkWriteSettingsPermission() {
        return Settings.System.canWrite(this);
    }

    private boolean requestWriteSettingsPermission() {
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS,
                    Uri.parse("package:" + getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (tryStartActivity(intent)) {
                return true;
            }
        } catch (Exception ignored) {}
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_WRITE_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (tryStartActivity(intent)) {
                return true;
            }
        } catch (Exception ignored) {}
        try {
            Intent intent = new Intent(Settings.ACTION_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return tryStartActivity(intent);
        } catch (Exception ignored) {}
        return false;
    }

    private boolean setSystemBrightness(int brightness) {
        if (brightness < 0 || brightness > 255) return false;
        if (TclBacklight.available()) return TclBacklight.apply(this, brightness);
        return SystemBrightnessWriter.apply(brightness,
                () -> checkWriteSettingsPermission() && saveOriginalBrightness(),
                () -> Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE,
                        Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL),
                () -> Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS, brightness));
    }

    // Separate from exported Flutter preferences: this baseline belongs to this device.
    private boolean saveOriginalBrightness() {
        android.content.SharedPreferences state = getSharedPreferences("brightness_restore", MODE_PRIVATE);
        if (state.contains("mode")) return true;
        try {
            int mode = Settings.System.getInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE);
            int value = Settings.System.getInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS);
            return state.edit().putInt("mode", mode).putInt("value", value).commit();
        } catch (Exception e) {
            return false;
        }
    }

    private boolean restoreSystemBrightness() {
        if (!TclBacklight.restore(this)) return false;
        android.content.SharedPreferences state = getSharedPreferences("brightness_restore", MODE_PRIVATE);
        if (!state.contains("mode")) return true;
        if (!checkWriteSettingsPermission()) return false;
        try {
            boolean valueWritten = Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS,
                    state.getInt("value", 0));
            boolean modeWritten = Settings.System.putInt(getContentResolver(), Settings.System.SCREEN_BRIGHTNESS_MODE,
                    state.getInt("mode", Settings.System.SCREEN_BRIGHTNESS_MODE_MANUAL));
            return valueWritten && modeWritten && state.edit().clear().commit();
        } catch (Exception e) {
            return false; // Keep the baseline so a later retry can restore it.
        }
    }

    private boolean openDefaultLauncherSettings() {
        // 1. Try Android TV home settings
        Intent homeIntent = new Intent(Settings.ACTION_HOME_SETTINGS);
        if (tryStartActivity(homeIntent)) {
            return true;
        }

        // 2. Try manage default apps settings
        Intent defaultAppsIntent = new Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS);
        if (tryStartActivity(defaultAppsIntent)) {
            return true;
        }

        // 3. Fallback to main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openWifiSettings() {
        // 1. Try Android Q+ WiFi panel
        Intent panelIntent = new Intent(Settings.Panel.ACTION_WIFI);
        if (tryStartActivity(panelIntent)) {
            return true;
        }

        // 2. Try standard WiFi settings
        Intent wifiIntent = new Intent(Settings.ACTION_WIFI_SETTINGS);
        if (tryStartActivity(wifiIntent)) {
            return true;
        }

        // 3. Fallback to general wireless settings
        Intent wirelessIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
        if (tryStartActivity(wirelessIntent)) {
            return true;
        }

        // 4. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openVpnSettings() {
        // 1. Try standard VPN settings
        Intent vpnIntent = new Intent(Settings.ACTION_VPN_SETTINGS);
        if (tryStartActivity(vpnIntent)) {
            return true;
        }

        // 2. Fallback to general wireless settings
        Intent wirelessIntent = new Intent(Settings.ACTION_WIRELESS_SETTINGS);
        if (tryStartActivity(wirelessIntent)) {
            return true;
        }

        // 3. Final fallback - open main settings
        return launchActivityFromAction(Settings.ACTION_SETTINGS);
    }

    private boolean openScreensaverSettings() {
        return new ScreensaverBridge(this).openSettings();
    }

    private boolean checkOverlayPermission() {
        return Settings.canDrawOverlays(this);
    }

    private boolean requestOverlayPermission() {
        try {
            Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                    Uri.parse("package:" + getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            startActivity(intent);
            return true;
        } catch (Exception e) {
            try {
                Intent intent = new Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(intent);
                return true;
            } catch (Exception ex) {
                ex.printStackTrace();
                return false;
            }
        }
    }

    private boolean isAccessibilityServiceEnabled() {
        String service = getPackageName() + "/" + LauncherAccessibilityService.class.getName();
        int accessibilityEnabled = 0;
        try {
            accessibilityEnabled = Settings.Secure.getInt(
                getContentResolver(),
                Settings.Secure.ACCESSIBILITY_ENABLED
            );
        } catch (Settings.SettingNotFoundException e) {
            e.printStackTrace();
        }

        if (accessibilityEnabled == 1) {
            String settingValue = Settings.Secure.getString(
                getContentResolver(),
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            );
            if (settingValue != null) {
                String[] services = settingValue.split(":");
                for (String s : services) {
                    if (s.equalsIgnoreCase(service)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private boolean openAccessibilitySettings() {
        try {
            Intent intent = new Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (tryStartActivity(intent)) {
                return true;
            }
        } catch (Exception ignored) {}
        try {
            Intent intent = new Intent(Settings.ACTION_SETTINGS);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            return tryStartActivity(intent);
        } catch (Exception ignored) {}
        return false;
    }

    private String getLatestWeatherData() {
        android.content.SharedPreferences prefs = getSharedPreferences(WeatherReceiver.PREFS_NAME, Context.MODE_PRIVATE);
        return prefs.getString(WeatherReceiver.KEY_WEATHER_JSON, null);
    }

    private boolean isBreezyWeatherInstalled() {
        try {
            getPackageManager().getPackageInfo("org.breezyweather", 0);
            return true;
        } catch (PackageManager.NameNotFoundException e) {
            return false;
        }
    }

    private boolean openBreezyWeather() {
        try {
            Intent launchIntent = getPackageManager().getLaunchIntentForPackage("org.breezyweather");
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                startActivity(launchIntent);
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode == WeatherLocationBridge.PERMISSION_REQUEST && weatherLocationBridge != null) {
            weatherLocationBridge.onPermissionResult();
        }
        if (requestCode == 1002) {
            if (pendingPermissionResult != null) {
                boolean granted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
                pendingPermissionResult.success(granted);
                pendingPermissionResult = null;
            }
        }
    }
}
