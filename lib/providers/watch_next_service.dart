import 'service_lifecycle.dart';
import 'memory_resources.dart';
import '../image_byte_cache.dart';
import 'package:pool/pool.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:flutter/widgets.dart';
import 'package:flauncher/flauncher_channel.dart';
import '../models/watch_next_program.dart';

class WatchNextService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel _channel;
  final Future<void> Function(String)? onAppLaunched;
  final MemoryResources? _memoryResources;
  List<WatchNextProgram> _programs = [];
  bool _initialized = false;
  bool _hasPermission = true;
  Timer? _refreshTimer;
  StreamSubscription<dynamic>? _watchNextSubscription;
  int _callCount = 0;
  final _posterPool = Pool(2);
  late final _posterCache = ImageByteCache(maximumBytes: 6 * 1024 * 1024,
    onEvict: (uri, bytes) {
      for (final program in _programs) {
        if (program.posterArtUri == uri && identical(program.posterBytes, bytes)) program.posterBytes = null;
      }
    });
  int get posterCacheBytes => _posterCache.byteCount;
  int get posterCacheEntries => _posterCache.length;
  int posterWindowSize = 32;
  void clearImageCaches() {
    ++_callCount;
    _hasPendingRefresh = false;
    _hasPendingPosterReload = false;
    _posterCache.clear();
    for (final program in _programs) { program.posterBytes = null; }
  }

  void configureImageCache({required int posterBytes, required int windowSize}) {
    _posterCache.maximumBytes = posterBytes;
    posterWindowSize = windowSize;
  }
  bool _isFetching = false;
  bool _hasPendingRefresh = false;
  bool _hasPendingPosterReload = false;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  WatchNextService(this._channel, {this._memoryResources, this.onAppLaunched}) {
    _memoryResources?.register(this, clear: clearImageCaches,
      activity: () => _posterCache.activity,
      stats: () => MemoryCacheStats(posterCacheBytes, posterCacheEntries),
      breakdown: () => {MemoryCacheKind.watchNextPosters: MemoryCacheStats(posterCacheBytes, posterCacheEntries)},
      configure: (economy) => configureImageCache(posterBytes: (economy ? 2 : 6) * 1024 * 1024,
        windowSize: economy ? 16 : 32));
    if (!_isTest) {
      WidgetsBinding.instance.addObserver(this);
    }
    _init();
  }

  List<WatchNextProgram> get programs => List.unmodifiable(_programs);
  bool get initialized => _initialized;
  bool get hasPermission => _hasPermission;

  Future<void> _init() async {
    await refresh();
    if (isDisposed) return;
    _initialized = true;
    notifyListeners();

    try {
      _watchNextSubscription = _channel.addWatchNextChangedListener((_) {
        refresh(reloadPosters: true);
      });
    } catch (e) {
      log('Failed to listen to watch next events', name: 'WatchNextService', error: e);
    }

    _startPeriodicTimer();
  }

  void _startPeriodicTimer() {
    if (isDisposed || _memoryResources?.isForeground == false) return;
    _refreshTimer?.cancel();
    // Refresh fallback every 5 minutes (reactive ContentObserver handles real-time updates)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => refresh(reloadPosters: true));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _refreshTimer?.cancel();
      _refreshTimer = null;
    } else if (state == AppLifecycleState.resumed) {
      refresh(reloadPosters: true);
      _startPeriodicTimer();
    }
  }

  Future<void> refresh({bool reloadPosters = false}) async {
    if (isDisposed || _memoryResources?.isForeground == false) return;
    if (_isFetching) {
      _hasPendingRefresh = true;
      _hasPendingPosterReload |= reloadPosters;
      return;
    }
    _isFetching = true;

    final int callSnapshot = ++_callCount;
    try {
      final bool hasPermission = await checkPermission();
      if (isDisposed || callSnapshot != _callCount) return;

      _hasPermission = hasPermission;
      if (!hasPermission) {
        if (_programs.isNotEmpty) {
          _programs = [];
        }
        if (callSnapshot == _callCount) notifyListeners();
        return;
      }

      List<Map<dynamic, dynamic>> list;
      try {
        list = await _channel.getWatchNextPrograms();
      } catch (e) {
        log('Failed to fetch watch next programs', name: 'WatchNextService', error: e);
        list = const [];
      }
      if (isDisposed || callSnapshot != _callCount) return;

      if (reloadPosters) _posterCache.clear();
      // Phase 1: Emit programs immediately with cached posters where available
      final List<WatchNextProgram> newPrograms = [];
      for (final map in list) {
        final program = WatchNextProgram.fromMap(map);
        // Reuse a poster only while both the program and its image URI match.
        program.posterBytes = _posterCache[program.posterArtUri];
        newPrograms.add(program);
      }

      // Explicitly sort programs so the most recently watched content is first
      newPrograms.sort((a, b) {
        int timeA = a.lastEngagementTime;
        int timeB = b.lastEngagementTime;
        if (timeA > 0 && timeA < 10000000000) timeA *= 1000;
        if (timeB > 0 && timeB < 10000000000) timeB *= 1000;
        if (timeA != timeB) {
          return timeB.compareTo(timeA);
        }
        return b.id.compareTo(a.id);
      });

      _programs = newPrograms;
      if (callSnapshot == _callCount) notifyListeners();

      // Phase 2: Fetch local posters if present (content://, android.resource://, file://)
      final needsPoster = newPrograms.take(posterWindowSize).where(
        (p) => p.posterArtUri.isNotEmpty &&
               p.posterBytes == null &&
               !p.posterArtUri.startsWith('http://') &&
               !p.posterArtUri.startsWith('https://'),
      ).toList();
      if (needsPoster.isNotEmpty) {
        await Future.wait(
          needsPoster.map((p) => _posterPool.withResource(() async {
            if (isDisposed || callSnapshot != _callCount) return;
            try {
              final bytes = await _channel.getWatchNextPoster(p.posterArtUri);
              if (!isDisposed && callSnapshot == _callCount && bytes != null && bytes.isNotEmpty) {
                _posterCache[p.posterArtUri] = bytes;
                p.posterBytes = _posterCache[p.posterArtUri];
              }
            } catch (e) {
              log('Failed to fetch poster for ${p.title}', name: 'WatchNextService', error: e);
            }
          })),
        ).timeout(
          const Duration(seconds: 2),
          onTimeout: () => [],
        );
        if (callSnapshot == _callCount) notifyListeners();
      }
    } catch (e) {
      log('Failed to refresh watch next programs', name: 'WatchNextService', error: e);
    } finally {
      _isFetching = false;
      if (!isDisposed && _hasPendingRefresh) {
        _hasPendingRefresh = false;
        final reload = _hasPendingPosterReload;
        _hasPendingPosterReload = false;
        refresh(reloadPosters: reload);
      }
    }
  }

  Future<bool> checkPermission() async {
    return await _channel.checkWatchNextPermission();
  }

  Future<bool> requestPermission() async {
    final bool granted = await _channel.requestWatchNextPermission();
    if (granted) {
      await refresh();
    }
    return granted;
  }

  Future<bool> launch(WatchNextProgram program) async {
    bool launched = false;
    if (program.intentUri.isNotEmpty) {
      try {
        launched = await _channel.launchWatchNextProgram(program.intentUri);
      } catch (e) {
        log('Failed to launch watch next program intent', name: 'WatchNextService', error: e);
      }
    }
    if (!launched && program.packageName.isNotEmpty) {
      try {
        launched = await _channel.launchApp(program.packageName);
      } catch (e) {
        log('Failed to launch app ${program.packageName}', name: 'WatchNextService', error: e);
      }
    }
    if (launched && !isDisposed) await onAppLaunched?.call(program.packageName);
    return launched;
  }

  Future<bool> deleteProgram(WatchNextProgram program) async {
    bool deleted = false;
    try {
      deleted = await _channel.deleteWatchNextProgram(program.id);
    } catch (e) {
      log('Failed to delete watch next program', name: 'WatchNextService', error: e);
    }
    if (deleted && !isDisposed) {
      _programs = _programs.where((p) => p.id != program.id).toList();
      notifyListeners();
    }
    return deleted;
  }

  @override
  void dispose() {
    _memoryResources?.unregister(this);
    ++_callCount;
    _posterCache.clear();
    unawaited(_posterPool.close());
    _hasPendingRefresh = false;
    _hasPendingPosterReload = false;
    if (!_isTest) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _watchNextSubscription?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
