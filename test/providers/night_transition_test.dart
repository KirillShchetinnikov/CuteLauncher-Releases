import 'dart:convert';

import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const config = NightModeConfiguration(
    enabled: true,
    scheduled: true,
    transitionMinutes: 60,
  );
  test('ramp reaches target at start and ends at morning boundary', () {
    double intensity(int hour, [int minute = 0]) =>
        config.intensityAt(DateTime(2026, 10, 11, hour, minute));
    expect(intensity(20, 59), 0);
    expect(intensity(21), 0);
    expect(intensity(21, 15), .25);
    expect(intensity(21, 30), .5);
    expect(intensity(22), 1);
    expect(intensity(6), 1);
    expect(intensity(6, 15), .75);
    expect(intensity(6, 30), .5);
    expect(intensity(6, 45), .25);
    expect(intensity(6, 59), closeTo(1 / 60, .000001));
    expect(intensity(7), 0);
    expect(
      config.copyWith(enabled: false).intensityAt(DateTime(2026, 10, 11, 22)),
      0,
    );
    expect(
      config.copyWith(scheduled: false).intensityAt(DateTime(2026, 10, 11, 12)),
      1,
    );
  });
  test('solar ramp respects offsets and manual override during transition', () {
    final days = [
      for (var day = 10; day <= 12; day++)
        {
          'sunrise': DateTime(2026, 10, day, 7).millisecondsSinceEpoch,
          'sunset': DateTime(2026, 10, day, 18).millisecondsSinceEpoch,
        },
    ];
    final solar = config.copyWith(solar: true, sunsetOffset: 30);
    final now = DateTime(2026, 10, 11, 18);
    expect(solar.intensityAt(now, solarDays: days), .5);
    expect(
      solar.intensityAt(now.add(const Duration(minutes: 30)), solarDays: days),
      1,
    );
    final off = solar.copyWith(
      overrideMode: 'off',
      overrideUntil: now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
    );
    expect(off.intensityAt(now, solarDays: days), 0);
    expect(off.activeAt(now, solarDays: days, tcl: true), isFalse);
    expect(solar.intensityAt(now), 0);
  });
  for (final solar in [false, true]) {
    test(
      'temporary off skips a night whose transition has started: solar=$solar',
      () {
        final days = [
          for (var day = 10; day <= 13; day++)
            {
              'sunrise': DateTime(2026, 10, day, 7).millisecondsSinceEpoch,
              'sunset': DateTime(2026, 10, day, 21, 30).millisecondsSinceEpoch,
            },
        ];
        final c = config.copyWith(solar: solar, sunsetOffset: 30);
        final start = DateTime(2026, 10, 11, 22);
        DateTime? until(DateTime now) => c.nextBoundary(
          now,
          true,
          solarDays: days,
          skipStartedTransition: true,
        );
        expect(until(DateTime(2026, 10, 11, 20, 59)), start);
        for (final now in [
          DateTime(2026, 10, 11, 21),
          DateTime(2026, 10, 11, 21, 30),
          start,
          DateTime(2026, 10, 12, 1),
        ]) {
          final end = until(now)!;
          expect(end, DateTime(2026, 10, 12, 22));
          final off = NightModeConfiguration.decode(
            jsonEncode(
              c
                  .copyWith(
                    overrideMode: 'off',
                    overrideUntil: end.millisecondsSinceEpoch,
                  )
                  .toJson(),
            ),
          );
          for (final time in [now, start, DateTime(2026, 10, 12, 21, 30)]) {
            expect(off.intensityAt(time, solarDays: days), 0);
            expect(off.activeAt(time, solarDays: days, tcl: true), isFalse);
          }
          expect(off.intensityAt(end, solarDays: days), 1);
        }
        // Ordinary schedule boundaries still describe the full-strength start.
        expect(
          c.nextBoundary(DateTime(2026, 10, 11, 21, 30), true, solarDays: days),
          start,
        );
        if (solar) {
          expect(
            c.nextBoundary(start, true, skipStartedTransition: true),
            isNull,
          );
          expect(until(DateTime(2026, 10, 13, 21, 30)), isNull);
        }
      },
    );
  }
  for (final solar in [false, true]) {
    test('morning fade respects offsets and overrides: solar=$solar', () {
      final days = [
        for (var day = 10; day <= 13; day++)
          {
            'sunrise': DateTime(2026, 10, day, 7).millisecondsSinceEpoch,
            'sunset': DateTime(2026, 10, day, 22).millisecondsSinceEpoch,
          },
      ];
      final c = config.copyWith(solar: solar, sunriseOffset: 30, endMinute: 30);
      final now = DateTime(2026, 10, 11, 7);
      final end = c.nextBoundary(now, false, solarDays: days)!;
      expect(end, DateTime(2026, 10, 11, 7, 30));
      expect(c.intensityAt(now, solarDays: days), .5);
      expect(c.intensityAt(end, solarDays: days), 0);
      for (final mode in ['on', 'off']) {
        final forced = c.copyWith(
          overrideMode: mode,
          overrideUntil: end.millisecondsSinceEpoch,
        );
        expect(forced.intensityAt(now, solarDays: days), mode == 'on' ? 1 : 0);
        expect(forced.intensityAt(end, solarDays: days), 0);
        expect(
          forced
              .copyWith(clearOverrides: true)
              .intensityAt(now, solarDays: days),
          .5,
        );
      }
      final next = c.nextBoundary(
        now,
        true,
        solarDays: days,
        skipStartedTransition: true,
      )!;
      final off = c.copyWith(
        overrideMode: 'off',
        overrideUntil: next.millisecondsSinceEpoch,
      );
      expect(
        off.intensityAt(
          next.subtract(const Duration(minutes: 30)),
          solarDays: days,
        ),
        0,
      );
      expect(off.intensityAt(next, solarDays: days), 1);
    });
  }
  test('short intervals combine ramps without adding their intensity', () {
    final c = config.copyWith(startHour: 6, endHour: 6, endMinute: 30);
    expect(c.intensityAt(DateTime(2026, 10, 11, 5, 45)), .75);
    expect(c.intensityAt(DateTime(2026, 10, 11, 6)), .5);
    expect(c.intensityAt(DateTime(2026, 10, 11, 6, 15)), .25);
    expect(c.intensityAt(DateTime(2026, 10, 11, 6, 30)), 0);
  });
  test('backup preserves new settings and rejects out of range transition', () {
    final value = config.copyWith(
      dim: 95,
      automaticLocation: true,
      transitionMinutes: 120,
    );
    final restored = NightModeConfiguration.parse(value.toJson());
    expect(restored.dim, 95);
    expect(restored.automaticLocation, isTrue);
    expect(restored.transitionMinutes, 120);
    final legacy = NightModeConfiguration.parse({
      ...config.toJson(),
      'sunsetOffset': 360,
      'sunriseOffset': -240,
    });
    expect(legacy.sunsetOffset, 180);
    expect(legacy.sunriseOffset, -180);
    for (final duration in [0, 14, 22, 121]) {
      expect(
        compatibleSettings({
          nightModeKey: jsonEncode({
            ...value.toJson(),
            'transitionMinutes': duration,
          }),
        }, {}),
        isEmpty,
      );
    }
  });
  testWidgets('maximum dimming attenuates the warm layer too', (tester) async {
    SharedPreferences.setMockInitialValues({
      nightModeKey: jsonEncode(
        const NightModeConfiguration(
          enabled: true,
          dim: 95,
          warmth: 90,
        ).toJson(),
      ),
    });
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedBuilder(
          animation: service,
          builder: (_, _) =>
              NightModeFilter(service: service, child: const SizedBox()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final boxes = tester
        .widgetList<ColoredBox>(
          find.descendant(
            of: find.byType(NightModeFilter),
            matching: find.byType(ColoredBox),
          ),
        )
        .toList();
    expect(boxes.length, 2);
    expect(boxes.last.color, const Color(0xff000000).withValues(alpha: .95));
    // Even on a black image, 90% warmth contributes at most 4.5% after dimming.
    expect(boxes.first.color.a * (1 - boxes.last.color.a), lessThan(.046));
    service.dispose();
    await tester.pumpWidget(const SizedBox());
  });
}
