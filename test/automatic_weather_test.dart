import 'dart:async';
import 'dart:convert';

import 'package:flauncher/launcher_defaults.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.mocks.dart';

const _city = WeatherConfiguration(
  source: WeatherSource.auto,
  locationMode: WeatherLocationMode.manual,
  location: 'Москва',
  cityLatitude: 55.75,
  cityLongitude: 37.62,
);

const _oldDefault = WeatherConfiguration(
  source: WeatherSource.openMeteo,
  locationMode: WeatherLocationMode.manual,
);

class _Transport implements WeatherTransport {
  final requests = <Uri>[];
  final errors = <String>{};
  bool emptyOpenMeteo = false;
  Completer<void>? pendingMet;

  @override
  Future<Map<String, dynamic>> request(
    Uri uri, {
    String? key,
    bool customServer = false,
    String? bearerToken,
    WeatherResponseDecoder? decode,
  }) async {
    expect(key, isNull);
    expect(bearerToken, isNull);
    expect(customServer, isFalse);
    requests.add(uri);
    if (uri.host == 'api.met.no') await pendingMet?.future;
    if (errors.contains(uri.host)) {
      throw const WeatherException(WeatherFailure.unavailable);
    }

    final now = DateTime.now().toUtc();
    final date = now.toIso8601String().substring(0, 10);
    switch (uri.host) {
      case 'api.met.no':
        return {
          'properties': {
            'timeseries': [
              {
                'time': now.toIso8601String(),
                'data': {
                  'instant': {
                    'details': {'air_temperature': 8.2},
                  },
                },
              },
            ],
          },
        };
      case 'api.open-meteo.com':
        return {
          'current': {
            'temperature_2m': 6.1,
            'time': now.millisecondsSinceEpoch ~/ 1000,
          },
          if (!emptyOpenMeteo)
            'daily': {
              'weather_code': [3],
              'temperature_2m_min': [3],
              'temperature_2m_max': [8],
            },
        };
      case 'services.gismeteo.ru':
        if (uri.path.endsWith('/cities/')) {
          return decode!('<document><item id="4368"/></document>');
        }
        expect(uri.queryParameters['city'], '4368');
        return decode!('''
<weather><location id="4368" name="Moscow" tzone="0">
  <fact valid="${now.toIso8601String()}"><values t="4"/></fact>
  <day date="$date" tmin="3" tmax="6"/>
</location></weather>''');
      default:
        fail('Unexpected weather host: ${uri.host}');
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the default replaces only the implicit or exact old default', () {
    final seeded =
        LauncherDefaults.preferences[weatherConfigurationKey] as String;
    expect(WeatherConfiguration.load(seeded).source, WeatherSource.auto);
    expect(WeatherConfiguration.load(null).source, WeatherSource.auto);
    final old = jsonEncode(_oldDefault.toJson());
    expect(WeatherConfiguration.load(old).source, WeatherSource.auto);
    for (final settings in [
      _oldDefault.copyWith(sourceSelected: true),
      _oldDefault.copyWith(
        location: 'Москва',
        cityLatitude: 55.75,
        cityLongitude: 37.62,
      ),
      _oldDefault.copyWith(intervalMinutes: 120),
      for (final source in WeatherSource.values.where(
        (s) => s != WeatherSource.openMeteo,
      ))
        _oldDefault.copyWith(source: source),
    ]) {
      final encoded = jsonEncode(settings.toJson());
      expect(WeatherConfiguration.load(encoded).toJson(), settings.toJson());
    }
  });

  test('backup keeps Auto, including the saved city and partial settings', () {
    for (final config in [_city, WeatherConfiguration.defaults]) {
      final encoded = jsonEncode(config.toJson());
      expect(compatibleSettings({weatherConfigurationKey: encoded}, {}), {
        weatherConfigurationKey: encoded,
      });
    }
  });

  test('Auto stops at the first valid MET forecast', () async {
    final transport = _Transport();
    final data = await DirectWeatherProvider(transport).fetch(_city);
    final weather = WeatherData.fromJson(data);
    expect(weatherDataSource(_city.source, weather), WeatherSource.metNorway);
    expect(weather.location, 'Москва');
    expect(transport.requests.map((uri) => uri.host), ['api.met.no']);
  });

