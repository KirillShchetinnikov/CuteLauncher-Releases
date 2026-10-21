import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/painting.dart';

class NightModeConfiguration {
  final bool enabled, scheduled, solar, tclScheduled, automaticLocation;
  final bool ignoreHdmiInputs, selectHdmiInputs;
  final List<String> ignoredHdmiInputIds;
  final List<int> ignoredPictureModes;
  final int transitionMinutes;
  final int startHour,
      endHour,
      startMinute,
      endMinute,
      dim,
      warmth,
      temperature;
  final int sunsetOffset, sunriseOffset, overrideUntil, tclOverrideUntil;
  final String city, overrideMode, tclOverrideMode;
  final double? latitude, longitude;
  final List<String> excludedPackages;
  const NightModeConfiguration(
      {this.excludedPackages = const [],
      this.ignoreHdmiInputs = true,
      this.selectHdmiInputs = false,
      this.ignoredHdmiInputIds = const [],
      this.ignoredPictureModes = const [],
      this.enabled = false,
      this.scheduled = false,
      this.startHour = 22,
      this.endHour = 7,
      this.startMinute = 0,
      this.endMinute = 0,
      this.dim = 30,
      this.warmth = 10,
      this.temperature = 2700,
      this.solar = false,
      this.tclScheduled = true,
      this.automaticLocation = false,
      this.transitionMinutes = 60,
      this.city = '',
      this.latitude,
      this.longitude,
      this.sunsetOffset = 0,
      this.sunriseOffset = 0,
      this.overrideMode = 'none',
      this.overrideUntil = 0,
      this.tclOverrideMode = 'none',
      this.tclOverrideUntil = 0});

  NightModeConfiguration copyWith(
          {List<String>? excludedPackages,
          bool? ignoreHdmiInputs,
          bool? selectHdmiInputs,
          List<String>? ignoredHdmiInputIds,
          List<int>? ignoredPictureModes,
          bool? enabled,
          bool? scheduled,
          bool? solar,
          bool? tclScheduled,
          bool? automaticLocation,
          int? transitionMinutes,
          int? startHour,
          int? endHour,
          int? startMinute,
          int? endMinute,
          int? dim,
          int? warmth,
          int? temperature,
          int? sunsetOffset,
          int? sunriseOffset,
          String? city,
          double? latitude,
          double? longitude,
          String? overrideMode,
          int? overrideUntil,
          String? tclOverrideMode,
          int? tclOverrideUntil,
          bool clearOverrides = false}) =>
      NightModeConfiguration(
          excludedPackages: excludedPackages ?? this.excludedPackages,
          ignoreHdmiInputs: ignoreHdmiInputs ?? this.ignoreHdmiInputs,
          selectHdmiInputs: selectHdmiInputs ?? this.selectHdmiInputs,
          ignoredHdmiInputIds: ignoredHdmiInputIds ?? this.ignoredHdmiInputIds,
          ignoredPictureModes: ignoredPictureModes ?? this.ignoredPictureModes,
          enabled: enabled ?? this.enabled,
          scheduled: scheduled ?? this.scheduled,
          solar: solar ?? this.solar,
          tclScheduled: tclScheduled ?? this.tclScheduled,
          automaticLocation: automaticLocation ?? this.automaticLocation,
          transitionMinutes: transitionMinutes ?? this.transitionMinutes,
          startHour: startHour ?? this.startHour,
          endHour: endHour ?? this.endHour,
          startMinute: startMinute ?? this.startMinute,
          endMinute: endMinute ?? this.endMinute,
          dim: dim ?? this.dim,
          warmth: warmth ?? this.warmth,
          temperature: temperature ?? this.temperature,
          sunsetOffset: sunsetOffset ?? this.sunsetOffset,
          sunriseOffset: sunriseOffset ?? this.sunriseOffset,
          city: city ?? this.city,
          latitude: latitude ?? this.latitude,
          longitude: longitude ?? this.longitude,
          overrideMode:
              clearOverrides ? 'none' : overrideMode ?? this.overrideMode,
          overrideUntil:
              clearOverrides ? 0 : overrideUntil ?? this.overrideUntil,
          tclOverrideMode:
              clearOverrides ? 'none' : tclOverrideMode ?? this.tclOverrideMode,
          tclOverrideUntil:
              clearOverrides ? 0 : tclOverrideUntil ?? this.tclOverrideUntil);

