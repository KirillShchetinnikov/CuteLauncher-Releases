import '../diagnostics_store.dart';
import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../bridge_result.dart';
import '../image_limits.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';

class SlideshowService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  static const _channel = BridgeChannel('me.efesser.flauncher/method');
  final SharedPreferences preferences;
  final SettingsService settings;
  final Future<List<String>> Function(String, bool) _list;
  final Future<Uint8List> Function(String) _read;
  final Random _random;
  final DateTime Function() _clock;
  Timer? _timer;
  DateTime? _nextChangeAt;
  List<String> _files = [];
  List<String> _remaining = [];
  String? _last;
  bool _foreground = true;
  bool _loading = false;
  bool failed = false;
  bool get loading => _loading;
  int version = 0;
  MemoryImage? image;
  int _generation = 0;
  String get folder => preferences.getString('slideshow_folder') ?? '';
  bool get recursive => preferences.getBool('slideshow_recursive') ?? true;
  bool get randomOrder => preferences.getBool('slideshow_random') ?? false;
  int get interval => preferences.getInt('slideshow_interval') ?? 300;
  bool get _active =>
      !isDisposed &&
      _foreground &&
      settings.backgroundSource == 'slideshow' &&
      folder.isNotEmpty;

  SlideshowService(
    this.preferences,
    this.settings, {
    Future<List<String>> Function(String, bool)? list,
    Future<Uint8List> Function(String)? read,
    Random? random,
    DateTime Function()? clock,
  }) : _list =
           list ??
           ((uri, recursive) async =>
               await _channel.invokeListMethod<String>('listWallpaperFolder', {
                 'uri': uri,
                 'recursive': recursive,
               }) ??
               []),
       _read =
           read ??
           ((uri) async =>
               await _channel.invokeMethod<Uint8List>(
                 'readWallpaperFolderImage',
                 {'uri': uri},
               ) ??
               Uint8List(0)),
       _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_settingsChanged);
    _settingsChanged();
  }

  Future<void> pickFolder() async {
    final selected = await _channel.invokeMethod<String>('pickWallpaperFolder');
    if (selected == null || isDisposed) return;
    await setFolder(selected);
  }

  Future<void> setFolder(String selected) async {
    if (isDisposed) return;
    final old = folder;
    await _save({'slideshow_folder': selected});
    if (old != selected) await _releaseFolder(old);
    await reload();
  }

  Future<void> reset() async {
    if (isDisposed) return;
    final old = folder;
    await _save({
      for (final key in ['slideshow_folder', 'slideshow_recursive', 'slideshow_random', 'slideshow_interval']) key: null,
    });
    ++_generation;
    _timer?.cancel();
    _nextChangeAt = null;
    _remaining = []; _files = []; _last = null; image = null;
    await _releaseFolder(old);
    failed = false;
    notifyListeners();
  }

  Future<void> _releaseFolder(String uri) async {
    if (uri.isEmpty ||
        uri == preferences.getString('wallpaper_video_folder') ||
        uri == preferences.getString('backup_transport_local_folder')) {
      return;
    }
    await _channel.invokeMethod<void>('releaseWallpaperFolder', {'uri': uri});
  }

  Future<void> configure({
    bool? recursive,
    bool? randomOrder,
    int? interval,
  }) async {
    if (isDisposed) return;
    final changes = <String, Object?>{};
    if (recursive != null) changes['slideshow_recursive'] = recursive;
    if (randomOrder != null) changes['slideshow_random'] = randomOrder;
    if (interval != null && [30, 60, 300, 600, 1800, 3600].contains(interval)) {
      changes['slideshow_interval'] = interval;
    }
    await _save(changes);
    await reload();
  }

  Future<void> _save(Map<String, Object?> values) async {
    final previous = {for (final key in values.keys) key: preferences.get(key)};
    Future<bool> write(String key, Object? value) => switch (value) {
      null => preferences.remove(key),
      String value => preferences.setString(key, value),
      bool value => preferences.setBool(key, value),
      int value => preferences.setInt(key, value),
      _ => throw ArgumentError.value(value),
    };
    try {
      for (final entry in values.entries) {
        if (!await write(entry.key, entry.value)) {
          throw StateError('Unable to save slideshow settings');
        }
      }
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'slideshowService', diagnosticError, diagnosticStack,
      );
      // SharedPreferences changes its memory cache even when the platform rejects a write.
      for (final entry in previous.entries) {
        try { await write(entry.key, entry.value); } catch (diagnosticError, diagnosticStack) {
          DiagnosticsStore.instance.recordException(
            'slideshowService', diagnosticError, diagnosticStack,
          ); /* Preserve the original error. */ }
      }
      rethrow;
    }
  }

  Future<void> reload() async {
    ++_generation;
    _nextChangeAt = null;
    _files = [];
    _remaining = [];
    _timer?.cancel();
    notifyListeners();
    if (_active) await advance();
    _startTimer();
  }

  void _settingsChanged() {
    if (!_active) {
      ++_generation;
      _timer?.cancel();
      if (settings.backgroundSource != 'slideshow' || folder.isEmpty) {
        _nextChangeAt = null;
      }
      return;
    }
    if (_timer?.isActive == true) return;
    _startTimer();
    if (image == null) unawaited(advance());
  }

  void _startTimer() {
    _timer?.cancel();
    if (_active) {
      final now = _clock();
      final deadline = _nextChangeAt ??= now.add(Duration(seconds: interval));
      final remaining = deadline.difference(now);
      // Keep the deadline across background pauses. Catch up once on return,
      // then start a fresh interval rather than replaying every missed slide.
      _timer = Timer(remaining.isNegative ? Duration.zero : remaining, () {
        _nextChangeAt = _clock().add(Duration(seconds: interval));
        _startTimer();
        unawaited(advance());
      });
    }
  }

  void _cycle() {
    _remaining = List.of(_files);
    if (randomOrder) _remaining.shuffle(_random);
    if (_remaining.length > 1 && _remaining.first == _last) {
      final first = _remaining.removeAt(0);
      _remaining.add(first);
    }
  }

  Future<void> advance() async {
    if (!_active || _loading) return;
    _loading = true;
    notifyListeners();
    final generation = _generation;
    bool current() => _active && generation == _generation;
    try {
      if (_remaining.isEmpty) {
        // Rescan at each cycle to notice additions and removals without polling in background.
        _files = (await _list(folder, recursive)).toSet().take(1000).toList()
          ..sort();
        if (!current()) return;
        _cycle();
      }
      var attempts = 0;
      while (_remaining.isNotEmpty && attempts++ < 20 && current()) {
        final uri = _remaining.removeAt(0);
        try {
          final bytes = await _read(uri);
          if (!current()) return;
          await validateImageBytes(bytes);
          if (!current()) return;
          final oldImage = image;
          image = MemoryImage(bytes);
          _last = uri;
          version++;
          failed = false;
          if (oldImage != null) unawaited(oldImage.evict());
          return;
        } catch (diagnosticError, diagnosticStack) {
          DiagnosticsStore.instance.recordException(
            'slideshowService', diagnosticError, diagnosticStack,
          );
          /* Skip inaccessible or corrupt files; retain the last good image. */
        }
      }
      if (current()) failed = true;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'slideshowService', diagnosticError, diagnosticStack,
      );
      if (current()) failed = true;
    } finally {
      _loading = false;
      if (!isDisposed) {
        notifyListeners();
        if (generation != _generation && _active) unawaited(advance());
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    ++_generation;
    _startTimer();
    if (_active && image == null) unawaited(advance());
  }

  @override
  void dispose() {
    ++_generation;
    _timer?.cancel();
    settings.removeListener(_settingsChanged);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
