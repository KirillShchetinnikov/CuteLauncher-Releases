import 'adaptive_landscape.dart';
import 'location_coordinates.dart';
import 'providers/night_mode_service.dart';
import 'providers/weather_service.dart';
import 'weather_sources.dart';

LocationCoordinates? landscapeCoordinates(
  NightModeConfiguration? night,
  WeatherService? weather,
) {
  final configuration = weather?.configuration;
  final weatherPoint = configuration?.source == WeatherSource.customOpenMeteo
      ? coordinatesFrom(
          weather?.weatherData?.latitude,
          weather?.weatherData?.longitude,
        )
      : configuration?.selectedCoordinates;
  return weatherPoint ?? coordinatesFrom(night?.latitude, night?.longitude);
}

typedef LandscapeScheduleData = ({
  List<Map<String, dynamic>> days,
  String source,
});

/// Resolves the same schedule for the live scene, demo and private report.
LandscapeScheduleData resolveLandscapeSchedule(
  DateTime now,
  LandscapeConfiguration config,
  NightModeService? night,
  WeatherService? weather, {
  bool request = false,
}) {
  if (config.schedule == LandscapeSchedule.nightMode && night != null) {
    final intervals = night.configuration.intervals(
      now,
      solarDays: night.solarDays,
    )..sort((a, b) => a.$1.compareTo(b.$1));
    final days = [
      for (var i = 1; i < intervals.length; i++)
        if (intervals[i - 1].$2.isBefore(intervals[i].$1))
          _day(intervals[i - 1].$2, intervals[i].$1),
    ];
    if (landscapeSunTimes(now, days).usesSchedule) {
      return (days: days, source: 'nightModeSchedule');
    }
  }
  if (config.schedule == LandscapeSchedule.auto && night != null) {
    final point = landscapeCoordinates(night.configuration, weather);
    if (point != null) {
      final days = night.landscapeSolarDays(now, point, request: request);
      if (landscapeSunTimes(now, days).usesSchedule) {
        return (days: days, source: 'localSolar');
      }
    }
  }
  return (
    days: [
      for (var offset = -1; offset <= 1; offset++)
        _day(
          _at(now, offset, config.sunriseMinute),
          _at(
            now,
            offset + (config.sunsetMinute < config.sunriseMinute ? 1 : 0),
            config.sunsetMinute,
          ),
        ),
    ],
    source: config.schedule == LandscapeSchedule.manual
        ? 'manual'
        : 'manualFallback',
  );
}

Map<String, dynamic> _day(DateTime sunrise, DateTime sunset) => {
  'sunrise': sunrise.millisecondsSinceEpoch,
  'sunset': sunset.millisecondsSinceEpoch,
};

DateTime _at(DateTime now, int offset, int minute) =>
    DateTime(now.year, now.month, now.day + offset, minute ~/ 60, minute % 60);