  Map<String, dynamic> toJson() => {
        'excludedPackages': excludedPackages,
        'ignoreHdmiInputs': ignoreHdmiInputs,
        'selectHdmiInputs': selectHdmiInputs,
        'ignoredHdmiInputIds': ignoredHdmiInputIds,
        'ignoredPictureModes': ignoredPictureModes,
        'enabled': enabled,
        'scheduled': scheduled,
        'startHour': startHour,
        'endHour': endHour,
        'startMinute': startMinute,
        'endMinute': endMinute,
        'dim': dim,
        'warmth': warmth,
        'temperature': temperature,
        'solar': solar,
        'tclScheduled': tclScheduled,
        'automaticLocation': automaticLocation,
        'transitionMinutes': transitionMinutes,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'sunsetOffset': sunsetOffset,
        'sunriseOffset': sunriseOffset,
        'overrideMode': overrideMode,
        'overrideUntil': overrideUntil,
        'tclOverrideMode': tclOverrideMode,
        'tclOverrideUntil': tclOverrideUntil
      };

  static NightModeConfiguration parse(Map map) {
    int integer(String key, int fallback, int min, int max) {
      final value = map[key] ?? fallback;
      if (value is! int || value < min || value > max) {
        throw const FormatException();
      }
      return value;
    }

    bool boolean(String key, bool fallback) {
      final value = map[key] ?? fallback;
      if (value is! bool) throw const FormatException();
      return value;
    }

    String mode(String key) {
      final value = map[key] ?? 'none';
      if (!['none', 'on', 'off'].contains(value)) throw const FormatException();
      return value as String;
    }

    double? coordinate(String key, int limit) {
      final value = map[key];
      if (value == null) return null;
      if (value is! num || !value.isFinite || value.abs() > limit) {
        throw const FormatException();
      }
      return value.toDouble();
    }

    final ignoredInputs = map['ignoredHdmiInputIds'] ?? <String>[];
    if (ignoredInputs is! List || ignoredInputs.length > 128 || ignoredInputs.any(
      (id) => id is! String || id.isEmpty || id.length > 512)) { throw const FormatException(); }
    final pictureModes = map['ignoredPictureModes'] ?? <int>[];
    if (pictureModes is! List || pictureModes.length > 128 ||
        pictureModes.any((v) => v is! int || v < 0 || v > 255)) {
      throw const FormatException();
    }
    final excluded = map['excludedPackages'] ?? <String>[];
    if (excluded is! List ||
        excluded.length > 128 ||
        excluded.any(
          (p) =>
              p is! String ||
              p.length > 255 ||
              !RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$')
                  .hasMatch(p),
        )) {
      throw const FormatException();
    }
    final city = map['city'] ?? '';
    if (city is! String || city.length > 200) throw const FormatException();
    final lat = coordinate('latitude', 90), lon = coordinate('longitude', 180);
    final transition = integer('transitionMinutes', 60, 15, 120);
    if (transition % 15 != 0) throw const FormatException();
    if ((lat == null) != (lon == null)) throw const FormatException();
    if (map['enabled'] is! bool || map['scheduled'] is! bool) {
      throw const FormatException();
    }
    return NightModeConfiguration(
        excludedPackages: List.unmodifiable(excluded.cast<String>().toSet()),
        ignoredPictureModes: List.unmodifiable(pictureModes.cast<int>().toSet()),
        ignoreHdmiInputs: boolean('ignoreHdmiInputs', true),
        selectHdmiInputs: boolean('selectHdmiInputs', false),
        ignoredHdmiInputIds: List.unmodifiable(ignoredInputs.cast<String>().toSet()),
        enabled: map['enabled'],
        scheduled: map['scheduled'],
        startHour: integer('startHour', 22, 0, 23),
        endHour: integer('endHour', 7, 0, 23),
        startMinute: integer('startMinute', 0, 0, 59),
        endMinute: integer('endMinute', 0, 0, 59),
        dim: integer('dim', 30, 0, 95),
        warmth: integer('warmth', 10, 0, 90),
        temperature: integer('temperature', 2700, 1000, 6500),
        solar: boolean('solar', false),
        tclScheduled: boolean('tclScheduled', true),
        automaticLocation: boolean('automaticLocation', false),
        transitionMinutes: transition,
        city: city,
        latitude: lat,
        longitude: lon,
        // Preserve legacy configurations, limiting their offsets to the new range.
        sunsetOffset: integer('sunsetOffset', 0, -360, 360).clamp(-180, 180),
        sunriseOffset: integer('sunriseOffset', 0, -360, 360).clamp(-180, 180),
        overrideMode: mode('overrideMode'),
        overrideUntil: integer('overrideUntil', 0, 0, 4102444800000),
        tclOverrideMode: mode('tclOverrideMode'),
        tclOverrideUntil: integer('tclOverrideUntil', 0, 0, 4102444800000));
  }

