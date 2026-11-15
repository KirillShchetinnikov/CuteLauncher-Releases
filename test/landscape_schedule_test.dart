import 'dart:convert';

import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/landscape_schedule.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final noon = DateTime(2026, 11, 15, 12);

  test(
    'legacy settings start in Auto with an editable 08:00–20:00 fallback',
    () {
      final config = LandscapeConfiguration.decode('{"timeOfDay":true}');
      expect(config.schedule, LandscapeSchedule.auto);
      final fallback = resolveLandscapeSchedule(noon, config, null, null);
      final sun = landscapeSunTimes(noon, fallback.days);
      expect(fallback.source, 'manualFallback');
      expect(sun.sunrise.hour, 8);
      expect(sun.sunset.hour, 20);
      final edited = config
          .withValue('schedule', 'manual')
          .withValue('sunsetMinute', 17 * 60 + 15);
      final afterRestart = LandscapeConfiguration.decode(edited.encode());
      final manual = resolveLandscapeSchedule(noon, afterRestart, null, null);
      expect(manual.source, 'manual');
      expect(
        landscapeSunTimes(noon, manual.days).sunset,
        DateTime(2026, 11, 15, 17, 15),
      );
      expect(
        () => edited.withValue('sunsetMinute', edited.sunriseMinute),
        throwsFormatException,
      );
    },
  );

  test('manual schedule can continue the day past midnight', () {
    const config = LandscapeConfiguration(
      schedule: LandscapeSchedule.manual,
      sunriseMinute: 15 * 60,
      sunsetMinute: 3 * 60,
    );
    final time = DateTime(2026, 11, 16, 1);
    final schedule = resolveLandscapeSchedule(time, config, null, null);
    expect(
      landscapePhase(time, config, solarDays: schedule.days),
      LandscapePhase.day,
    );
    final preview = LandscapeDemoTimeline(time, solarDays: schedule.days);
    expect(
      landscapePhase(time, config, solarDays: preview.solarDays),
      LandscapePhase.day,
    );
    expect(
      landscapePhase(
        DateTime(2026, 11, 16, 5),
        config,
        solarDays: schedule.days,
      ),
      LandscapePhase.night,
    );
  });

  testWidgets(
    'Auto gets solar events once per local date and night mode uses saved hours',
    (tester) async {
      const saved = NightModeConfiguration(
        city: 'Configured city',
        latitude: 52.52,
        longitude: 13.405,
        startHour: 21,
        startMinute: 30,
        endHour: 7,
        endMinute: 15,
      );
      SharedPreferences.setMockInitialValues({
        nightModeKey: jsonEncode(saved.toJson()),
      });
      const bridge = MethodChannel('cutelauncher/night');
      final calls = <MethodCall>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(bridge, (call) async {
        if (call.method != 'landscapeSolarDays') return {'permission': false};
        calls.add(call);
        final now = DateTime.fromMillisecondsSinceEpoch(
          (call.arguments as Map)['now'] as int,
        );
        return [
          {
            'sunrise': DateTime(
              now.year,
              now.month,
              now.day,
              7,
              30,
            ).millisecondsSinceEpoch,
            'sunset': DateTime(
              now.year,
              now.month,
              now.day,
              16,
              15,
            ).millisecondsSinceEpoch,
          },
        ];
      });
      addTearDown(() => messenger.setMockMethodCallHandler(bridge, null));
      final service = NightModeService(await SharedPreferences.getInstance());
      const auto = LandscapeConfiguration();
      const night = LandscapeConfiguration(
        schedule: LandscapeSchedule.nightMode,
      );
      await tester.pump();
      final nightTiming = resolveLandscapeSchedule(
        noon,
        night,
        service,
        null,
        request: true,
      );
      final hours = landscapeSunTimes(noon, nightTiming.days);
      expect(nightTiming.source, 'nightModeSchedule');
      expect(hours.sunrise, DateTime(2026, 11, 15, 7, 15));
      expect(hours.sunset, DateTime(2026, 11, 15, 21, 30));
      expect(calls, isEmpty);
      expect(
        resolveLandscapeSchedule(
          noon,
          auto,
          service,
          null,
          request: true,
        ).source,
        'manualFallback',
      );
      resolveLandscapeSchedule(noon, auto, service, null, request: true);
      await tester.pump();
      final calculated = resolveLandscapeSchedule(
        noon,
        auto,
        service,
        null,
        request: true,
      );
      expect(calculated.source, 'localSolar');
      expect(
        landscapeSunTimes(noon, calculated.days).sunset,
        DateTime(2026, 11, 15, 16, 15),
      );
      expect(calls, hasLength(1));
      expect((calls.single.arguments as Map)['latitude'], 52.52);
      resolveLandscapeSchedule(
        DateTime(2026, 11, 16, 12),
        auto,
        service,
        null,
        request: true,
      );
      await tester.pump();
      expect(calls, hasLength(2));
      service.dispose();
    },
  );
}