  test('Auto uses Open-Meteo only after MET fails', () async {
    final transport = _Transport()..errors.add('api.met.no');
    final data = await DirectWeatherProvider(transport).fetch(_city);
    expect(data['source'], 'openMeteo');
    expect(transport.requests.map((uri) => uri.host), [
      'api.met.no',
      'api.open-meteo.com',
    ]);
  });

  test('Auto falls back to Gismeteo if Open-Meteo lacks a forecast', () async {
    final transport = _Transport()
      ..errors.add('api.met.no')
      ..emptyOpenMeteo = true;
    final data = await DirectWeatherProvider(transport).fetch(_city);
    expect(data['source'], 'gismeteo');
    expect(data['currentTemp'], 4);
    expect(transport.requests.map((uri) => uri.path), [
      '/weatherapi/locationforecast/2.0/compact',
      '/v1/forecast',
      '/inform-service/inf_chrome/cities/',
      '/inform-service/inf_chrome/forecast/',
    ]);
  });

  late MockFLauncherChannel channel;
  late StreamController<dynamic> events;
  setUp(() {
    channel = MockFLauncherChannel();
    events = StreamController<dynamic>.broadcast();
    when(
      channel.addWeatherChangedListener(any),
    ).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
  });
  tearDown(() => events.close());

  Future<WeatherService> start(
    SharedPreferences prefs,
    _Transport transport,
  ) async {
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

  test('manual Open-Meteo stays selected after restart, even before choosing a city', () async {
    SharedPreferences.setMockInitialValues({
      weatherConfigurationKey: jsonEncode(_oldDefault.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final transport = _Transport();
    final first = await start(prefs, transport);
    expect(first.configuration.source, WeatherSource.auto);
    await first.selectSource(WeatherSource.openMeteo);
    first.dispose();

    final restored = await start(prefs, transport);
    addTearDown(restored.dispose);
    expect(restored.configuration.source, WeatherSource.openMeteo);
    expect(restored.configuration.sourceSelected, isTrue);
    expect(transport.requests, isEmpty);
    transport.errors.add('api.open-meteo.com');
    await restored.configure(
      _city.copyWith(source: WeatherSource.openMeteo, sourceSelected: true),
    );
    expect(restored.failure, WeatherFailure.unavailable);
    expect(transport.requests.map((uri) => uri.host), ['api.open-meteo.com']);
  });

  test(
    'Auto preserves cached data and its provider when all sources fail',
    () async {
      SharedPreferences.setMockInitialValues({
        weatherConfigurationKey: jsonEncode(_city.toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      final transport = _Transport();
      final first = await start(prefs, transport);
      expect(first.weatherData?.source, 'metNorway');
      first.dispose();

      transport.errors.addAll([
        'api.met.no',
        'api.open-meteo.com',
        'services.gismeteo.ru',
      ]);
      final restored = await start(prefs, transport);
      addTearDown(restored.dispose);
      await restored.refresh();
      expect(restored.configuration.source, WeatherSource.auto);
      expect(restored.weatherData?.source, 'metNorway');
      expect(restored.weatherData?.currentTemp, 8);
      expect(restored.failure, WeatherFailure.unavailable);
      expect(restored.stale, isTrue);
    },
  );

  test(
    'Auto does not start another provider after leaving the foreground',
    () async {
      SharedPreferences.setMockInitialValues({});
      final transport = _Transport()
        ..errors.add('api.met.no')
        ..pendingMet = Completer<void>();
      final prefs = await SharedPreferences.getInstance();
      final service = await start(prefs, transport);
      addTearDown(service.dispose);
      expect(transport.requests, isEmpty);

      final configuring = service.configure(_city);
      while (transport.requests.isEmpty) {
        await Future<void>.delayed(Duration.zero);
      }
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      transport.pendingMet!.complete();
      await configuring;
      expect(transport.requests.map((uri) => uri.host), ['api.met.no']);
      expect(service.weatherData, isNull);
      expect(service.failure, isNull);
    },
  );
}
