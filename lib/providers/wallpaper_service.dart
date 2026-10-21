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

import 'service_lifecycle.dart';
import '../image_limits.dart';
import '../versioned_file_image.dart';
import 'dart:io';
import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/cupertino.dart';
import '../document_files.dart';
import 'package:path_provider/path_provider.dart';

class WallpaperService extends ChangeNotifier with ServiceLifecycle {
  final FLauncherChannel _fLauncherChannel;
  final SettingsService _settingsService;

  late File _wallpaperFile;
  late File _wallpaperDayFile;
  late File _wallpaperNightFile;
  Timer? _timer;
  late final Future<void> _initialization;

  ImageProvider? _wallpaper;
  int _version = 0;
  int _updateWallpaperCallCount = 0;

  ImageProvider?  get wallpaper     => _wallpaper;
  int             get version       => _version;

  FLauncherGradient get gradient => FLauncherGradients.all.firstWhere(
        (gradient) => gradient.uuid == _settingsService.gradientUuid,
        orElse: () => FLauncherGradients.pitchBlack,
      );

  WallpaperService(this._fLauncherChannel, this._settingsService) :
    _wallpaper = null
  {
    _settingsService.addListener(_onSettingsChanged);
    _initialization = _init();
  }

  bool _lastTimeBasedEnabled = false;

  void _onSettingsChanged() {
    if (isDisposed) return;
    final enabled = _settingsService.timeBasedWallpaperEnabled;
    if (enabled != _lastTimeBasedEnabled) {
      _lastTimeBasedEnabled = enabled;
      _updateTimerState();
      _updateWallpaper();
    }
  }

  @override
  void dispose() {
    ++_updateWallpaperCallCount;
    _settingsService.removeListener(_onSettingsChanged);
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final directory = await getApplicationDocumentsDirectory();
    if (isDisposed) return;
    _wallpaperFile = File("${directory.path}/wallpaper");
    _wallpaperDayFile = File("${directory.path}/wallpaper_day");
    _wallpaperNightFile = File("${directory.path}/wallpaper_night");

    _lastTimeBasedEnabled = _settingsService.timeBasedWallpaperEnabled;
    await _updateWallpaper();
    _updateTimerState();
  }

  Future<void> refresh() async {
    await FileImage(_wallpaperFile).evict();
    await FileImage(_wallpaperDayFile).evict();
    await FileImage(_wallpaperNightFile).evict();
    _version++;
    _updateTimerState();
    await _updateWallpaper(force: true);
  }

  void _updateTimerState() {
    if (isDisposed) return;
    final enabled = _settingsService.timeBasedWallpaperEnabled;
    if (enabled && (_timer == null || !_timer!.isActive)) {
      _timer = Timer.periodic(const Duration(minutes: 1), (_) => _updateWallpaper());
    } else if (!enabled && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<bool> _safeWallpaper(File file) async {
    try { return await file.exists() && await file.length() <= maximumImageInputBytes; }
    on FileSystemException { return false; }
  }

  Future<void> _updateWallpaper({bool force = false}) async {
    if (isDisposed) return;
    final callId = ++_updateWallpaperCallCount;
    final now = DateTime.now();
    final isDay = now.hour >= 6 && now.hour < 18;
    final enabled = _settingsService.timeBasedWallpaperEnabled;

    ImageProvider? newWallpaper;

    if (enabled) {
      if (isDay && await _safeWallpaper(_wallpaperDayFile)) {
        newWallpaper = VersionedFileImage(_wallpaperDayFile, _version);
      } else if (!isDay && await _safeWallpaper(_wallpaperNightFile)) {
        newWallpaper = VersionedFileImage(_wallpaperNightFile, _version);
      } else if (await _safeWallpaper(_wallpaperFile)) {
        newWallpaper = VersionedFileImage(_wallpaperFile, _version); // Fallback
      }
    } else {
      if (await _safeWallpaper(_wallpaperFile)) {
        newWallpaper = VersionedFileImage(_wallpaperFile, _version);
      }
    }

    if (!isDisposed && callId == _updateWallpaperCallCount) {
      if (_wallpaper != newWallpaper || force) {
        _wallpaper = newWallpaper;
        notifyListeners();
      }
    }
  }

  Future<void> pickWallpaper() async {
    await _pickAndSave(_wallpaperFile);
  }

  Future<void> pickWallpaperDay() async {
    await _pickAndSave(_wallpaperDayFile);
  }

  Future<void> pickWallpaperNight() async {
    await _pickAndSave(_wallpaperNightFile);
  }

  Future<void> _pickAndSave(File targetFile) async {
    if (!await _fLauncherChannel.checkForGetContentAvailability()) {
      throw NoFileExplorerException();
    }

    final pickedFile = await DocumentFiles.pickImage();
    if (isDisposed && pickedFile != null) {
      await DocumentFiles.releaseImage(pickedFile);
      return;
    }
    if (!isDisposed && pickedFile != null) {
      final bytes = await DocumentFiles.readImage(pickedFile);
      if (isDisposed) return;
      await targetFile.writeAsBytes(bytes, flush: true);

      // Evict from cache to ensure UI updates
      await FileImage(targetFile).evict();

      _version++;
      await _updateWallpaper(force: true);
    }
  }

  Future<void> reset() async {
    await _initialization;
    if (isDisposed) return;
    for (final file in [_wallpaperFile, _wallpaperDayFile, _wallpaperNightFile]) {
      await FileImage(file).evict();
      if (await file.exists()) await file.delete();
    }
    _version++;
    await _updateWallpaper(force: true);
  }

  Future<void> setGradient(FLauncherGradient fLauncherGradient) async {
    await _settingsService.setBackgroundSource('gradient');
    await _settingsService.setGradientUuid(fLauncherGradient.uuid);
    notifyListeners();
  }
}

class NoFileExplorerException implements Exception {}
