import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'models/weather_data.dart';

const weatherConfigurationKey = 'weather_configuration';
enum WeatherSource { breezy, openMeteo, yandex, openWeather }
enum WeatherLocationMode { automatic, manual }

bool validWeatherConfiguration(String value) {
  try {
    final map = jsonDecode(value) as Map;
    if (!WeatherSource.values.any((source) => source.name == map['source'])) return false;
    if (map['location'] is! String || (map['location'] as String).length > 200) return false;
    if (![30, 60, 120, 180].contains(map['intervalMinutes'])) return false;
    if (map['locationMode'] != null && !WeatherLocationMode.values.any((mode) => mode.name == map['locationMode'])) return false;
    final config = WeatherConfiguration.decode(value);
    return ((config.latitude == null && config.longitude == null) || config.validCoordinates) &&
      ((config.cityLatitude == null && config.cityLongitude == null) || config.validCityCoordinates);
  } catch (_) { return false; }
}

class WeatherConfiguration {
  final WeatherSource source;
  final double? latitude, longitude;
  final double? cityLatitude, cityLongitude;
  final String location;
  final int intervalMinutes;
  final WeatherLocationMode locationMode;
  const WeatherConfiguration({this.source = WeatherSource.breezy, this.latitude,
    this.longitude, this.location = '', this.intervalMinutes = 60,
    this.locationMode = WeatherLocationMode.automatic, this.cityLatitude, this.cityLongitude});
  bool get validCityCoordinates => WeatherConfiguration(latitude: cityLatitude, longitude: cityLongitude).validCoordinates;
  bool get hasLocation => locationMode == WeatherLocationMode.manual ? location.trim().isNotEmpty : validCoordinates;
  WeatherConfiguration copyWith({WeatherSource? source, int? intervalMinutes, WeatherLocationMode? locationMode,
    String? location, double? cityLatitude, double? cityLongitude}) => WeatherConfiguration(
    source: source ?? this.source, latitude: latitude, longitude: longitude,
    location: location ?? this.location, locationMode: locationMode ?? this.locationMode,
    cityLatitude: cityLatitude ?? this.cityLatitude, cityLongitude: cityLongitude ?? this.cityLongitude,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes);
  bool get validCoordinates => latitude != null && longitude != null &&
    latitude!.isFinite && longitude!.isFinite && latitude!.abs() <= 90 && longitude!.abs() <= 180;
  Map<String, dynamic> toJson() => {'source': source.name, 'latitude': latitude,
    'longitude': longitude, 'location': location, 'intervalMinutes': intervalMinutes, 'locationMode': locationMode.name,
    'cityLatitude': cityLatitude, 'cityLongitude': cityLongitude};
  static WeatherConfiguration decode(String? value) {
    try {
      final map = jsonDecode(value ?? '{}') as Map;
      final source = WeatherSource.values.firstWhere((s) => s.name == map['source'], orElse: () => WeatherSource.breezy);
      final interval = map['intervalMinutes'];
      return WeatherConfiguration(source: source,
        locationMode: map['locationMode'] == 'manual' ? WeatherLocationMode.manual : WeatherLocationMode.automatic,
        latitude: (map['latitude'] as num?)?.toDouble(), longitude: (map['longitude'] as num?)?.toDouble(),
        cityLatitude: (map['cityLatitude'] as num?)?.toDouble(), cityLongitude: (map['cityLongitude'] as num?)?.toDouble(),
        location: map['location'] is String ? (map['location'] as String).substring(0, (map['location'] as String).length.clamp(0, 200)) : '',
        intervalMinutes: interval is int && [30, 60, 120, 180].contains(interval) ? interval : 60);
    } catch (_) { return const WeatherConfiguration(); }
  }
}

enum WeatherFailure { coordinates, cityNotFound, keyRequired, authorization, rateLimit, unavailable, invalidResponse }
class WeatherException implements Exception {
  final WeatherFailure failure;
  const WeatherException(this.failure);
}

abstract class WeatherTransport {
  Future<Map<String, dynamic>> request(Uri uri, {String? key});
}

class HttpWeatherTransport implements WeatherTransport {
  @override
  Future<Map<String, dynamic>> request(Uri uri, {String? key}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        if (key != null) request.headers.set('X-Yandex-Weather-Key', key);
        final response = await request.close();
        if (response.statusCode == 401 || response.statusCode == 403) throw const WeatherException(WeatherFailure.authorization);
        if (response.statusCode == 429) throw const WeatherException(WeatherFailure.rateLimit);
        if (response.statusCode != 200) throw const WeatherException(WeatherFailure.unavailable);
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 512 * 1024) throw const WeatherException(WeatherFailure.invalidResponse);
          bytes.addAll(chunk);
        }
        return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      })().timeout(const Duration(seconds: 15));
    } on WeatherException { rethrow; }
    on FormatException { throw const WeatherException(WeatherFailure.invalidResponse); }
    catch (_) { throw const WeatherException(WeatherFailure.unavailable); }
    finally { client.close(force: true); }
  }
}

