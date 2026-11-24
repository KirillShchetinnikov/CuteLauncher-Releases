import '../diagnostics_store.dart';
import '../diagnostics/poster_loads.dart';
import 'service_lifecycle.dart';
import 'foreground_work.dart';
import 'memory_resources.dart';
import 'settings_service.dart';
import '../image_byte_cache.dart';
import '../network_poster.dart';
import '../poster_disk_cache.dart';
import '../poster_queue.dart';
import 'dart:async';
import 'dart:developer';
import 'dart:io' show HttpClient, Platform;
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flauncher/flauncher_channel.dart';
import '../models/watch_next_program.dart';
import '../models/content_load_state.dart';

class WatchNextService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel _channel;
  final ForegroundWork? work;
  final Future<void> Function(String)? onAppLaunched;
  final MemoryResources? _memoryResources;
  final SettingsService? settings;
  final PosterDiskCache? disk;
  final _catalogOwners = <Object>{};
  bool _wasNeeded = false;
  bool get _needed => (settings?.showContinueWatching ?? true) || _catalogOwners.isNotEmpty;
  bool get _active => !isDisposed && _foreground && _needed && _memoryResources?.isForeground != false;
  List<WatchNextProgram> _programs = [];
  bool _initialized = false;
  bool _failed = false;
  DateTime? _lastPosterReload;
  static const metadataTimeout = Duration(seconds: 8);
  ContentLoadState get loadState => contentLoadState(
    initialized: _initialized, loading: _isFetching,
    failed: _failed || !_hasPermission, hasContent: _programs.isNotEmpty,
  );
  bool _hasPermission = true;
  Timer? _refreshTimer;
  StreamSubscription<dynamic>? _watchNextSubscription;
  int _callCount = 0;
  final _posterPool = PosterQueue();
  final _posterCache = ImageByteCache(
    maximumBytes: 4 * 1024 * 1024,
    maximumEntries: 2048,
  );
  final _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..maxConnectionsPerHost = 2;
  final _pendingPosters =
      <(int, String), ({PosterDemand demand, Future<Uint8List?> result})>{};
  final posterRefreshes = ValueNotifier<int>(0);
  int _posterGeneration = 0;
  DateTime? _diskFreshAfter;
  bool _foreground = true;
  int get posterCacheBytes => _posterCache.byteCount;
  int get posterCacheEntries => _posterCache.length;
  void clearImageCaches() {
    ++_posterGeneration;
    _posterCache.clear();
  }
  bool _isFetching = false;
  bool _hasPendingRefresh = false;
  bool _hasPendingPosterReload = false;
  bool _scheduledPosterReload = false;

  bool get _isTest => Platform.environment.containsKey('FLUTTER_TEST');

  WatchNextService(this._channel, {this._memoryResources, this.onAppLaunched, this.work, this.settings, this.disk}) {
    _memoryResources?.register(this, clear: clearImageCaches,
      activity: () => _posterCache.activity,
      stats: () => MemoryCacheStats(posterCacheBytes, posterCacheEntries),
      breakdown: () => {MemoryCacheKind.watchNextPosters: MemoryCacheStats(posterCacheBytes, posterCacheEntries)},
      disk: {MemoryCacheKind.watchNextPosters: ?disk},
      configure: (economy) => _configureCache(economy));
    if (!_isTest) {
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
      WidgetsBinding.instance.addObserver(this);
    }
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.watchNext,
        WidgetsBinding.instance.lifecycleState?.name ?? 'resumed');
    settings?.addListener(_settingsChanged);
    _settingsChanged();
  }

  List<WatchNextProgram> get programs => List.unmodifiable(_programs);
  bool get initialized => _initialized;
  bool get hasPermission => _hasPermission;

  void setCatalogVisible(Object owner, bool visible) {
    if (isDisposed) return;
    visible ? _catalogOwners.add(owner) : _catalogOwners.remove(owner);
    _settingsChanged();
  }

  void _settingsChanged() {
    if (isDisposed) return;
    _configureCache();
    if (_wasNeeded == _needed) return;
    _wasNeeded = _needed;
    if (_needed) {
      _scheduledPosterReload |= _initialized;
      _start();
    } else {
      _stop();
    }
  }

  void _configureCache([bool? economy]) {
    const section = PosterCacheSection.watchNext;
    final saving = economy ?? settings?.memorySaverEnabled ?? false;
    final ram = saving ? section.ram.economy : settings?.posterCacheLimit(section, disk: false) ?? section.ram.normal;
    final storage = saving ? section.disk.economy : settings?.posterCacheLimit(section, disk: true) ?? section.disk.normal;
    _posterCache.maximumBytes = ram * 1024 * 1024;
    disk?.maximumBytes = storage * 1024 * 1024;
  }

  void _start({bool resuming = false}) {
    if (!_active) return;
    final stalePosters = _lastPosterReload == null ||
        DateTime.now().difference(_lastPosterReload!) >= const Duration(minutes: 5);
    final reload = _scheduledPosterReload || _initialized && (!resuming || stalePosters);
    _scheduleRefresh(reloadPosters: reload,
        maxAge: resuming && !reload ? const Duration(seconds: 30) : Duration.zero);
    if (_initialized) _startPeriodicTimer();
  }

  void _listen() {
    if (!_active) return;
    try {
      _watchNextSubscription ??= _channel.addWatchNextChangedListener((_) {
        // Retain only an invalidation in background, not a catalogue read.
        _scheduledPosterReload = true;
        _scheduleRefresh(reloadPosters: true);
      });
    } catch (e, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'watchNextService', e, diagnosticStack,
      );
      log('Failed to listen to watch next events', name: 'WatchNextService', error: e);
    }

  }

  void _stop({bool background = false}) {
    if (!background) work?.cancel(this);
    ++_callCount;
    ++_posterGeneration;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    if (!background) {
      unawaited(_watchNextSubscription?.cancel());
      _watchNextSubscription = null;
    }
    if (background) _scheduledPosterReload |= _hasPendingPosterReload;
    _hasPendingRefresh = false;
    _hasPendingPosterReload = false;
    if (!background) _scheduledPosterReload = false;
  }

  void _startPeriodicTimer() {
    if (!_active) return;
    _refreshTimer?.cancel();
    // Refresh fallback every 5 minutes (reactive ContentObserver handles real-time updates)
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) => _scheduleRefresh(reloadPosters: true));
  }

  void _scheduleRefresh({bool reloadPosters = false, Duration maxAge = Duration.zero}) {
    if (!_active) return;
    // A resume request must not overwrite a pending content-change invalidation.
    _scheduledPosterReload |= reloadPosters;
    Future<void> run() {
      final reload = _scheduledPosterReload;
      _scheduledPosterReload = false;
      return refresh(reloadPosters: reload);
    }
    (work?.schedule(this, run, maxAge: maxAge) ?? run())
        .catchError((Object error) { log('Watch Next automatic refresh failed', error: error); });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.watchNext, state.name);
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _foreground = false;
      _stop(background: true);
    } else if (state == AppLifecycleState.resumed) {
      _foreground = true;
      _start(resuming: true);
      ++posterRefreshes.value;
    }
  }

  Future<void> refresh({bool reloadPosters = false}) async {
    if (!_active) return;
    if (_isFetching) {
      _hasPendingRefresh = true;
      _hasPendingPosterReload |= reloadPosters;
      return;
    }
    final previousState = (_initialized, _failed, _hasPermission);
    var changed = false;
    _isFetching = true;

    final int callSnapshot = ++_callCount;
    try {
      final bool hasPermission = await checkPermission().timeout(metadataTimeout);
      if (isDisposed || callSnapshot != _callCount) return;

      _hasPermission = hasPermission;
      _failed = false;
      if (!hasPermission) {
        if (_programs.isNotEmpty) {
          _programs = [];
          changed = true;
        }
        return;
      }

      final list = await _channel.getWatchNextPrograms().timeout(metadataTimeout);
      if (isDisposed || callSnapshot != _callCount) return;

      if (reloadPosters) {
        _diskFreshAfter = DateTime.now();
        clearImageCaches();
      }
      if (reloadPosters || _lastPosterReload == null) _lastPosterReload = DateTime.now();
      final newPrograms = list
          .map(WatchNextProgram.fromMap)
          .where((program) => program.displayTitle.isNotEmpty)
          .toList();

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

      changed = _programs.length != newPrograms.length;
      if (!changed) {
        for (var i = 0; i < newPrograms.length; i++) {
          if (!_programs[i].sameContent(newPrograms[i])) { changed = true; break; }
        }
      }
      if (changed) _programs = newPrograms;
      if (reloadPosters) ++posterRefreshes.value;
    } catch (e, diagnosticStack) {
      if (isDisposed || callSnapshot != _callCount) return;
      _failed = true;
      DiagnosticsStore.instance.recordException(
        'watchNextService', e, diagnosticStack,
      );
      log('Failed to refresh watch next programs', name: 'WatchNextService', error: e);
    } finally {
      _isFetching = false;
      if (!isDisposed && callSnapshot == _callCount) {
        _initialized = true;
        _listen();
        if (_refreshTimer?.isActive != true) _startPeriodicTimer();
      }
      if (!isDisposed && callSnapshot == _callCount &&
          (changed || previousState != (_initialized, _failed, _hasPermission))) {
        notifyListeners();
      }
      if (!isDisposed && _hasPendingRefresh) {
        _hasPendingRefresh = false;
        final reload = _hasPendingPosterReload;
        _hasPendingPosterReload = false;
        _scheduleRefresh(reloadPosters: reload);
      }
    }
  }

  bool _canLoadPoster(int generation) =>
      _active &&
      generation == _posterGeneration;

  Uint8List? cachedPoster(WatchNextProgram program) =>
      _posterCache[program.posterArtUri] ?? _posterCache[program.thumbnailUri];

  Future<Uint8List?> poster(WatchNextProgram program, {PosterPriority? priority}) async {
    final generation = _posterGeneration;
    final primary = await _loadPoster(program.posterArtUri, generation, program.packageName,
        priority: priority);
    if (!_canLoadPoster(generation)) return null;
    if (primary != null || program.posterArtUri == program.thumbnailUri) {
      return primary;
    }
    return _loadPoster(program.thumbnailUri, generation, program.packageName,
        thumbnail: true, priority: priority);
  }

  void evictPoster(WatchNextProgram program) {
    DiagnosticsStore.instance.activePosterLoads?.decodeFailed(
        PosterSource.watchNext, program.posterArtUri, program.thumbnailUri, program.packageName);
    _posterCache.remove(program.posterArtUri);
    _posterCache.remove(program.thumbnailUri);
    unawaited(disk?.remove(program.posterArtUri));
    if (program.thumbnailUri != program.posterArtUri) {
      unawaited(disk?.remove(program.thumbnailUri));
    }
  }

  Future<Uint8List?> _loadPoster(String address, int generation, String packageName,
      {bool thumbnail = false, PosterPriority? priority}) async {
    if (address.isEmpty || !_canLoadPoster(generation)) {
      return null;
    }
    final cached = _posterCache[address];
    final diagnostics = DiagnosticsStore.instance.activePosterLoads;
    if (cached != null) {
      diagnostics?.count(PosterSource.watchNext, 'cacheHit');
      return cached;
    }

    final key = (generation, address);
    final pending = _pendingPosters[key];
    if (pending != null) {
      diagnostics?.count(PosterSource.watchNext, 'deduplicated');
      pending.demand.add(priority);
      return pending.result;
    }
    final demand = PosterDemand()..add(priority);
    final trace = diagnostics?.start(PosterSource.watchNext, address,
        packageName: packageName, thumbnail: thumbnail);
    final result = _readPoster(address, generation, demand, trace, diagnostics).whenComplete(() {
      trace?.finish(PosterOutcome.discarded);
      _pendingPosters.remove(key);
    });
    _pendingPosters[key] = (demand: demand, result: result);
    return result;
  }

  Future<Uint8List?> _readPoster(
    String address,
    int generation,
    PosterDemand demand,
    PosterLoad? trace,
    PosterLoads? diagnostics,
  ) async {
    final diskGeneration = disk?.generation;
    ({Uint8List bytes, bool fresh})? onDisk;
    if (disk != null) {
      trace?.stage(PosterStage.disk);
      onDisk = await disk!.read(address, freshAfter: _diskFreshAfter);
      if (!_canLoadPoster(generation) || demand.priority < 0) return null;
      if (onDisk != null && onDisk.fresh) {
        diagnostics?.count(PosterSource.watchNext, 'diskHit');
        trace?.receivedBytes = onDisk.bytes.length;
        _posterCache[address] = onDisk.bytes;
        trace?.finish(PosterOutcome.loaded);
        return onDisk.bytes;
      }
      diagnostics?.count(
        PosterSource.watchNext, onDisk == null ? 'diskMiss' : 'diskStale',
      );
      trace?.stage(PosterStage.queue);
    }
    return _posterPool.load(demand, () async {
      if (!_canLoadPoster(generation)) return null;
      final fetchedAt = DateTime.now();
      var cacheOnDisk = true;
      Uint8List? bytes;
      try {
        final uri = Uri.tryParse(address);
        if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
          bytes = await readNetworkPoster(_http, uri, trace: trace,
              onDiskCachePolicy: (allowed) => cacheOnDisk = allowed);
        } else {
          trace?.stage(PosterStage.platform);
          bytes = await _channel.getWatchNextPoster(address);
          trace?.receivedBytes = bytes?.length ?? 0;
        }
      } catch (error, stack) {
        trace?.error(error);
        if (_canLoadPoster(generation)) {
          DiagnosticsStore.instance.recordException('watchNextPoster', error, stack);
        }
      }
      if (!_canLoadPoster(generation)) return null;
      if (bytes == null || bytes.isEmpty) {
        trace?.finish(onDisk == null ? PosterOutcome.failed : PosterOutcome.cachedFallback);
        return onDisk?.bytes;
      }
      _posterCache[address] = bytes;
      trace?.finish(PosterOutcome.loaded);
      if (disk != null && disk!.generation == diskGeneration) {
        if (cacheOnDisk) {
          await disk!.write(address, bytes, fetchedAt: fetchedAt);
        } else {
          await disk!.remove(address);
        }
      }
      return _canLoadPoster(generation) ? bytes : null;
    });
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
      } catch (e, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'watchNextService', e, diagnosticStack,
        );
        log('Failed to launch watch next program intent', name: 'WatchNextService', error: e);
      }
    }
    if (!launched && program.packageName.isNotEmpty) {
      try {
        launched = await _channel.launchApp(program.packageName);
      } catch (e, diagnosticStack) {
        DiagnosticsStore.instance.recordException(
          'watchNextService', e, diagnosticStack,
        );
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
    } catch (e, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'watchNextService', e, diagnosticStack,
      );
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
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.watchNext, 'disposed');
    work?.cancel(this);
    settings?.removeListener(_settingsChanged);
    _catalogOwners.clear();
    _memoryResources?.unregister(this);
    ++_callCount;
    _posterCache.clear();
    posterRefreshes.dispose();
    _http.close(force: true);
    _posterPool.close();
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
