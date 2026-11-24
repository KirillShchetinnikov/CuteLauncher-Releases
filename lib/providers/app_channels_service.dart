import '../diagnostics_store.dart';
import '../diagnostics/poster_loads.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals, setEquals;

import '../flauncher_channel.dart';
import '../image_byte_cache.dart';
import '../feed_format.dart';
import '../models/app_content_channel.dart';
import '../models/content_load_state.dart';
import '../models/watch_next_program.dart';
import '../network_poster.dart';
import '../poster_disk_cache.dart';
import '../poster_queue.dart';
import 'foreground_work.dart';
import 'memory_resources.dart';
import 'service_lifecycle.dart';
import 'settings_service.dart';
import 'apps_service.dart';
import '../models/category.dart';

class AppChannelsService extends ChangeNotifier
    with ServiceLifecycle, WidgetsBindingObserver {
  final FLauncherChannel channel;
  final SettingsService settings;
  final AppsService? apps;
  final ForegroundWork? work;
  final MemoryResources? memory;
  final PosterDiskCache? disk;
  final Future<void> Function(String)? onAppLaunched;
  final _posterVersions = <String, int>{};
  final _formatSamples = <String, Map<int, double?>>{};

  FeedFormat formatFor(AppContentChannel feed) {
    final manual = settings.appChannelFormat(feed.key);
    if (manual != FeedFormat.auto) return manual;
    final detected = settings.appChannelFormat(feed.key, detected: true);
    if (detected != FeedFormat.auto) return detected;
    return FeedFormat.majority(
      feed.programs.map((p) => p.posterAspectRatio).whereType<double>(),
    );
  }

  /// Uses only the first three already requested covers. Never warms distant feeds.
  Future<void> observePoster(
    AppContentChannel feed,
    int id,
    Uint8List? bytes,
  ) async {
    if (isDisposed ||
        !_foreground ||
        settings.appChannelFormat(feed.key, detected: true) !=
            FeedFormat.auto ||
        settings.appChannelFormat(feed.key) != FeedFormat.auto) {
      return;
    }
    final metadata = feed.programs
        .map((p) => p.posterAspectRatio)
        .whereType<double>()
        .where((r) => r.isFinite && r > 0)
        .toList();
    FeedFormat? format;
    if (metadata.isNotEmpty) {
      format = FeedFormat.majority(metadata);
    } else {
      if (!feed.programs.take(3).any((p) => p.id == id)) return;
      if (_formatSamples[feed.key]?.containsKey(id) == true) return;
      final generation = _generation;
      final epoch = _posterEpoch;
      double? ratio;
      if (bytes != null) {
        ui.ImmutableBuffer? buffer;
        ui.ImageDescriptor? descriptor;
        try {
          buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          descriptor = await ui.ImageDescriptor.encoded(buffer);
          ratio = descriptor.width / descriptor.height;
        } catch (diagnosticError, diagnosticStack) {
          DiagnosticsStore.instance.recordException(
            'appChannelsService', diagnosticError, diagnosticStack,
          );
          // An invalid image contributes no orientation vote.
        } finally {
          descriptor?.dispose();
          buffer?.dispose();
        }
      }
      if (isDisposed ||
          !_foreground ||
          generation != _generation ||
          epoch != _posterEpoch) {
        return;
      }
      final samples = _formatSamples.putIfAbsent(feed.key, () => {});
      samples[id] = ratio;
      if (samples.length < feed.programs.take(3).length) return;
      final valid = samples.values.whereType<double>().toList();
      if (valid.isEmpty) return;
      format = FeedFormat.majority(valid);
    }
    if (isDisposed || !_foreground) return;
    try {
      await settings.setAppChannelFormat(feed.key, format, detected: true);
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'appChannelsService', diagnosticError, diagnosticStack,
      );
      // Keep the current layout when local preferences cannot be written.
    }
  }

  late final _posters = ImageByteCache(
    maximumBytes: 4 * 1024 * 1024,
    maximumEntries: 2048,
    onEvict: (uri, _) => _posterVersions.remove(uri),
  );

  /// Only mounted cards observe artwork invalidation; it never rebuilds Home.
  final posterRefreshes = ValueNotifier<int>(0);
  int _posterEpoch = 0;
  DateTime? _diskFreshAfter;
  final _pool = PosterQueue();
  final _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..maxConnectionsPerHost = 2;
  final _pendingPosters =
      <String, ({PosterDemand demand, Future<Uint8List?> result})>{};
  List<AppContentChannel> _channels = [];
  List<AppContentChannel> get channels => List.unmodifiable(_channels);
  bool initialized = false;
  bool unavailable = false;
  bool loading = false;
  static const metadataTimeout = Duration(seconds: 8);
  ContentLoadState get loadState => contentLoadState(
    initialized: initialized, loading: loading, failed: unavailable,
    hasContent: _channels.any((channel) => channel.programs.isNotEmpty),
  );
  Completer<void>? _inFlight;
  bool _foreground = true;
  bool _again = false;
  int _generation = 0;
  late Set<String> _selection;
  late int _cardLimit;
  int get cardLimit => _cardLimit;
  String? _snapshot;
  int _catalogUsers = 0;
  bool _wasGroupVisible = true;
  bool get _groupVisible =>
      apps == null ||
      apps!.launcherSections.whereType<Category>().any(
        (section) => section.isAppChannels && section.visible,
      );
  bool get _needed =>
      _catalogUsers > 0 ||
      _groupVisible && settings.selectedAppChannels.isNotEmpty;
  StreamSubscription<dynamic>? _subscription;

  AppChannelsService(
    this.channel,
    this.settings, {
    this.apps,
    this.work,
    this.memory,
    this.disk,
    this.onAppLaunched,
  }) {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.appChannels,
        WidgetsBinding.instance.lifecycleState?.name ?? 'resumed');
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_settingsChanged);
    _wasGroupVisible = _groupVisible;
    apps?.addListener(_appsChanged);
    memory?.register(
      this,
      clear: _clearPosters,
      stats: () => MemoryCacheStats(_posters.byteCount, _posters.length),
      breakdown: () => {
        MemoryCacheKind.appChannelPosters: MemoryCacheStats(_posters.byteCount, _posters.length),
      },
      disk: {MemoryCacheKind.appChannelPosters: ?disk},
      configure: (economy) => _configureCache(economy),
    );
    _configureCache();
    _selection = settings.selectedAppChannels.toSet();
    _cardLimit = settings.appChannelCardLimit;
    if (settings.selectedAppChannels.isNotEmpty) _listenAndRefresh();
  }

  void _clearPosters() {
    ++_generation;
    _invalidatePosters();
    _posters.clear();
  }

  void _invalidatePosters({bool refreshDisk = false}) {
    // A new catalogue may keep the same URIs. Let their queued loads finish.
    _formatSamples.clear();
    ++_posterEpoch;
    if (refreshDisk) _diskFreshAfter = DateTime.now();
    if (loading) _again = true;
  }

  void _configureCache([bool? economy]) {
    const section = PosterCacheSection.appChannels;
    final saving = economy ?? settings.memorySaverEnabled;
    final ram = saving ? section.ram.economy : settings.posterCacheLimit(section, disk: false);
    final storage = saving ? section.disk.economy : settings.posterCacheLimit(section, disk: true);
    _posters.maximumBytes = ram * 1024 * 1024;
    disk?.maximumBytes = storage * 1024 * 1024;
  }

  void _settingsChanged() {
    _configureCache();
    final selected = settings.selectedAppChannels.toSet();
    final limit = settings.appChannelCardLimit;
    final limitChanged = limit != _cardLimit;
    _cardLimit = limit;
    if (setEquals(selected, _selection)) {
      if (limitChanged) notifyListeners();
      return;
    }
    _selection = selected;
    ++_generation;
    _snapshot = null;
    notifyListeners();
    if (!_needed) {
      _stop();
      return;
    }
    _listenAndRefresh();
  }

  void _stop() {
    ++_generation;
    work?.cancel(this);
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void _appsChanged() {
    final visible = _groupVisible;
    if (visible == _wasGroupVisible) return;
    _wasGroupVisible = visible;
    if (_needed) {
      _listenAndRefresh();
    } else {
      _stop();
    }
  }

  void openCatalog() {
    ++_catalogUsers;
    _listenAndRefresh();
  }

  void closeCatalog() {
    if (_catalogUsers > 0) --_catalogUsers;
    if (!_needed) _stop();
  }

  void _listenAndRefresh() {
    if (!_foreground || isDisposed || !_needed) return;
    _subscription ??= channel.addAppChannelsChangedListener((_) {
      _invalidatePosters(refreshDisk: true);
      _schedule();
    });
    _schedule();
  }

  void _schedule() {
    if (!_foreground || isDisposed || apps != null && !_needed) return;
    unawaited(
      (work?.schedule(this, refresh) ?? refresh()).catchError((Object _) {}),
    );
  }

  /// Explicit settings refresh also discovers channels before the first selection.
  Future<void> refresh({bool reloadPosters = false}) async {
    if (isDisposed || !_foreground || apps != null && !_needed) return;
    if (reloadPosters) _invalidatePosters(refreshDisk: true);
    if (loading) {
      _again = true;
      await _inFlight?.future;
      return;
    }
    loading = true;
    final completion = _inFlight = Completer<void>();
    var changed = false;
    final generation = _generation;
    final epoch = _posterEpoch;
    try {
      final raw = await channel.getAppChannels(settings.selectedAppChannels)
          .timeout(metadataTimeout);
      if (isDisposed ||
          !_foreground ||
          generation != _generation ||
          epoch != _posterEpoch) {
        return;
      }
      final snapshot = jsonEncode(raw);
      changed = unavailable || !initialized;
      if (snapshot != _snapshot) {
        final previous = {for (final entry in _channels) entry.key: entry};
        final next = raw
            .take(128)
            .map(
              (value) => AppContentChannel.fromMap(
                value,
                previous: previous['${value['packageName']}:${value['id']}'],
              ),
            )
            .toList();
        if (!listEquals(next, _channels)) {
          _channels = next;
          _formatSamples.removeWhere(
            (key, _) => !next.any((c) => c.key == key),
          );
          changed = true;
        }
      }
      _snapshot = snapshot;
      unavailable = false;
      initialized = true;
      posterRefreshes.value = _posterEpoch;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'appChannelsService', diagnosticError, diagnosticStack,
      );
      if (isDisposed ||
          !_foreground ||
          generation != _generation ||
          epoch != _posterEpoch) {
        return;
      }
      changed = !unavailable || !initialized;
      unavailable = true;
      initialized = true;
    } finally {
      loading = false;
      _inFlight = null;
      completion.complete();
      if (!isDisposed && _foreground && changed) notifyListeners();
      if (_again) {
        _again = false;
        _schedule();
      }
    }
  }

  Uint8List? cachedPoster(String uri) => _posters[uri];

  void evictPoster(WatchNextProgram program) {
    DiagnosticsStore.instance.activePosterLoads?.decodeFailed(
        PosterSource.appChannels, program.posterArtUri, program.thumbnailUri, program.packageName);
    _posters.remove(program.posterArtUri);
    _posters.remove(program.thumbnailUri);
    unawaited(disk?.remove(program.posterArtUri));
    if (program.thumbnailUri != program.posterArtUri) {
      unawaited(disk?.remove(program.thumbnailUri));
    }
  }

  Future<Uint8List?> programPoster(
    WatchNextProgram program, {
    PosterPriority? priority,
  }) async {
    final generation = _generation;
    final primary = await poster(program.posterArtUri,
        packageName: program.packageName, priority: priority);
    if (primary != null ||
        generation != _generation ||
        program.posterArtUri == program.thumbnailUri) {
      return primary;
    }
    return poster(program.thumbnailUri,
        packageName: program.packageName, thumbnail: true, priority: priority);
  }

  Future<Uint8List?> poster(
    String uri, {
    String? packageName,
    bool thumbnail = false,
    PosterPriority? priority,
  }) {
    if (uri.isEmpty || !_foreground || isDisposed || !_groupVisible) {
      return Future.value(null);
    }
    final cached = _posters[uri];
    final diagnostics = DiagnosticsStore.instance.activePosterLoads;
    if (cached != null && _posterVersions[uri] == _posterEpoch) {
      diagnostics?.count(PosterSource.appChannels, 'cacheHit');
      return Future.value(cached);
    }
    final pendingKey = '$_generation:$uri';
    final pending = _pendingPosters[pendingKey];
    if (pending != null) {
      diagnostics?.count(PosterSource.appChannels, 'deduplicated');
      pending.demand.add(priority);
      return pending.result;
    }
    final demand = PosterDemand()..add(priority);
    final trace = diagnostics?.start(PosterSource.appChannels, uri,
        packageName: packageName, thumbnail: thumbnail, cached: cached != null);
    final result = _loadPoster(uri, demand, trace, diagnostics).whenComplete(() {
      trace?.finish(PosterOutcome.discarded);
      _pendingPosters.remove(pendingKey);
    });
    _pendingPosters[pendingKey] = (demand: demand, result: result);
    return result;
  }

  Future<Uint8List?> _loadPoster(
    String uri,
    PosterDemand demand,
    PosterLoad? trace,
    PosterLoads? diagnostics,
  ) async {
    final generation = _generation;
    final epoch = _posterEpoch;
    bool active() => !isDisposed && _foreground && generation == _generation;
    final diskGeneration = disk?.generation;
    ({Uint8List bytes, bool fresh})? onDisk;
    if (disk != null) {
      trace?.stage(PosterStage.disk);
      onDisk = await disk!.read(uri, freshAfter: _diskFreshAfter);
      if (!active() || demand.priority < 0) return null;
      if (onDisk != null && onDisk.fresh) {
        diagnostics?.count(PosterSource.appChannels, 'diskHit');
        trace?.receivedBytes = onDisk.bytes.length;
        _cachePoster(uri, onDisk.bytes, epoch);
        trace?.finish(PosterOutcome.loaded);
        return onDisk.bytes;
      }
      diagnostics?.count(
        PosterSource.appChannels, onDisk == null ? 'diskMiss' : 'diskStale',
      );
      trace?.stage(PosterStage.queue);
    }
    return _pool.load(demand, () async {
      if (!active()) return null;
      Uint8List? bytes;
      final fetchedAt = DateTime.now();
      var cacheOnDisk = true;
      try {
        final parsed = Uri.tryParse(uri);
        if (parsed != null && (parsed.scheme == 'https' || parsed.scheme == 'http')) {
          bytes = await readNetworkPoster(_http, parsed, trace: trace,
              onDiskCachePolicy: (allowed) => cacheOnDisk = allowed);
        } else {
          trace?.stage(PosterStage.platform);
          bytes = await channel.getWatchNextPoster(uri);
          trace?.receivedBytes = bytes?.length ?? 0;
        }
      } catch (diagnosticError, diagnosticStack) {
        trace?.error(diagnosticError);
        DiagnosticsStore.instance.recordException('appChannelsService', diagnosticError, diagnosticStack);
      }
      if (!active()) return null;
      if (bytes != null && bytes.isNotEmpty) {
        final result = _cachePoster(uri, bytes, epoch);
        trace?.finish(PosterOutcome.loaded);
        if (disk != null && epoch == _posterEpoch && disk!.generation == diskGeneration) {
          if (cacheOnDisk) {
            await disk!.write(uri, bytes, fetchedAt: fetchedAt);
          } else {
            await disk!.remove(uri);
          }
        }
        return active() ? result : null;
      }
      final previous = _posters[uri] ?? onDisk?.bytes;
      trace?.finish(previous == null ? PosterOutcome.failed : PosterOutcome.cachedFallback);
      return previous;
    });
  }

  Uint8List _cachePoster(String uri, Uint8List bytes, int epoch) {
    final previous = _posters[uri];
    if (!listEquals(bytes, previous)) _posters[uri] = bytes;
    if (_posters.containsKey(uri)) _posterVersions[uri] = epoch;
    return _posters[uri] ?? bytes;
  }

  Future<bool> launch(WatchNextProgram program) async {
    try {
      final ok = await channel.launchAppChannelProgram(
        program.intentUri,
        program.packageName,
      );
      if (ok && !isDisposed) {
        try {
          await onAppLaunched?.call(program.packageName);
        } catch (diagnosticError, diagnosticStack) {
          DiagnosticsStore.instance.recordException(
            'appChannelsService', diagnosticError, diagnosticStack,
          );
          debugPrint('Unable to record app feed launch');
        }
      }
      return ok;
    } catch (diagnosticError, diagnosticStack) {
      DiagnosticsStore.instance.recordException(
        'appChannelsService', diagnosticError, diagnosticStack,
      );
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.appChannels, state.name);
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      ++_generation;
      work?.cancel(this);
      unawaited(_subscription?.cancel());
      _subscription = null;
    } else if (_needed) {
      _invalidatePosters();
      _listenAndRefresh();
    }
  }

  @override
  void dispose() {
    DiagnosticsStore.instance.activePosterLoads?.lifecycle(PosterSource.appChannels, 'disposed');
    work?.cancel(this);
    ++_generation;
    settings.removeListener(_settingsChanged);
    apps?.removeListener(_appsChanged);
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    memory?.unregister(this);
    _posters.clear();
    posterRefreshes.dispose();
    _http.close(force: true);
    _pool.close();
    super.dispose();
  }
}