class DirectWeatherProvider {
  final WeatherTransport transport;
  const DirectWeatherProvider(this.transport);
  Future<Map<String, dynamic>> fetch(WeatherConfiguration config, {String? key}) async {
    final locationLabel = config.locationMode == WeatherLocationMode.automatic && config.validCityCoordinates
      ? '' : config.location;
    if (!config.hasLocation) throw const WeatherException(WeatherFailure.coordinates);
    if ((config.source == WeatherSource.yandex || config.source == WeatherSource.openWeather) &&
        (key == null || key.trim().isEmpty)) {
      throw const WeatherException(WeatherFailure.keyRequired);
    }
    if (config.locationMode == WeatherLocationMode.manual) {
      if (config.validCityCoordinates) {
        config = WeatherConfiguration(source: config.source, location: config.location,
          latitude: config.cityLatitude, longitude: config.cityLongitude, intervalMinutes: config.intervalMinutes);
      } else {
        final data = await transport.request(Uri.https('geocoding-api.open-meteo.com', '/v1/search',
          {'name': config.location.trim(), 'count': '1', 'language': 'en', 'format': 'json'}));
        final results = data['results'];
        if (results == null || (results is List && results.isEmpty)) throw const WeatherException(WeatherFailure.cityNotFound);
        try {
          final place = (results as List).first as Map;
          config = WeatherConfiguration(source: config.source, location: config.location,
            latitude: (place['latitude'] as num).toDouble(), longitude: (place['longitude'] as num).toDouble(),
            intervalMinutes: config.intervalMinutes);
          if (!config.validCoordinates) throw const FormatException();
        } catch (_) { throw const WeatherException(WeatherFailure.invalidResponse); }
      }
    }
    if (config.source == WeatherSource.openWeather) {
      final query = {'lat': '${config.latitude}', 'lon': '${config.longitude}',
        'units': 'metric', 'appid': key!.trim()};
      final current = await _openWeatherRequest(Uri.https('api.openweathermap.org', '/data/2.5/weather', query));
      final forecast = await _openWeatherRequest(Uri.https('api.openweathermap.org', '/data/2.5/forecast', query));
      try {
        final normalized = normalizeOpenWeather(current, forecast);
        normalized['location'] = locationLabel;
        WeatherData.fromJson(normalized);
        return normalized;
      } catch (_) { throw const WeatherException(WeatherFailure.invalidResponse); }
    }
    final query = {'latitude': '${config.latitude}', 'longitude': '${config.longitude}',
      'current': 'temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max',
      'timezone': 'auto', 'timeformat': 'unixtime', 'wind_speed_unit': 'ms', 'forecast_days': '7'};
    final uri = config.source == WeatherSource.yandex
      ? Uri.https('api.weather.yandex.ru', '/v2/forecast', {'lat': '${config.latitude}', 'lon': '${config.longitude}', 'limit': '7', 'hours': 'false'})
      : Uri.https('api.open-meteo.com', '/v1/forecast', query);
    final data = await transport.request(uri, key: config.source == WeatherSource.yandex ? key : null);
    try {
      final normalized = config.source == WeatherSource.yandex ? normalizeYandex(data) : normalizeOpenMeteo(data);
      normalized['location'] = locationLabel;
      if (normalized['currentTemp'] is! num || !(normalized['currentTemp'] as num).isFinite) throw const FormatException();
      WeatherData.fromJson(normalized);
      return normalized;
    } catch (_) { throw const WeatherException(WeatherFailure.invalidResponse); }
  }

  Future<Map<String, dynamic>> _openWeatherRequest(Uri uri) async {
    final data = await transport.request(uri);
    final code = int.tryParse('${data['cod']}');
    if (code == 401 || code == 403) throw const WeatherException(WeatherFailure.authorization);
    if (code == 429) throw const WeatherException(WeatherFailure.rateLimit);
    if (code != 200) throw const WeatherException(WeatherFailure.invalidResponse);
    return data;
  }
}

