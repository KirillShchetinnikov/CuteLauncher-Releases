import 'dart:convert';

import 'package:flutter/material.dart';

enum WeatherWarningType { none, rain, snow, storm }

enum WeatherCondition {
  unknown(Icons.cloud_outlined),
  sun(Icons.wb_sunny_outlined),
  moon(Icons.nightlight_outlined),
  partlyCloudy(Icons.wb_cloudy_outlined),
  cloudy(Icons.cloud_outlined),
  rain(Icons.grain_outlined),
  snow(Icons.ac_unit_outlined),
  storm(Icons.flash_on_outlined),
  fog(Icons.waves_outlined),
  wind(Icons.air_outlined);

  const WeatherCondition(this.standardIcon);
  final IconData standardIcon;
}

class WeatherForecastItem {
  /// Calendar date in the forecast's time zone, without a time component.
  final DateTime? date;
  final int? minTemp;
  final int? maxTemp;
  final int? conditionCode;
  final int? humidity;
  final int? precipProbability;

  const WeatherForecastItem({
    this.date,
    this.minTemp,
    this.maxTemp,
    this.conditionCode,
    this.humidity,
    this.precipProbability,
  });

  factory WeatherForecastItem.fromJson(
    Map<String, dynamic> json, {
    DateTime? fallbackDate,
  }) {
    return WeatherForecastItem(
      date: json['date'] == null
          ? fallbackDate
          : parseWeatherDate(json['date']),
      minTemp: WeatherData.parseTemperature(json['minTemp']),
      maxTemp: WeatherData.parseTemperature(json['maxTemp']),
      conditionCode: json['conditionCode'] as int?,
      humidity: json['humidity'] as int?,
      precipProbability: json['precipProbability'] as int?,
    );
  }
}

class WeatherData {
  /// Null means the source uses the TV's local calendar (Breezy / MET Norway).
  final int? utcOffsetSeconds;
  final double? latitude, longitude;
  final String? timezone;
  final int? timestamp;
  final String? location;
  final String? source;
  final bool? isDay;
  final int? currentTemp;
  final int? feelsLikeTemp;
  final int? currentConditionCode;
  final String? currentCondition;
  final int? currentHumidity;
  final double? windSpeed;
  final int? todayMaxTemp;
  final int? todayMinTemp;
  final List<WeatherForecastItem> forecasts;

  // Computed warning attributes
  final bool hasWarning;
  final WeatherWarningType warningType;
  final String? warningText;
  final int? warningConditionCode;
  final int? warningPrecipProbability;
  final int? warningDayIndex; // 0 = today, 1 = tomorrow, 2+ = upcoming days

  const WeatherData({
    this.utcOffsetSeconds,
    this.latitude,
    this.longitude,
    this.timezone,
    this.timestamp,
    this.location,
    this.source,
    this.isDay,
    this.currentTemp,
    this.feelsLikeTemp,
    this.currentConditionCode,
    this.currentCondition,
    this.currentHumidity,
    this.windSpeed,
    this.todayMaxTemp,
    this.todayMinTemp,
    this.forecasts = const [],
    this.hasWarning = false,
    this.warningType = WeatherWarningType.none,
    this.warningText,
    this.warningConditionCode,
    this.warningPrecipProbability,
    this.warningDayIndex,
  });

  static const rainCodes = {500, 501, 502, 503, 504, 511, 520, 521, 522, 531};
  static const snowCodes = {600, 601, 602, 611, 612, 615, 616, 620, 621, 622};
  static const stormCodes = {200, 201, 202, 210, 211, 212, 221, 230, 231, 232};

  static double? _coordinate(Object? value, int limit) =>
      value is num && value.isFinite && value.abs() <= limit
          ? value.toDouble()
          : null;

