import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.mocks.dart';

const response = <String, dynamic>{
  'latitude': 50.0,
  'longitude': 30.0,
  'timezone': 'Europe/Kyiv',
  'utc_offset_seconds': 7200,
  'source': 'Тестовый сервер',
  'updated_at': '2026-11-05T10:00:00+02:00',
  'ignored': {'nested': 'ignored'},
  'current': {
    'time': '2026-11-05T01:00',
    'temperature_2m': 4.2,
    'apparent_temperature': null,
    'weather_code': 61,
    'is_day': null,
    'wind_speed_10m': 3.2,
  },
  'daily': {
    'time': ['2026-11-05', '2026-11-06'],
    'temperature_2m_max': [6.0, 5.1],
    'temperature_2m_min': [null, 0.0],
    'weather_code': [61, null],
    'precipitation_probability_max': [null, null],
  },
};

class _Transport implements WeatherTransport {
  final requests = <(Uri, String?)>[];
  FutureOr<Map<String, dynamic>> Function() reply = () => response;

  @override
  Future<Map<String, dynamic>> request(
    Uri uri, {
    String? key,
    bool customServer = false,
    String? bearerToken,
    WeatherResponseDecoder? decode,
  }) async {
    requests.add((uri, bearerToken));
    return reply();
  }
}

