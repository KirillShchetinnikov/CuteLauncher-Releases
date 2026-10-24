import 'dart:convert';

import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('demo is 1.5x faster and pairs two seconds of each season with three seconds of weather', () {
    final start = DateTime(2026, 10, 24);
    LandscapeDemoFrame at(int ms) =>
        LandscapeDemoFrame(Duration(milliseconds: ms), start);
    for (final (elapsed, hour, minute) in [
      (1944, 5, 50),
      (2611, 6, 0),
      (6611, 7, 0),
      (9944, 17, 0),
      (13944, 18, 0),
      (14611, 18, 10),
    ]) {
      expect(
        at(elapsed).now
            .difference(DateTime(2026, 10, 24, hour, minute))
            .inMilliseconds
            .abs(),
        lessThan(2),
      );
    }
    expect(at(1000).now.difference(start).inSeconds, closeTo(10800, 12));
    expect(
      at(7611).now.difference(at(6611).now).inSeconds,
      closeTo(10800, 12),
      reason: 'fast clock resumes at the end of dawn glow',
    );
    expect(
      at(15611).now.difference(at(14611).now).inSeconds,
      closeTo(10800, 12),
      reason: 'fast clock resumes at the end of sunset glow',
    );
    expect(
      at(6111).now.difference(at(5111).now).inSeconds,
      closeTo(900, 1),
      reason: 'last part of dawn glow stays slow',
    );
    expect(
      at(14511).now.difference(at(14011).now).inSeconds,
      closeTo(450, 1),
      reason: 'last part of sunset glow stays slow',
    );
    final dayEnd = at(0).timeline.dayDuration.inMilliseconds;
    expect(dayEnd, LandscapeDemoFrame.dayDuration.inMilliseconds);
    const pairs = [
      (LandscapeSeason.summer, LandscapeWeather.cloudy),
      (LandscapeSeason.autumn, LandscapeWeather.rain),
      (LandscapeSeason.winter, LandscapeWeather.snow),
      (LandscapeSeason.spring, LandscapeWeather.fog),
    ];
    for (var i = 0; i < 4; i++) {
      for (final offset in [0, 1999, 2000, 4999]) {
        final frame = at(dayEnd + i * 5000 + offset);
        expect(frame.season, pairs[i].$1);
        expect(
          frame.weather,
          offset < 2000 ? LandscapeWeather.clear : pairs[i].$2,
        );
        expect(frame.showingSeasons, offset < 2000);
        expect(frame.now.hour, 12);
      }
    }
    expect(at(dayEnd + 20000).isComplete, true);
    expect(at(dayEnd + 20000).progress, 1);
    expect(at(dayEnd + 20000).weather, LandscapeWeather.fog);
  });

  test('demo starts at the exact current time and makes one full day from every starting hour', () {
    for (final hour in [0, 5, 6, 9, 12, 17, 18, 19, 23]) {
      final start = DateTime(2026, 10, 24, hour, 28, 12, 345, 678);
      final timeline = LandscapeDemoTimeline(start);
      expect(timeline.at(Duration.zero), start);
      var previous = start;
      for (var ms = 100; ms < timeline.dayDuration.inMilliseconds; ms += 100) {
        final now = timeline.at(Duration(milliseconds: ms));
        expect(now.isAfter(previous), true);
        previous = now;
      }
      expect(
        timeline.at(timeline.dayDuration).difference(start).inMilliseconds,
        closeTo(Duration.millisecondsPerDay, 1),
      );
      final frame = LandscapeDemoFrame(
        Duration.zero,
        start,
        timeline: timeline,
      );
      expect(frame.now, start);
      expect(frame.isComplete, false);
      expect(
        LandscapeDemoFrame(
          frame.totalDuration,
          start,
          timeline: timeline,
        ).isComplete,
        true,
      );
    }
  });

  test('demo clock and first lighting match the cached local sun schedule across midnight', () {
    final start = DateTime(2026, 10, 24, 8, 15);
    final solarDays = [
      {
        'sunrise': DateTime(2026, 10, 24, 8).millisecondsSinceEpoch,
        'sunset': DateTime(2026, 10, 24, 17).millisecondsSinceEpoch,
      },
    ];
    final timeline = LandscapeDemoTimeline(start, solarDays: solarDays);
    const config = LandscapeConfiguration();
    final before = landscapeLight(start, config, solarDays: solarDays);
    final first = landscapeLight(
      timeline.at(Duration.zero),
      config,
      solarDays: timeline.solarDays,
    );
    expect(
      (first.from, first.to, first.mix),
      (before.from, before.to, before.mix),
    );
    // Sunrise is still slowed down at the start, rather than fast-forwarding a cached 08:00 sunrise.
    final later = timeline.at(const Duration(seconds: 1));
    expect(
      later.difference(start).inMicroseconds / Duration.microsecondsPerMinute,
      closeTo(15, .02),
    );
    expect(
      landscapeLight(
        DateTime(2026, 10, 25, 8),
        config,
        solarDays: timeline.solarDays,
      ).from,
      LandscapePhase.dawn,
    );
    solarDays.clear();
    expect(timeline.solarDays, hasLength(2));
  });

  test(
    'lighting is continuous through sunrise and sunset, also on short days',
    () {
      const config = LandscapeConfiguration();
      DateTime at(int h, [int m = 0, int second = 0]) =>
          DateTime(2026, 10, 23, h, m, second);
      final before = landscapeLight(
        at(6, 0, 0).subtract(const Duration(seconds: 1)),
        config,
      );
      final after = landscapeLight(at(6, 0, 1), config);
      expect(before.to, after.from);
      expect(before.mix, greaterThan(.999));
      expect(after.mix, lessThan(.001));
      expect(landscapeLight(at(17, 40), config).mix, closeTo(.5, .001));
      final short = landscapeLight(
        at(12, 5),
        config,
        solarDays: [
          {
            'sunrise': at(12).millisecondsSinceEpoch,
            'sunset': at(12, 10).millisecondsSinceEpoch,
          },
        ],
      );
      expect(short.from, LandscapePhase.day);
      expect(short.to, LandscapePhase.day);
      expect(
        landscapeLight(at(0), config.withValue('timeOfDay', false)).from,
        LandscapePhase.day,
      );
    },
  );
  test('seasons respect month, southern hemisphere and disabled effect', () {
    const c = LandscapeConfiguration();
    expect(landscapeSeason(DateTime(2026, 1), c), LandscapeSeason.winter);
    expect(landscapeSeason(DateTime(2026, 4), c), LandscapeSeason.spring);
    expect(landscapeSeason(DateTime(2026, 7), c), LandscapeSeason.summer);
    expect(landscapeSeason(DateTime(2026, 10), c), LandscapeSeason.autumn);
    expect(
      landscapeSeason(DateTime(2026, 1), c, latitude: -30),
      LandscapeSeason.summer,
    );
    expect(
      landscapeSeason(DateTime(2026, 7), c.withValue('hemisphere', 'south')),
      LandscapeSeason.winter,
    );
    expect(
      landscapeSeason(DateTime(2026, 1), c.withValue('seasons', false)),
      LandscapeSeason.summer,
    );
  });
  test('sun cache and fallback transition boundaries are deterministic', () {
    const c = LandscapeConfiguration();
    DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 21, h, m);
    expect(landscapePhase(at(5, 19), c), LandscapePhase.night);
    expect(landscapePhase(at(5, 20), c), LandscapePhase.dawn);
    expect(landscapePhase(at(6, 40), c), LandscapePhase.day);
    expect(landscapePhase(at(17, 20), c), LandscapePhase.dusk);
    expect(landscapePhase(at(18, 40), c), LandscapePhase.twilight);
    expect(landscapePhase(at(19, 20), c), LandscapePhase.night);
    final evening = landscapeLight(at(19), c);
    expect(evening.from, LandscapePhase.twilight);
    expect(evening.to, LandscapePhase.night);
    expect(evening.mix, closeTo(.5, .001));
    final days = [
      {
        'sunrise': at(8).millisecondsSinceEpoch,
        'sunset': at(16).millisecondsSinceEpoch,
      },
    ];
    expect(landscapePhase(at(7, 30), c, solarDays: days), LandscapePhase.dawn);
    expect(landscapePhase(at(16), c, solarDays: days), LandscapePhase.dusk);
    expect(
      landscapePhase(at(23), c.withValue('timeOfDay', false), solarDays: days),
      LandscapePhase.day,
    );
    expect(
      landscapePhase(DateTime(2026, 10, 22, 8), c, solarDays: days),
      LandscapePhase.day,
    );
  });
  test(
    'only current normalized weather drives effects, never forecast warnings',
    () {
      expect(landscapeWeather(null), LandscapeWeather.clear);
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 600)),
        LandscapeWeather.snow,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 211)),
        LandscapeWeather.rain,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 301)),
        LandscapeWeather.rain,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 741)),
        LandscapeWeather.fog,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 803)),
        LandscapeWeather.cloudy,
      );
      expect(
        landscapeWeather(
          const WeatherData(
            currentConditionCode: 800,
            hasWarning: true,
            warningType: WeatherWarningType.snow,
          ),
        ),
        LandscapeWeather.clear,
      );
    },
  );
  test('separate sun and moon arcs follow the cached day and night', () {
    final date = DateTime(2026, 10, 24);
    final days = [
      {
        'sunrise': DateTime(2026, 10, 24, 8).millisecondsSinceEpoch,
        'sunset': DateTime(2026, 10, 24, 16).millisecondsSinceEpoch,
      },
    ];
    LandscapeCelestialState at(int hour, [int minute = 0]) =>
        LandscapeCelestialState.at(
          date.add(Duration(hours: hour, minutes: minute)),
          const LandscapeConfiguration(),
          solarDays: days,
        );
    expect(at(8).sunProgress, 0);
    expect(at(12).sunProgress, .5);
    expect(at(16).sunProgress, 1);
    expect(at(0).moonProgress, .5);
    expect(at(12).moonProgress, greaterThan(1.12));
    expect(at(20).sunProgress, greaterThan(1.12));
    expect(at(23, 59).moonProgress, closeTo(at(0).moonProgress, .002));
    final fixed = LandscapeCelestialState.at(
      date,
      const LandscapeConfiguration(timeOfDay: false),
      solarDays: days,
    );
    expect(fixed.sunProgress, .5);
    expect(fixed.moonProgress, greaterThan(1.12));
    expect(LandscapeConfiguration.decode('{}').celestialBodies, true);
    expect(
      () => LandscapeConfiguration.parse({'celestialBodies': 'yes'}),
      throwsFormatException,
    );
  });

  test('optional star rotation follows the displayed hour without reseeding the sky', () {
    const off = LandscapeConfiguration();
    const on = LandscapeConfiguration(starRotation: true);
    expect(landscapeStarAngle(DateTime(2026, 10, 24, 5), off), 0);
    final midnight = landscapeStarAngle(DateTime(2026, 10, 24), on);
    final four = landscapeStarAngle(DateTime(2026, 10, 24, 4), on);
    expect(midnight, 0);
    expect(four, closeTo(1.04719755, .00001));
    expect(
      landscapeStarAngle(DateTime(2026, 10, 24, 4, 1), on) - four,
      closeTo(.00436332, .00001),
    );
    expect(LandscapeConfiguration.decode('{}').starRotation, false);
  });

  test('preview enables weather movement and star rotation without changing saved settings', () {
    const saved = LandscapeConfiguration(
      motion: false,
      starRotation: false,
      clouds: false,
      precipitation: false,
      celestialBodies: false,
      hemisphere: 'south',
    );
    final preview = saved.forDemo();
    expect(preview.motion, true);
    expect(preview.starRotation, true);
    expect(preview.precipitation, true);
    expect(preview.clouds, true);
    expect(preview.celestialBodies, false);
    expect(preview.hemisphere, 'south');
    expect(saved.motion, false);
    expect(saved.starRotation, false);
    expect(saved.precipitation, false);
  });

  test('video start date cannot change the season/weather pairings', () {
    final start = DateTime(2026, 6, 21);
    final timeline = LandscapeDemoTimeline(start);
    final rain = LandscapeDemoFrame(
      timeline.dayDuration + const Duration(seconds: 7),
      start,
    );
    final snow = LandscapeDemoFrame(
      timeline.dayDuration + const Duration(seconds: 12),
      start,
    );
    final fog = LandscapeDemoFrame(
      timeline.dayDuration + const Duration(seconds: 17),
      start,
    );
    expect(
      (rain.season, rain.weather),
      (LandscapeSeason.autumn, LandscapeWeather.rain),
    );
    expect(
      (snow.season, snow.weather),
      (LandscapeSeason.winter, LandscapeWeather.snow),
    );
    expect(
      (fog.season, fog.weather),
      (LandscapeSeason.spring, LandscapeWeather.fog),
    );
  });

  test('glow starts an hour before sunset and ends an hour after sunrise', () {
    final day = DateTime(2026, 10, 24);
    final sun = [
      {
        'sunrise': day.add(const Duration(hours: 8)).millisecondsSinceEpoch,
        'sunset': day.add(const Duration(hours: 17)).millisecondsSinceEpoch,
      },
    ];
    const config = LandscapeConfiguration();
    for (final hour in [8, 17]) {
      LandscapeGlow at(int minute) => LandscapeGlow.at(
        day.add(Duration(hours: hour, minutes: minute)),
        config,
        solarDays: sun,
      );
      final before = hour == 8 ? 10 : 60;
      expect(at(-before - 1).strength, 0);
      expect(at(-before).strength, 0);
      expect(at(-before ~/ 2).strength, closeTo(.5, .00001));
      expect(at(0).strength, 1);
      expect(at(0).sunrise, hour == 8);
      final end = hour == 8 ? 60 : 10;
      expect(at(end ~/ 2).strength, closeTo(.5, .00001));
      expect(at(end - 1).strength, greaterThan(0));
      expect(at(end).strength, 0);
      expect(at(end + 1).strength, 0);
      expect(
        LandscapeCelestialState.at(
          day.add(Duration(hours: hour)),
          config,
          solarDays: sun,
        ).sunWarmth,
        1,
      );
    }
    expect(
      LandscapeGlow.at(
        day.add(const Duration(hours: 8)),
        const LandscapeConfiguration(timeOfDay: false),
        solarDays: sun,
      ).strength,
      0,
    );
  });

  test(
    'sun emerges red and warms before sunset relative to each cached schedule',
    () {
      final day = DateTime(2026, 10, 24);
      const config = LandscapeConfiguration();
      for (final (riseMinute, setMinute) in [
        (360, 1080),
        (490, 1190),
        (420, 990),
      ]) {
        final rise = day.add(Duration(minutes: riseMinute));
        final sunset = day.add(Duration(minutes: setMinute));
        final sun = [
          {
            'sunrise': rise.millisecondsSinceEpoch,
            'sunset': sunset.millisecondsSinceEpoch,
          },
        ];
        double warmth(DateTime time) =>
            LandscapeCelestialState.at(time, config, solarDays: sun).sunWarmth;
        expect(
          warmth(rise.subtract(const Duration(minutes: 28))),
          1,
          reason: 'the first visible sliver must already be red',
        );
        expect(warmth(rise), 1);
        expect(
          warmth(rise.add(const Duration(minutes: 20))),
          closeTo(.5, .00001),
        );
        expect(warmth(rise.add(const Duration(minutes: 40))), 0);
        expect(warmth(sunset.subtract(const Duration(minutes: 41))), 0);
        expect(warmth(sunset.subtract(const Duration(minutes: 40))), 0);
        expect(
          warmth(sunset.subtract(const Duration(minutes: 39))),
          greaterThan(.1),
        );
        expect(
          warmth(sunset.subtract(const Duration(minutes: 30))),
          closeTo(.875, .00001),
        );
        expect(warmth(sunset.subtract(const Duration(minutes: 20))), 1);
        expect(
          warmth(sunset.add(const Duration(minutes: 20))),
          1,
          reason: 'sun must not turn pale while disappearing behind the ridge',
        );
        expect(
          LandscapeGlow.at(
            rise.subtract(const Duration(minutes: 28)),
            config,
            solarDays: sun,
          ).strength,
          0,
          reason: 'the separate sky glow window stays unchanged',
        );
        expect(
          LandscapeCelestialState.at(
            rise,
            const LandscapeConfiguration(timeOfDay: false),
            solarDays: sun,
          ).sunWarmth,
          0,
        );
      }
    },
  );

  test('settings survive reload and compatible backup; invalid effects cannot import', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    addTearDown(settings.dispose);
    await settings.setBackgroundSource('landscape');
    await settings.setLandscape(
      const LandscapeConfiguration(
        variant: 'realistic',
        celestialBodies: false,
        starRotation: true,
        motion: true,
        fog: false,
      ),
    );
    settings.reload();
    expect(settings.backgroundSource, 'landscape');
    expect(settings.landscape.variant, 'realistic');
    expect(settings.landscape.fog, false);
    expect(settings.landscape.celestialBodies, false);
    expect(settings.landscape.starRotation, true);
    final exported = settings.exportSettingsMap();
    final imported = compatibleSettings(exported, exported);
    expect(imported[landscapeSettingsKey], exported[landscapeSettingsKey]);
    expect(imported['background_source'], 'landscape');
    expect(
      backupSyncPartGroup('setting:$landscapeSettingsKey'),
      BackupSyncGroup.background,
    );
    final invalid = compatibleSettings({
      landscapeSettingsKey: jsonEncode({'motion': 'yes'}),
    }, exported);
    expect(invalid.containsKey(landscapeSettingsKey), false);
    await settings.resetAppearanceSection('background');
    expect(settings.landscape.motion, false);
    expect(settings.landscape.variant, 'illustrated');
  });
}
