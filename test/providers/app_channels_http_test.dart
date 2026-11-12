import 'dart:io';

import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import '../support/app_channels.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(DiagnosticsStore.instance.clear);
  test('revalidation keeps identical bytes and retains artwork on invalid responses', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      var invalid = false;
      var requests = 0;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final subscription = server.listen((request) {
        requests++;
        request.response.add(invalid ? [1, 2, 3] : kTransparentImage);
        request.response.close();
      });
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final channel = FeedChannel();
      final service = AppChannelsService(channel, settings);
      final uri = 'http://127.0.0.1:${server.port}/poster';
      try {
        final original = await service.poster(uri);
        expect(original, kTransparentImage);
        await service.refresh(reloadPosters: true);
        expect(service.cachedPoster(uri), same(original));
        expect(await service.poster(uri), same(original));
        expect(requests, 2);
        expect(await service.poster(uri), same(original));
        expect(requests, 2);
        invalid = true;
        await service.refresh(reloadPosters: true);
        expect(await service.poster(uri), same(original));
        expect(service.cachedPoster(uri), same(original));
        final failures = DiagnosticsStore.instance.posterLoads.snapshot()['failures'] as List;
        expect(failures.single['stage'], 'validation');
        expect(failures.single['reason'], 'invalidImage');
        expect(failures.single['outcome'], 'cachedFallback');
        expect(failures.single['httpStatus'], 200);
      } finally {
        service.dispose(); settings.dispose(); await channel.events.close();
        await subscription.cancel(); await server.close(force: true);
      }
    }, _RealHttp());
  });
  test('header timeouts release connections for later posters', () async {
    await HttpOverrides.runWithHttpOverrides(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final subscription = server.listen((request) {
        if (request.uri.path == '/good') {
          request.response.add(kTransparentImage);
          request.response.close();
        }
        // /stall deliberately never sends response headers.
      });
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final channel = FeedChannel();
      final service = AppChannelsService(channel, settings);
      final base = 'http://127.0.0.1:${server.port}';
      try {
        expect(await Future.wait([
          service.poster('$base/stall?one'),
          service.poster('$base/stall?two'),
        ]), [null, null]);
        expect(await service.poster('$base/good'), kTransparentImage);
        final failures = DiagnosticsStore.instance.posterLoads.snapshot()['failures'] as List;
        expect(failures, hasLength(2));
        expect(failures.first['stage'], 'headers');
        expect(failures.first['timeoutMs'], 5000);
      } finally {
        service.dispose();
        settings.dispose();
        await channel.events.close();
        await subscription.cancel();
        await server.close(force: true);
      }
    }, _RealHttp());
  });

  for (final failure in ['http error', 'stalled body']) {
    test('$failure releases connections so posters recover without restart', () async {
      await HttpOverrides.runWithHttpOverrides(() async {
        var goodRequests = 0;
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final subscription = server.listen((request) async {
          if (request.uri.path == '/good') {
            goodRequests++;
            request.response.add(kTransparentImage);
            await request.response.close();
          } else if (failure == 'http error') {
            request.response.statusCode = HttpStatus.serviceUnavailable;
            request.response.write('Temporarily unavailable');
            await request.response.close();
          } else {
            // Headers arrive, but the image never finishes (e.g. lost network).
            request.response.contentLength = 6;
            request.response.bufferOutput = false;
            request.response.add([1, 2, 3]);
            await request.response.flush();
          }
        });
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        final channel = FeedChannel();
        final service = AppChannelsService(channel, settings);
        final base = 'http://127.0.0.1:${server.port}';
        try {
          expect(
            await Future.wait([
              service.poster('$base/fail?one'),
              service.poster('$base/fail?two'),
            ]),
            [null, null],
          );
          // Resume must recover using the same service and HttpClient.
          service.didChangeAppLifecycleState(AppLifecycleState.paused);
          service.didChangeAppLifecycleState(AppLifecycleState.resumed);
          expect(await service.poster('$base/good'), kTransparentImage);
          expect(goodRequests, 1);
          final diagnostics = DiagnosticsStore.instance.posterLoads.snapshot();
          final errors = diagnostics['failures'] as List;
          expect(errors, hasLength(2));
          expect(errors.first['stage'], failure == 'http error' ? 'headers' : 'body');
          expect(errors.first['reason'], failure == 'http error' ? 'http' : 'timeout');
          expect(errors.first['httpStatus'], failure == 'http error' ? 503 : 200);
          if (failure == 'stalled body') {
            expect(errors.first['receivedBytes'], 3);
            expect(errors.first['expectedBytes'], 6);
            expect(errors.first['timeoutMs'], 8000);
          }
          expect(diagnostics['active'], isEmpty);
          expect((diagnostics['recent'] as List).last['outcome'], 'loaded');
        } finally {
          service.dispose();
          settings.dispose();
          await channel.events.close();
          await subscription.cancel();
          await server.close(force: true);
        }
      }, _RealHttp());
    });
  }
}
