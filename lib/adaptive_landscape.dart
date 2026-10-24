import 'dart:convert';
import 'dart:math' as math;

import 'models/weather_data.dart';

const landscapeSettingsKey = 'wallpaper_landscape';

class LandscapeConfiguration {
  final String variant;
  final bool timeOfDay,
      seasons,
      clouds,
      precipitation,
      fog,
      motion,
      celestialBodies,
      starRotation;
  final String hemisphere;
  const LandscapeConfiguration({
    this.variant = 'illustrated',
    this.timeOfDay = true,
    this.seasons = true,
    this.clouds = true,
    this.precipitation = true,
    this.fog = true,
    this.motion = false,
    this.celestialBodies = true,
    this.starRotation = false,
    this.hemisphere = 'auto',
  });

  /// Preview all moving effects without rewriting the user's normal configuration.
  LandscapeConfiguration forDemo() => LandscapeConfiguration(
    variant: variant,
    hemisphere: hemisphere,
    celestialBodies: celestialBodies,
    motion: true,
    starRotation: true,
  );

  Map<String, dynamic> toJson() => {
    'variant': variant,
    'timeOfDay': timeOfDay,
    'seasons': seasons,
    'clouds': clouds,
    'precipitation': precipitation,
    'fog': fog,
    'motion': motion,
    'celestialBodies': celestialBodies,
    'starRotation': starRotation,
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
      celestialBodies: flag('celestialBodies', true),
      starRotation: flag('starRotation', false),
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

enum LandscapePhase { dawn, day, dusk, twilight, night }

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
      !now.isBefore(sunset.add(twilight * 2))) {
    return LandscapePhase.night;
  }
  if (!now.isBefore(sunset.add(twilight))) return LandscapePhase.twilight;
  if (now.isBefore(sunrise.add(twilight))) return LandscapePhase.dawn;
  if (!now.isBefore(sunset.subtract(twilight))) return LandscapePhase.dusk;
  return LandscapePhase.day;
}

/// Adjacent lighting keyframes. Reuses today's sun cache without network work.
class LandscapeLight {
  final LandscapePhase from, to;
  final double mix;
  const LandscapeLight(this.from, this.to, this.mix);
}

LandscapeLight landscapeLight(
  DateTime now,
  LandscapeConfiguration config, {
  List<Map<String, dynamic>> solarDays = const [],
}) {
  if (!config.timeOfDay) {
    return const LandscapeLight(LandscapePhase.day, LandscapePhase.day, 0);
  }
  final points = landscapeLightKeyframes(now, solarDays: solarDays);
  const phases = [
    LandscapePhase.night,
    LandscapePhase.dawn,
    LandscapePhase.day,
    LandscapePhase.day,
    LandscapePhase.dusk,
    LandscapePhase.twilight,
    LandscapePhase.night,
  ];
  final t = now.millisecondsSinceEpoch;
  for (var i = 0; i < points.length - 1; i++) {
    if (t >= points[i] && t < points[i + 1]) {
      return LandscapeLight(
        phases[i],
        phases[i + 1],
        (t - points[i]) / (points[i + 1] - points[i]),
      );
    }
  }
  return const LandscapeLight(LandscapePhase.night, LandscapePhase.night, 0);
}

/// Shared sun keyframes for scene lighting and the accelerated preview clock.
List<int> landscapeLightKeyframes(
  DateTime now, {
  List<Map<String, dynamic>> solarDays = const [],
}) {
  var rise = DateTime(now.year, now.month, now.day, 6);
  var set = DateTime(now.year, now.month, now.day, 18);
  for (final day in solarDays) {
    final r = day['sunrise'], s = day['sunset'];
    if (r is! int || s is! int || r <= 0 || s <= r) continue;
    final candidate = DateTime.fromMillisecondsSinceEpoch(r);
    if (candidate.year == now.year &&
        candidate.month == now.month &&
        candidate.day == now.day) {
      rise = candidate;
      set = DateTime.fromMillisecondsSinceEpoch(s);
      break;
    }
  }
  // Clamp twilight to a quarter of daylight so even very short days stay ordered.
  final span = (set.difference(rise).inMilliseconds / 4)
      .clamp(1, const Duration(minutes: 40).inMilliseconds)
      .round();
  return [
    rise.millisecondsSinceEpoch - span,
    rise.millisecondsSinceEpoch,
    rise.millisecondsSinceEpoch + span,
    set.millisecondsSinceEpoch - span,
    set.millisecondsSinceEpoch,
    set.millisecondsSinceEpoch + span,
    set.millisecondsSinceEpoch + span * 2,
  ];
}

/// Colored glow has its own short window, separate from ambient day/night light.
class LandscapeGlow {
  final double strength;
  final bool sunrise;
  const LandscapeGlow(this.strength, {required this.sunrise});
  static const none = LandscapeGlow(0, sunrise: true);
  static const sunriseBefore = 10,
      sunriseAfter = 60,
      sunsetBefore = 60,
      sunsetAfter = 10;

