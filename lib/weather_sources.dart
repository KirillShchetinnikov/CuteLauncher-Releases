import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import 'models/weather_data.dart';

const weatherConfigurationKey = 'weather_configuration';
enum WeatherSource { breezy, openMeteo, yandex, openWeather, metNorway, customOpenMeteo, gismeteo }
enum WeatherLocationMode { automatic, manual }

bool isWeatherBearerToken(String token) =>
    token.length <= 1024 && RegExp(r'^[A-Za-z0-9._~+/-]+=*$').hasMatch(token);

Uri? parseWeatherServer(String input) {
  final value = input.trim();
  if (value.length > 2048 || RegExp(r'[\s\x00-\x1f\x7f\\]').hasMatch(value)) return null;
  final authority = RegExp(r'^https://([^/?#]+)', caseSensitive: false).firstMatch(value)?.group(1);
  if (authority == null || authority.contains('@')) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.scheme != 'https' || !uri.hasAuthority || uri.host.isEmpty ||
      uri.authority.contains('@') || uri.hasQuery || uri.hasFragment ||
      uri.port <= 0 || uri.port > 65535) {
    return null;
  }
  final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
  if (path.endsWith('/v1/forecast')) return null;
  return uri.replace(path: path);
}

bool validWeatherConfiguration(String value) {
  try {
    final map = jsonDecode(value) as Map;
    if (!WeatherSource.values.any((source) => source.name == map['source'])) return false;
    if (map['location'] is! String || (map['location'] as String).length > 200) return false;
    if (![30, 60, 120, 180].contains(map['intervalMinutes'])) return false;
    if (map['locationMode'] != null && !WeatherLocationMode.values.any((mode) => mode.name == map['locationMode'])) return false;
    final server = map['server_url'];
    if (server != null && (server is! String || parseWeatherServer(server) == null)) return false;
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
  final Uri? server;
  final int intervalMinutes;
  final WeatherLocationMode locationMode;
  const WeatherConfiguration({this.source = WeatherSource.breezy, this.latitude,
    this.longitude, this.location = '', this.intervalMinutes = 60,
    this.locationMode = WeatherLocationMode.automatic, this.cityLatitude, this.cityLongitude, this.server});
  bool get validCityCoordinates => WeatherConfiguration(latitude: cityLatitude, longitude: cityLongitude).validCoordinates;
  bool get hasLocation => locationMode == WeatherLocationMode.manual
      ? (source == WeatherSource.customOpenMeteo ? validCityCoordinates : location.trim().isNotEmpty)
      : validCoordinates;
  WeatherConfiguration copyWith({WeatherSource? source, int? intervalMinutes, WeatherLocationMode? locationMode,
    String? location, double? cityLatitude, double? cityLongitude, double? latitude,
    double? longitude, Uri? server}) => WeatherConfiguration(
    source: source ?? this.source, latitude: latitude ?? this.latitude, longitude: longitude ?? this.longitude,
    location: location ?? this.location, locationMode: locationMode ?? this.locationMode,
    cityLatitude: cityLatitude ?? this.cityLatitude, cityLongitude: cityLongitude ?? this.cityLongitude,
    intervalMinutes: intervalMinutes ?? this.intervalMinutes, server: server ?? this.server);
  bool get validCoordinates => latitude != null && longitude != null &&
    latitude!.isFinite && longitude!.isFinite && latitude!.abs() <= 90 && longitude!.abs() <= 180;
  Map<String, dynamic> toJson() => {'source': source.name, 'latitude': latitude,
    'longitude': longitude, 'location': location, 'intervalMinutes': intervalMinutes, 'locationMode': locationMode.name,
    'cityLatitude': cityLatitude, 'cityLongitude': cityLongitude,
    if (server != null) 'server_url': server.toString()};
  static WeatherConfiguration decode(String? value) {
    try {
      final map = jsonDecode(value ?? '{}') as Map;
      final source = WeatherSource.values.firstWhere((s) => s.name == map['source'], orElse: () => WeatherSource.breezy);
      final interval = map['intervalMinutes'];
      return WeatherConfiguration(source: source,
        server: map['server_url'] is String ? parseWeatherServer(map['server_url'] as String) : null,
        locationMode: map['locationMode'] == 'manual' ? WeatherLocationMode.manual : WeatherLocationMode.automatic,
        latitude: (map['latitude'] as num?)?.toDouble(), longitude: (map['longitude'] as num?)?.toDouble(),
        cityLatitude: (map['cityLatitude'] as num?)?.toDouble(), cityLongitude: (map['cityLongitude'] as num?)?.toDouble(),
        location: map['location'] is String ? (map['location'] as String).substring(0, (map['location'] as String).length.clamp(0, 200)) : '',
        intervalMinutes: interval is int && [30, 60, 120, 180].contains(interval) ? interval : 60);
    } catch (_) { return const WeatherConfiguration(); }
  }
}

enum WeatherFailure { coordinates, cityNotFound, keyRequired, authorization, rateLimit, unavailable, invalidResponse, serverAddress, parameters }
class WeatherException implements Exception {
  final WeatherFailure failure;
  const WeatherException(this.failure);
}

typedef WeatherResponseDecoder = Map<String, dynamic> Function(String body);

abstract class WeatherTransport {
  Future<Map<String, dynamic>> request(
    Uri uri, {
    String? key,
    bool customServer = false,
    String? bearerToken,
    WeatherResponseDecoder? decode,
  });
}

class HttpWeatherTransport implements WeatherTransport {
  Uri? _metUri;
  Map<String, dynamic>? _metData;
  DateTime? _metExpires;
  String? _metModified;
  @override
  Future<Map<String, dynamic>> request(
    Uri uri, {
    String? key,
    bool customServer = false,
    String? bearerToken,
    WeatherResponseDecoder? decode,
  }) async {
    if (customServer && uri.scheme != 'https') throw const WeatherException(WeatherFailure.serverAddress);
    final met = !customServer && uri.host == 'api.met.no';
    if (met && uri == _metUri && _metData != null &&
        _metExpires != null && DateTime.now().isBefore(_metExpires!)) { return _metData!; }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        if (met) {
          request.headers.set(HttpHeaders.userAgentHeader,
            'CuteLauncher (https://github.com/KirillShchetinnikov/CuteLauncher-Releases)');
          if (uri == _metUri && _metModified != null) {
            request.headers.set(HttpHeaders.ifModifiedSinceHeader, _metModified!);
          }
        }
        if (key != null) request.headers.set('X-Yandex-Weather-Key', key);
        if (customServer && bearerToken != null && bearerToken.trim().isNotEmpty) {
          request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
        }
        final response = await request.close();
        DateTime? expiry() {
          try { return HttpDate.parse(response.headers.value(HttpHeaders.expiresHeader) ?? ''); }
          catch (_) { return null; }
        }
        if (met && response.statusCode == 304 && uri == _metUri && _metData != null) {
          _metExpires = expiry();
          return _metData!;
        }
        if (response.statusCode == 401 || response.statusCode == 403) throw const WeatherException(WeatherFailure.authorization);
        if (response.statusCode == 429) throw const WeatherException(WeatherFailure.rateLimit);
        if (customServer && response.statusCode == 400) throw const WeatherException(WeatherFailure.parameters);
        if (response.statusCode != 200) throw const WeatherException(WeatherFailure.unavailable);
        final bytes = <int>[];
        await for (final chunk in response) {
          if (bytes.length + chunk.length > 512 * 1024) throw const WeatherException(WeatherFailure.invalidResponse);
          bytes.addAll(chunk);
        }
        final body = utf8.decode(bytes);
        final data = decode == null ? jsonDecode(body) as Map<String, dynamic> : decode(body);
        if (met) {
          _metUri = uri;
          _metData = data;
          _metExpires = expiry();
          _metModified = response.headers.value(HttpHeaders.lastModifiedHeader);
        }
        return data;
      })().timeout(const Duration(seconds: 15));
    } on WeatherException { rethrow; }
    on FormatException { throw const WeatherException(WeatherFailure.invalidResponse); }
    on XmlException { throw const WeatherException(WeatherFailure.invalidResponse); }
    catch (_) { throw const WeatherException(WeatherFailure.unavailable); }
    finally { client.close(force: true); }
  }
}

