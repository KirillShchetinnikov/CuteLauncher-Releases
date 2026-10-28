import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../image_limits.dart';
import '../versioned_file_image.dart';
import '../bing_wallpaper.dart';
import '../reddit_wallpaper.dart';
import 'service_lifecycle.dart';
import 'foreground_work.dart';

const onlineWallpaperKey = 'online_wallpaper';
const onlineWallpaperCacheKey = 'online_wallpaper_cache';
bool validOnlineWallpaperConfiguration(String value) {
  try {
    final map = jsonDecode(value) as Map;
    if (map['source'] != null && !['url', 'bing', 'reddit'].contains(map['source'])) return false;
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
  int get intervalHours => source == 'reddit' ? _intervalHours : 1;
  final String source;
  final String redditTheme, redditResolution;
  String get identity => source == 'reddit' ? 'reddit:$redditTheme:$redditResolution' : source == 'bing' ? 'bing' : url;
  const OnlineWallpaperConfiguration({this.enabled = false, this.url = '', int intervalHours = 24, this.source = 'url',
    // Keep the public constructor argument while normalizing non-Reddit intervals in the getter.
    // ignore: prefer_initializing_formals
    this.redditTheme = 'all', this.redditResolution = 'fullHd'}) : _intervalHours = intervalHours;
  OnlineWallpaperConfiguration copyWith({bool? enabled, String? source, int? intervalHours, String? redditTheme, String? redditResolution}) =>
    OnlineWallpaperConfiguration(enabled: enabled ?? this.enabled, url: url, source: source ?? this.source,
      intervalHours: intervalHours ?? _intervalHours, redditTheme: redditTheme ?? this.redditTheme,
      redditResolution: redditResolution ?? this.redditResolution);
  bool get validUrl {
    if (source == 'bing') return true;
    if (source == 'reddit') return redditWallpaperThemes.containsKey(redditTheme) && redditWallpaperResolutions.contains(redditResolution);
    final uri = Uri.tryParse(url);
    return url.length <= 2048 && uri != null && uri.scheme == 'https' && uri.host.isNotEmpty && uri.userInfo.isEmpty;
  }
  String encode() => jsonEncode({'enabled': enabled, 'url': url, 'intervalHours': _intervalHours, 'source': source,
    'redditTheme': redditTheme, 'redditResolution': redditResolution});
  static OnlineWallpaperConfiguration decode(String? value) {
    try {
      final map = jsonDecode(value ?? '{}') as Map;
      final config = OnlineWallpaperConfiguration(enabled: map['enabled'] == true,
        source: map['source'] == 'reddit' && !redditWallpapersAvailable ? 'bing' :
          ['bing', 'reddit'].contains(map['source']) ? map['source'] as String : 'url',
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
        if (uri.scheme != 'https' || uri.userInfo.isNotEmpty) throw ImageInputException();
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        final response = await request.close();
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          final target = response.headers.value(HttpHeaders.locationHeader);
          if (target == null) throw ImageInputException();
          uri = uri.resolve(target);
          await response.drain<void>();
          continue;
        }
        if (response.statusCode != 200 || response.contentLength > maximumImageInputBytes) throw ImageInputException();
        final bytes = await readBoundedImage(response);
        await validateImageBytes(bytes);
        return bytes;
      }
      throw ImageInputException();
    })().timeout(const Duration(seconds: 20));
  } finally { client.close(force: true); }
}

class OnlineWallpaperService extends ChangeNotifier with ServiceLifecycle, WidgetsBindingObserver {
  final SharedPreferences preferences;
  final WallpaperDownload download;
  final Future<Directory> Function() directory;
  final Future<BingWallpaper> Function() bingLookup;
  final RedditWallpaperLookup redditLookup;
  final DateTime Function() clock;
  final ForegroundWork? work;
  late OnlineWallpaperConfiguration configuration;
  File? _file;
  bool _ready = false, _loading = false, _foreground = true;
  bool failed = false;
  bool initialized = false;
  int version = 0, _generation = 0;
  DateTime? updatedAt, _lastAttempt;
  DateTime? _bingExpiresAt;
  String? _imageUrl;
  String copyright = '';
  Timer? _timer;
  bool get loading => _loading;
  ImageProvider? get wallpaper => configuration.enabled && _ready && _file != null ? VersionedFileImage(_file!, version) : null;
  OnlineWallpaperService(this.preferences, {WallpaperDownload? download, Future<Directory> Function()? directory, Future<BingWallpaper> Function()? bingLookup, RedditWallpaperLookup? redditLookup, DateTime Function()? clock, this.work})
      : download = download ?? downloadWallpaper, directory = directory ?? getApplicationSupportDirectory, bingLookup = bingLookup ?? fetchBingWallpaper,
        redditLookup = redditLookup ?? fetchRedditWallpaper, clock = clock ?? DateTime.now {
    configuration = OnlineWallpaperConfiguration.decode(preferences.getString(onlineWallpaperKey));
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
    } catch (_) { if (!isDisposed) failed = true; }
    finally { if (!isDisposed) { initialized = true; _startTimer(); notifyListeners(); } }
  }
  Future<void> _restore() async {
    try {
      final cache = jsonDecode(preferences.getString(onlineWallpaperCacheKey) ?? '{}') as Map;
      if (cache['url'] is String && (cache['url'] == 'bing' ||
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
    if (!['url', 'bing', 'reddit'].contains(value.source) ||
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
    try {
      final bing = config.source == 'bing' ? await bingLookup() : null;
      final reddit = config.source == 'reddit' ? await redditLookup(config.redditTheme, config.redditResolution, _imageUrl) : null;
      final uri = reddit?.uri ?? bing?.uri ?? Uri.parse(config.url);
      if (reddit != null && uri.toString() == _imageUrl) throw const FormatException('Reddit returned the previous wallpaper');
      if (isDisposed || generation != _generation) return;
      if (force || !_ready || _imageUrl != uri.toString() || config.source != 'bing') {
      final bytes = await download(uri);
      if (isDisposed || generation != _generation) return;
      await validateImageBytes(bytes);
      if (isDisposed || generation != _generation) return;
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
      updatedAt = clock();
      _imageUrl = uri.toString();
      _bingExpiresAt = bing?.expiresAt;
      copyright = reddit?.credit ?? bing?.copyright ?? '';
      await preferences.setString(onlineWallpaperCacheKey, jsonEncode({'url': config.identity, 'updatedAt': updatedAt!.toIso8601String(),
        'imageUrl': _imageUrl, 'copyright': copyright, 'expiresAt': _bingExpiresAt?.toIso8601String()}));
      _ready = true;
      failed = false;
    } catch (_) { if (!isDisposed && generation == _generation) failed = true; }
    finally {
      try { if (temporary != null && await temporary.exists()) await temporary.delete(); } catch (_) {}
      _loading = false;
      if (!isDisposed) { notifyListeners(); if (generation != _generation) await refresh(); }
    }
  }
  void _startTimer() {
    _timer?.cancel();
    if (!isDisposed && configuration.enabled && _foreground) {
      _timer = Timer.periodic(configuration.source == 'reddit' ? const Duration(minutes: 5) : const Duration(hours: 1), (_) => refresh());
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _startTimer();
    if (_foreground) {
      (work?.schedule(this, () => refresh(), delay: const Duration(seconds: 1)) ?? refresh());
    }
  }
  @override
  void dispose() { work?.cancel(this); _generation++; _timer?.cancel(); WidgetsBinding.instance.removeObserver(this); super.dispose(); }
}
