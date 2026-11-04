import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/reddit_wallpaper.dart';
import 'package:flauncher/wallhaven_wallpaper.dart';
import 'package:flauncher/apod_wallpaper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final image = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=');
  late Directory root;
  late SharedPreferences preferences;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cute-online-test-');
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() async { await root.delete(recursive: true); });
  Future<void> initialized(OnlineWallpaperService service) async {
    while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
  }
  test('APOD checks hourly, reuses unchanged image, keeps offline cache and restores it', () async {
    var now = DateTime.utc(2026, 11, 4);
    var lookups = 0, downloads = 0;
    var offline = false;
    final current = ApodWallpaper(Uri.parse('https://assets.science.nasa.gov/day.jpg'),
        'NASA APOD · Author · 2026-11-04', '2026-11-04');
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      clock: () => now, apodLookup: () async {
        lookups++;
        if (offline) throw const SocketException('offline');
        return current;
      }, download: (_) async { downloads++; return image; });
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'apod'));
    expect(downloads, 1);
    await service.refresh();
    expect(lookups, 1);
    now = now.add(const Duration(hours: 1));
    await service.refresh();
    expect(lookups, 2);
    expect(downloads, 1);
    expect(service.version, 1);
    await service.refresh(force: true);
    expect(downloads, 2);
    final metadata = preferences.getString(onlineWallpaperCacheKey);
    offline = true;
    now = now.add(const Duration(hours: 1));
    await service.refresh();
    expect(service.failed, isTrue);
    expect(service.wallpaper, isNotNull);
    expect(service.copyright, contains('Author'));
    expect(downloads, 2);
    expect(preferences.getString(onlineWallpaperCacheKey), metadata);
    service.dispose();
    final restored = OnlineWallpaperService(preferences, directory: () async => root,
      clock: () => now, apodLookup: () async => throw const SocketException('offline'));
    addTearDown(restored.dispose);
    await initialized(restored);
    expect(restored.configuration.source, 'apod');
    expect(restored.wallpaper, isNotNull);
    expect(restored.copyright, current.credit);
  });
  test('APOD pending metadata is ignored in background and after changing source', () async {
    for (final background in [true, false]) {
      final pending = Completer<ApodWallpaper>();
      var downloads = 0;
      final service = OnlineWallpaperService(preferences, directory: () async => root,
        apodLookup: () => pending.future,
        download: (_) async { downloads++; return image; });
      await initialized(service);
      final task = service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'apod'));
      await Future<void>.delayed(Duration.zero);
      if (background) {
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
      } else {
        await service.configure(const OnlineWallpaperConfiguration(source: 'url'));
      }
      pending.complete(ApodWallpaper(Uri.parse('https://assets.science.nasa.gov/day.jpg'), 'Old', '2026-11-04'));
      await task;
      expect(downloads, 0);
      expect(service.version, 0);
      service.dispose();
      await preferences.clear();
    }
  });
  test('Wallhaven rotates, respects interval, keeps cache offline and restores it', () async {
    var now = DateTime.utc(2026, 11, 1);
    var calls = 0;
    var offline = false;
    final themes = <String>[];
    final previous = <String?>[];
    final service = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
      wallhavenLookup: (theme, last) async {
        calls++;
        themes.add(theme); previous.add(last);
        if (offline) throw const SocketException('offline');
        return WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab000$calls.jpg'), 'Credit $calls');
      }, download: (_) async => image);
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'wallhaven', wallhavenTheme: 'nature', intervalHours: 6));
    expect(calls, 1);
    expect(service.copyright, 'Credit 1');
    await service.refresh();
    expect(calls, 1);
    now = now.add(const Duration(hours: 6));
    await service.refresh();
    expect(calls, 2);
    expect(previous.last, endsWith('ab0001.jpg'));
    final goodCache = preferences.getString(onlineWallpaperCacheKey);
    final goodBytes = await File('${root.path}/online-wallpaper').readAsBytes();
    offline = true;
    await service.refresh(force: true);
    expect(service.failed, isTrue);
    expect(service.wallpaper, isNotNull);
    expect(preferences.getString(onlineWallpaperCacheKey), goodCache);
    expect(await File('${root.path}/online-wallpaper').readAsBytes(), goodBytes);
    offline = false;
    await service.configure(service.configuration.copyWith(wallhavenTheme: 'city'));
    expect(themes.last, 'city');
    expect(service.failed, isFalse);
    service.dispose();
    final restored = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
      wallhavenLookup: (_, _) async => throw StateError('fresh cache must avoid lookup'));
    addTearDown(restored.dispose);
    await initialized(restored);
    expect(restored.configuration.wallhavenTheme, 'city');
    expect(restored.configuration.intervalHours, 6);
    expect(restored.wallpaper, isNotNull);
    expect(restored.failed, isFalse);
    expect(restored.copyright, 'Credit 4');
  });
  test('Wallhaven rejects repeated images and corrupt downloads without replacing cache', () async {
    var corrupt = false;
    var id = 1;
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      wallhavenLookup: (_, _) async => WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab000$id.jpg'), 'Credit'),
      download: (_) async => corrupt ? Uint8List.fromList([1, 2, 3]) : image);
    addTearDown(service.dispose);
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'wallhaven'));
    final cache = preferences.getString(onlineWallpaperCacheKey);
    final version = service.version;
    await service.refresh(force: true);
    expect(service.failed, isTrue);
    expect(service.version, version);
    id = 2; corrupt = true;
    await service.refresh(force: true);
    expect(service.failed, isTrue);
    expect(service.version, version);
    expect(service.wallpaper, isNotNull);
    expect(preferences.getString(onlineWallpaperCacheKey), cache);
    corrupt = false;
    await service.refresh(force: true);
    expect(service.failed, isFalse);
    expect(service.version, version + 1);
  });
  test('Wallhaven theme change discards pending lookup and downloads the latest theme', () async {
    final pending = Completer<WallhavenWallpaper>();
    final themes = <String>[];
    final urls = <String>[];
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      wallhavenLookup: (theme, _) async {
        themes.add(theme);
        if (theme == 'nature') return pending.future;
        return WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab0002.jpg'), 'City');
      }, download: (uri) async { urls.add(uri.toString()); return image; });
    addTearDown(service.dispose);
    await initialized(service);
    final old = service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'wallhaven', wallhavenTheme: 'nature'));
    await Future<void>.delayed(Duration.zero);
    await service.configure(service.configuration.copyWith(wallhavenTheme: 'city'));
    pending.complete(WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab0001.jpg'), 'Nature'));
    await old;
    expect(themes, ['nature', 'city']);
    expect(urls, ['https://w.wallhaven.cc/full/ab/wallhaven-ab0002.jpg']);
    expect(service.copyright, 'City');
    expect(service.configuration.wallhavenTheme, 'city');
  });
  test('Wallhaven ignores lookup completing in background and retries on resume', () async {
    final pending = Completer<WallhavenWallpaper>();
    var calls = 0, downloads = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      wallhavenLookup: (_, _) async {
        calls++;
        return calls == 1 ? pending.future : WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab0002.jpg'), 'New');
      }, download: (_) async { downloads++; return image; });
    addTearDown(service.dispose);
    await initialized(service);
    final task = service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'wallhaven'));
    await Future<void>.delayed(Duration.zero);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    pending.complete(WallhavenWallpaper(Uri.parse('https://w.wallhaven.cc/full/ab/wallhaven-ab0001.jpg'), 'Old'));
    await task;
    expect(downloads, 0);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    while (service.loading) { await Future<void>.delayed(Duration.zero); }
    expect(calls, 2);
    expect(downloads, 1);
  });
  test('creation in background defers saved wallpaper download until resume', () async {
    const config = OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/day.jpg');
    await preferences.setString(onlineWallpaperKey, config.encode());
    var attempts = 0;
    final binding = TestWidgetsFlutterBinding.instance;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      download: (_) async { attempts++; return image; });
    try {
      await initialized(service);
      expect(attempts, 0);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      while (service.loading) { await Future<void>.delayed(Duration.zero); }
      expect(attempts, 1);
      expect(service.wallpaper, isNotNull);
    } finally {
      service.dispose();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    }
  });
  for (final stage in ['lookup', 'download']) {
    test('background invalidates a pending $stage and resume retries immediately', () async {
      final lookup = Completer<BingWallpaper>();
      final bytes = Completer<Uint8List>();
      var lookups = 0, downloads = 0;
      final now = DateTime.utc(2026, 10, 30);
      final fresh = BingWallpaper(Uri.parse('https://example.com/fresh.png'), 'Fresh', now.add(const Duration(days: 1)));
      final service = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
        bingLookup: () async => ++lookups == 1 && stage == 'lookup' ? lookup.future : fresh,
        download: (_) async => ++downloads == 1 && stage == 'download' ? bytes.future : image);
      addTearDown(service.dispose);
      await initialized(service);
      final task = service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'bing'));
      await Future<void>.delayed(Duration.zero);
      expect(service.loading, isTrue);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      if (stage == 'lookup') {
        lookup.complete(fresh);
      } else {
        bytes.complete(image);
      }
      await task;
      expect(downloads, stage == 'lookup' ? 0 : 1);
      expect(service.version, 0);
      expect(service.updatedAt, isNull);
      expect(preferences.getString(onlineWallpaperCacheKey), isNull);
      expect(await File('${root.path}/online-wallpaper').exists(), isFalse);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      while (service.loading) { await Future<void>.delayed(Duration.zero); }
      expect(lookups, 2);
      expect(service.version, 1);
      expect(service.wallpaper, isNotNull);
      expect(service.failed, isFalse);
    });
  }
  test('Reddit remains unavailable for saved settings, import and direct configuration', () async {
    const draft = OnlineWallpaperConfiguration(enabled: true, source: 'reddit',
      intervalHours: 1, redditTheme: 'nature', redditResolution: '4k');
    await preferences.setString(onlineWallpaperKey, draft.encode());
    await File('${root.path}/online-wallpaper').writeAsBytes(image);
    await preferences.setString(onlineWallpaperCacheKey, jsonEncode({
      'url': draft.identity, 'updatedAt': DateTime.now().toIso8601String(),
      'imageUrl': 'https://i.redd.it/last.jpg', 'copyright': 'Reddit artist',
    }));
    var redditCalls = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      bingLookup: () async => throw const SocketException('offline'),
      download: (_) async { throw StateError('no image should be downloaded'); },
      redditLookup: (_, _, _) async { redditCalls++; throw StateError('Reddit must stay disabled'); });
    addTearDown(service.dispose);
    await initialized(service);
    expect(service.configuration.source, 'bing');
    expect(service.wallpaper, isNull);
    expect(service.copyright, isEmpty);
    await service.configure(draft);
    await service.refresh(force: true);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(service.configuration.source, 'bing');
    expect(OnlineWallpaperConfiguration.decode(preferences.getString(onlineWallpaperKey)).source, 'bing');
    final imported = compatibleSettings({onlineWallpaperKey: draft.encode()}, {});
    expect(OnlineWallpaperConfiguration.decode(imported[onlineWallpaperKey] as String).source, 'bing');
    expect(redditCalls, 0);
    await expectLater(fetchRedditWallpaper('all', 'fullHd', null), throwsStateError);
  });
  test('enabled HTTPS draft persists without downloads and preserves the last successful wallpaper', () async {
    var attempts = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      download: (_) async { attempts++; return image; });
    addTearDown(service.dispose);
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/a.png'));
    expect(attempts, 1);
    final lastWallpaper = service.wallpaper;
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'url'));
    await service.refresh();
    expect(attempts, 1);
    expect(service.failed, false);
    expect(service.wallpaper, lastWallpaper);
    final saved = preferences.getString(onlineWallpaperKey)!;
    expect(validOnlineWallpaperConfiguration(saved), true);
    final restored = OnlineWallpaperConfiguration.decode(saved);
    expect(restored.enabled, true);
    expect(restored.source, 'url');
    expect(restored.url, isEmpty);
    expect(compatibleSettings({onlineWallpaperKey: saved}, {})[onlineWallpaperKey], saved);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/b.png'));
    expect(attempts, 2);
  });

  test('Bing day change preserves the last success offline and refreshes after resume', () async {
    var now = DateTime.utc(2026, 10, 6, 12);
    var day = 1, attempts = 0;
    var offline = false;
    final secondImage = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=');
    final service = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
      bingLookup: () async => BingWallpaper(Uri.parse('https://www.bing.com/day$day.jpg'), 'Day $day', now.add(const Duration(days: 1))),
      download: (_) async { attempts++; if (offline) throw const SocketException('offline'); return day == 1 ? image : secondImage; });
    addTearDown(service.dispose);
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'bing'));
    final file = File('${root.path}/online-wallpaper');
    final savedMetadata = preferences.getString(onlineWallpaperCacheKey);
    final savedVersion = service.version;
    day = 2; offline = true; now = now.add(const Duration(days: 1, minutes: 1));
    await service.refresh();
    expect(service.failed, isTrue);
    expect(service.wallpaper, isNotNull);
    expect(service.version, savedVersion);
    expect(service.copyright, 'Day 1');
    expect(await file.readAsBytes(), image);
    expect(preferences.getString(onlineWallpaperCacheKey), savedMetadata);
    offline = false;
    await service.refresh();
    expect(attempts, 2); // Five-minute throttle still applies to a failed attempt.
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 5));
    await service.refresh();
    expect(attempts, 2);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    while (service.loading) { await Future<void>.delayed(Duration.zero); }
    expect(service.failed, isFalse);
    expect(service.copyright, 'Day 2');
    expect(await file.readAsBytes(), secondImage);
    expect(service.version, savedVersion + 1);
    expect(attempts, 3);
    expect(File('${file.path}.tmp').existsSync(), isFalse);
  });
  test('legacy intervals normalize to one hour, including expired Bing metadata', () async {
    expect(const OnlineWallpaperConfiguration(intervalHours: 24).intervalHours, 1);
    expect(OnlineWallpaperConfiguration.decode('{"enabled":false,"url":"","intervalHours":6}').intervalHours, 1);
    var lookups = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root,
      download: (_) async => image, bingLookup: () async {
        lookups++;
        return BingWallpaper(Uri.parse('https://example.com/day.jpg'), '', DateTime.now().subtract(const Duration(hours: 1)));
      });
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'bing'));
    await service.refresh();
    expect(lookups, 1);
    service.dispose();
  });
  for (final source in ['bing', 'url']) {
    test('forced $source refresh downloads immediately and retries offline without throttling', () async {
      var attempts = 0;
      var offline = false;
      final now = DateTime.utc(2026, 10, 19);
      final service = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
        bingLookup: () async => BingWallpaper(Uri.parse('https://example.com/same.png'), 'Credit', now.add(const Duration(days: 1))),
        download: (_) async { attempts++; if (offline) throw const SocketException('offline'); return image; });
      addTearDown(service.dispose);
      await initialized(service);
      await service.configure(OnlineWallpaperConfiguration(enabled: true, source: source, url: 'https://example.com/same.png'));
      expect(attempts, 1);
      await service.refresh(force: true);
      expect(attempts, 2);
      expect(service.version, 2);
      offline = true;
      final metadata = preferences.getString(onlineWallpaperCacheKey);
      await service.refresh(force: true);
      expect(attempts, 3);
      expect(service.failed, isTrue);
      expect(service.wallpaper, isNotNull);
      expect(service.version, 2);
      expect(preferences.getString(onlineWallpaperCacheKey), metadata);
      offline = false;
      await service.refresh(force: true);
      expect(attempts, 4);
      expect(service.failed, isFalse);
      expect(service.version, 3);
    });
  }
  test('automatic HTTPS refresh becomes due after one hour and respects foreground', () async {
    var now = DateTime.utc(2026, 10, 19);
    var attempts = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root, clock: () => now,
      download: (_) async { attempts++; return image; });
    addTearDown(service.dispose);
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/same.png'));
    now = now.add(const Duration(minutes: 59));
    await service.refresh();
    expect(attempts, 1);
    now = now.add(const Duration(minutes: 1));
    await service.refresh();
    expect(attempts, 2);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(hours: 1));
    await service.refresh();
    expect(attempts, 2);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    while (service.loading) { await Future<void>.delayed(Duration.zero); }
    expect(attempts, 3);
  });
  test('disabled service makes no requests and validates HTTPS sources on import', () async {
    var calls = 0;
    final service = OnlineWallpaperService(preferences, directory: () async => root, download: (_) async { calls++; return image; });
    await initialized(service);
    expect(calls, 0);
    expect(compatibleSettings({onlineWallpaperKey: '{"enabled":true,"url":"http://example.com/a.jpg","intervalHours":24}', onlineWallpaperCacheKey: '{}'}, {}), isEmpty);
    expect(const OnlineWallpaperConfiguration(url: 'https://user:pass@example.com/a.jpg').validUrl, isFalse);
    service.dispose();
  });
  test('valid image persists, survives offline restart, and disabling releases the displayed image', () async {
    final service = OnlineWallpaperService(preferences, directory: () async => root, download: (_) async => image);
    await initialized(service);
    const config = OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/day.jpg');
    await service.configure(config);
    expect(service.wallpaper, isNotNull);
    expect(await File('${root.path}/online-wallpaper').readAsBytes(), image);
    service.dispose();
    await preferences.setString(onlineWallpaperCacheKey, jsonEncode({'url': config.url, 'updatedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()}));
    final offline = OnlineWallpaperService(preferences, directory: () async => root, download: (_) async => throw const SocketException('offline'));
    await initialized(offline);
    expect(offline.failed, isTrue);
    expect(offline.wallpaper, isNotNull);
    await offline.configure(OnlineWallpaperConfiguration(url: config.url));
    expect(offline.wallpaper, isNull);
    expect(await File('${root.path}/online-wallpaper').exists(), isTrue);
    offline.dispose();
  });
  test('damaged download retains cached file and repeated refresh does not retry immediately', () async {
    var calls = 0;
    var bytes = image;
    final service = OnlineWallpaperService(preferences, directory: () async => root, download: (_) async { calls++; return bytes; });
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/first.jpg'));
    bytes = Uint8List.fromList([0, 1, 2]);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/broken.jpg'));
    expect(service.failed, isTrue);
    expect(service.wallpaper, isNotNull);
    expect(await File('${root.path}/online-wallpaper').readAsBytes(), image);
    await service.refresh();
    expect(calls, 2);
    service.dispose();
  });
  test('late download after disabling never replaces wallpaper and background refresh makes no requests', () async {
    final pending = Completer<Uint8List>();
    final service = OnlineWallpaperService(preferences, directory: () async => root, download: (_) => pending.future);
    await initialized(service);
    final download = service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/day.jpg'));
    await Future<void>.delayed(Duration.zero);
    await service.configure(const OnlineWallpaperConfiguration());
    pending.complete(image);
    await download;
    expect(service.wallpaper, isNull);
    expect(await File('${root.path}/online-wallpaper').exists(), isFalse);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, url: 'https://example.com/day.jpg'));
    expect(service.wallpaper, isNull);
    service.dispose();
  });
  test('expired Bing metadata refreshes copyright without downloading the same image again', () async {
    var downloads = 0;
    final uri = Uri.parse('https://www.bing.com/th?id=Example_1920x1080.jpg');
    Future<BingWallpaper> lookup() async => BingWallpaper(uri, '© Example', DateTime.now().add(const Duration(days: 1)));
    final service = OnlineWallpaperService(preferences, directory: () async => root, bingLookup: lookup,
      download: (_) async { downloads++; return image; });
    await initialized(service);
    await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'bing'));
    expect(downloads, 1);
    expect(service.copyright, '© Example');
    service.dispose();
    final cache = jsonDecode(preferences.getString(onlineWallpaperCacheKey)!) as Map;
    cache['expiresAt'] = DateTime.now().subtract(const Duration(minutes: 1)).toIso8601String();
    cache['updatedAt'] = DateTime.now().subtract(const Duration(hours: 24)).toIso8601String();
    await preferences.setString(onlineWallpaperCacheKey, jsonEncode(cache));
    var metadataRequests = 0;
    final restored = OnlineWallpaperService(preferences, directory: () async => root,
      bingLookup: () async { metadataRequests++; return lookup(); }, download: (_) async { downloads++; return image; });
    await initialized(restored);
    expect(metadataRequests, 1);
    expect(downloads, 1);
    expect(restored.wallpaper, isNotNull);
    restored.dispose();
  });
}
