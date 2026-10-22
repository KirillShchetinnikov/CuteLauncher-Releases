import 'dart:convert';

import 'models/weather_data.dart';

const landscapeSettingsKey = 'wallpaper_landscape';

class LandscapeConfiguration {
  final String variant;
  final bool timeOfDay, seasons, clouds, precipitation, fog, motion;
  final String hemisphere;
  const LandscapeConfiguration({
    this.variant = 'illustrated',
    this.timeOfDay = true,
    this.seasons = true,
    this.clouds = true,
    this.precipitation = true,
    this.fog = true,
    this.motion = false,
    this.hemisphere = 'auto',
  });

  Map<String, dynamic> toJson() => {
    'variant': variant,
    'timeOfDay': timeOfDay,
    'seasons': seasons,
    'clouds': clouds,
    'precipitation': precipitation,
    'fog': fog,
    'motion': motion,
    'hemisphere': hemisphere,
  };
  String encode() => jsonEncode(toJson());
  LandscapeConfiguration withValue(String key, dynamic value) =>
      parse({...toJson(), key: value});
  static LandscapeConfiguration parse(Map data) {
    final variant = data['variant'] ?? 'illustrated';
    final hemisphere = data['hemisphere'] ?? 'auto';
    if (!['illustrated', 'realistic'].contains(variant) ||
        !['auto', 'north', 'south'].contains(hemisphere)) {
      throw const FormatException('Invalid landscape');
    }
    bool flag(String key, bool fallback) {
      if (!data.containsKey(key)) return fallback;
      if (data[key] is! bool) {
        throw const FormatException('Invalid landscape effect');
      }
      return data[key] as bool;
    }

    return LandscapeConfiguration(
      variant: variant,
      hemisphere: hemisphere,
      timeOfDay: flag('timeOfDay', true),
      seasons: flag('seasons', true),
      clouds: flag('clouds', true),
      precipitation: flag('precipitation', true),
      fog: flag('fog', true),
      motion: flag('motion', false),
    );
  }

  static LandscapeConfiguration decode(String? source) {
    try {
      return parse(jsonDecode(source ?? '{}') as Map);
    } catch (_) {
      return const LandscapeConfiguration();
    }
  }
}

enum LandscapePhase { dawn, day, dusk, night }

enum LandscapeSeason { spring, summer, autumn, winter }

enum LandscapeWeather { clear, cloudy, rain, snow, fog }

LandscapeWeather landscapeWeather(WeatherData? weather) {
  final code = weather?.currentConditionCode;
  if (code == null) return LandscapeWeather.clear;
  if (WeatherData.snowCodes.contains(code)) return LandscapeWeather.snow;
  if (WeatherData.rainCodes.contains(code) ||
      WeatherData.stormCodes.contains(code) ||
      code >= 300 && code < 400) {
    return LandscapeWeather.rain;
  }
  if (code >= 700 && code < 800) return LandscapeWeather.fog;
  if (code > 800 && code <= 804) return LandscapeWeather.cloudy;
  return LandscapeWeather.clear;
}

LandscapeSeason landscapeSeason(
  DateTime now,
  LandscapeConfiguration config, {
  double? latitude,
}) {
  if (!config.seasons) return LandscapeSeason.summer;
  final south =
      config.hemisphere == 'south' ||
      config.hemisphere == 'auto' && latitude != null && latitude < 0;
  final month = south ? (now.month + 5) % 12 + 1 : now.month;
  return switch (month) {
    3 || 4 || 5 => LandscapeSeason.spring,
    6 || 7 || 8 => LandscapeSeason.summer,
    9 || 10 || 11 => LandscapeSeason.autumn,
    _ => LandscapeSeason.winter,
  };
}

/// Reuse cached local sun times; never requests location or network itself.
LandscapePhase landscapePhase(
  DateTime now,
  LandscapeConfiguration config, {
  List<Map<String, dynamic>> solarDays = const [],
}) {
  if (!config.timeOfDay) return LandscapePhase.day;
  var sunrise = DateTime(now.year, now.month, now.day, 6);
  var sunset = DateTime(now.year, now.month, now.day, 18);
  for (final day in solarDays) {
    final rise = day['sunrise'], set = day['sunset'];
    if (rise is! int || set is! int || rise <= 0 || set <= rise) continue;
    final r = DateTime.fromMillisecondsSinceEpoch(rise),
        s = DateTime.fromMillisecondsSinceEpoch(set);
    if (r.year == now.year && r.month == now.month && r.day == now.day) {
      sunrise = r;
      sunset = s;
      break;
    }
  }
  const twilight = Duration(minutes: 40);
  if (now.isBefore(sunrise.subtract(twilight)) ||
      !now.isBefore(sunset.add(twilight))) {
    return LandscapePhase.night;
  }
  if (now.isBefore(sunrise.add(twilight))) return LandscapePhase.dawn;
  if (!now.isBefore(sunset.subtract(twilight))) return LandscapePhase.dusk;
  return LandscapePhase.day;
}
