import 'dart:io';

import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import '../support/app_channels.dart';

class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
