import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../image_limits.dart';
import '../online_wallpaper_failure.dart';
import '../diagnostics_store.dart';
import '../versioned_file_image.dart';
import '../bing_wallpaper.dart';
import '../apod_wallpaper.dart';
import '../reddit_wallpaper.dart';
import '../wallhaven_wallpaper.dart';
import 'service_lifecycle.dart';
import 'foreground_work.dart';

const onlineWallpaperKey = 'online_wallpaper';
const onlineWallpaperCacheKey = 'online_wallpaper_cache';
bool validOnlineWallpaperConfiguration(String value) {
  try {
    final map = jsonDecode(value) as Map;
    if (map['source'] != null && !['url', 'bing', 'reddit', 'wallhaven', 'apod'].contains(map['source'])) return false;
    if (map['wallhavenTheme'] != null && !wallhavenWallpaperThemes.containsKey(map['wallhavenTheme'])) return false;
    if (map['redditTheme'] != null && !redditWallpaperThemes.containsKey(map['redditTheme'])) return false;
    if (map['redditResolution'] != null && !redditWallpaperResolutions.contains(map['redditResolution'])) return false;
    if (map['enabled'] is! bool || map['url'] is! String || ![1, 6, 12, 24].contains(map['intervalHours'])) return false;
    final config = OnlineWallpaperConfiguration.decode(value);
    return map['enabled'] == false || config.enabled && (config.validUrl || config.url.isEmpty);
  } catch (_) { return false; }
}
class OnlineWallpaperConfiguration {
  final bool enabled;
  final String url;
  final int _intervalHours;
  int get intervalHours => ['reddit', 'wallhaven'].contains(source) ? _intervalHours : 1;
  final String source;
  final String redditTheme, redditResolution;
  final String wallhavenTheme;
  String get identity => source == 'wallhaven' ? 'wallhaven:$wallhavenTheme' : source == 'reddit' ? 'reddit:$redditTheme:$redditResolution' : ['bing', 'apod'].contains(source) ? source : url;
  const OnlineWallpaperConfiguration({this.enabled = false, this.url = '', int intervalHours = 24, this.source = 'url',
    // Keep the public constructor argument while normalizing Bing/URL intervals in the getter.
    // ignore: prefer_initializing_formals
    this.wallhavenTheme = 'all', this.redditTheme = 'all', this.redditResolution = 'fullHd'}) : _intervalHours = intervalHours;
  OnlineWallpaperConfiguration copyWith({bool? enabled, String? source, int? intervalHours, String? redditTheme, String? redditResolution, String? wallhavenTheme}) =>
    OnlineWallpaperConfiguration(enabled: enabled ?? this.enabled, url: url, source: source ?? this.source,
      intervalHours: intervalHours ?? _intervalHours, redditTheme: redditTheme ?? this.redditTheme,
      redditResolution: redditResolution ?? this.redditResolution, wallhavenTheme: wallhavenTheme ?? this.wallhavenTheme);
  bool get validUrl {
    if (source == 'wallhaven') return wallhavenWallpaperThemes.containsKey(wallhavenTheme);
    if (source == 'bing' || source == 'apod') return true;
    if (source == 'reddit') return redditWallpaperThemes.containsKey(redditTheme) && redditWallpaperResolutions.contains(redditResolution);
    final uri = Uri.tryParse(url);
    return url.length <= 2048 && uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty;
  }
  String encode() => jsonEncode({'enabled': enabled, 'url': url, 'intervalHours': _intervalHours, 'source': source,
    'wallhavenTheme': wallhavenTheme, 'redditTheme': redditTheme, 'redditResolution': redditResolution});
  static OnlineWallpaperConfiguration decode(String? value) {
    try {
      final map = jsonDecode(value ?? '{}') as Map;
      final config = OnlineWallpaperConfiguration(enabled: map['enabled'] == true,
        source: map['source'] == 'reddit' && !redditWallpapersAvailable ? 'bing' :
          ['bing', 'reddit', 'wallhaven', 'apod'].contains(map['source']) ? map['source'] as String : 'url',
        wallhavenTheme: wallhavenWallpaperThemes.containsKey(map['wallhavenTheme']) ? map['wallhavenTheme'] as String : 'all',
        redditTheme: redditWallpaperThemes.containsKey(map['redditTheme']) ? map['redditTheme'] as String : 'all',
        redditResolution: redditWallpaperResolutions.contains(map['redditResolution']) ? map['redditResolution'] as String : 'fullHd',
        url: map['url'] as String? ?? '', intervalHours: [1, 6, 12, 24].contains(map['intervalHours']) ? map['intervalHours'] as int : 24);
      return !config.enabled || config.validUrl || config.url.isEmpty ? config : const OnlineWallpaperConfiguration();
    } catch (_) { return const OnlineWallpaperConfiguration(); }
  }
}
typedef WallpaperDownload = Future<Uint8List> Function(Uri uri);
Future<Uint8List> downloadWallpaper(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
  try {
    return await (() async {
      for (var redirects = 0; redirects <= 3; redirects++) {
        if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) throw const WallpaperException(WallpaperFailureReason.insecureUrl);
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        final response = await request.close();
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          final target = response.headers.value(HttpHeaders.locationHeader);
          if (target == null) throw const WallpaperException(WallpaperFailureReason.redirect);
          uri = uri.resolve(target);
          await response.drain<void>();
          continue;
        }
        if (response.statusCode != 200) throw WallpaperException(WallpaperFailureReason.http, httpStatus: response.statusCode);
        if (response.contentLength > maximumImageInputBytes) throw const WallpaperException(WallpaperFailureReason.tooLarge);
        final bytes = await readBoundedImage(response);
        try {
          await validateImageBytes(bytes);
        } catch (error) {
          final failure = WallpaperFailure.from(error, WallpaperStage.validation);
          throw WallpaperException(failure.reason, stage: failure.stage);
        }
        return bytes;
      }
      throw const WallpaperException(WallpaperFailureReason.redirect);
    })().timeout(const Duration(seconds: 20));
  } finally { client.close(force: true); }
}

