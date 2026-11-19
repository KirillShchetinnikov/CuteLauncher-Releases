import 'dart:async';
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bridge_result.dart';
import '../diagnostics_store.dart';
import '../local_background_media.dart';
import '../image_limits.dart';
import 'launcher_state.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';

const videoFolderSource = 'videoFolder';
const mediaFolderSource = 'mediaFolder';
const mediaFolderKey = 'wallpaper_media_folder';
const mediaFolderOrderKey = 'wallpaper_media_order';
const mediaFolderRecursiveKey = 'wallpaper_media_recursive';
const mediaFolderIntervalKey = 'wallpaper_media_interval';
const videoFolderKey = 'wallpaper_video_folder';
const videoFolderOrderKey = 'wallpaper_video_order';

enum VideoFolderOrder { name, date, random }

class VideoFolderClip {
  final Uri uri;
  final String name;
  final int modified;
  final int size;
  final bool isImage;

  VideoFolderClip.fromMap(Map<Object?, Object?> data)
    : uri = Uri.parse(data['uri'] as String),
      name = data['name'] as String,
      modified = data['modified'] as int,
      size = data['size'] as int,
      isImage = data['image'] == true;
}

class VideoFolderService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  final SharedPreferences _preferences;
  final SettingsService _settings;
  final LauncherState _launcher;
  List<VideoFolderClip>? _validatedFiles;
  final _remaining = Queue<VideoFolderClip>();
  final _failedUris = <Uri>{};
  final _random = Random();
  Future<void> _settingsWrite = Future.value();
  late String _folder;
  late VideoFolderOrder _order;
  bool _resumed = false;
  bool _visible = false;
  bool _selected = false;
  bool _reading = false;
  bool _failed = false;
  bool _blocked = false;
  bool _changingSettings = false;
  int _generation = 0;
  VideoFolderClip? _clip;
  Uri? _last;
  bool _mixed = false;
  bool _recursive = false;
  int _interval = 300;
  Timer? _photoTimer;
  DateTime? _photoDeadline;
  MemoryImage? _image;

  String get folder => _folder;
  VideoFolderOrder get order => _order;
  VideoFolderClip? get clip => _clip;
  bool get loading => _reading;
  bool get failed => _failed;
  bool get mixed => _mixed;
  bool get recursive => _recursive;
  int get interval => _interval;
  MemoryImage? get image => _image;
  bool get canAdvance => _active && !_reading && !_blocked && folder.isNotEmpty;
  bool get _active =>
      !isDisposed && _selected && _resumed && _launcher.launcherVisible;

  VideoFolderService(this._preferences, this._settings, this._launcher) {
    final binding = WidgetsBinding.instance;
    _resumed =
        (binding.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    _readSettings();
    _visible = _launcher.launcherVisible;
    binding.addObserver(this);
    _settings.addListener(reload);
    _launcher.addListener(_visibilityChanged);
    reload();
  }

  void _readSettings() {
    _mixed = _settings.backgroundSource == mediaFolderSource;
    _folder =
        _preferences.getString(mixed ? mediaFolderKey : videoFolderKey) ?? '';
    _recursive =
        mixed && (_preferences.getBool(mediaFolderRecursiveKey) ?? true);
    _interval = _preferences.getInt(mediaFolderIntervalKey) ?? 300;
    final value = _preferences.getString(
      mixed ? mediaFolderOrderKey : videoFolderOrderKey,
    );
    _order = VideoFolderOrder.values.firstWhere(
      (order) => order.name == value,
      orElse: () => VideoFolderOrder.name,
    );
  }

  void reload({List<VideoFolderClip>? validatedFiles}) {
    if (isDisposed || _changingSettings) return;
    final previousFolder = folder;
    final previousOrder = order;
    final previousMode = mixed;
    final previousRecursive = recursive;
    final previousInterval = interval;
    final wasSelected = _selected;
    _selected = [
      videoFolderSource,
      mediaFolderSource,
    ].contains(_settings.backgroundSource);
    _readSettings();
    if (folder != previousFolder ||
        order != previousOrder ||
        _selected != wasSelected ||
        previousMode != mixed ||
        previousRecursive != recursive) {
      ++_generation;
      _validatedFiles = validatedFiles;
      _remaining.clear();
      _failedUris.clear();
      _last = null;
      _clip = null;
      _clearImage();
      _failed = false;
      if (!_selected) _blocked = false;
      notifyListeners();
    }
    if (previousInterval != interval) {
      _photoDeadline = null;
      notifyListeners();
    }
    _resume();
  }

  void _resume() {
    if (canAdvance && _clip == null && !_failed) unawaited(_advance());
    _schedulePhoto();
  }

  void _clearImage() {
    _photoTimer?.cancel();
    _photoDeadline = null;
    final old = _image;
    _image = null;
    if (old != null) unawaited(old.evict());
  }

  void _schedulePhoto() {
    _photoTimer?.cancel();
    final current = _clip;
    if (!_active || current?.isImage != true || _image == null) return;
    final now = DateTime.now();
    final remaining = (_photoDeadline ??= now.add(
      Duration(seconds: interval),
    )).difference(now);
    _photoTimer = Timer(
      remaining.isNegative ? Duration.zero : remaining,
      () => completed(current!),
    );
  }

  void _visibilityChanged() {
    if (_visible == _launcher.launcherVisible) return;
    _visible = _launcher.launcherVisible;
    notifyListeners();
    _resume();
  }

  Future<void> setFolder(String selected) => _changeSettings(() async {
    final old = folder;
    final generation = _generation;
    final folderKey = mixed ? mediaFolderKey : videoFolderKey;
    try {
      final files = await _list(selected);
      if (isDisposed) {
        if (old != selected) await _release(selected);
        return;
      }
      if (generation != _generation) throw StateError('Folder source changed');
      if (old == selected) {
        if (_failed) {
          _remaining.clear();
          _validatedFiles = files;
          await next();
        }
        return;
      }
      await _write({folderKey: selected}, validatedFiles: files);
    } catch (_) {
      if (old != selected) await _release(selected);
      rethrow;
    }
    await _release(old);
  });

  Future<void> setOrder(VideoFolderOrder order) => _changeSettings(
    () =>
        _write({mixed ? mediaFolderOrderKey : videoFolderOrderKey: order.name}),
  );

  Future<void> setRecursive(bool value) =>
      _changeSettings(() => _write({mediaFolderRecursiveKey: value}));
  Future<void> setInterval(int value) =>
      _changeSettings(() => _write({mediaFolderIntervalKey: value}));

  Future<void> reset({bool all = false}) => _changeSettings(() async {
    final old = folder;
    final oldMedia = _preferences.getString(mediaFolderKey) ?? '';
    final oldVideo = _preferences.getString(videoFolderKey) ?? '';
    await _write(
      all
          ? {
              mediaFolderKey: null,
              mediaFolderOrderKey: null,
              mediaFolderRecursiveKey: null,
              mediaFolderIntervalKey: null,
              videoFolderKey: null,
              videoFolderOrderKey: null,
            }
          : mixed
          ? {
              mediaFolderKey: null,
              mediaFolderOrderKey: null,
              mediaFolderRecursiveKey: null,
              mediaFolderIntervalKey: null,
            }
          : {videoFolderKey: null, videoFolderOrderKey: null},
    );
    await _release(old);
    if (all) {
      if (oldMedia != old) await _release(oldMedia);
      if (oldVideo != old && oldVideo != oldMedia) await _release(oldVideo);
    }
  });

  Future<void> _changeSettings(Future<void> Function() action) {
    final operation = _settingsWrite.then((_) => action());
    _settingsWrite = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _write(
    Map<String, Object?> values, {
    List<VideoFolderClip>? validatedFiles,
  }) async {
    final previous = {
      for (final key in values.keys) key: _preferences.get(key),
    };
    Future<bool> write(String key, Object? value) => switch (value) {
      null => _preferences.remove(key),
      bool value => _preferences.setBool(key, value),
      int value => _preferences.setInt(key, value),
      String value => _preferences.setString(key, value),
      _ => throw ArgumentError.value(value),
    };
    final source = _settings.backgroundSource;
    _changingSettings = true;
    try {
      for (final entry in values.entries) {
        if (!await write(entry.key, entry.value)) {
          throw StateError('Preference write failed');
        }
      }
    } catch (error, stack) {
      for (final entry in previous.entries) {
        try {
          await write(entry.key, entry.value);
        } catch (rollbackError, rollbackStack) {
          DiagnosticsStore.instance.recordException(
            'listWallpaperVideos',
            rollbackError,
            rollbackStack,
          );
        }
      }
      validatedFiles = null;
      Error.throwWithStackTrace(error, stack);
    } finally {
      _changingSettings = false;
      reload(
        validatedFiles: source == _settings.backgroundSource
            ? validatedFiles
            : null,
      );
    }
  }

  Future<void> _release(String uri) async {
    if (!uri.startsWith('content:') ||
        uri == _preferences.getString(videoFolderKey) ||
        uri == _preferences.getString(mediaFolderKey) ||
        uri == _preferences.getString('slideshow_folder') ||
        uri == _preferences.getString('backup_transport_local_folder')) {
      return;
    }
    await _channel.invokeMethod<void>('releaseWallpaperFolder', {'uri': uri});
  }

  Future<List<VideoFolderClip>> _list(String folder) async {
    final rows = await _channel
        .invokeListMethod<Map<Object?, Object?>>(
          mixed ? 'listWallpaperMedia' : 'listWallpaperVideos',
          {'uri': folder, if (mixed) 'recursive': recursive},
        )
        .timeout(const Duration(seconds: 15));
    return [
      for (final row in rows ?? const <Map<Object?, Object?>>[])
        VideoFolderClip.fromMap(row),
    ];
  }

  Future<void> next() async {
    if (!canAdvance) return;
    if (_failed) _failedUris.clear();
    await _advance();
  }

  void completed(VideoFolderClip clip) {
    if (!identical(_clip, clip)) return;
    _failedUris.clear();
    _clip = null;
    _photoTimer?.cancel();
    _photoDeadline = null;
    if (_active) {
      unawaited(_advance());
    } else {
      notifyListeners();
    }
  }

  void playbackFailed(VideoFolderClip clip, bool released) {
    if (!identical(_clip, clip)) return;
    _failedUris.add(clip.uri);
    _clip = null;
    _blocked = !released;
    if (_active && released) {
      unawaited(_advance());
    } else {
      _failed = !released;
      notifyListeners();
    }
  }

  Future<void> _advance() async {
    if (!canAdvance) return;
    final generation = _generation;
    bool current() => _active && generation == _generation;
    _reading = true;
    _photoTimer?.cancel();
    _photoDeadline = null;
    _failed = false;
    notifyListeners();
    try {
      if (_remaining.isEmpty) {
        final validated = _validatedFiles;
        _validatedFiles = null;
        final clips = validated ?? await _list(folder);
        if (!current()) return;
        _fillQueue(clips);
      }
      _clip = null;
      var attempts = 0;
      while (_remaining.isNotEmpty && current()) {
        if (attempts == 20) {
          await Future<void>.delayed(Duration.zero);
          attempts = 0;
          if (!current()) return;
        }
        attempts++;
        final candidate = _remaining.removeFirst();
        if (!candidate.isImage) {
          _clearImage();
          _clip = candidate;
          break;
        }
        try {
          final bytes = await _channel
              .invokeMethod<Uint8List>('readWallpaperFolderImage', {
                'uri': candidate.uri.toString(),
              })
              .timeout(const Duration(seconds: 15));
          if (bytes == null) throw const ImageInputException();
          await validateImageBytes(bytes);
          if (!current()) return;
          _clearImage();
          _image = MemoryImage(bytes);
          _clip = candidate;
          break;
        } catch (error, stack) {
          if (!current()) return;
          DiagnosticsStore.instance.recordException(
            'wallpaperFolderImage',
            error,
            stack,
          );
          _failedUris.add(candidate.uri);
        }
      }
      if (_clip case final clip?) _last = clip.uri;
      _failed = _clip == null;
    } catch (error, stack) {
      DiagnosticsStore.instance.recordException(
        'listWallpaperVideos',
        error,
        stack,
      );
      if (current()) {
        _clip = null;
        _failed = true;
      }
    } finally {
      _reading = false;
      notifyListeners();
      _schedulePhoto();
      if (generation != _generation || !current()) _resume();
    }
  }

  void _fillQueue(List<VideoFolderClip> clips) {
    final seen = <Uri>{..._failedUris};
    clips = clips
        .where(
          (clip) =>
              clip.size <=
                  (clip.isImage
                      ? maximumImageInputBytes
                      : maximumBackgroundVideoBytes) &&
              seen.add(clip.uri),
        )
        .toList();
    int compareNames(VideoFolderClip a, VideoFolderClip b) {
      final name = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return name != 0 ? name : a.uri.toString().compareTo(b.uri.toString());
    }

    switch (order) {
      case VideoFolderOrder.name:
        clips.sort(compareNames);
      case VideoFolderOrder.date:
        clips.sort((a, b) {
          final date = b.modified.compareTo(a.modified);
          return date != 0 ? date : compareNames(a, b);
        });
      case VideoFolderOrder.random:
        clips.shuffle(_random);
        if (clips.length > 1 && clips.first.uri == _last) {
          clips.add(clips.removeAt(0));
        }
    }
    _remaining.addAll(clips);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state == AppLifecycleState.resumed;
    if (_resumed == resumed) return;
    _resumed = resumed;
    notifyListeners();
    _resume();
  }

  @override
  void dispose() {
    _clearImage();
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(reload);
    _launcher.removeListener(_visibilityChanged);
    super.dispose();
  }
}
