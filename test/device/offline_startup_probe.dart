import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/flauncher_app.dart';
import 'package:flauncher/main.dart' as launcher;
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> waitFor(bool Function() ready) async {
  final end = DateTime.now().add(const Duration(seconds: 45));
  while (!ready()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Service not ready');
    }
    WidgetsBinding.instance.scheduleFrame();
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

/// Runs the real Home and its providers. Requires OfflineStartupProbe backup and
/// Android's per-UID firewall. No injected transports or mock server responses.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hardware = await Process.run('/system/bin/getprop', ['ro.hardware']);
  require(
    Platform.isAndroid &&
        ['ranchu', 'goldfish'].contains(hardware.stdout.toString().trim()),
    'Emulator required',
  );
  final cache = await getTemporaryDirectory();
  final reportFile = File('${cache.path}/offline-startup-runtime.json');
  if (await reportFile.exists()) await reportFile.delete();
  final preferences = await SharedPreferences.getInstance();
  final support = await getApplicationSupportDirectory();
  final wallpaperFile = File('${support.path}/online-wallpaper');
  final originalImage = await wallpaperFile.exists()
      ? await wallpaperFile.readAsBytes()
      : null;
  final checks = <Map<String, Object?>>[];
  var frames = 0;
  WidgetsBinding.instance.addPersistentFrameCallback((_) => frames++);
  final heartbeat = Timer.periodic(
    const Duration(milliseconds: 200),
    (_) => WidgetsBinding.instance.scheduleFrame(),
  );
  Future<void> check(String name, Future<void> Function() action) async {
    final timer = Stopwatch()..start();
    try {
      await action().timeout(const Duration(seconds: 50));
      checks.add({
        'name': name,
        'result': 'PASS',
        'ms': timer.elapsedMilliseconds,
      });
    } catch (error) {
      checks.add({
        'name': name,
        'result': 'FAIL',
        'error': error.toString(),
        'ms': timer.elapsedMilliseconds,
      });
    }
    await reportFile.writeAsString(
      jsonEncode({'status': 'RUNNING', 'checks': checks}),
      flush: true,
    );
  }

  try {
    const config = WeatherConfiguration(
      source: WeatherSource.openMeteo,
      latitude: 55.75,
      longitude: 37.62,
      location: 'Offline cache',
    );
    final cachedWeather = jsonEncode({
      'configuration': jsonEncode(config.toJson()),
      'fetchedAt': DateTime.now()
          .subtract(const Duration(hours: 2))
          .toIso8601String(),
      'data': {
        'timestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'location': 'Offline cache',
        'currentTemp': 18,
        'currentConditionCode': 800,
        'currentCondition': 'Clear',
        'forecasts': <Object>[],
      },
    });
    await preferences.setString(
      weatherConfigurationKey,
      jsonEncode(config.toJson()),
    );
    await preferences.setString('weather_cache', cachedWeather);
    const online = OnlineWallpaperConfiguration(
      enabled: true,
      source: 'bing',
      intervalHours: 1,
    );
    await preferences.setString(onlineWallpaperKey, online.encode());
    await wallpaperFile.parent.create(recursive: true);
    final image = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=',
    );
    await wallpaperFile.writeAsBytes(image, flush: true);
    final cachedWallpaper = jsonEncode({
      'url': 'bing',
      'imageUrl': 'https://www.bing.com/offline-cache.png',
      'updatedAt': DateTime.now()
          .subtract(const Duration(days: 2))
          .toIso8601String(),
      'expiresAt': '2000-01-01T00:00:00Z',
      'copyright': 'Offline fixture',
    });
    await preferences.setString(onlineWallpaperCacheKey, cachedWallpaper);

    await launcher.main();
    Element? context;
    void visit(Element element) {
      if (element.widget is FLauncherApp) context = element;
      element.visitChildElements(visit);
    }

    await waitFor(() {
      WidgetsBinding.instance.rootElement?.visitChildElements(visit);
      return context != null;
    });
    final weather = context!.read<WeatherService>();
    final wallpaper = context!.read<OnlineWallpaperService>();
    final night = context!.read<NightModeService>();
    await check('cold Home renders while real network requests fail', () async {
      await waitFor(
        () =>
            weather.initialized && wallpaper.initialized && !wallpaper.loading,
      );
      require(frames > 2, 'Home stopped rendering');
      require(
        weather.failure == WeatherFailure.unavailable && wallpaper.failed,
        'Network unexpectedly available',
      );
    });
    await check(
      'weather cache survives offline cold start and forced refresh',
      () async {
        require(
          weather.hasWeather &&
              weather.weatherData!.currentTemp == 18 &&
              weather.stale,
          'Cached weather missing',
        );
        await weather.refresh();
        require(
          !weather.loading && weather.failure == WeatherFailure.unavailable,
          'Weather did not finish with network error',
        );
        require(
          weather.hasWeather &&
              preferences.getString('weather_cache') == cachedWeather,
          'Weather history replaced',
        );
      },
    );
    await check(
      'weather without cache finishes with unavailable data',
      () async {
        await preferences.remove('weather_cache');
        await weather.configure(config);
        require(
          !weather.loading &&
              weather.failure == WeatherFailure.unavailable &&
              !weather.hasWeather,
          'Empty weather state incorrect',
        );
      },
    );
    await check('expired weather cache is not presented as current', () async {
      final expired = jsonDecode(cachedWeather) as Map<String, dynamic>;
      expired['fetchedAt'] = DateTime.now()
          .subtract(const Duration(hours: 25))
          .toIso8601String();
      await preferences.setString('weather_cache', jsonEncode(expired));
      await weather.configure(config);
      require(
        !weather.hasWeather &&
            !weather.loading &&
            weather.failure == WeatherFailure.unavailable,
        'Expired weather retained',
      );
    });
    for (final source in [
      WeatherSource.metNorway,
      WeatherSource.yandex,
      WeatherSource.openWeather,
    ]) {
      await check('${source.name} real transport reports offline', () async {
        var unavailable = false;
        try {
          await DirectWeatherProvider(HttpWeatherTransport()).fetch(
            config.copyWith(source: source),
            key: 'offline-test-placeholder',
          );
        } on WeatherException catch (error) {
          unavailable = error.failure == WeatherFailure.unavailable;
        }
        require(unavailable, 'Expected transport unavailability');
      });
    }
    await check('Bing cached wallpaper survives offline refresh', () async {
      await wallpaper.refresh(force: true);
      require(
        wallpaper.failed && !wallpaper.loading && wallpaper.wallpaper != null,
        'Cached wallpaper lost',
      );
      require(
        preferences.getString(onlineWallpaperCacheKey) == cachedWallpaper,
        'Wallpaper history overwritten',
      );
      require(
        base64Encode(await wallpaperFile.readAsBytes()) == base64Encode(image),
        'Cached file changed',
      );
    });
    await check(
      'direct HTTPS wallpaper failure preserves last image',
      () async {
        await wallpaper.configure(
          const OnlineWallpaperConfiguration(
            enabled: true,
            url: 'https://www.bing.com/offline-test.png',
          ),
        );
        require(
          wallpaper.failed && !wallpaper.loading && wallpaper.wallpaper != null,
          'HTTPS failure lost existing wallpaper',
        );
      },
    );
    await check('online wallpaper without cache finishes safely', () async {
      await preferences.remove(onlineWallpaperCacheKey);
      await wallpaperFile.delete();
      final empty = OnlineWallpaperService(preferences);
      try {
        await waitFor(() => empty.initialized);
        require(
          empty.failed && !empty.loading && empty.wallpaper == null,
          'Empty wallpaper failure state incorrect',
        );
      } finally {
        empty.dispose();
      }
    });
    await check(
      'GitHub update check finishes and releases busy state',
      () async {
        final updates = context!.read<UpdateService>();
        await waitFor(() => updates.initialized);
        await updates.check(force: true, notify: false);
        require(
          updates.failed && !updates.busy,
          'Update failure left spinner or reported success',
        );
      },
    );
    await check(
      'bundled city search returns coordinates offline',
      () async {
        final cities = await night.searchCities('Москва', 'ru');
        require(cities.isNotEmpty && (cities.first['latitude'] as num) > 55,
          'Bundled city search did not return Moscow');
      },
    );
    await check('solar refresh retains working schedule offline', () async {
      await night.refreshSolar();
      await waitFor(() => !night.solarLoading);
      require(
        night.nextStart != null && night.nextEnd != null,
        'Solar fallback boundaries lost',
      );
    });
    await check('WebDAV connection fails without saving an account', () async {
      final cloud = context!.read<CloudBackupService>();
      await cloud.refreshAccount();
      final original = cloud.account;
      var failed = false;
      try {
        await cloud.signIn(
          'https://example.com/offline/',
          'offline-test',
          'offline-test',
        );
      } catch (_) {
        failed = true;
      }
      require(
        failed && !cloud.busy && cloud.account == original,
        'WebDAV failure changed account or left busy',
      );
    });
    await check(
      'Google Drive connection fails and releases busy state',
      () async {
        final drive = context!.read<DriveBackupService>();
        var failed = false;
        try {
          await drive.connect('offline-test', 'offline-test');
        } catch (_) {
          failed = true;
        }
        require(
          failed && drive.failed && !drive.busy,
          'Drive failure left busy or reported success',
        );
      },
    );
    await check('Home keeps rendering after online failures', () async {
      final previous = frames;
      await Future<void>.delayed(const Duration(seconds: 1));
      require(frames > previous, 'Home stopped producing frames');
      await preferences.setString('weather_cache', cachedWeather);
      await weather.configure(config);
    });
  } catch (error) {
    checks.add({
      'name': 'probe setup',
      'result': 'FAIL',
      'error': error.toString(),
    });
  } finally {
    heartbeat.cancel();
    if (originalImage != null) {
      await wallpaperFile.writeAsBytes(originalImage, flush: true);
    } else if (await wallpaperFile.exists()) {
      await wallpaperFile.delete();
    }
    await reportFile.writeAsString(
      jsonEncode({
        'status':
            checks.isNotEmpty &&
                checks.every((item) => item['result'] == 'PASS')
            ? 'PASS'
            : 'FAIL',
        'realLauncher': true,
        'mockTransports': false,
        'frames': frames,
        'checks': checks,
      }),
      flush: true,
    );
  }
}
