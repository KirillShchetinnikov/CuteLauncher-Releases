import 'dart:async';
import 'dart:convert';
import 'package:flauncher/city_search.dart';
import 'package:flauncher/location_coordinates.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/settings_import.dart';
import 'mocks.mocks.dart';

class FakeTransport implements WeatherTransport {
  int calls = 0;
  Uri? uri;
  String? key;
  Future<Map<String, dynamic>> Function() response;
  FakeTransport(this.response);
  @override
  Future<Map<String, dynamic>> request(Uri value, {String? key, bool customServer = false, String? bearerToken, WeatherResponseDecoder? decode}) {
    calls++; uri = value; this.key = key; return response();
  }
}
Map<String, dynamic> payload() => {
  'current': {'time': 1780000000, 'temperature_2m': -3.5, 'apparent_temperature': -8.6, 'relative_humidity_2m': 80.0, 'weather_code': 71, 'wind_speed_10m': 4.5},
  'daily': {'weather_code': [71, 95], 'temperature_2m_min': [-5, -2], 'temperature_2m_max': [0, 4], 'precipitation_probability_max': [80.0, 90.0]}
};
const config = WeatherConfiguration(source: WeatherSource.openMeteo, latitude: 55.75, longitude: 37.62, location: 'Москва');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all supported Open-Meteo fields are requested and parsed regardless of display', () async {
    final response = payload();
    (response['current'] as Map)['is_day'] = 0;
    (response['daily'] as Map)['relative_humidity_2m_mean'] = [61, 70];
    final transport = FakeTransport(() async => response);
    final data = WeatherData.fromJson(await DirectWeatherProvider(transport).fetch(config));
    expect(transport.uri!.queryParameters['current']!.split(','), containsAll([
      'temperature_2m', 'apparent_temperature', 'relative_humidity_2m', 'weather_code', 'is_day', 'wind_speed_10m',
    ]));
    expect(transport.uri!.queryParameters['daily'], contains('relative_humidity_2m_mean'));
    expect(data.isDay, isFalse); expect(data.forecasts.first.humidity, 61);
    expect(data.todayMinTemp, -5); expect(data.todayMaxTemp, 0);
  });
  test('selected city coordinates survive backup and avoid ambiguous geocoding', () async {
    const city = WeatherConfiguration(source: WeatherSource.openMeteo,
      locationMode: WeatherLocationMode.manual, location: 'Moscow, Idaho, United States',
      latitude: 55.75583, longitude: 37.61778,
      cityLatitude: 46.73239, cityLongitude: -117.00017);
    final encoded = jsonEncode(city.toJson());
    expect(validWeatherConfiguration(encoded), isTrue);
    final restored = WeatherConfiguration.decode(encoded);
    expect(restored.toJson(), city.toJson());
    expect(restored.copyWith(locationMode: WeatherLocationMode.automatic).latitude, 55.75583);
    expect(restored.copyWith(locationMode: WeatherLocationMode.automatic).cityLatitude, 46.73239);
    final transport = FakeTransport(() async => payload());
    await DirectWeatherProvider(transport).fetch(restored);
    expect(transport.calls, 1);
    expect(transport.uri!.host, 'api.open-meteo.com');
    expect(transport.uri!.queryParameters['latitude'], '46.73239');
    expect(transport.uri!.queryParameters['longitude'], '-117.00017');
    expect(validWeatherConfiguration(jsonEncode({...city.toJson(), 'cityLatitude': 91})), isFalse);
    expect(validWeatherConfiguration(jsonEncode({...city.toJson(), 'cityLongitude': null})), isFalse);
  });
  test('manual coordinates work without a city and survive backup separately', () async {
    const coordinates = WeatherConfiguration(
      source: WeatherSource.openMeteo,
      locationMode: WeatherLocationMode.manual,
      manualLocationInput: ManualLocationInput.coordinates,
      manualCoordinates: (latitude: -33.8, longitude: 151.2),
    );
    final encoded = jsonEncode(coordinates.toJson());
    expect(validWeatherConfiguration(encoded), isTrue);
    expect(compatibleSettings({weatherConfigurationKey: encoded}, {})[weatherConfigurationKey], encoded);
    final saved = WeatherConfiguration.decode(encoded).copyWith(
      location: 'Москва', cityLatitude: 55.75, cityLongitude: 37.62,
      latitude: 48, longitude: 2,
    );
    final transport = FakeTransport(() async => payload());
    final data = await DirectWeatherProvider(transport).fetch(saved);
    expect(transport.calls, 1);
    expect(transport.uri!.queryParameters['latitude'], '-33.8');
    expect(transport.uri!.queryParameters['longitude'], '151.2');
    expect(data['location'], isEmpty);
    expect(saved.copyWith(manualLocationInput: ManualLocationInput.city).selectedCoordinates,
      (latitude: 55.75, longitude: 37.62));
    expect(saved.copyWith(locationMode: WeatherLocationMode.automatic).selectedCoordinates,
      (latitude: 48.0, longitude: 2.0));
    expect(validWeatherConfiguration(jsonEncode({
      ...coordinates.toJson(),
      'manualCoordinates': {'latitude': 91, 'longitude': 0},
    })), isFalse);
  });
  test('manual city resolves coordinates before requesting weather and sends no key to geocoding', () async {
    final requests = <Uri>[];
    final transport = FakeTransport(() async =>
        {'fact': {'temp': 7, 'condition': 'clear'}, 'forecasts': []});
    final search = CitySearch(
      loadCatalog: () async => '',
      request: (uri) async {
        expect(transport.calls, 0);
        requests.add(uri);
        return {'geonames': [{'name': 'Moscow', 'lat': '55.75', 'lng': '37.62'}]};
      },
      username: 'test',
    );
    final data = await DirectWeatherProvider(transport, citySearch: search).fetch(const WeatherConfiguration(
      source: WeatherSource.yandex, locationMode: WeatherLocationMode.manual, location: 'Moscow'), key: 'test-key');
    expect(requests.single.queryParameters['name_equals'], 'Moscow');
    expect(requests.single.toString(), isNot(contains('test-key')));
    expect(transport.uri!.queryParameters['lat'], '55.75');
    expect(transport.key, 'test-key');
    expect(data['location'], 'Moscow');
  });
  test('unknown city reports cityNotFound and malformed coordinates report invalidResponse', () async {
    const city = WeatherConfiguration(source: WeatherSource.openMeteo,
      locationMode: WeatherLocationMode.manual, location: 'WrongCityDefinitely');
    for (final (response, failure) in <(Map<String, dynamic>, WeatherFailure)>[
      ({'geonames': []}, WeatherFailure.cityNotFound),
      ({}, WeatherFailure.invalidResponse),
      ({'geonames': [{'name': 'Bad', 'lat': 91, 'lng': 1}]}, WeatherFailure.invalidResponse),
      ({'geonames': [
        {'name': 'One', 'lat': 42, 'lng': 40},
        {'name': 'Two', 'lat': 53, 'lng': 50},
      ]}, WeatherFailure.cityNotFound),
    ]) {
      final transport = FakeTransport(() async => response);
      final search = CitySearch(loadCatalog: () async => '', request: (_) async => response, username: 'test');
      await expectLater(DirectWeatherProvider(transport, citySearch: search).fetch(city), throwsA(
        isA<WeatherException>().having((e) => e.failure, 'failure', failure)));
      expect(transport.calls, 0);
    }
  });
  test('partial weather configuration roundtrips through backup without enabling requests', () {
    for (final value in [const WeatherConfiguration(source: WeatherSource.openMeteo),
      const WeatherConfiguration(source: WeatherSource.openWeather, locationMode: WeatherLocationMode.manual),
      const WeatherConfiguration(source: WeatherSource.yandex, locationMode: WeatherLocationMode.manual, location: 'Moscow')]) {
      final encoded = jsonEncode(value.toJson());
      expect(validWeatherConfiguration(encoded), isTrue);
      expect(WeatherConfiguration.decode(encoded).toJson(), value.toJson());
    }
  });
  test('missing city or automatic coordinates skips initialization, refresh and resume requests', () async {
    for (final value in [const WeatherConfiguration(source: WeatherSource.openMeteo),
      const WeatherConfiguration(source: WeatherSource.openMeteo, locationMode: WeatherLocationMode.manual, location: ' ')]) {
      SharedPreferences.setMockInitialValues({weatherConfigurationKey: jsonEncode(value.toJson())});
      final channel = MockFLauncherChannel();
      final events = StreamController<dynamic>.broadcast();
      when(channel.addWeatherChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
      final transport = FakeTransport(() async => payload());
      final service = WeatherService(channel, preferences: await SharedPreferences.getInstance(), transport: transport);
      while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
      expect(service.canRefresh, isFalse);
      await service.refresh();
      await service.configure(value);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(transport.calls, 0); expect(service.loading, isFalse);
      service.dispose(); await events.close();
    }
  });
  test('Open-Meteo requests metric units and maps snow and storm to existing warnings', () async {
    final transport = FakeTransport(() async => payload());
    final data = WeatherData.fromJson(await DirectWeatherProvider(transport).fetch(config));
    expect(data.currentTemp, -4);
    expect(data.feelsLikeTemp, -9);
    expect(transport.calls, 1);
    expect(transport.uri!.queryParameters['current']!.split(','), contains('apparent_temperature'));
    expect(data.warningType, WeatherWarningType.snow);
    expect(data.forecasts[1].conditionCode, 211);
    expect(transport.uri!.queryParameters['wind_speed_unit'], 'ms');
    expect(transport.key, isNull);
  });
  test('Yandex uses its header only for Yandex and rejects missing key before network', () async {
    final transport = FakeTransport(() async => {'now': 1780000000, 'fact': {'temp': 7, 'feels_like': 0, 'condition': 'clear'}, 'forecasts': []});
    final provider = DirectWeatherProvider(transport);
    const yandex = WeatherConfiguration(source: WeatherSource.yandex, latitude: 0, longitude: 0);
    await expectLater(provider.fetch(yandex), throwsA(isA<WeatherException>().having((e) => e.failure, 'failure', WeatherFailure.keyRequired)));
    expect(transport.calls, 0);
    final data = await provider.fetch(yandex, key: 'test-key');
    expect(transport.key, 'test-key');
    expect(transport.uri!.host, 'api.weather.yandex.ru');
    expect(data['currentConditionCode'], 800);
    expect(WeatherData.fromJson(data).feelsLikeTemp, 0);
  });
  test('invalid coordinates and malformed payload fail without inventing weather', () async {
    final transport = FakeTransport(() async => {});
    final provider = DirectWeatherProvider(transport);
    await expectLater(provider.fetch(const WeatherConfiguration(source: WeatherSource.openMeteo, latitude: 91, longitude: 0)), throwsA(isA<WeatherException>()));
    expect(transport.calls, 0);
    await expectLater(provider.fetch(config), throwsA(isA<WeatherException>().having((e) => e.failure, 'failure', WeatherFailure.invalidResponse)));
  });
  test('import ignores invalid source, cache, and key, retaining valid configuration', () {
    expect(compatibleSettings({weatherConfigurationKey: '{"source":"unknown"}', 'weather_api_key': 'secret', 'weather_cache': '{}'}, {}), isEmpty);
    final serialized = jsonEncode(config.toJson());
    expect(compatibleSettings({weatherConfigurationKey: serialized}, {})[weatherConfigurationKey], serialized);
  });
  test('direct service survives offline restart and coalesces concurrent refreshes', () async {
    SharedPreferences.setMockInitialValues({weatherConfigurationKey: jsonEncode(config.toJson())});
    final prefs = await SharedPreferences.getInstance();
    final channel = MockFLauncherChannel();
    final events = StreamController<dynamic>.broadcast();
    when(channel.addWeatherChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    final pending = Completer<Map<String, dynamic>>();
    final transport = FakeTransport(() => pending.future);
    final service = WeatherService(channel, preferences: prefs, transport: transport);
    await Future<void>.delayed(Duration.zero);
    await Future.wait([service.refresh(), service.refresh()]);
    expect(transport.calls, 1);
    pending.complete(payload());
    while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
    expect(service.weatherData!.currentTemp, -4);
    expect(prefs.getString('weather_cache'), isNotNull);
    service.dispose();
    final cache = jsonDecode(prefs.getString('weather_cache')!) as Map;
    cache['fetchedAt'] = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
    await prefs.setString('weather_cache', jsonEncode(cache));
    final offline = WeatherService(channel, preferences: prefs, transport: FakeTransport(() async => throw const WeatherException(WeatherFailure.unavailable)));
    while (!offline.initialized) { await Future<void>.delayed(Duration.zero); }
    expect(offline.weatherData!.location, 'Москва');
    expect(offline.weatherData!.feelsLikeTemp, -9);
    expect(offline.failure, WeatherFailure.unavailable);
    expect(offline.stale, isTrue);
    offline.dispose();
    await events.close();
  });
  test('manual refresh bypasses fresh cache and failure backoff but automatic refresh does not', () async {
    final old = DateTime.now().subtract(const Duration(minutes: 10));
    SharedPreferences.setMockInitialValues({
      weatherConfigurationKey: jsonEncode(config.toJson()),
      'weather_cache': jsonEncode({'configuration': jsonEncode(config.toJson()),
        'fetchedAt': old.toIso8601String(), 'data': payload()}),
    });
    final channel = MockFLauncherChannel();
    final events = StreamController<dynamic>.broadcast();
    when(channel.addWeatherChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    final transport = FakeTransport(() async => payload());
    final service = WeatherService(channel, preferences: await SharedPreferences.getInstance(), transport: transport);
    while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
    expect(transport.calls, 0);
    expect(service.updatedAt, old);
    await service.refresh();
    expect(transport.calls, 1);
    expect(service.updatedAt!.isAfter(old), isTrue);
    final successTime = service.updatedAt;
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await Future<void>.delayed(Duration.zero);
    expect(transport.calls, 1);
    transport.response = () async => throw const WeatherException(WeatherFailure.unavailable);
    await service.refresh();
    expect(transport.calls, 2);
    expect(service.updatedAt, successTime);
    expect(service.failure, WeatherFailure.unavailable);
    transport.response = () async => payload();
    await service.refresh();
    expect(transport.calls, 3);
    expect(service.failure, isNull);
    service.dispose();
    await events.close();
  });
  test('late response from previous location cannot replace the new location', () async {
    SharedPreferences.setMockInitialValues({weatherConfigurationKey: jsonEncode(config.toJson())});
    final channel = MockFLauncherChannel();
    final events = StreamController<dynamic>.broadcast();
    when(channel.addWeatherChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    final first = Completer<Map<String, dynamic>>();
    final transport = FakeTransport(() => first.future);
    final service = WeatherService(channel, preferences: await SharedPreferences.getInstance(), transport: transport);
    await Future<void>.delayed(Duration.zero);
    await service.configure(const WeatherConfiguration(source: WeatherSource.openMeteo, latitude: 59.9, longitude: 30.3, location: 'Петербург'));
    transport.response = () async => payload();
    first.complete(payload());
    while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
    expect(transport.calls, 2);
    expect(service.weatherData!.location, 'Петербург');
    service.dispose();
    await events.close();
  });
}
