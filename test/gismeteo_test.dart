import 'dart:async';
import 'dart:convert';

import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mocks.mocks.dart';

const _cityXml = '<document><item id="4368"/><item id="13068"/></document>';
const _config = WeatherConfiguration(
  source: WeatherSource.gismeteo,
  locationMode: WeatherLocationMode.manual,
  location: 'Москва',
  cityLatitude: 55.7558,
  cityLongitude: 37.6173,
);

final _forecastXml =
    '''
<weather>
  <location id="4368" name="Moscow" tzone="180">
    <fact valid="2026-11-06T01:00:00" sunrise="1793951152" sunset="1793983179">
      <values t="2" cl="2" pt="3" pr="1" ts="0" hum="70" ws="2"/>
    </fact>
    <day date="2026-11-06" tmin="1" tmax="4" cl="3" pt="3" pr="1">
      <forecast valid="2026-11-06T01:00:00"/>
    </day>
    <day date="2026-11-07" tmin="-2" tmax="3" ts="1" pr="3"/>
    ${[for (var day = 8; day <= 12; day++) '<day date="2026-11-${day.toString().padLeft(2, '0')}" tmin="0" tmax="2" cl="0"/>'].join()}
  </location>
</weather>
''';

class _Transport implements WeatherTransport {
  final requests = <Uri>[];
  String city = _cityXml;
  FutureOr<String> Function() forecast = () => _forecastXml;

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
    return decode!(uri.path.endsWith('/cities/') ? city : await forecast());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'gets the selected city and seven dated XML forecast days without a key',
    () async {
      final transport = _Transport();
      final result = await DirectWeatherProvider(transport).fetch(_config);
      expect(transport.requests, [
        Uri.parse(
          'https://services.gismeteo.ru/inform-service/inf_chrome/cities/'
          '?lat=55.7558&lng=37.6173&count=1&lang=en',
        ),
        Uri.parse(
          'https://services.gismeteo.ru/inform-service/inf_chrome/forecast/'
          '?city=4368&lang=en',
        ),
      ]);
      final weather = WeatherData.fromJson(result);
      final observation = DateTime.utc(2026, 11, 5, 22);
      expect(weather.timestamp, observation.millisecondsSinceEpoch ~/ 1000);
      expect(weather.utcOffsetSeconds, 10800);
      expect(weather.location, 'Москва');
      expect(weather.currentTemp, 2);
      expect(weather.currentConditionCode, 611);
      expect(weather.currentHumidity, 70);
      expect(weather.windSpeed, 2);
      expect(weather.isDay, isFalse);
      expect(weather.todayMinTemp, 1);
      expect(weather.todayMaxTemp, 4);
      final days = weather.forecastDays(observation, 7);
      expect(days.map((day) => day.date), [
        for (var day = 6; day <= 12; day++) DateTime(2026, 11, day),
      ]);
      expect(days[1].minTemp, -2);
      expect(days[1].conditionCode, 211);
      expect(days.every((day) => day.precipProbability == null), isTrue);
    },
  );

  test(
    'skips unavailable forecast dates and rejects the wrong location and DTDs',
    () async {
      final transport = _Transport();
      final provider = DirectWeatherProvider(transport);
      transport.forecast = () =>
          _forecastXml.replaceFirst('2026-11-07', '2026-11-31');
      final result = await provider.fetch(_config);
      expect(WeatherData.fromJson(result).forecasts, hasLength(6));

      transport.forecast = () =>
          _forecastXml.replaceFirst('id="4368"', 'id="2391"');
      await expectLater(provider.fetch(_config), throwsFormatException);
      transport.forecast = () => '<!DOCTYPE weather>$_forecastXml';
      await expectLater(provider.fetch(_config), throwsFormatException);

      transport.city = '<document/>';
      transport.requests.clear();
      await expectLater(
        provider.fetch(_config),
        throwsA(
          isA<WeatherException>().having(
            (error) => error.failure,
            'failure',
            WeatherFailure.cityNotFound,
          ),
        ),
      );
      expect(transport.requests, hasLength(1));
    },
  );

  test(
    'restores the selected city and retains the observation when offline',
    () async {
      final saved = jsonEncode(_config.toJson());
      expect(
        compatibleSettings({
          weatherConfigurationKey: saved,
        }, {})[weatherConfigurationKey],
        saved,
      );
      SharedPreferences.setMockInitialValues({weatherConfigurationKey: saved});
      final prefs = await SharedPreferences.getInstance();
      final channel = MockFLauncherChannel();
      when(channel.addWeatherChangedListener(any))
          .thenAnswer((_) => const Stream<dynamic>.empty().listen((_) {}));
      final transport = _Transport();
      final service = WeatherService(
        channel,
        preferences: prefs,
        transport: transport,
      );
      addTearDown(service.dispose);
      while (!service.initialized) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(service.weatherData?.currentTemp, 2);
      expect(service.updatedAt, DateTime.utc(2026, 11, 5, 22));

      transport.forecast = () =>
          throw const WeatherException(WeatherFailure.unavailable);
      await service.refresh();
      expect(service.failure, WeatherFailure.unavailable);
      expect(service.weatherData?.forecasts, hasLength(7));
      expect(service.updatedAt, DateTime.utc(2026, 11, 5, 22));
      expect(service.stale, isTrue);
    },
  );

  test('discards an in-flight XML forecast when the launcher goes to the background', () async {
    SharedPreferences.setMockInitialValues({
      weatherConfigurationKey: jsonEncode(_config.toJson()),
    });
    final prefs = await SharedPreferences.getInstance();
    final channel = MockFLauncherChannel();
    when(channel.addWeatherChangedListener(any))
        .thenAnswer((_) => const Stream<dynamic>.empty().listen((_) {}));
    final started = Completer<void>();
    final response = Completer<String>();
    final transport = _Transport()
      ..forecast = () {
        started.complete();
        return response.future;
      };
    final service = WeatherService(
      channel,
      preferences: prefs,
      transport: transport,
    );
    addTearDown(service.dispose);
    await started.future;
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    response.complete(_forecastXml);
    while (!service.initialized) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(service.weatherData, isNull);
    expect(prefs.getString('weather_cache'), isNull);
    await service.refresh();
    expect(transport.requests, hasLength(2));
  });
}
