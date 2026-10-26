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
import '../local_background_media.dart';
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
  late File _videoFile;
  File? _video;
  File? get video => _video;
  final Future<void> Function(File) _validateVideo;
  bool _picking = false;
  late File _wallpaperDayFile;
  late File _wallpaperNightFile;
  Timer? _timer;
  late final Future<void> _initialization;

  ImageProvider? _wallpaper;
  int _version = 0;
  int _updateWallpaperCallCount = 0;

  ImageProvider? get wallpaper => _wallpaper;
  int get version => _version;

  FLauncherGradient get gradient => FLauncherGradients.all.firstWhere(
    (gradient) => gradient.uuid == _settingsService.gradientUuid,
    orElse: () => FLauncherGradients.pitchBlack,
  );

  WallpaperService(
    this._fLauncherChannel,
    this._settingsService, {
    Future<void> Function(File)? validateVideo,
  }) : _validateVideo = validateVideo ?? validateBackgroundVideo,
       _wallpaper = null {
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
    _videoFile = File("${directory.path}/wallpaper_video");
    _wallpaperDayFile = File("${directory.path}/wallpaper_day");
    _wallpaperNightFile = File("${directory.path}/wallpaper_night");

    _lastTimeBasedEnabled = _settingsService.timeBasedWallpaperEnabled;
    await _updateWallpaper();
    _updateTimerState();
  }

  Future<void> refresh() async {
    await _initialization;
    if (isDisposed) return;
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
      _timer = Timer.periodic(
        const Duration(minutes: 1),
        (_) => _updateWallpaper(),
      );
    } else if (!enabled && _timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  Future<bool> _safeWallpaper(File file) async {
    try {
      return await file.exists() &&
          await file.length() <= maximumImageInputBytes;
    } on FileSystemException {
      return false;
    }
  }

  Future<File?> _safeVideo() async {
    try {
      return await _videoFile.exists() &&
              await _videoFile.length() <= maximumBackgroundVideoBytes
          ? _videoFile
          : null;
    } on FileSystemException {
      return null;
    }
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

    final newVideo = enabled ? null : await _safeVideo();
    if (!isDisposed && callId == _updateWallpaperCallCount) {
      if (_wallpaper != newWallpaper ||
          _video?.path != newVideo?.path ||
          force) {
        _video = newVideo;
        _wallpaper = newWallpaper;
        notifyListeners();
      }
    }
  }

  Future<bool> pickWallpaper() => _pickAndSave(null);

  Future<bool> pickWallpaperDay() => _pickAndSave('day');

  Future<bool> pickWallpaperNight() => _pickAndSave('night');

  Future<bool> _pickAndSave(String? period) async {
    if (_picking || isDisposed) return false;
    _picking = true;
    File? staging;
    try {
      await _initialization;
      if (isDisposed) return false;
      if (!await _fLauncherChannel.checkForGetContentAvailability()) {
        throw NoFileExplorerException();
      }
      final picked = period == null
          ? await DocumentFiles.pickWallpaper()
          : await DocumentFiles.pickImage();
      if (picked == null) return false;
      try {
        if (isDisposed) return false;
        final header = await picked
            .openRead(0, 32)
            .fold<List<int>>([], (all, chunk) => all..addAll(chunk));
        final kind = backgroundMediaKind(header);
        final image = kind == BackgroundMediaKind.image;
        if (!image && period != null) {
          throw const BackgroundMediaException(BackgroundMediaFailure.format);
        }
        final target = period == 'day'
            ? _wallpaperDayFile
            : period == 'night'
            ? _wallpaperNightFile
            : image
            ? _wallpaperFile
            : _videoFile;
        staging = File('${target.path}.pending');
        if (image) {
          final bytes = await readBoundedImage(picked.openRead());
          await validateImageBytes(bytes);
          if (isDisposed) return false;
          await staging.writeAsBytes(bytes, flush: true);
        } else {
          final sink = staging.openWrite();
          try {
            var count = 0;
            final bounded = picked.openRead().map((chunk) {
              count += chunk.length;
              if (count > maximumBackgroundVideoBytes) {
                throw const BackgroundMediaException(
                  BackgroundMediaFailure.videoSize,
                );
              }
              return chunk;
            });
            await sink.addStream(bounded);
            await sink.flush();
          } finally {
            await sink.close();
          }
          await _validateVideo(staging);
        }
        if (isDisposed) return false;
        await staging.rename(target.path);
        if (period == null) {
          final other = image ? _videoFile : _wallpaperFile;
          if (await other.exists()) await other.delete();
        }
        await FileImage(target).evict();
        _version++;
        await _updateWallpaper(force: true);
        return true;
      } finally {
        await DocumentFiles.releaseImage(picked);
      }
    } finally {
      if (staging != null && await staging.exists()) await staging.delete();
      _picking = false;
    }
  }

  Future<void> reset() async {
    await _initialization;
    if (isDisposed) return;
    for (final file in [
      _wallpaperFile,
      _wallpaperDayFile,
      _wallpaperNightFile,
      _videoFile,
    ]) {
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
