import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mocks.mocks.dart';

const openConfig = WeatherConfiguration(source: WeatherSource.openWeather,
  latitude: 55.75, longitude: 37.62, location: 'Москва');
final day = DateTime.utc(2026, 10, 5).millisecondsSinceEpoch ~/ 1000;
Map<String, dynamic> current() => {'cod': 200, 'dt': day + 20 * 3600, 'timezone': 3 * 3600,
  'main': {'temp': 7.5, 'humidity': 80}, 'weather': [{'id': 800}], 'wind': {'speed': 2.5}};
Map<String, dynamic> forecast() => {'cod': '200', 'list': [
  for (var i = 0; i < 3; i++) {'dt': day + (20 + i * 3) * 3600,
    'main': {'temp_min': 4 - i, 'temp_max': 10 + i}, 'pop': i * .4,
    'weather': [{'id': i == 2 ? 211 : i == 1 ? 601 : 800}]},
]};

class OpenTransport implements WeatherTransport {
  final requests = <Uri>[];
  final headers = <String?>[];
  Future<Map<String, dynamic>> Function(Uri)? response;
  @override Future<Map<String, dynamic>> request(Uri uri, {String? key}) async {
    requests.add(uri); headers.add(key);
    return response != null ? response!(uri) : uri.path.endsWith('/weather') ? current() : forecast();
  }
}
class KeyPaths extends PathProviderPlatform {
  final String path;
  KeyPaths(this.path);
  @override Future<String?> getApplicationSupportPath() async => path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('OpenWeather uses two HTTPS metric requests with its own key, never Yandex header', () async {
    final transport = OpenTransport();
    final data = WeatherData.fromJson(await DirectWeatherProvider(transport).fetch(openConfig, key: ' test-key '));
    expect(transport.requests.map((uri) => uri.path), ['/data/2.5/weather', '/data/2.5/forecast']);
    for (final uri in transport.requests) {
      expect(uri.scheme, 'https'); expect(uri.host, 'api.openweathermap.org');
      expect(uri.queryParameters['units'], 'metric'); expect(uri.queryParameters['appid'], 'test-key');
    }
    expect(transport.headers, [null, null]);
    expect(data.currentTemp, 8); expect(data.windSpeed, 2.5); expect(data.location, 'Москва');
    expect(data.forecasts.length, 2);
    expect(data.forecasts[1].minTemp, 2); expect(data.forecasts[1].maxTemp, 12);
    expect(data.forecasts[1].precipProbability, 80); expect(data.forecasts[1].conditionCode, 211);
    expect(data.warningType, WeatherWarningType.storm);
  });
  test('missing key fails before network; tomorrow keeps model index 1', () async {
    final transport = OpenTransport();
    await expectLater(DirectWeatherProvider(transport).fetch(openConfig),
      throwsA(isA<WeatherException>().having((e) => e.failure, 'failure', WeatherFailure.keyRequired)));
    expect(transport.requests, isEmpty);
    final payload = forecast();
    (payload['list'] as List).removeAt(0);
    final data = WeatherData.fromJson(normalizeOpenWeather(current(), payload));
    expect(data.forecasts[0].conditionCode, isNull);
    expect(data.forecasts[1].conditionCode, 211);
    expect(data.todayMinTemp, isNull);
  });
  for (final code in [401, 403, 429]) {
    test('OpenWeather JSON error $code becomes a sanitized failure', () async {
      final transport = OpenTransport()..response = (_) async => {'cod': '$code', 'message': 'secret must not be logged'};
      await expectLater(DirectWeatherProvider(transport).fetch(openConfig, key: 'test-key'),
        throwsA(isA<WeatherException>().having((e) => e.failure, 'failure',
          code == 429 ? WeatherFailure.rateLimit : WeatherFailure.authorization)));
    });
  }
  test('bad temperatures, empty forecast and probabilities are rejected', () async {
    for (final invalid in [<String, dynamic>{}, {...forecast(), 'list': <dynamic>[]},
      {...current(), 'main': {'temp': 'hot', 'humidity': 80}}]) {
      final transport = OpenTransport()..response = (uri) async => uri.path.endsWith('/weather') ? invalid : forecast();
      await expectLater(DirectWeatherProvider(transport).fetch(openConfig, key: 'test-key'), throwsA(isA<WeatherException>()));
    }
    final invalid = forecast(); (invalid['list'] as List).first['pop'] = 2;
    expect(() => normalizeOpenWeather(current(), invalid), throwsFormatException);
  });
  test('configuration is portable while both provider secrets are excluded', () {
    final encoded = jsonEncode(openConfig.toJson());
    expect(validWeatherConfiguration(encoded), isTrue);
    expect(compatibleSettings({weatherConfigurationKey: encoded,
      'weather_api_key_yandex': 'one', 'weather_api_key_openweather': 'two'}, {}), {weatherConfigurationKey: encoded});
  });

