import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:pool/pool.dart';

import '../flauncher_channel.dart';
import '../image_byte_cache.dart';
import '../image_limits.dart';
import '../feed_format.dart';
import '../models/app_content_channel.dart';
import '../models/watch_next_program.dart';
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
      double? ratio;
      if (bytes != null) {
        ui.ImmutableBuffer? buffer;
        ui.ImageDescriptor? descriptor;
        try {
          buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
          descriptor = await ui.ImageDescriptor.encoded(buffer);
          ratio = descriptor.width / descriptor.height;
        } catch (_) {
          // An invalid image contributes no orientation vote.
        } finally {
          descriptor?.dispose();
          buffer?.dispose();
        }
      }
      if (isDisposed || !_foreground || generation != _generation) return;
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
    } catch (_) {
      // Keep the current layout when local preferences cannot be written.
    }
  }

  late final _posters = ImageByteCache(
    maximumBytes: 4 * 1024 * 1024,
    onEvict: (uri, _) => _posterVersions.remove(uri),
  );

  /// Only mounted cards observe artwork invalidation; it never rebuilds Home.
  final posterRefreshes = ValueNotifier<int>(0);
  int _posterEpoch = 0;
  final _pool = Pool(2);
  final _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..maxConnectionsPerHost = 2;
  final _pendingPosters = <String, Future<Uint8List?>>{};
  List<AppContentChannel> _channels = [];
  List<AppContentChannel> get channels => List.unmodifiable(_channels);
  bool initialized = false;
  bool unavailable = false;
  bool loading = false;
  Completer<void>? _inFlight;
  bool _foreground = true;
  bool _again = false;
  int _generation = 0;
  String _selection = '';
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
    this.onAppLaunched,
  }) {
    _foreground =
        WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    settings.addListener(_settingsChanged);
    _wasGroupVisible = _groupVisible;
    apps?.addListener(_appsChanged);
    memory?.register(
      this,
      clear: _clearPosters,
      stats: () => MemoryCacheStats(_posters.byteCount, _posters.length),
      configure: (economy) =>
          _posters.maximumBytes = (economy ? 1 : 4) * 1024 * 1024,
    );
    _selection = jsonEncode(settings.selectedAppChannels);
    if (settings.selectedAppChannels.isNotEmpty) _listenAndRefresh();
  }

  void _clearPosters() {
    _invalidatePosters();
    _posters.clear();
  }

  void _invalidatePosters() {
    _formatSamples.clear();
    ++_generation;
    ++_posterEpoch;
    if (loading) _again = true;
  }

  void _settingsChanged() {
    final next = jsonEncode(settings.selectedAppChannels);
    if (next == _selection) return;
    final previousKeys = _selection.isEmpty
        ? <String>[]
        : (jsonDecode(_selection) as List).cast<String>();
    _selection = next;
    if (listEquals(
      previousKeys..sort(),
      settings.selectedAppChannels.toList()..sort(),
    )) {
      return;
    }
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
      _invalidatePosters();
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
    if (reloadPosters) _invalidatePosters();
    if (loading) {
      _again = true;
      await _inFlight?.future;
      return;
    }
    loading = true;
    final completion = _inFlight = Completer<void>();
    var changed = false;
    final generation = _generation;
    try {
      final raw = await channel.getAppChannels(settings.selectedAppChannels);
      if (isDisposed || !_foreground || generation != _generation) return;
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
    } catch (_) {
      if (isDisposed || !_foreground || generation != _generation) return;
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

  Future<Uint8List?> poster(String uri) {
    if (uri.isEmpty || !_foreground || isDisposed || !_groupVisible) {
      return Future.value(null);
    }
    final cached = _posters[uri];
    if (cached != null && _posterVersions[uri] == _posterEpoch) {
      return Future.value(cached);
    }
    final pendingKey = '$_generation:$uri';
    return _pendingPosters.putIfAbsent(pendingKey, () {
      final generation = _generation;
      final epoch = _posterEpoch;
      return _pool
          .withResource(() async {
            if (isDisposed || !_foreground || generation != _generation) {
              return null;
            }
            Uint8List? bytes;
            HttpClientRequest? request;
            var abandoned = false;
            try {
              final parsed = Uri.tryParse(uri);
              if (parsed != null &&
                  (parsed.scheme == 'https' || parsed.scheme == 'http')) {
                request = await _http
                    .getUrl(parsed)
                    .then((value) {
                      if (abandoned) value.abort();
                      return value;
                    })
                    .timeout(const Duration(seconds: 5));
                final response = await request.close().timeout(
                  const Duration(seconds: 5),
                );
                if (response.statusCode != 200) {
                  request.abort();
                  throw const ImageInputException();
                }
                bytes = await readBoundedImage(response).timeout(
                  const Duration(seconds: 8),
                  onTimeout: () {
                    request?.abort();
                    throw const ImageInputException();
                  },
                );
                await validateImageBytes(bytes);
              } else {
                bytes = await channel.getWatchNextPoster(uri);
              }
            } catch (_) {
              bytes = null;
              abandoned = true;
              request?.abort();
            }
            if (isDisposed || !_foreground || generation != _generation) {
              return null;
            }
            final previous = _posters[uri];
            if (bytes != null && bytes.isNotEmpty) {
              if (!listEquals(bytes, previous)) _posters[uri] = bytes;
              if (_posters.containsKey(uri)) _posterVersions[uri] = epoch;
            }
            return _posters[uri];
          })
          .whenComplete(() {
            _pendingPosters.remove(pendingKey);
          });
    });
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
        } catch (_) {
          debugPrint('Unable to record app feed launch');
        }
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
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
    unawaited(_pool.close());
    super.dispose();
  }
}