  static List<(int, int)> windows(
    DateTime day, {
    List<Map<String, dynamic>> solarDays = const [],
  }) {
    final sun = landscapeLightKeyframes(day, solarDays: solarDays);
    const minute = Duration.millisecondsPerMinute;
    return [
      (sun[1] - sunriseBefore * minute, sun[1] + sunriseAfter * minute),
      (sun[4] - sunsetBefore * minute, sun[4] + sunsetAfter * minute),
    ];
  }

  factory LandscapeGlow.at(
    DateTime now,
    LandscapeConfiguration config, {
    List<Map<String, dynamic>> solarDays = const [],
  }) {
    if (!config.timeOfDay) return none;
    final sun = landscapeLightKeyframes(now, solarDays: solarDays);
    double intensity(int event, int before, int after) {
      final minutes =
          (now.millisecondsSinceEpoch - event) / Duration.millisecondsPerMinute;
      if (minutes <= -before || minutes >= after) return 0;
      final t = minutes < 0
          ? (minutes + before) / before
          : (after - minutes) / after;
      return t * t * (3 - 2 * t);
    }

    final dawn = intensity(sun[1], sunriseBefore, sunriseAfter),
        dusk = intensity(sun[4], sunsetBefore, sunsetAfter);
    return LandscapeGlow(math.max(dawn, dusk), sunrise: dawn >= dusk);
  }
}

/// Slow decorative rotation: one full turn per local day.
double landscapeStarAngle(DateTime now, LandscapeConfiguration config) {
  if (!config.starRotation) return 0;
  final midnight = DateTime(now.year, now.month, now.day);
  return now.difference(midnight).inMilliseconds /
      Duration.millisecondsPerDay *
      (math.pi * 2);
}

/// Decorative sun/day and moon/night arcs, using the same cached sun schedule.
class LandscapeCelestialState {
  final double sunProgress, moonProgress, sunWarmth;
  const LandscapeCelestialState(
    this.sunProgress,
    this.moonProgress, {
    this.sunWarmth = 0,
  });

  factory LandscapeCelestialState.at(
    DateTime now,
    LandscapeConfiguration config, {
    List<Map<String, dynamic>> solarDays = const [],
  }) {
    if (!config.timeOfDay) return const LandscapeCelestialState(.5, 2);
    final points = landscapeLightKeyframes(now, solarDays: solarDays);
    final rise = points[1], set = points[4];
    final day = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).difference(DateTime(now.year, now.month, now.day)).inMilliseconds;
    final daylight = set - rise;
    final night = day - daylight;
    final time = now.millisecondsSinceEpoch;
    double smooth(double value) {
      final t = value.clamp(0.0, 1.0);
      return t * t * (3 - 2 * t);
    }

    // The horizon geometry places the first/last disc pixel at these solar events.
    // Keep it red throughout emergence, independently of the sky glow.
    final sinceRise = (time - rise) / Duration.millisecondsPerMinute;
    final untilSet = (set - time) / Duration.millisecondsPerMinute;
    final morning = smooth(1 - sinceRise / 40);
    final eveningProgress = ((40 - untilSet) / 20).clamp(0.0, 1.0);
    final evening = 1 - math.pow(1 - eveningProgress, 3).toDouble();
    return LandscapeCelestialState(
      (time - rise) / daylight,
      night > 0 ? ((time - set) % day) / night : 2,
      sunWarmth: math.max(morning, evening),
    );
  }
}

/// A complete sun cycle, rotated to start at the current instant.
class LandscapeDemoTimeline {
  final DateTime start;
  final List<Map<String, dynamic>> solarDays;
  late final DateTime _midnight = DateTime(start.year, start.month, start.day);
  late final int _daySpan = DateTime(
    start.year,
    start.month,
    start.day + 1,
  ).difference(_midnight).inMilliseconds;
  late final List<(int, int)> _points = _buildPoints();
  Duration get dayDuration => Duration(milliseconds: _points.last.$1);
  late final double _offset = _position(
    start.difference(_midnight).inMilliseconds,
  );

  LandscapeDemoTimeline(
    this.start, {
    List<Map<String, dynamic>> solarDays = const [],
  }) : solarDays = _snapshotSun(start, solarDays);

  static List<Map<String, dynamic>> _snapshotSun(
    DateTime start,
    List<Map<String, dynamic>> source,
  ) {
    final points = landscapeLightKeyframes(start, solarDays: source);
    final rise = DateTime.fromMillisecondsSinceEpoch(points[1]);
    final set = DateTime.fromMillisecondsSinceEpoch(points[4]);
    final midnight = DateTime(start.year, start.month, start.day);
    final sunsetDay = DateTime(
      set.year,
      set.month,
      set.day,
    ).difference(midnight).inDays;
    // Repeat the captured schedule after midnight, rather than silently switching to fallback sun times.
    return List.unmodifiable(
      List.generate(
        2,
        (day) => Map<String, dynamic>.unmodifiable({
          'sunrise': DateTime(
            start.year,
            start.month,
            start.day + day,
            rise.hour,
            rise.minute,
            rise.second,
            rise.millisecond,
          ).millisecondsSinceEpoch,
          'sunset': DateTime(
            start.year,
            start.month,
            start.day + day + sunsetDay,
            set.hour,
            set.minute,
            set.second,
            set.millisecond,
          ).millisecondsSinceEpoch,
        }),
      ),
    );
  }