class _RealHttp extends HttpOverrides {
  final bool trustFixture;
  _RealHttp({this.trustFixture = false});

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      super.createHttpClient(
        trustFixture
            ? (SecurityContext(withTrustedRoots: false)..setTrustedCertificates(
                'test/fixtures/cloud/test_certificate.txt',
              ))
            : context,
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final base = parseWeatherServer('https://weather.example.test/home%2Ftv/')!;
  final config = WeatherConfiguration(
    source: WeatherSource.customOpenMeteo,
    latitude: 50,
    longitude: 30,
    server: base,
  );

  test(
    'validates HTTPS base addresses and preserves the encoded path prefix',
    () async {
      for (final invalid in [
        'http://weather.example.test',
        'https:///home',
        '//weather.example.test',
        'https://user:password@weather.example.test',
        'https://@weather.example.test',
        'https://weather.example.test/home?',
        'https://weather.example.test/home#',
        'https://weather.example.test/v1/forecast/',
      ]) {
        expect(parseWeatherServer(invalid), isNull, reason: invalid);
      }
      final transport = _Transport();
      final provider = DirectWeatherProvider(transport);
      final normalized = await provider.fetch(
        config,
        bearerToken: 'fixture-token',
        forecastDays: 7,
      );
      expect(normalized['updatedAt'], '2026-11-05T08:00:00.000Z');
      final data = WeatherData.fromJson(normalized);
      final (uri, token) = transport.requests.single;
      expect(
        uri.toString(),
        startsWith('https://weather.example.test/home%2Ftv/v1/forecast?'),
      );
      expect(uri.queryParameters, {
        'timezone': 'auto',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'ms',
        'timeformat': 'iso8601',
        'forecast_days': '7',
        'current': 'temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m',
        'daily': 'temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max',
      });
      expect(token, 'fixture-token');
      expect(data.latitude, 50);
      expect(data.longitude, 30);
      expect(data.timezone, 'Europe/Kyiv');
      expect(data.source, 'Тестовый сервер');
      expect(data.currentTemp, 4);
      expect(data.windSpeed, 3.2);
      expect(data.feelsLikeTemp, isNull);
      expect(data.isDay, isNull);
      expect(
        data.timestamp,
        DateTime.utc(2026, 11, 4, 23).millisecondsSinceEpoch ~/ 1000,
      );
      final days = data.forecastDays(DateTime.utc(2026, 11, 5, 22, 30), 7);
      expect(days.single.date, DateTime(2026, 11, 6));
      expect(days.single.minTemp, 0);
      expect(days.single.conditionCode, isNull);
      expect(data.forecasts, hasLength(2));
      expect(data.forecasts.first.minTemp, isNull);
      expect(
        data.forecasts.every((day) => day.precipProbability == null),
        isTrue,
      );
    },
  );

  test('server determines location regardless of stored client coordinates or city', () async {
    for (final selected in [
      WeatherConfiguration(source: WeatherSource.customOpenMeteo, server: base),
      config.copyWith(locationMode: WeatherLocationMode.manual, location: 'Ignored city', cityLatitude: -33, cityLongitude: 151),
    ]) {
      final transport = _Transport();
      final result = WeatherData.fromJson(await DirectWeatherProvider(transport).fetch(selected, forecastDays: 3));
      final query = transport.requests.single.$1.queryParameters;
      expect(query.containsKey('latitude'), isFalse);
      expect(query.containsKey('longitude'), isFalse);
      expect(query['forecast_days'], '3');
      expect(result.latitude, 50);
      expect(result.longitude, 30);
      expect(result.location, isNull);
    }
  });

  test('accepts current-only, empty daily and daily-only responses', () async {
    final transport = _Transport();
    final provider = DirectWeatherProvider(transport);
    for (final reply in [
      {'current': response['current']},
      {
        'current': response['current'],
        'daily': {'time': []},
      },
      {
        'daily': {'time': []},
      },
    ]) {
      transport.reply = () => reply;
      expect(
        WeatherData.fromJson(await provider.fetch(config)).forecasts,
        isEmpty,
      );
    }
    transport.reply = () => {
      'daily': {
        'time': ['2026-11-05'],
        'temperature_2m_min': [0],
      },
    };
    final weather = WeatherData.fromJson(await provider.fetch(config));
    expect(weather.currentTemp, isNull);
    expect(weather.forecasts.single.minTemp, 0);
  });

  test(
    'HTTPS transport validates certificates, sends Bearer, and never redirects',
    () async {
      final tls = SecurityContext()
        ..useCertificateChain('test/fixtures/cloud/test_certificate.txt')
        ..usePrivateKey('test/fixtures/cloud/test_key.txt');
      final server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        tls,
      );
      addTearDown(() => server.close(force: true));
      final requests = <(String, String, String?)>[];
      var status = 200;
      server.listen((request) async {
        requests.add((
          request.method,
          request.uri.path,
          request.headers.value(HttpHeaders.authorizationHeader),
        ));
        request.response.statusCode = status;
        if (status == 302) {
          request.response.headers.set(
            HttpHeaders.locationHeader,
            '/redirect-target',
          );
        }
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(
            status == 200 ? response : {'error': true, 'reason': 'fixture'},
          ),
        );
        await request.response.close();
      });
      final provider = DirectWeatherProvider(HttpWeatherTransport());
      final local = config.copyWith(
        server: parseWeatherServer('https://127.0.0.1:${server.port}/home'),
      );
      Future<Map<String, dynamic>> fetch() =>
          provider.fetch(local, bearerToken: 'fixture-token');
      Matcher fails(WeatherFailure failure) => throwsA(
        isA<WeatherException>().having((e) => e.failure, 'failure', failure),
      );
      await HttpOverrides.runWithHttpOverrides(() async {
        await expectLater(fetch(), fails(WeatherFailure.unavailable));
        expect(requests, isEmpty);
      }, _RealHttp());
      await HttpOverrides.runWithHttpOverrides(() async {
        await fetch();
        await provider.fetch(local);
        for (final (code, failure) in [
          (302, WeatherFailure.unavailable),
          (400, WeatherFailure.parameters),
          (401, WeatherFailure.authorization),
          (403, WeatherFailure.authorization),
          (503, WeatherFailure.unavailable),
        ]) {
          status = code;
          await expectLater(fetch(), fails(failure));
        }
        expect(
          requests,
          [
            ('GET', '/home/v1/forecast', 'Bearer fixture-token'),
            ('GET', '/home/v1/forecast', null),
            ...List.filled(5, ('GET', '/home/v1/forecast', 'Bearer fixture-token')),
          ],
        );
      }, _RealHttp(trustFixture: true));
    },
  );

  test('cache uses source freshness, survives outages, and isolates server and provider', () async {
    final old = DateTime.now().toUtc().subtract(const Duration(hours: 3));
    final transport = _Transport()
      ..reply = () => {...response, 'updated_at': old.toIso8601String()};
    SharedPreferences.setMockInitialValues({
      weatherConfigurationKey: jsonEncode(WeatherConfiguration(source: WeatherSource.customOpenMeteo, server: base).toJson()),
      tileAppearanceKey: jsonEncode({'panelForecastDays': 7}),
    });
    final prefs = await SharedPreferences.getInstance();
    final events = StreamController<dynamic>.broadcast();
    addTearDown(events.close);
    final channel = MockFLauncherChannel();
    when(channel.addWeatherChangedListener(any)).thenAnswer(
      (call) => events.stream.listen(call.positionalArguments.first),
    );
    const secrets = MethodChannel('cutelauncher/weather_token');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(secrets, (call) async {
      expect(call.method, 'read');
      return call.arguments['server'] == base.toString()
          ? 'fixture-token'
          : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(secrets, null));
    Future<WeatherService> start() async {
      final service = WeatherService(
        channel,
        preferences: prefs,
        transport: transport,
      );
      while (!service.initialized) {
        await Future<void>.delayed(Duration.zero);
      }
      return service;
    }

    final initial = await start();
    expect(initial.canRefresh, isTrue);
    expect(initial.configuration.hasLocation, isFalse);
    expect(initial.updatedAt, old);
    expect(initial.stale, isTrue);
    expect(transport.requests.single.$1.queryParameters['forecast_days'], '7');
    expect(transport.requests.single.$2, 'fixture-token');
    expect(prefs.getString('weather_cache'), isNot(contains('fixture-token')));
    expect(
      prefs.getString(weatherConfigurationKey),
      isNot(contains('fixture-token')),
    );
    initial.dispose();
    transport.reply = () =>
        throw const WeatherException(WeatherFailure.unavailable);
    final restored = await start();
    addTearDown(restored.dispose);
    expect(transport.requests, hasLength(1)); // Cached download is recent.
    await restored.refresh();
    expect(restored.failure, WeatherFailure.unavailable);
    expect(restored.weatherData?.currentTemp, 4);
    expect(restored.updatedAt, old);
    expect(restored.stale, isTrue);

    final pending = Completer<Map<String, dynamic>>();
    transport.reply = () => pending.future;
    final refreshing = restored.refresh();
    await pumpEventQueue();
    expect(transport.requests.last.$1.queryParameters['forecast_days'], '7');
    await prefs.setString(tileAppearanceKey, jsonEncode({'panelForecastDays': 3}));
    await restored.refreshForecastDays();
    transport.reply = () => {...response}..remove('updated_at');
    pending.complete({'current': {'temperature_2m': 99}});
    await refreshing;
    expect(transport.requests.last.$1.queryParameters['forecast_days'], '3');
    expect(restored.weatherData?.currentTemp, 4);
    expect(restored.updatedAt, DateTime.utc(2026, 11, 4, 23));

    for (final error in [TimeoutException('fixture'), const SocketException('fixture')]) {
      transport.reply = () => throw error;
      await restored.refresh();
      expect(restored.failure, WeatherFailure.unavailable);
      expect(restored.weatherData?.currentTemp, 4);
    }
    await restored.configure(
      config.copyWith(
        server: parseWeatherServer('https://weather.example.test/other'),
      ),
    );
    expect(transport.requests.last.$2, isNull);
    expect(restored.weatherData, isNull);
    await restored.configure(config.copyWith(source: WeatherSource.openMeteo));
    expect(transport.requests.last.$1.host, 'api.open-meteo.com');
    expect(transport.requests.last.$2, isNull);
    expect(restored.weatherData, isNull);
  });

  test('changing a token preserves cached freshness and ignores an old pending response', () async {
    SharedPreferences.setMockInitialValues({
      weatherConfigurationKey: jsonEncode(WeatherConfiguration(
        source: WeatherSource.customOpenMeteo, server: base,
      ).toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final channel = MockFLauncherChannel();
    final events = StreamController<dynamic>.broadcast();
    addTearDown(events.close);
    when(channel.addWeatherChangedListener(any)).thenAnswer(
      (call) => events.stream.listen(call.positionalArguments.first),
    );
    const secrets = MethodChannel('cutelauncher/weather_token');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    var token = 'fixture-old-token';
    messenger.setMockMethodCallHandler(secrets, (call) async {
      if (call.method == 'save') token = call.arguments['token'] as String;
      return call.method == 'read' ? token : null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(secrets, null));
    final transport = _Transport();
    final service = WeatherService(channel, preferences: prefs, transport: transport);
    addTearDown(service.dispose);
    while (!service.initialized) { await pumpEventQueue(); }
    final updated = service.updatedAt;
    expect(transport.requests, hasLength(1));
    final pending = Completer<Map<String, dynamic>>();
    transport.reply = () => pending.future;
    final oldRequest = service.refresh();
    await pumpEventQueue();
    expect(transport.requests, hasLength(2));
    await service.setServerToken(base, 'fixture-new-token');
    expect(service.weatherData?.currentTemp, 4);
    expect(service.updatedAt, updated);
    pending.complete({'current': {'temperature_2m': 99}});
    await oldRequest;
    expect(service.weatherData?.currentTemp, 4);
    expect(service.updatedAt, updated);
    await service.refreshForecastDays();
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();
    expect(transport.requests, hasLength(2));
    transport.reply = () => response;
    await service.refresh();
    expect(transport.requests, hasLength(3));
    expect(transport.requests.last.$2, 'fixture-new-token');
  });

  test(
    'backup import preserves the configuration but strips an injected token',
    () {
      final imported = compatibleSettings({
        weatherConfigurationKey: jsonEncode({
          ...config.toJson(),
          'token': 'fixture-token',
        }),
      }, {});
      final encoded = imported[weatherConfigurationKey] as String;
      expect(WeatherConfiguration.decode(encoded).server, base);
      expect(encoded, isNot(contains('fixture-token')));
    },
  );
}