  group('source-specific keys and service cache', () {
    late Directory directory;
    late PathProviderPlatform originalPaths;
    late StreamController<dynamic> events;
    late MockFLauncherChannel channel;
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('openweather-test-');
      originalPaths = PathProviderPlatform.instance;
      PathProviderPlatform.instance = KeyPaths(directory.path);
      SharedPreferences.setMockInitialValues({});
      events = StreamController<dynamic>.broadcast(); channel = MockFLauncherChannel();
      when(channel.isBreezyWeatherInstalled()).thenAnswer((_) async => false);
      when(channel.getLatestWeatherData()).thenAnswer((_) async => null);
      when(channel.addWeatherChangedListener(any)).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    });
    tearDown(() async {
      await events.close(); PathProviderPlatform.instance = originalPaths;
      await directory.delete(recursive: true);
    });
    test('replace and delete one key preserves the other and secrets stay out of preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      final service = WeatherService(channel, preferences: prefs);
      addTearDown(service.dispose);
      await service.setApiKey('yandex-test', source: WeatherSource.yandex);
      await service.setApiKey('open-test', source: WeatherSource.openWeather);
      await service.setApiKey('replacement', source: WeatherSource.openWeather);
      expect(await File('${directory.path}/weather-api-key').readAsString(), 'yandex-test');
      expect(await File('${directory.path}/weather-api-key-openweather').readAsString(), 'replacement');
      await service.setApiKey('', source: WeatherSource.openWeather);
      expect(await service.hasApiKey(source: WeatherSource.openWeather), isFalse);
      expect(await service.hasApiKey(source: WeatherSource.yandex), isTrue);
      expect(prefs.getKeys(), isEmpty);
    });
    test('quota failure preserves cached weather across restart and retries are limited', () async {
      final prefs = await SharedPreferences.getInstance();
      final transport = OpenTransport();
      final service = WeatherService(channel, preferences: prefs, transport: transport);
      await service.setApiKey('test-key', source: WeatherSource.openWeather);
      await service.configure(openConfig);
      expect(service.weatherData!.currentTemp, 8);
      final cache = jsonDecode(prefs.getString('weather_cache')!) as Map;
      expect(jsonEncode(cache), isNot(contains('test-key')));
      service.dispose();
      cache['fetchedAt'] = DateTime.now().subtract(const Duration(hours: 2)).toIso8601String();
      await prefs.setString('weather_cache', jsonEncode(cache));
      final failed = OpenTransport()..response = (_) async => throw const WeatherException(WeatherFailure.rateLimit);
      final restored = WeatherService(channel, preferences: prefs, transport: failed);
      addTearDown(restored.dispose);
      while (!restored.initialized) { await Future<void>.delayed(Duration.zero); }
      expect(restored.weatherData!.currentTemp, 8); expect(restored.failure, WeatherFailure.rateLimit);
      await restored.refresh(); expect(failed.requests.length, 1);
    });
    test('removing a key rejects the in-flight response and reports missing key', () async {
      final prefs = await SharedPreferences.getInstance();
      final pending = Completer<Map<String, dynamic>>();
      final transport = OpenTransport()..response = (_) => pending.future;
      final service = WeatherService(channel, preferences: prefs, transport: transport);
      addTearDown(service.dispose);
      await service.setApiKey('test-key', source: WeatherSource.openWeather);
      final configuring = service.configure(openConfig);
      while (transport.requests.isEmpty) { await Future<void>.delayed(Duration.zero); }
      await service.setApiKey('', source: WeatherSource.openWeather);
      transport.response = (_) async => forecast(); pending.complete(current());
      await configuring;
      expect(service.weatherData, isNull); expect(service.failure, WeatherFailure.keyRequired);
      expect(prefs.getString('weather_cache'), isNull);
    });
  });
}