  List<(int, int)> _buildPoints() {
    final sun = landscapeLightKeyframes(start, solarDays: solarDays);
    final windows = LandscapeGlow.windows(start, solarDays: solarDays)
        .map(
          (w) => (
            w.$1 - _midnight.millisecondsSinceEpoch,
            w.$2 - _midnight.millisecondsSinceEpoch,
          ),
        )
        .toList();
    final points = <int>{
      0,
      _daySpan,
      for (final w in windows) ...[
        w.$1.clamp(0, _daySpan),
        w.$2.clamp(0, _daySpan),
      ],
      for (final event in [sun[1], sun[4]])
        (event - _midnight.millisecondsSinceEpoch).clamp(0, _daySpan),
    }.toList()..sort();
    final result = <(int, int)>[(0, 0)];
    var elapsed = 0.0;
    for (var i = 1; i < points.length; i++) {
      final from = points[i - 1], to = points[i];
      final middle = (from + to) / 2;
      final slow = windows.any((w) => middle >= w.$1 && middle < w.$2);
      elapsed += (to - from) / (slow ? 900 : 10800);
      result.add((math.max(result.last.$1 + 1, elapsed.round()), to));
    }
    return result;
  }

  double _position(int simulated) {
    for (var i = 1; i < _points.length; i++) {
      final (end, to) = _points[i];
      if (simulated <= to) {
        final (begin, from) = _points[i - 1];
        return begin + (simulated - from) * (end - begin) / (to - from);
      }
    }
    return dayDuration.inMilliseconds.toDouble();
  }

  DateTime at(Duration elapsed) {
    if (elapsed == Duration.zero) return start;
    final full = _offset + elapsed.inMilliseconds;
    final duration = dayDuration.inMilliseconds;
    final wraps = (full / duration).floor();
    final position = full % duration;
    for (var i = 1; i < _points.length; i++) {
      final (end, to) = _points[i];
      if (position < end) {
        final (begin, from) = _points[i - 1];
        final simulated =
            from + ((position - begin) * (to - from) / (end - begin)).round();
        return _midnight.add(
          Duration(milliseconds: wraps * _daySpan + simulated),
        );
      }
    }
    return start;
  }
}

/// A complete day, then summer/clouds, autumn/rain, winter/snow, spring/fog.
class LandscapeDemoFrame {
  static const dayDuration = Duration(milliseconds: 16556);
  static const stateDuration = Duration(seconds: 5);
  static const clearDuration = Duration(seconds: 2);
  static const weatherStart = Duration(milliseconds: 18556);
  static const cycleDuration = Duration(milliseconds: 36556);
  static const seasons = [
    LandscapeSeason.summer,
    LandscapeSeason.autumn,
    LandscapeSeason.winter,
    LandscapeSeason.spring,
  ];
  static const effects = [
    LandscapeWeather.cloudy,
    LandscapeWeather.rain,
    LandscapeWeather.snow,
    LandscapeWeather.fog,
  ];
  final Duration elapsed;
  final DateTime _start;
  final LandscapeDemoTimeline timeline;
  Duration get weatherOffset => timeline.dayDuration + clearDuration;
  Duration get totalDuration =>
      timeline.dayDuration + const Duration(seconds: 20);
  bool get isComplete => elapsed >= totalDuration;
  int get _milliseconds =>
      elapsed.inMilliseconds.clamp(0, totalDuration.inMilliseconds - 1);
  int get _stageTime => _milliseconds - timeline.dayDuration.inMilliseconds;
  int get _stage => (_stageTime ~/ stateDuration.inMilliseconds).clamp(0, 3);
  double get progress =>
      (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0, 1);
  bool get showingTime => _milliseconds < timeline.dayDuration.inMilliseconds;
  bool get showingSeasons =>
      !showingTime &&
      _stageTime % stateDuration.inMilliseconds < clearDuration.inMilliseconds;
  DateTime get now => showingTime
      ? timeline.at(Duration(milliseconds: _milliseconds))
      : DateTime(_start.year, _start.month, _start.day, 12);
  LandscapeSeason? get season => showingTime ? null : seasons[_stage];
  LandscapeWeather get weather =>
      showingTime || showingSeasons ? LandscapeWeather.clear : effects[_stage];
  LandscapeDemoFrame(
    this.elapsed,
    this._start, {
    LandscapeDemoTimeline? timeline,
  }) : timeline = timeline ?? LandscapeDemoTimeline(_start);
}
