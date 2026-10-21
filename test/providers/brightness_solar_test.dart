import 'dart:convert';

import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'linked manual schedule uses night start/end instead of unrelated sunset',
    () async {
      SharedPreferences.setMockInitialValues({
        'brightness_solar': true,
        'brightness_transition_minutes': 60,
        nightModeKey: jsonEncode(
          const NightModeConfiguration(startHour: 22, endHour: 7).toJson(),
        ),
      });
      const channel = MethodChannel('me.efesser.flauncher/method');
      final applied = <int>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setSystemBrightness') {
              applied.add(call.arguments['brightness']);
            }
            return true;
          });
      final prefs = await SharedPreferences.getInstance();
      final night = NightModeService(prefs);
      var now = DateTime(2026, 10, 11, 18, 30);
      final service = BrightnessService(
        prefs,
        nightMode: night,
        now: () => now,
      );
      await service.setEnabled(true);
      expect(
        applied.last,
        204,
      ); // Manual night starts at 22, regardless of sunset at 18.
      now = DateTime(2026, 10, 11, 22, 30);
      await service.applyCurrentSlotBrightness();
      expect(applied.last, 128);
      now = DateTime(2026, 10, 12, 0);
      await service.applyCurrentSlotBrightness();
      expect(applied.last, 51);
      now = DateTime(2026, 10, 12, 7, 30);
      await service.applyCurrentSlotBrightness();
      expect(applied.last, 128);
      now = DateTime(2026, 10, 12, 8);
      await service.applyCurrentSlotBrightness();
      expect(applied.last, 204);
      service.dispose();
      night.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
  test('failed native writes retry without repeating window fallback and clear it on recovery', () async {
    SharedPreferences.setMockInitialValues({
      for (final slot in TimeSlot.values) 'brightness_${slot.name}': 50,
    });
    const native = MethodChannel('me.efesser.flauncher/method');
    const window = MethodChannel('github.com/aaassseee/screen_brightness');
    var available = false, writes = 0;
    final windowCalls = <String>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, (call) async {
          if (call.method == 'setSystemBrightness') {
            writes++;
            return available;
          }
          return true;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(window, (call) async {
          windowCalls.add(call.method);
          return null;
        });
    final service = BrightnessService(await SharedPreferences.getInstance());
    await service.setEnabled(true);
    await service.applyCurrentSlotBrightness();
    expect(writes, 2);
    expect(windowCalls, ['setApplicationScreenBrightness']);
    available = true;
    await service.applyCurrentSlotBrightness();
    await service.applyCurrentSlotBrightness();
    expect(writes, 3);
    expect(windowCalls, [
      'setApplicationScreenBrightness',
      'resetApplicationScreenBrightness',
    ]);
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(window, null);
  });
  final days = [
    for (var day = 10; day <= 12; day++)
      {
        'sunrise': DateTime(2026, 10, day, 7).millisecondsSinceEpoch,
        'sunset': DateTime(2026, 10, day, 18).millisecondsSinceEpoch,
      },
  ];
  int? level(DateTime now, {int minutes = 60, int sunsetOffset = 0}) =>
      BrightnessService.solarBrightnessAt(
        now,
        days,
        day: 80,
        night: 20,
        minutes: minutes,
        sunsetOffset: sunsetOffset,
      );
  test(
    'solar brightness changes gradually after each event in both directions',
    () {
      expect(level(DateTime(2026, 10, 11, 7)), 20);
      expect(level(DateTime(2026, 10, 11, 7, 30)), 50);
      expect(level(DateTime(2026, 10, 11, 8)), 80);
      expect(level(DateTime(2026, 10, 11, 18)), 80);
      expect(level(DateTime(2026, 10, 11, 18, 30)), 50);
      expect(level(DateTime(2026, 10, 11, 19)), 20);
      expect(level(DateTime(2026, 10, 11, 23)), 20);
      expect(level(DateTime(2026, 10, 11, 18, 30), sunsetOffset: 30), 80);
      expect(level(DateTime(2026, 10, 11, 18, 0, 30), minutes: 1), 50);
      expect(level(DateTime(2026, 10, 20)), isNull);
      expect(
        BrightnessService.solarBrightnessAt(
          DateTime(2026),
          [],
          day: 80,
          night: 20,
          minutes: 60,
        ),
        isNull,
      );
    },
  );
  test('new brightness keys are validated for backup', () {
    final source = {
      'brightness_solar': true,
      'brightness_transition_minutes': 60,
      'brightness_sunrise': 80,
      'brightness_sunset': 20,
    };
    expect(compatibleSettings(source, {}), source);
    for (final key in [
      'brightness_sunrise',
      'brightness_sunset',
      'brightness_transition_minutes',
    ]) {
      expect(compatibleSettings({key: 101}, {}), isEmpty);
    }
    expect(compatibleSettings({'brightness_solar': 'true'}, {}), isEmpty);
  });
  test(
    'live night data drives brightness independently of night master switch',
    () async {
      SharedPreferences.setMockInitialValues({
        'brightness_solar': true,
        'brightness_transition_minutes': 60,
        nightModeKey: jsonEncode(
          const NightModeConfiguration(
            solar: true,
            latitude: 55,
            longitude: 37,
          ).toJson(),
        ),
      });
      const channel = MethodChannel('me.efesser.flauncher/method');
      final applied = <int>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'setSystemBrightness') {
              applied.add(call.arguments['brightness']);
            }
            return true;
          });
      final prefs = await SharedPreferences.getInstance();
      final night = NightModeService(prefs);
      var now = DateTime(2026, 10, 11, 18, 30);
      final service = BrightnessService(
        prefs,
        nightMode: night,
        now: () => now,
      );
      await service.setEnabled(true);
      expect(applied, isEmpty);
      night.solarDays = days;
      await service.applyCurrentSlotBrightness();
      expect(applied, [128]);
      await service.applyCurrentSlotBrightness();
      expect(applied, [128]);
      now = DateTime(2026, 10, 11, 19);
      await service.applyCurrentSlotBrightness();
      expect(applied, [128, 51]);
      await service.setSolarBrightness(false, 30);
      expect(applied.last, 77);
      service.dispose();
      night.dispose();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    },
  );
}
