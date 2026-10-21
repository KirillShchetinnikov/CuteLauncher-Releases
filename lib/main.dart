/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'providers/memory_resources.dart';
import 'providers/screensaver_service.dart';
import 'diagnostics/economy_diagnostics.dart';
import 'providers/settings_sync_service.dart';
import 'providers/sleep_timer_service.dart';
import 'providers/automatic_backup_service.dart';
import 'providers/cloud_backup_service.dart';
import 'providers/drive_backup_service.dart';
import 'providers/backup_automation_service.dart';
import 'widgets/settings/backup_restore_actions.dart';
import 'providers/update_service.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:flauncher/database.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flutter/material.dart';
import 'providers/slideshow_service.dart';
import 'providers/now_playing_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'providers/night_mode_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/appearance_service.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'flauncher_app.dart';
import 'providers/remote_panel_service.dart';
import 'widgets/remote_panel.dart';
import 'package:flauncher/l10n/app_localizations.dart';

Future<void> main() => _runLauncher();

@pragma('vm:entry-point')
Future<void> remotePanelMain() => _runLauncher(remotePanel: true);

Future<void> _runLauncher({bool remotePanel = false}) async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(['dadb'],
        await rootBundle.loadString('docs/DADB_LICENSE.txt'));
    yield LicenseEntryWithLineBreaks(['dadb', 'Okio', 'Kotlin', 'Kotlinx Coroutines',
        'JetBrains annotations', 'AndroidX', 'ReLinker', 'Guava ListenableFuture', 'JSpecify'],
        await rootBundle.loadString('assets/licenses/android_runtime.txt'));
    for (final family in ['roboto', 'notoserif', 'robotomono', 'robotocondensed']) {
      yield LicenseEntryWithLineBreaks([family],
          await rootBundle.loadString('assets/fonts/LICENSE_$family.txt'));
    }
  });
  initializeDateFormatting();

  // Configure LRU Image Cache bounds to preserve RAM on Android TV devices
  PaintingBinding.instance.imageCache.maximumSizeBytes = (remotePanel ? 8 : 50) * 1024 * 1024; // 50MB max RAM
  PaintingBinding.instance.imageCache.maximumSize = remotePanel ? 20 : 100; // max 100 images

  // Global Error Boundary & Crash Protection
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FLauncher Error Boundary: ${details.exception}');
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFF0F0F0F),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 12),
              Builder(builder: (context) => Text(
                AppLocalizations.of(context)?.appError ?? 'Something went wrong',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              )),
              const SizedBox(height: 8),
              Text(
                details.exceptionAsString(),
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  };

  final sharedPreferences = await SharedPreferences.getInstance();
  final settingsSync = SettingsSyncService(sharedPreferences);
  try { if (!remotePanel) await settingsSync.recover(); }
  catch (_) { debugPrint('Settings exchange recovery will be retried.'); }
  final packageInfo = await PackageInfo.fromPlatform();
  final fLauncherChannel = FLauncherChannel();
  final fLauncherDatabase = FLauncherDatabase(connect());

  if (remotePanel) {
    bool closing = false;
    remotePanelChannel.setMethodCallHandler((call) async {
      if (call.method != 'dispose' || closing) return;
      closing = true;
      runApp(const SizedBox.shrink());
      await WidgetsBinding.instance.endOfFrame;
      await fLauncherDatabase.close();
      await remotePanelChannel.invokeMethod<void>('closed');
    });
  }
  runApp(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RemotePanelService(sharedPreferences)),
        ChangeNotifierProvider(create: (_) => CloudBackupService()),
        ChangeNotifierProvider(create: (_) => DriveBackupService()),
        ChangeNotifierProvider(create: (_) => NightModeService(sharedPreferences, remotePanel: remotePanel), lazy: false),
        ChangeNotifierProvider(create: (_) => UpdateService(sharedPreferences), lazy: remotePanel),
        ChangeNotifierProvider(create: (_) => AppearanceService(sharedPreferences)),
        Provider<BackupService>(
          create: (_) => BackupService(fLauncherDatabase, sharedPreferences),
        ),
        ChangeNotifierProvider(
            create: (_) => SettingsService(sharedPreferences),
            lazy: false),
        ChangeNotifierProvider(create: (context) => AutomaticBackupService(
            context.read<BackupService>(), context.read<SettingsService>(), sharedPreferences), lazy: remotePanel),
        ChangeNotifierProvider(create: (context) => MemoryResources(settings: context.read<SettingsService>()), lazy: false),
        ChangeNotifierProvider(create: (context) => AppsService(fLauncherChannel, fLauncherDatabase,
          settingsService: context.read<SettingsService>(), ownPackageName: packageInfo.packageName, memoryResources: context.read<MemoryResources>())),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider(create: (_) => ScreensaverService()..refresh(), lazy: remotePanel),
        ChangeNotifierProvider(create: (_) => SleepTimerService()..refresh(), lazy: false),
        ChangeNotifierProvider(create: (_) => NetworkService(fLauncherChannel)),
        ChangeNotifierProvider(
            create: (context) {
              SettingsService settingsService = Provider.of(context, listen: false);
              return WallpaperService(fLauncherChannel, settingsService);
            }
        ),
        ChangeNotifierProvider(
            create: (context) => BrightnessService(sharedPreferences, nightMode: context.read<NightModeService>()),
            lazy: false),
        ChangeNotifierProvider(create: (context) => TvInputsService(fLauncherChannel, preferences: sharedPreferences, settings: context.read<SettingsService>())),
        ChangeNotifierProvider(create: (_) => NotificationsService(fLauncherChannel)),
        ChangeNotifierProvider(create: (context) => NowPlayingService(context.read<SettingsService>())),
        ChangeNotifierProvider(create: (context) => WatchNextService(fLauncherChannel, onAppLaunched: context.read<AppsService>().recordAppLaunch, memoryResources: context.read<MemoryResources>())),
        ChangeNotifierProvider(create: (_) => WeatherService(fLauncherChannel, preferences: sharedPreferences)),
        ChangeNotifierProvider(create: (_) => OnlineWallpaperService(sharedPreferences)),
        ChangeNotifierProvider(create: (context) => SlideshowService(sharedPreferences, context.read<SettingsService>())),
        ChangeNotifierProvider(create: (context) => BackupAutomationService(
          sharedPreferences, context.read<BackupService>(), context.read<SettingsService>(),
          context.read<AutomaticBackupService>(), context.read<CloudBackupService>(), context.read<DriveBackupService>(),
          sources: [context.read<TvInputsService>(), context.read<SettingsService>(), context.read<AppearanceService>(), context.read<AppsService>(),
            context.read<WallpaperService>(), context.read<BrightnessService>(), context.read<NightModeService>(),
            context.read<WeatherService>(), context.read<SlideshowService>(), context.read<OnlineWallpaperService>(),
            context.read<NotificationsService>(), context.read<WatchNextService>(), context.read<UpdateService>()],
          databaseSources: [context.read<AppsService>()],
          resourceSources: [context.read<WallpaperService>(), context.read<AppsService>()],
          apply: (file) => restoreBackupAndRefresh(context, file,
            restoreAction: () => context.read<BackupService>().replaceBackup(file, context.read<SettingsService>())),
        ), lazy: remotePanel),
      ],
      child: const bool.fromEnvironment('CUTE_PERFORMANCE_PROBE')
          ? EconomyDiagnostics(child: FLauncherApp(remotePanel: remotePanel)) : FLauncherApp(remotePanel: remotePanel)
    )
  );
}