class DirectWeatherProvider {
  final WeatherTransport transport;
  const DirectWeatherProvider(this.transport);
  Future<Map<String, dynamic>> fetch(WeatherConfiguration config, {String? key, String? bearerToken, int forecastDays = 5}) async {
    if (config.source == WeatherSource.customOpenMeteo) {
      return _fetchCustom(config, bearerToken, forecastDays);
    }
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
    if (config.source == WeatherSource.gismeteo) {
      return _fetchGismeteo(config, locationLabel);
    }
    if (config.source == WeatherSource.metNorway) {
      final data = await transport.request(Uri.https('api.met.no', '/weatherapi/locationforecast/2.0/compact', {
        'lat': config.latitude!.toStringAsFixed(4), 'lon': config.longitude!.toStringAsFixed(4),
      }));
      try {
        final normalized = normalizeMetNorway(data);
        normalized['location'] = locationLabel;
        WeatherData.fromJson(normalized);
        return normalized;
      } catch (_) { throw const WeatherException(WeatherFailure.invalidResponse); }
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
      'current': 'temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m',
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

  Future<Map<String, dynamic>> _fetchGismeteo(
    WeatherConfiguration config,
    String locationLabel,
  ) async {
    const host = 'services.gismeteo.ru';
    const path = '/inform-service/inf_chrome';
    final city = await transport.request(
      Uri.https(host, '$path/cities/', {
        'lat': '${config.latitude}',
        'lng': '${config.longitude}',
        'count': '1',
        'lang': 'en',
      }),
      decode: (body) {
        final item = _weatherXmlRoot(body, 'document').getElement('item');
        if (item == null) throw const WeatherException(WeatherFailure.cityNotFound);
        final id = int.tryParse(item.getAttribute('id') ?? '');
        if (id == null || id <= 0) throw const FormatException();
        return {'id': id};
      },
    );
    final id = '${city['id']}';
    return transport.request(
      Uri.https(host, '$path/forecast/', {'city': id, 'lang': 'en'}),
      decode: (body) => _normalizeGismeteo(body, id, locationLabel),
    );
  }

  Future<Map<String, dynamic>> _fetchCustom(WeatherConfiguration config, String? token, int forecastDays) async {
    final base = parseWeatherServer(config.server?.toString() ?? '');
    if (base == null) throw const WeatherException(WeatherFailure.serverAddress);
    final uri = base.replace(path: '${base.path}/v1/forecast', queryParameters: {
      'timezone': 'auto', 'temperature_unit': 'celsius', 'wind_speed_unit': 'ms',
      'timeformat': 'iso8601', 'forecast_days': '${const [3, 5, 7].contains(forecastDays) ? forecastDays : 5}',
      'current': 'temperature_2m,apparent_temperature,weather_code,is_day,wind_speed_10m',
      'daily': 'temperature_2m_max,temperature_2m_min,weather_code,precipitation_probability_max',
    });
    final data = await transport.request(uri, customServer: true, bearerToken: token);
    try {
      if (data['error'] == true || (data['current'] is! Map && data['daily'] is! Map)) throw const FormatException();
      final normalized = normalizeOpenMeteo(data, isoTime: true);
      final latitude = _finiteNumber(data['latitude'])?.toDouble();
      final longitude = _finiteNumber(data['longitude'])?.toDouble();
      if (latitude != null && longitude != null &&
          latitude.abs() <= 90 && longitude.abs() <= 180) {
        normalized['latitude'] = latitude;
        normalized['longitude'] = longitude;
      }
      final timezone = data['timezone'];
      if (timezone is String && timezone.length <= 100 &&
          RegExp(r'^[A-Za-z0-9_+./:-]+$').hasMatch(timezone) &&
          (token == null || token.isEmpty || !timezone.contains(token))) {
        normalized['timezone'] = timezone;
      }
      final name = data['source'];
      if (name is String && name.trim().isNotEmpty && name.length <= 120 &&
          !RegExp(r'[\x00-\x1f\x7f]').hasMatch(name) && (token == null || token.isEmpty || !name.contains(token))) {
        normalized['source'] = name.trim();
      }
      final updated = _localWeatherTime(data['updated_at']);
      if (updated != null) normalized['updatedAt'] = updated.toUtc().toIso8601String();
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

XmlElement _weatherXmlRoot(String body, String name) {
  final document = XmlDocument.parse(body);
  final roots = document.children.whereType<XmlElement>();
  if (roots.length != 1 ||
      roots.single.name.qualified != name ||
      document.children.any((node) => node is XmlDoctype)) {
    throw const FormatException();
  }
  return roots.single;
}

Map<String, dynamic> _normalizeGismeteo(
  String body,
  String id,
  String locationLabel,
) {
  final location = _weatherXmlRoot(body, 'weather').getElement('location');
  final fact = location?.getElement('fact');
  final values = fact?.getElement('values');
  if (location == null ||
      location.getAttribute('id') != id ||
      fact == null ||
      values == null) {
    throw const FormatException();
  }
  final offsetMinutes = int.tryParse(location.getAttribute('tzone') ?? '');
  if (offsetMinutes == null || offsetMinutes.abs() > 14 * 60) throw const FormatException();
  final offset = offsetMinutes * 60;
  final observed = _localWeatherTime(fact.getAttribute('valid'), offset: offset);
  final temperature = _gismeteoTemperature(values, 't');
  if (observed == null || temperature == null) throw const FormatException();
  final timestamp = observed.millisecondsSinceEpoch ~/ 1000;
  final sunrise = int.tryParse(fact.getAttribute('sunrise') ?? '');
  final sunset = int.tryParse(fact.getAttribute('sunset') ?? '');
  final days = <String, Map<String, dynamic>>{};
  for (final day in location.findElements('day')) {
    final date = day.getAttribute('date');
    if (date == null || parseWeatherDate(date) == null) continue;
    final min = _gismeteoTemperature(day, 'tmin');
    final max = _gismeteoTemperature(day, 'tmax');
    final condition = _gismeteoCondition(day);
    if ((min != null && max != null && min > max) ||
        (min == null && max == null && condition == null)) {
      continue;
    }
    days.putIfAbsent(date, () => {
      'date': date,
      'minTemp': min,
      'maxTemp': max,
      'conditionCode': condition,
    });
  }
  if (days.isEmpty) throw const FormatException();
  final dates = days.keys.toList()..sort();
  final today = days[weatherDateString(weatherCalendarDay(observed, offset))];
  final cityName = location.getAttribute('name')?.trim();
  final humidity = int.tryParse(values.getAttribute('hum') ?? '');
  final wind = double.tryParse(values.getAttribute('ws') ?? '');
  return {
    'timestamp': timestamp,
    'utcOffsetSeconds': offset,
    'location': locationLabel.isNotEmpty
        ? locationLabel
        : (cityName != null && cityName.length <= 200 ? cityName : null),
    'currentTemp': temperature,
    'currentConditionCode': _gismeteoCondition(values),
    if (humidity != null && humidity >= 0 && humidity <= 100) 'currentHumidity': humidity,
    if (wind != null && wind.isFinite && wind >= 0) 'windSpeed': wind,
    if (sunrise != null && sunset != null && sunrise < sunset)
      'isDay': timestamp >= sunrise && timestamp < sunset,
    'todayMinTemp': today?['minTemp'],
    'todayMaxTemp': today?['maxTemp'],
    'forecasts': [for (final date in dates.take(7)) days[date]!],
  };
}

double? _gismeteoTemperature(XmlElement element, String attribute) {
  final temperature = double.tryParse(element.getAttribute(attribute) ?? '');
  return temperature != null && temperature >= -100 && temperature <= 100 ? temperature : null;
}

int? _gismeteoCondition(XmlElement element) {
  if (element.getAttribute('ts') == '1') return 211;
  return switch (element.getAttribute('pt')) {
    '1' => element.getAttribute('pr') == '3' ? 502 : 500,
    '2' => 601,
    '3' => 611,
    _ => switch (element.getAttribute('cl')) {
      '0' => 800,
      '1' => 801,
      '2' || '101' => 802,
      '3' => 804,
      _ => null,
    },
  };
}

num? _finiteNumber(Object? value) =>
    value is num && value.isFinite ? value : null;

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
      if (!today.add(Duration(days: index)).isAfter(ordered.last)) {
        ...?days[today.add(Duration(days: index))],
        'date': weatherDateString(today.add(Duration(days: index))),
      },
  ];
  return {'timestamp': timestamp, 'utcOffsetSeconds': offset, 'currentTemp': number(main['temp']),
    'feelsLikeTemp': _finiteNumber(main['feels_like']),
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
DateTime? _localWeatherTime(Object? value, {int? offset}) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}').hasMatch(value) ||
      parseWeatherDate(value.substring(0, 10)) == null) {
    return null;
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null || parsed.isUtc) return parsed;
  // Interpret wall time using the city's offset, independently of the TV zone.
  return offset == null ? null : DateTime.tryParse('${value}Z')?.subtract(Duration(seconds: offset));
}

Map<String, dynamic> normalizeOpenMeteo(Map<String, dynamic> data, {bool isoTime = false}) {
  int? integer(dynamic value) => value is num && value.isFinite ? value.round() : null;
  final current = (isoTime ? data['current'] as Map? : data['current'] as Map) ?? {};
  final daily = data['daily'] as Map? ?? {};
  final codes = daily['weather_code'] as List? ?? [];
  dynamic item(String field, int i) {
    final list = daily[field] as List?;
    return list != null && i < list.length ? list[i] : null;
  }
  final offset = integer(data['utc_offset_seconds']) ??
      (isoTime && (data['timezone'] == 'UTC' || data['timezone'] == 'GMT') ? 0 : null);
  final time = current['time'];
  final currentTime = isoTime ? _localWeatherTime(time, offset: offset) : null;
  final count = isoTime ? (daily['time'] as List? ?? []).length : codes.length;
  String? date(int i) {
    final time = item('time', i);
    if (isoTime) return parseWeatherDate(time) == null ? null : time as String;
    return time is num ? weatherDateString(weatherCalendarDay(
      DateTime.fromMillisecondsSinceEpoch(time.toInt() * 1000, isUtc: true), offset)) : null;
  }
  return {'timestamp': isoTime ? (currentTime == null ? null : currentTime.millisecondsSinceEpoch ~/ 1000) : integer(time),
    'utcOffsetSeconds': offset, 'currentTemp': _finiteNumber(current['temperature_2m']),
    'feelsLikeTemp': _finiteNumber(current['apparent_temperature']),
    'currentConditionCode': wmoCondition(current['weather_code']), 'currentHumidity': integer(current['relative_humidity_2m']),
    if (isoTime) 'isDay': switch (current['is_day']) { 0 => false, 1 => true, _ => null },
    'windSpeed': _finiteNumber(current['wind_speed_10m']),
    'todayMaxTemp': _finiteNumber(item('temperature_2m_max', 0)), 'todayMinTemp': _finiteNumber(item('temperature_2m_min', 0)),
    'forecasts': [for (var i = 0; i < count && i < 7; i++)
      if (!isoTime || date(i) != null) {'date': date(i), 'conditionCode': wmoCondition(item('weather_code', i)),
        'minTemp': _finiteNumber(item('temperature_2m_min', i)), 'maxTemp': _finiteNumber(item('temperature_2m_max', i)),
        'precipProbability': integer(item('precipitation_probability_max', i))}]};
}
Map<String, dynamic> normalizeYandex(Map<String, dynamic> data) {
  final fact = data['fact'] as Map;
  final forecasts = <Map<String, dynamic>>[];
  for (final day in (data['forecasts'] as List? ?? []).take(7)) {
    final parts = (day as Map)['parts'] as Map? ?? {};
    final part = parts['day_short'] as Map? ?? parts['day'] as Map? ?? {};
    forecasts.add({'date': day['date'], 'conditionCode': yandexCondition(part['condition']), 'minTemp': part['temp_min'], 'maxTemp': part['temp_max'], 'precipProbability': part['prec_prob']});
  }
  final info = data['info'] as Map?;
  final tz = info?['tzinfo'] as Map?;
  return {'timestamp': data['now'], 'utcOffsetSeconds': tz?['offset'], 'currentTemp': fact['temp'], 'currentConditionCode': yandexCondition(fact['condition']),
    'feelsLikeTemp': _finiteNumber(fact['feels_like']),
    'currentHumidity': fact['humidity'], 'windSpeed': fact['wind_speed'],
    'todayMinTemp': forecasts.isEmpty ? null : forecasts.first['minTemp'], 'todayMaxTemp': forecasts.isEmpty ? null : forecasts.first['maxTemp'], 'forecasts': forecasts};
}

/// MET timestamps are UTC; forecast calendar days use the TV time zone.
Map<String, dynamic> normalizeMetNorway(Map<String, dynamic> data, {DateTime? now}) {
  num number(dynamic value) {
    if (value is! num || !value.isFinite) throw const FormatException();
    return value;
  }
  final series = (data['properties'] as Map)['timeseries'] as List;
  if (series.isEmpty || series.length > 300) throw const FormatException();
  final instant = (now ?? DateTime.now()).toUtc();
  final entries = series.map((e) => e as Map).toList();
  DateTime time(Map e) => DateTime.parse(e['time'] as String);
  final current = entries.reduce((a, b) => time(a).difference(instant).abs() <=
    time(b).difference(instant).abs() ? a : b);
  if (time(current).difference(instant).abs() > const Duration(hours: 6)) throw const FormatException();
  Map details(Map e) => ((e['data'] as Map)['instant'] as Map)['details'] as Map;
  Map? period(Map e) {
    final values = e['data'] as Map;
    return (values['next_1_hours'] ?? values['next_6_hours'] ?? values['next_12_hours']) as Map?;
  }
  int? code(Map e) => metNorwayCondition((period(e)?['summary'] as Map?)?['symbol_code']);
  DateTime day(DateTime t) { final local = t.toLocal(); return DateTime(local.year, local.month, local.day); }
  final today = day(instant);
  final days = <DateTime, Map<String, dynamic>>{};
  int severity(int? c) => WeatherData.stormCodes.contains(c) ? 3 : WeatherData.snowCodes.contains(c) ? 2 : WeatherData.rainCodes.contains(c) ? 1 : 0;
  for (final e in entries) {
    final date = day(time(e));
    if (date.isBefore(today) || date.isAfter(DateTime(today.year, today.month, today.day + 6))) continue;
    final temp = number(details(e)['air_temperature']);
    final c = code(e);
    final daily = days.putIfAbsent(date, () => {'minTemp': temp, 'maxTemp': temp, 'conditionCode': c});
    if (temp < daily['minTemp']) daily['minTemp'] = temp;
    if (temp > daily['maxTemp']) daily['maxTemp'] = temp;
    if (severity(c) > severity(daily['conditionCode'] as int?)) daily['conditionCode'] = c;
  }
  final values = details(current);
  return {'timestamp': time(current).millisecondsSinceEpoch ~/ 1000,
    'currentTemp': number(values['air_temperature']), 'currentConditionCode': code(current),
    'currentHumidity': values['relative_humidity'] == null ? null : number(values['relative_humidity']).round(),
    'windSpeed': values['wind_speed'] == null ? null : number(values['wind_speed']).toDouble(),
    'todayMinTemp': days[today]?['minTemp'], 'todayMaxTemp': days[today]?['maxTemp'],
    'forecasts': [for (var i = 0; i < 7; i++) {
      ...?days[DateTime(today.year, today.month, today.day + i)],
      'date': weatherDateString(DateTime(today.year, today.month, today.day + i)),
    }]};
}

int? metNorwayCondition(dynamic value) {
  if (value is! String) return null;
  final symbol = value.split('_').first;
  if (symbol.contains('thunder')) return 211;
  if (symbol.contains('sleet')) return 611;
  if (symbol.contains('snow')) return 601;
  if (symbol.contains('rain')) return symbol.contains('showers') ? 521 : 501;
  return switch (symbol) {
    'clearsky' => 800, 'fair' => 801, 'partlycloudy' => 802,
    'cloudy' => 804, 'fog' => 741, _ => null,
  };
}