  static NightModeConfiguration decode(String? value) {
    try {
      return parse(jsonDecode(value ?? '') as Map);
    } catch (_) {
      return const NightModeConfiguration();
    }
  }

  List<(DateTime, DateTime)> intervals(DateTime now,
      {List<Map<String, dynamic>> solarDays = const []}) {
    if (solar) {
      final result = <(DateTime, DateTime)>[];
      for (var i = 0; i + 1 < solarDays.length; i++) {
        final sunset = solarDays[i]['sunset'],
            sunrise = solarDays[i + 1]['sunrise'];
        if (sunset is! int || sunrise is! int || sunset <= 0 || sunrise <= 0) {
          continue;
        }
        final start = DateTime.fromMillisecondsSinceEpoch(sunset)
            .add(Duration(minutes: sunsetOffset));
        final end = DateTime.fromMillisecondsSinceEpoch(sunrise)
            .add(Duration(minutes: sunriseOffset));
        if (start.isBefore(end)) result.add((start, end));
      }
      return result;
    }
    if (startHour == endHour && startMinute == endMinute) return [];
    return [
      for (var offset = -1; offset <= 3; offset++)
        (() {
          final start = DateTime(
              now.year, now.month, now.day + offset, startHour, startMinute);
          var end = DateTime(
              now.year, now.month, now.day + offset, endHour, endMinute);
          if (!end.isAfter(start)) {
            end = DateTime(
                now.year, now.month, now.day + offset + 1, endHour, endMinute);
          }
          return (start, end);
        })()
    ];
  }

  DateTime? nextBoundary(DateTime now, bool start,
      {List<Map<String, dynamic>> solarDays = const [],
      bool skipStartedTransition = false}) {
    final times = intervals(now, solarDays: solarDays)
        // A night already being faded in must stay skipped until the next night.
        .where((i) =>
            !start ||
            !skipStartedTransition ||
            i.$1.subtract(Duration(minutes: transitionMinutes)).isAfter(now))
        .map((i) => start ? i.$1 : i.$2)
        .where((t) => t.isAfter(now))
        .toList()
      ..sort();
    return times.isEmpty ? null : times.first;
  }

  bool activeAt(
    DateTime time, {
    List<Map<String, dynamic>> solarDays = const [],
    bool tcl = false,
  }) {
    return intensityAt(time, solarDays: solarDays) > 0;
  }

  double intensityAt(
    DateTime time, {
    List<Map<String, dynamic>> solarDays = const [],
  }) {
    if (!enabled) return 0;
    if (!scheduled) return 1;
    if (overrideMode != 'none' && time.millisecondsSinceEpoch < overrideUntil) {
      return overrideMode == 'on' ? 1 : 0;
    }
    double intensity = 0;
    for (final interval in intervals(time, solarDays: solarDays)) {
      final ramp = interval.$1.subtract(Duration(minutes: transitionMinutes));
      if (!time.isBefore(ramp) && time.isBefore(interval.$2)) {
        final value =
            (time.difference(ramp).inMilliseconds /
                    Duration(minutes: transitionMinutes).inMilliseconds)
                .clamp(0.0, 1.0);
        final remaining =
            (interval.$2.difference(time).inMilliseconds /
                    Duration(minutes: transitionMinutes).inMilliseconds)
                .clamp(0.0, 1.0);
        intensity = math.max(intensity, math.min(value, remaining));
      }
    }
    return intensity;
  }

  Color get filterColor {
    final t = temperature / 100;
    int clamp(double v) => v.clamp(0, 255).round();
    return Color.fromARGB(
        255,
        255,
        clamp(99.4708025861 * math.log(t) - 161.1195681661),
        t <= 19
            ? 0
            : clamp(138.5177312231 * math.log(t - 10) - 305.0447927307));
  }
}
