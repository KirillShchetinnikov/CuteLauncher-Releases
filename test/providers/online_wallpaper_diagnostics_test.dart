import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/apod_wallpaper.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/online_wallpaper_failure.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/wallhaven_wallpaper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final image = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=',
  );
  late Directory root;
  late SharedPreferences preferences;
  setUp(() async {
    DiagnosticsStore.instance.clear();
    root = await Directory.systemTemp.createTemp('wallpaper-diagnostics-');
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });
  Future<void> initialized(OnlineWallpaperService service) async {
    while (!service.initialized) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  for (final source in ['bing', 'wallhaven', 'apod', 'url']) {
    test(
      '$source download errors retain source and HTTP code in diagnostics',
      () async {
        final uri = Uri.parse('https://private.example/path?token=secret');
        final service = OnlineWallpaperService(
          preferences,
          directory: () async => root,
          bingLookup: () async => BingWallpaper(uri, '', DateTime.now()),
          apodLookup: () async => ApodWallpaper(uri, '', '2026-11-04'),
          wallhavenLookup: (_, _) async => WallhavenWallpaper(uri, ''),
          download: (_) async => throw const WallpaperException(
            WallpaperFailureReason.http,
            httpStatus: 429,
          ),
        );
        addTearDown(service.dispose);
        await initialized(service);
        await service.configure(
          OnlineWallpaperConfiguration(
            enabled: true,
            source: source,
            url: uri.toString(),
          ),
        );
        final event =
            (DiagnosticsStore.instance.snapshot()['failures'] as List).last
                as Map;
        expect(event['details'], containsPair('exception', 'other'));
        expect(event['details'], containsPair('wallpaperSource', source));
        expect(event['details'], containsPair('stage', 'wallpaper_download'));
        expect(event['details'], containsPair('reason', 'wallpaper_http'));
        expect(event['details'], containsPair('httpStatus', 429));
        expect(jsonEncode(event), isNot(contains('private')));
        expect(jsonEncode(event), isNot(contains('secret')));
      },
    );
  }

  test('lookup failures export source, stage and codes without private exception data', () async {
    Object? error;
    final service = OnlineWallpaperService(
      preferences,
      directory: () async => root,
      bingLookup: () async {
        if (error != null) throw error;
        return BingWallpaper(
          Uri.parse('https://example.com/image.png'),
          '',
          DateTime.now(),
        );
      },
      download: (_) async => image,
    );
    addTearDown(service.dispose);
    await initialized(service);
    for (final (failureError, reason) in <(Object, WallpaperFailureReason)>[
      (
        const SocketException(
          'Failed host lookup: secret.example?token=private',
          osError: OSError('secret', 7),
        ),
        WallpaperFailureReason.dns,
      ),
      (
        const SocketException('secret IP and path'),
        WallpaperFailureReason.connection,
      ),
      (
        const HandshakeException('private certificate'),
        WallpaperFailureReason.tls,
      ),
      (TimeoutException('secret URL'), WallpaperFailureReason.timeout),
      (
        const WallpaperException(WallpaperFailureReason.http, httpStatus: 403),
        WallpaperFailureReason.http,
      ),
      (
        const FormatException('private JSON and URL'),
        WallpaperFailureReason.invalidResponse,
      ),
      (
        const WallpaperException(WallpaperFailureReason.noImage),
        WallpaperFailureReason.noImage,
      ),
    ]) {
      error = failureError;
      await service.configure(
        const OnlineWallpaperConfiguration(enabled: true, source: 'bing'),
      );
      await service.refresh(force: true);
      expect(service.failed, isTrue);
      expect(service.failure!.stage, WallpaperStage.metadata);
      expect(service.failure!.reason, reason);
      final event =
          (DiagnosticsStore.instance.snapshot()['failures'] as List).last
              as Map;
      expect(event['operation'], 'dart.onlineWallpaperRefresh');
      final details = event['details'] as Map;
      expect(details['wallpaperSource'], 'bing');
      expect(details['stage'], 'wallpaper_metadata');
      expect(details['reason'], 'wallpaper_${reason.name}');
      if (reason == WallpaperFailureReason.http) {
        expect(details['httpStatus'], 403);
      }
      if (reason == WallpaperFailureReason.dns) {
        expect(details['osErrorCode'], 7);
      }
      expect(jsonEncode(event), isNot(contains('secret')));
      expect(jsonEncode(event), isNot(contains('private')));
    }
    error = null;
    await service.refresh(force: true);
    expect(service.failed, isFalse);
    expect(service.failure, isNull);
    expect(service.wallpaper, isNotNull);
  });

  test('download, validation, storage and initialization errors identify their stage', () async {
    Object? error = TimeoutException('private URL');
    var bytes = image;
    final service = OnlineWallpaperService(
      preferences,
      directory: () async => root,
      download: (_) async {
        if (error != null) throw error;
        return bytes;
      },
    );
    addTearDown(service.dispose);
    await initialized(service);
    await service.configure(
      const OnlineWallpaperConfiguration(
        enabled: true,
        url: 'https://private.example/token',
      ),
    );
    expect(service.failure!.stage, WallpaperStage.download);
    expect(service.failure!.reason, WallpaperFailureReason.timeout);
    error = null;
    bytes = Uint8List.fromList([1, 2, 3]);
    await service.refresh(force: true);
    expect(service.failure!.stage, WallpaperStage.validation);
    expect(service.failure!.reason, WallpaperFailureReason.invalidImage);
    bytes = image;
    await service.refresh(force: true);
    expect(service.failure, isNull);
    final saved = await File('${root.path}/online-wallpaper').readAsBytes();
    final metadata = preferences.getString(onlineWallpaperCacheKey);
    error = const WallpaperException(
      WallpaperFailureReason.http,
      httpStatus: 503,
    );
    await service.refresh(force: true);
    expect(service.wallpaper, isNotNull);
    expect(await File('${root.path}/online-wallpaper').readAsBytes(), saved);
    expect(preferences.getString(onlineWallpaperCacheKey), metadata);

    final invalidRoot = File('${root.path}/not-a-directory');
    await invalidRoot.writeAsString('keep');
    final storage = OnlineWallpaperService(
      preferences,
      directory: () async => Directory(invalidRoot.path),
      download: (_) async => image,
    );
    addTearDown(storage.dispose);
    await initialized(storage);
    await storage.refresh(force: true);
    expect(storage.failure!.stage, WallpaperStage.save);
    expect(storage.failure!.reason, WallpaperFailureReason.storage);
    final init = OnlineWallpaperService(
      preferences,
      directory: () async => throw const FileSystemException('private path'),
    );
    addTearDown(init.dispose);
    await initialized(init);
    expect(init.failure!.stage, WallpaperStage.initialize);
    expect(init.failure!.reason, WallpaperFailureReason.storage);
  });

  test(
    'obsolete failed lookup does not publish an error after source change',
    () async {
      final pending = Completer<BingWallpaper>();
      final service = OnlineWallpaperService(
        preferences,
        directory: () async => root,
        bingLookup: () => pending.future,
        download: (_) async => image,
      );
      addTearDown(service.dispose);
      await initialized(service);
      final old = service.configure(
        const OnlineWallpaperConfiguration(enabled: true, source: 'bing'),
      );
      while (!service.loading) {
        await Future<void>.delayed(Duration.zero);
      }
      await service.configure(
        const OnlineWallpaperConfiguration(
          enabled: true,
          url: 'https://example.com/new.png',
        ),
      );
      pending.completeError(const SocketException('obsolete private error'));
      await old;
      expect(service.failed, isFalse);
      expect(service.failure, isNull);
      expect(DiagnosticsStore.instance.snapshot()['failures'], isEmpty);
      expect(service.wallpaper, isNotNull);
    },
  );
}