/// Aggregates the public three-hour forecast in the location's time zone.
Map<String, dynamic> normalizeOpenWeather(Map<String, dynamic> current, Map<String, dynamic> forecast) {
  num number(dynamic value) {
    if (value is! num || !value.isFinite) throw const FormatException();
    return value;
  }
  int condition(Map data) => number((data['weather'] as List).first['id']).toInt();
  final main = current['main'] as Map;
  final timestamp = number(current['dt']).toInt();
  final offset = number(current['timezone']).toInt();
  DateTime day(int time) {
    final local = DateTime.fromMillisecondsSinceEpoch((time + offset) * 1000, isUtc: true);
    return DateTime.utc(local.year, local.month, local.day);
  }
  final today = day(timestamp);
  final days = <DateTime, Map<String, dynamic>>{};
  final periods = forecast['list'] as List;
  if (periods.isEmpty || periods.length > 40) throw const FormatException();
  for (final period in periods) {
    final item = period as Map;
    final date = day(number(item['dt']).toInt());
    if (date.isBefore(today)) continue;
    final temperatures = item['main'] as Map;
    final low = number(temperatures['temp_min']).toDouble();
    final high = number(temperatures['temp_max']).toDouble();
    final probability = number(item['pop']).toDouble();
    if (low > high || probability < 0 || probability > 1) throw const FormatException();
    final code = condition(item);
    int severity(int value) => WeatherData.stormCodes.contains(value) ? 3 :
      WeatherData.snowCodes.contains(value) ? 2 : WeatherData.rainCodes.contains(value) ? 1 : 0;
    final previous = days[date];
    if (previous == null) {
      days[date] = {'minTemp': low, 'maxTemp': high, 'conditionCode': code,
        'precipProbability': (probability * 100).round()};
    } else {
      if (low < previous['minTemp']) previous['minTemp'] = low;
      if (high > previous['maxTemp']) previous['maxTemp'] = high;
      if (severity(code) > severity(previous['conditionCode'])) previous['conditionCode'] = code;
      if (probability * 100 > previous['precipProbability']) previous['precipProbability'] = (probability * 100).round();
    }
  }
  if (days.isEmpty) throw const FormatException();
  final ordered = days.keys.toList()..sort();
  // Preserve the existing model's index 0=today even if the first period is tomorrow.
  final forecasts = <Map<String, dynamic>>[
    for (var index = 0; index < 6; index++)
      if (days[today.add(Duration(days: index))] != null) days[today.add(Duration(days: index))]!
      else if (!today.add(Duration(days: index)).isAfter(ordered.last)) <String, dynamic>{},
  ];
  return {'timestamp': timestamp, 'currentTemp': number(main['temp']),
    'currentConditionCode': condition(current), 'currentHumidity': number(main['humidity']).round(),
    'windSpeed': number((current['wind'] as Map)['speed']).toDouble(),
    'todayMinTemp': days[today]?['minTemp'], 'todayMaxTemp': days[today]?['maxTemp'], 'forecasts': forecasts};
}

int? wmoCondition(dynamic value) => switch (value) {
  0 => 800, 1 => 801, 2 => 802, 3 => 804, 45 || 48 => 741,
  51 || 53 || 55 || 56 || 57 => 500, 61 || 63 || 65 || 66 || 67 => 501,
  71 || 73 || 75 || 77 || 85 || 86 => 601, 80 || 81 || 82 => 521,
  95 || 96 || 97 || 99 => 211, _ => null,
};
int? yandexCondition(dynamic value) => switch (value) {
  'clear' => 800, 'partly-cloudy' => 801, 'cloudy' => 803, 'overcast' => 804,
  'light-rain' => 500, 'rain' || 'heavy-rain' => 501, 'showers' => 521,
  'wet-snow' => 611, 'light-snow' || 'snow' || 'snow-showers' || 'hail' => 601,
  'thunderstorm' || 'thunderstorm-with-rain' || 'thunderstorm-with-hail' => 211,
  _ => null,
};
Map<String, dynamic> normalizeOpenMeteo(Map<String, dynamic> data) {
  int? integer(dynamic value) => value is num && value.isFinite ? value.round() : null;
  final current = data['current'] as Map;
  final daily = data['daily'] as Map? ?? {};
  final codes = daily['weather_code'] as List? ?? [];
  dynamic item(String field, int i) {
    final list = daily[field] as List?;
    return list != null && i < list.length ? list[i] : null;
  }
  return {'timestamp': integer(current['time']), 'currentTemp': current['temperature_2m'],
    'currentConditionCode': wmoCondition(current['weather_code']), 'currentHumidity': integer(current['relative_humidity_2m']),
    'windSpeed': current['wind_speed_10m'], 'todayMaxTemp': item('temperature_2m_max', 0), 'todayMinTemp': item('temperature_2m_min', 0),
    'forecasts': [for (var i = 0; i < codes.length && i < 7; i++) {'conditionCode': wmoCondition(codes[i]),
      'minTemp': item('temperature_2m_min', i), 'maxTemp': item('temperature_2m_max', i), 'precipProbability': integer(item('precipitation_probability_max', i))}]};
}
Map<String, dynamic> normalizeYandex(Map<String, dynamic> data) {
  final fact = data['fact'] as Map;
  final forecasts = <Map<String, dynamic>>[];
  for (final day in (data['forecasts'] as List? ?? []).take(7)) {
    final parts = (day as Map)['parts'] as Map? ?? {};
    final part = parts['day_short'] as Map? ?? parts['day'] as Map? ?? {};
    forecasts.add({'conditionCode': yandexCondition(part['condition']), 'minTemp': part['temp_min'], 'maxTemp': part['temp_max'], 'precipProbability': part['prec_prob']});
  }
  return {'timestamp': data['now'], 'currentTemp': fact['temp'], 'currentConditionCode': yandexCondition(fact['condition']),
    'currentHumidity': fact['humidity'], 'windSpeed': fact['wind_speed'],
    'todayMinTemp': forecasts.isEmpty ? null : forecasts.first['minTemp'], 'todayMaxTemp': forecasts.isEmpty ? null : forecasts.first['maxTemp'], 'forecasts': forecasts};
}
