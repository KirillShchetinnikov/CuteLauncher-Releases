import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../providers/apps_service.dart';
import '../../providers/backup_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/appearance_service.dart';
import '../../providers/weather_service.dart';
import '../../providers/online_wallpaper_service.dart';
import '../../providers/slideshow_service.dart';
import '../../providers/update_service.dart';
import '../../providers/night_mode_service.dart';
import '../../providers/wallpaper_service.dart';
import '../../providers/brightness_service.dart';
import '../../providers/automatic_backup_service.dart';

/// Refresh the same live services after either a public or automatic restore.
Future<void> restoreBackupAndRefresh(
  BuildContext context,
  File file, {
  Future<void> Function()? restoreAction,
}) async {
  final backup = context.read<BackupService>();
  final settings = context.read<SettingsService>();
  final apps = context.read<AppsService>();
  final appearance = context.read<AppearanceService?>();
  final weather = context.read<WeatherService?>();
  final online = context.read<OnlineWallpaperService?>();
  final slideshow = context.read<SlideshowService?>();
  final updates = context.read<UpdateService?>();
  final night = context.read<NightModeService?>();
  final wallpaper = context.read<WallpaperService>();
  final brightness = context.read<BrightnessService>();
  final automatic = context.read<AutomaticBackupService?>();
  await (restoreAction?.call() ?? backup.replaceBackup(file, settings));
  // Restored custom artwork can change bytes at the same saved file path.
  apps.clearImageCaches();
  await apps.refreshState();
  appearance?.reload();
  await weather?.reloadConfiguration();
  await online?.reload();
  await slideshow?.reload();
  updates?.reloadPreferences();
  night?.reload();
  await wallpaper.refresh();
  await brightness.setEnabled(brightness.isEnabled);
  await automatic?.reloadPreferences();
}
