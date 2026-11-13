import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bridge_result.dart';
import '../diagnostics_store.dart';
import '../local_background_media.dart';
import 'launcher_state.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';

const videoFolderSource = 'videoFolder';
const videoFolderKey = 'wallpaper_video_folder';
const videoFolderOrderKey = 'wallpaper_video_order';

enum VideoFolderOrder { name, date, random }

class VideoFolderClip {
  final Uri uri;
  final String name;
  final int modified;
  final int size;

  VideoFolderClip.fromMap(Map<Object?, Object?> data)
    : uri = Uri.parse(data['uri'] as String),
      name = data['name'] as String,
      modified = data['modified'] as int,
      size = data['size'] as int;
}

class VideoFolderService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  final SharedPreferences _preferences;
  final SettingsService _settings;
  final LauncherState _launcher;
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

  String get folder => _folder;
  VideoFolderOrder get order => _order;
  VideoFolderClip? get clip => _clip;
  bool get loading => _reading;
  bool get failed => _failed;
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
    _folder = _preferences.getString(videoFolderKey) ?? '';
    final value = _preferences.getString(videoFolderOrderKey);
    _order = VideoFolderOrder.values.firstWhere(
      (order) => order.name == value,
      orElse: () => VideoFolderOrder.name,
    );
  }

  void reload() {
    if (isDisposed || _changingSettings) return;
    final previousFolder = folder;
    final previousOrder = order;
    final wasSelected = _selected;
    _selected = _settings.backgroundSource == videoFolderSource;
    _readSettings();
    if (folder != previousFolder ||
        order != previousOrder ||
        _selected != wasSelected) {
      ++_generation;
      _remaining.clear();
      _failedUris.clear();
      _last = null;
      _clip = null;
      _failed = false;
      if (!_selected) _blocked = false;
      notifyListeners();
    }
    _resume();
  }

  void _resume() {
    if (canAdvance && _clip == null && !_failed) unawaited(_advance());
  }

  void _visibilityChanged() {
    if (_visible == _launcher.launcherVisible) return;
    _visible = _launcher.launcherVisible;
    notifyListeners();
    _resume();
  }

  Future<void> setFolder(String selected) => _changeSettings(() async {
    final old = folder;
    try {
      await _list(selected);
      if (isDisposed) {
        if (old != selected) await _release(selected);
        return;
      }
      await _write({videoFolderKey: selected});
    } catch (_) {
      if (old != selected) await _release(selected);
      rethrow;
    }
    if (old != selected) await _release(old);
    if (old == selected && _failed) await next();
  });

  Future<void> setOrder(VideoFolderOrder order) =>
      _changeSettings(() => _write({videoFolderOrderKey: order.name}));

  Future<void> reset() => _changeSettings(() async {
    final old = folder;
    await _write({videoFolderKey: null, videoFolderOrderKey: null});
    await _release(old);
  });

  Future<void> _changeSettings(Future<void> Function() action) {
    final operation = _settingsWrite.then((_) => action());
    _settingsWrite = operation.catchError((Object _) {});
    return operation;
  }

  Future<void> _write(Map<String, String?> values) async {
    final previous = {
      for (final key in values.keys) key: _preferences.getString(key),
    };
    Future<bool> write(String key, String? value) => value == null
        ? _preferences.remove(key)
        : _preferences.setString(key, value);
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
      Error.throwWithStackTrace(error, stack);
    } finally {
      _changingSettings = false;
      reload();
    }
  }

  Future<void> _release(String uri) async {
    if (!uri.startsWith('content:') ||
        uri == _preferences.getString(videoFolderKey) ||
        uri == _preferences.getString('slideshow_folder') ||
        uri == _preferences.getString('backup_transport_local_folder')) {
      return;
    }
    await _channel.invokeMethod<void>('releaseWallpaperFolder', {'uri': uri});
  }

  static Future<List<VideoFolderClip>> _list(String folder) async {
    final rows = await _channel
        .invokeListMethod<Map<Object?, Object?>>('listWallpaperVideos', {
          'uri': folder,
        })
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
    _failed = false;
    notifyListeners();
    try {
      if (_remaining.isEmpty) {
        final clips = await _list(folder);
        if (!current()) return;
        _fillQueue(clips);
      }
      _clip = _remaining.isEmpty ? null : _remaining.removeFirst();
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
      if (generation != _generation || !current()) _resume();
    }
  }

  void _fillQueue(List<VideoFolderClip> clips) {
    final seen = <Uri>{..._failedUris};
    clips = clips
        .where(
          (clip) =>
              clip.size <= maximumBackgroundVideoBytes && seen.add(clip.uri),
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
    WidgetsBinding.instance.removeObserver(this);
    _settings.removeListener(reload);
    _launcher.removeListener(_visibilityChanged);
    super.dispose();
  }
}