class OnlineWallpaperService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final SharedPreferences preferences;
  final WallpaperDownload download;
  final Future<Directory> Function() directory;
  final Future<BingWallpaper> Function() bingLookup;
  final Future<ApodWallpaper> Function() apodLookup;
  final RedditWallpaperLookup redditLookup;
  final WallhavenWallpaperLookup wallhavenLookup;
  final DateTime Function() clock;
  final ForegroundWork? work;
  late OnlineWallpaperConfiguration configuration;
  File? _file;
  bool _ready = false, _loading = false, _foreground = true;
  bool failed = false;
  WallpaperFailure? failure;
  bool initialized = false;
  int version = 0, _generation = 0;
  DateTime? updatedAt, _lastAttempt;
  DateTime? _bingExpiresAt;
  String? _imageUrl;
  String copyright = '';
  Timer? _timer;
  bool get loading => _loading;
  ImageProvider? get wallpaper => configuration.enabled && _ready && _file != null ? VersionedFileImage(_file!, version) : null;
  OnlineWallpaperService(this.preferences, {WallpaperDownload? download, Future<Directory> Function()? directory, Future<BingWallpaper> Function()? bingLookup, Future<ApodWallpaper> Function()? apodLookup, RedditWallpaperLookup? redditLookup, WallhavenWallpaperLookup? wallhavenLookup, DateTime Function()? clock, this.work})
      : download = download ?? downloadWallpaper, directory = directory ?? getApplicationSupportDirectory, bingLookup = bingLookup ?? fetchBingWallpaper,
        apodLookup = apodLookup ?? fetchApodWallpaper, redditLookup = redditLookup ?? fetchRedditWallpaper, wallhavenLookup = wallhavenLookup ?? fetchWallhavenWallpaper, clock = clock ?? DateTime.now {
    configuration = OnlineWallpaperConfiguration.decode(preferences.getString(onlineWallpaperKey));
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
    _init();
  }
  Future<void> _init() async {
    try {
      final root = await directory();
      if (isDisposed) return;
      _file = File('${root.path}/online-wallpaper');
      await _restore();
      if (work == null) { await refresh(); }
      else if (!isDisposed) {
        notifyListeners();
        work!.schedule(this, () => refresh(), delay: const Duration(seconds: 1));
      }
    } catch (error, stack) {
      if (!isDisposed) _recordFailure(error, stack, WallpaperStage.initialize, configuration.source, 0);
    }
    finally { if (!isDisposed) { initialized = true; _startTimer(); notifyListeners(); } }
  }
  Future<void> _restore() async {
    try {
      final cache = jsonDecode(preferences.getString(onlineWallpaperCacheKey) ?? '{}') as Map;
      if (cache['url'] is String && (cache['url'] == 'bing' || cache['url'] == 'apod' ||
          wallhavenWallpaperThemes.keys.any((theme) => cache['url'] == 'wallhaven:$theme') ||
          redditWallpapersAvailable && RegExp(r'^reddit:(all|nature|space|city|minimal):(hd|fullHd|4k)$').hasMatch(cache['url'] as String) ||
          OnlineWallpaperConfiguration(url: cache['url'] as String).validUrl) && _file != null && await _file!.exists() && await _file!.length() <= maximumImageInputBytes) {
        await validateImageBytes(await readBoundedImage(_file!.openRead()));
        if (isDisposed) return;
        updatedAt = cache['url'] == configuration.identity ? DateTime.tryParse(cache['updatedAt'] as String? ?? '') : null;
        _imageUrl = cache['imageUrl'] as String?;
        _bingExpiresAt = DateTime.tryParse(cache['expiresAt'] as String? ?? '');
        copyright = cache['copyright'] as String? ?? '';
        _ready = true;
      }
    } catch (_) {}
  }
  Future<void> configure(OnlineWallpaperConfiguration value) async {
    if (value.source == 'reddit' && !redditWallpapersAvailable) value = value.copyWith(source: 'bing');
    if (!['url', 'bing', 'reddit', 'wallhaven', 'apod'].contains(value.source) ||
        !wallhavenWallpaperThemes.containsKey(value.wallhavenTheme) ||
        !redditWallpaperThemes.containsKey(value.redditTheme) ||
        !redditWallpaperResolutions.contains(value.redditResolution)) {
      throw ImageInputException();
    }
    if (value.enabled && !value.validUrl && value.url.isNotEmpty) throw ImageInputException();
    if (![1, 6, 12, 24].contains(value._intervalHours)) throw ImageInputException();
    await preferences.setString(onlineWallpaperKey, value.encode());
    _generation++;
    if (value.identity != configuration.identity) { updatedAt = null; _lastAttempt = null; _bingExpiresAt = null; }
    configuration = value;
    failed = false;
    failure = null;
    _startTimer();
    notifyListeners();
    await refresh();
  }
  Future<void> reload() async {
    final value = OnlineWallpaperConfiguration.decode(preferences.getString(onlineWallpaperKey));
    if (value.encode() != configuration.encode()) await configure(value);
  }
  Future<void> refresh({bool force = false}) async {
    if (configuration.source == 'reddit' && !redditWallpapersAvailable) return;
    if (isDisposed || !configuration.enabled || !configuration.validUrl || !_foreground || _file == null || _loading) return;
    final now = clock();
    if (!force && _lastAttempt != null && now.difference(_lastAttempt!) < const Duration(minutes: 5)) return;
    if (!force && updatedAt != null && !updatedAt!.isAfter(now) && now.difference(updatedAt!) < Duration(hours: configuration.intervalHours)) {
      return;
    }
    final generation = ++_generation;
    final config = configuration;
    _lastAttempt = now;
    _loading = true;
    notifyListeners();
    File? temporary;
    var stage = config.source == 'url' ? WallpaperStage.download : WallpaperStage.metadata;
    final stopwatch = Stopwatch()..start();
    try {
      final bing = config.source == 'bing' ? await bingLookup() : null;
      final apod = config.source == 'apod' ? await apodLookup() : null;
      final reddit = config.source == 'reddit' ? await redditLookup(config.redditTheme, config.redditResolution, _imageUrl) : null;
      final wallhaven = config.source == 'wallhaven' ? await wallhavenLookup(config.wallhavenTheme, _imageUrl) : null;
      final uri = wallhaven?.uri ?? reddit?.uri ?? apod?.uri ?? bing?.uri ?? Uri.parse(config.url);
      if (wallhaven != null && uri.toString() == _imageUrl) throw const WallpaperException(WallpaperFailureReason.noImage);
      if (reddit != null && uri.toString() == _imageUrl) throw const WallpaperException(WallpaperFailureReason.noImage);
      if (isDisposed || generation != _generation) return;
      if (force || !_ready || _imageUrl != uri.toString() || !['bing', 'apod'].contains(config.source)) {
      stage = WallpaperStage.download;
      final bytes = await download(uri);
      if (isDisposed || generation != _generation) return;
      stage = WallpaperStage.validation;
      await validateImageBytes(bytes);
      if (isDisposed || generation != _generation) return;
      stage = WallpaperStage.save;
      await _file!.parent.create(recursive: true);
      temporary = File('${_file!.path}.tmp');
      await temporary.writeAsBytes(bytes, flush: true);
      if (isDisposed || generation != _generation) return;
      await temporary.rename(_file!.path);
      temporary = null;
      if (isDisposed || generation != _generation) return;
      await FileImage(_file!).evict();
      version++;
      }
      stage = WallpaperStage.save;
      updatedAt = clock();
      _imageUrl = uri.toString();
      _bingExpiresAt = bing?.expiresAt;
      copyright = wallhaven?.credit ?? reddit?.credit ?? apod?.credit ?? bing?.copyright ?? '';
      await preferences.setString(onlineWallpaperCacheKey, jsonEncode({'url': config.identity, 'updatedAt': updatedAt!.toIso8601String(),
        'imageUrl': _imageUrl, 'copyright': copyright, 'expiresAt': _bingExpiresAt?.toIso8601String()}));
      _ready = true;
      failed = false;
      failure = null;
    } catch (error, stack) {
      if (!isDisposed && generation == _generation) {
        _recordFailure(error, stack, stage, config.source, stopwatch.elapsedMilliseconds);
      }
    }
    finally {
      try { if (temporary != null && await temporary.exists()) await temporary.delete(); } catch (_) {}
      _loading = false;
      if (!isDisposed) { notifyListeners(); if (generation != _generation) await refresh(); }
    }
  }
  void _recordFailure(Object error, StackTrace stack, WallpaperStage stage, String source, int durationMs) {
    failed = true;
    failure = WallpaperFailure.from(error, stage);
    DiagnosticsStore.instance.record('dart', 'onlineWallpaperRefresh', 'error', 'operation_failed', context: {
      'durationMs': durationMs,
      'frames': DiagnosticsStore.safeFrames(stack),
      'details': {...failure!.details(source), 'exception': DiagnosticsStore.exceptionKind(error)},
    });
  }
  void _startTimer() {
    _timer?.cancel();
    if (!isDisposed && configuration.enabled && _foreground) {
      _timer = Timer.periodic(['reddit', 'wallhaven'].contains(configuration.source) ? const Duration(minutes: 5) : const Duration(hours: 1), (_) => refresh());
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isDisposed) return;
    final foreground = state == AppLifecycleState.resumed;
    if (foreground == _foreground) return;
    _foreground = foreground;
    if (!_foreground) {
      _generation++;
      // An interrupted attempt is not a failure; resume may retry without delay.
      if (_loading) _lastAttempt = null;
      work?.cancel(this);
    }
    _startTimer();
    if (_foreground) {
      (work?.schedule(this, () => refresh(), delay: const Duration(seconds: 1)) ?? refresh());
    }
  }
  @override
  void dispose() { work?.cancel(this); _generation++; _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
}