  factory WeatherData.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return WeatherData.fromJson(json);
  }

  static int? parseTemperature(dynamic val) {
    if (val == null) return null;
    num? n;
    if (val is num) {
      n = val;
    } else if (val is String) {
      n = num.tryParse(val);
    }
    if (n == null || !n.isFinite) return null;
    // Gadgetbridge / Breezy Weather WeatherSpec sends temperatures in Kelvin (e.g., 300K for ~27°C).
    // If value > 100, treat as Kelvin and convert to Celsius.
    if (n > 100) {
      return (n - 273.15).round();
    }
    return n.round();
  }

  factory WeatherData.fromJson(
    Map<String, dynamic> json, {
    DateTime? referenceTime,
  }) {
    final offset = json['utcOffsetSeconds'] is int
        ? json['utcOffsetSeconds'] as int
        : null;
    final timestamp = json['timestamp'] as int?;
    final origin = timestamp == null
        ? (referenceTime ?? DateTime.now())
        : DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: true);
    final base = weatherCalendarDay(origin, offset);
    final List<dynamic>? rawForecasts = json['forecasts'] as List<dynamic>?;
    final List<WeatherForecastItem> forecasts = rawForecasts != null
        ? [
            for (var i = 0; i < rawForecasts.length; i++)
              WeatherForecastItem.fromJson(
                rawForecasts[i] is Map<String, dynamic>
                    ? rawForecasts[i] as Map<String, dynamic>
                    : {},
                fallbackDate: DateTime(base.year, base.month, base.day + i),
              ),
          ]
        : [];

    bool hasWarning = false;
    WeatherWarningType warningType = WeatherWarningType.none;
    String? warningText;
    int? warningConditionCode;
    int? warningPrecipProbability;
    int? warningDayIndex;

    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();

    for (int i = 0; i < forecasts.length && i < 7; i++) {
      final f = forecasts[i];
      final code = f.conditionCode;
      if (code == null) continue;

      if (rainCodes.contains(code) ||
          snowCodes.contains(code) ||
          stormCodes.contains(code)) {
        hasWarning = true;
        warningConditionCode = code;
        warningPrecipProbability = f.precipProbability;
        warningDayIndex = i;

        String dayText;
        if (i == 0) {
          dayText = "today";
        } else if (i == 1) {
          dayText = "tomorrow";
        } else {
          final targetDate = now.add(Duration(days: i));
          dayText = "on ${dayNames[targetDate.weekday - 1]}";
        }

        final precipString =
            (f.precipProbability != null && f.precipProbability! > 0)
            ? "${f.precipProbability}% "
            : "";

        if (rainCodes.contains(code)) {
          warningType = WeatherWarningType.rain;
          warningText = "${precipString}Rain $dayText";
        } else if (snowCodes.contains(code)) {
          warningType = WeatherWarningType.snow;
          warningText = "${precipString}Snow $dayText";
        } else {
          warningType = WeatherWarningType.storm;
          warningText = "${precipString}Storm $dayText";
        }
        break;
      }
    }

    return WeatherData(
      utcOffsetSeconds: offset,
      latitude: _coordinate(json['latitude'], 90),
      longitude: _coordinate(json['longitude'], 180),
      timezone: json['timezone'] is String ? json['timezone'] as String : null,
      timestamp: json['timestamp'] as int?,
      location: json['location'] as String?,
      source: json['source'] is String ? json['source'] as String : null,
      isDay: json['isDay'] is bool ? json['isDay'] as bool : null,
      currentTemp: parseTemperature(json['currentTemp']),
      feelsLikeTemp: parseTemperature(json['feelsLikeTemp']),
      currentConditionCode: json['currentConditionCode'] as int?,
      currentCondition: json['currentCondition'] as String?,
      currentHumidity: json['currentHumidity'] as int?,
      windSpeed: (json['windSpeed'] is num)
          ? (json['windSpeed'] as num).toDouble()
          : null,
      todayMaxTemp: parseTemperature(json['todayMaxTemp']),
      todayMinTemp: parseTemperature(json['todayMinTemp']),
      forecasts: forecasts,
      hasWarning: hasWarning,
      warningType: warningType,
      warningText: warningText,
      warningConditionCode: warningConditionCode,
      warningPrecipProbability: warningPrecipProbability,
      warningDayIndex: warningDayIndex,
    );
  }

  /// The requested calendar horizon, including today; expired days are omitted.
  List<WeatherForecastItem> forecastDays(DateTime now, int count) {
    final today = weatherCalendarDay(now, utcOffsetSeconds);
    final end = DateTime(today.year, today.month, today.day + count);
    final result = forecasts
        .where(
          (item) =>
              item.date != null &&
              !item.date!.isBefore(today) &&
              item.date!.isBefore(end),
        )
        .toList();
    result.sort((a, b) => a.date!.compareTo(b.date!));
    return result;
  }

  IconData getConditionIcon({bool isWarning = false}) =>
      getCondition(isWarning: isWarning).standardIcon;

  WeatherCondition getCondition({bool isWarning = false}) {
    final code = isWarning
        ? (warningConditionCode ?? currentConditionCode)
        : currentConditionCode;
    if (code == null) return WeatherCondition.unknown;

    if (code == 800) {
      var daylight = isDay;
      if (daylight == null && timestamp != null && utcOffsetSeconds != null) {
        // Match the landscape's approximate hours when daylight is unknown.
        final hour = DateTime.fromMillisecondsSinceEpoch(
          (timestamp! + utcOffsetSeconds!) * 1000,
          isUtc: true,
        ).hour;
        daylight = hour >= 6 && hour < 18;
      }
      return daylight == false ? WeatherCondition.moon : WeatherCondition.sun;
    }
    if (code == 801 || code == 802) return WeatherCondition.partlyCloudy;
    if (code == 803 || code == 804) return WeatherCondition.cloudy;
    if (rainCodes.contains(code)) return WeatherCondition.rain;
    if (snowCodes.contains(code)) return WeatherCondition.snow;
    if (stormCodes.contains(code)) return WeatherCondition.storm;
    if (code == 741 ||
        code == 701 ||
        code == 711 ||
        code == 721 ||
        code == 751) {
      return WeatherCondition.fog;
    }
    if (code == 771) return WeatherCondition.wind;

    return WeatherCondition.unknown;
  }

  String formatTemperature({bool useFahrenheit = false}) {
    final value = currentTemp;
    return value == null
        ? '--°'
        : formatDegrees(value, useFahrenheit: useFahrenheit);
  }

  static String formatDegrees(int celsius, {required bool useFahrenheit}) =>
      useFahrenheit ? '${(celsius * 9 / 5 + 32).round()}°F' : '$celsius°C';
}

DateTime weatherCalendarDay(DateTime instant, int? utcOffsetSeconds) {
  final local = utcOffsetSeconds == null
      ? instant.toLocal()
      : instant.toUtc().add(Duration(seconds: utcOffsetSeconds));
  return DateTime(local.year, local.month, local.day);
}

String weatherDateString(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

DateTime? parseWeatherDate(dynamic value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final date = DateTime.tryParse(value);
  return date != null && weatherDateString(date) == value ? date : null;
}
