import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/models/weather_data.dart';

Map<String, dynamic> fixture() => {'properties': {'timeseries': [
  for (var i = 0; i < 48; i++) {
    'time': DateTime.utc(2026, 10, 22, i).toIso8601String(),
    'data': {
      'instant': {'details': {'air_temperature': i - 5, 'relative_humidity': 80, 'wind_speed': 3.5}},
      if (i < 47) 'next_6_hours': {'summary': {'symbol_code': i > 20 ? 'snow_night' : 'rain_day'}}
    }
  }
]}};

class Transport implements WeatherTransport {
  Uri? uri;
  @override
  Future<Map<String, dynamic>> request(Uri value, {String? key}) async {
    uri = value;
    expect(key, isNull);
    final data = fixture();
    final series = (data['properties'] as Map)['timeseries'] as List;
    final offset = DateTime.now().toUtc().difference(DateTime.utc(2026, 10, 22));
    for (final e in series) {
      e['time'] = DateTime.parse(e['time'] as String).add(offset).toIso8601String();
    }
    return data;
  }
}

void main() {
  test('MET symbols include suffixes, sleet, thunder and unknown values', () {
    expect(metNorwayCondition('clearsky_polartwilight'), 800);
    expect(metNorwayCondition('heavysleetshowers_day'), 611);
    expect(metNorwayCondition('lightssnowshowersandthunder_night'), 211);
    expect(metNorwayCondition('fog'), 741);
    expect(metNorwayCondition('unknown'), isNull);
  });
  test('MET aggregates available periods and keeps missing probability absent', () {
    final raw = normalizeMetNorway(fixture(), now: DateTime.utc(2026, 10, 22));
    final weather = WeatherData.fromJson(raw);
    expect(weather.currentTemp, -5);
    expect(weather.currentHumidity, 80);
    expect(weather.windSpeed, 3.5);
    expect(weather.forecasts.first.precipProbability, isNull);
    expect(weather.forecasts.any((e) => e.conditionCode == 601), isTrue);
    expect(weather.forecasts.last.minTemp, isNull);
  });
  test('MET rejects empty, stale and malformed data', () {
    for (final data in [
      <String, dynamic>{},
      {'properties': {'timeseries': []}},
      fixture(),
    ]) {
      expect(() => normalizeMetNorway(data, now: DateTime.utc(2030)), throwsA(anything));
    }
  });
  test('MET routes without a key and rounds coordinates to four decimals', () async {
    final transport = Transport();
    const config = WeatherConfiguration(source: WeatherSource.metNorway, latitude: 55.755826, longitude: 37.6173);
    expect(validWeatherConfiguration(jsonEncode(config.toJson())), isTrue);
    final restored = WeatherConfiguration.decode('{"source":"metNorway","latitude":55.755826,"longitude":37.6173}');
    expect(restored.source, WeatherSource.metNorway);
    await DirectWeatherProvider(transport).fetch(config);
    expect(transport.uri!.host, 'api.met.no');
    expect(transport.uri!.path, '/weatherapi/locationforecast/2.0/compact');
    expect(transport.uri!.queryParameters, {'lat': '55.7558', 'lon': '37.6173'});
  });
}
