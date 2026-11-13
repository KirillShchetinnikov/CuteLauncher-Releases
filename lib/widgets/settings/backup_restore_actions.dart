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
import '../../providers/video_folder_service.dart';
import '../../providers/update_service.dart';
import '../../providers/night_mode_service.dart';
import '../../providers/wallpaper_service.dart';
import '../../providers/brightness_service.dart';
import '../../providers/automatic_backup_service.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/vpn_service.dart';
import '../../providers/background_startup_service.dart';

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
  final videos = context.read<VideoFolderService?>();
  final updates = context.read<UpdateService?>();
  final night = context.read<NightModeService?>();
  final wallpaper = context.read<WallpaperService>();
  final brightness = context.read<BrightnessService>();
  final automatic = context.read<AutomaticBackupService?>();
  final remotePanel = context.read<RemotePanelService?>();
  final vpn = context.read<VpnService?>();
  final background = context.read<BackgroundStartupService?>();
  await (restoreAction?.call() ?? backup.replaceBackup(file, settings));
  // Restored custom artwork can change bytes at the same saved file path.
  apps.clearImageCaches();
  await apps.refreshState();
  appearance?.reload();
  remotePanel?.reload();
  await vpn?.refresh();
  await background?.refresh();
  await weather?.reloadConfiguration();
  await online?.reload();
  await slideshow?.reload();
  videos?.reload();
  updates?.reloadPreferences();
  night?.reload();
  await wallpaper.refresh();
  await brightness.setEnabled(brightness.isEnabled);
  await automatic?.reloadPreferences();
}
