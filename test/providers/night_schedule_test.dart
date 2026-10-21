import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  test(
      'legacy schedule migrates and backup accepts 90 percent but rejects corrupt fields',
      () {
    final legacy = jsonEncode({
      'enabled': true,
      'scheduled': true,
      'startHour': 22,
      'endHour': 7,
      'dim': 60,
      'warmth': 30
    });
    final c = NightModeConfiguration.decode(legacy);
    expect(c.enabled, isTrue);
    expect(c.temperature, 2700);
    expect(
        compatibleSettings({nightModeKey: legacy}, {})
            .containsKey(nightModeKey),
        isTrue);
    expect(
        compatibleSettings({
          nightModeKey: jsonEncode(c.copyWith(dim: 90, warmth: 90).toJson())
        }, {}).containsKey(nightModeKey),
        isTrue);
    for (final bad in [
      {'temperature': 999},
      {'latitude': 91, 'longitude': 30},
      {'overrideMode': 'invalid'},
      {'dim': 96}
    ]) {
      expect(
          compatibleSettings({
            nightModeKey: jsonEncode({...c.toJson(), ...bad})
          }, {}),
          isEmpty);
    }
  });
  test(
      'temporary overrides survive serialization and expire at the next schedule edge',
      () {
    const c = NightModeConfiguration(
        enabled: true,
        scheduled: true,
        startHour: 22,
        startMinute: 30,
        endHour: 7,
        endMinute: 30);
    final now = DateTime(2026, 10, 4, 23);
    final nextStart = c.nextBoundary(now, true)!;
    expect(nextStart, DateTime(2026, 10, 5, 22, 30));
    expect(c.nextBoundary(now, false), DateTime(2026, 10, 5, 7, 30));
    final skipped = NightModeConfiguration.decode(jsonEncode(c
        .copyWith(
            overrideMode: 'off',
            overrideUntil: nextStart.millisecondsSinceEpoch)
        .toJson()));
    expect(skipped.activeAt(now), isFalse);
    expect(skipped.activeAt(nextStart), isTrue);
    final daytime = DateTime(2026, 10, 4, 12);
    final until = c.nextBoundary(daytime, false)!;
    final forced = c.copyWith(
        overrideMode: 'on', overrideUntil: until.millisecondsSinceEpoch);
    expect(forced.activeAt(daytime), isTrue);
    expect(forced.activeAt(until), isFalse);
    expect(forced.activeAt(daytime, tcl: true), isTrue);
  });
  test(
      'sun offsets use absolute timestamps across midnight and missing solar data pauses schedule',
      () {
    final days = [
      for (var day = 3; day <= 6; day++)
        {
          'sunrise': DateTime.utc(2026, 10, day, 4).millisecondsSinceEpoch,
          'sunset': DateTime.utc(2026, 10, day, 16).millisecondsSinceEpoch,
        }
    ];
    const c = NightModeConfiguration(
        enabled: true,
        scheduled: true,
        solar: true,
        sunsetOffset: 60,
        sunriseOffset: -30);
    expect(c.activeAt(DateTime.utc(2026, 10, 4, 16), solarDays: days),
        isFalse);
    expect(c.activeAt(DateTime.utc(2026, 10, 4, 17), solarDays: days), isTrue);
    expect(
        c.activeAt(DateTime.utc(2026, 10, 5, 3, 29), solarDays: days), isTrue);
    expect(
        c.activeAt(DateTime.utc(2026, 10, 5, 3, 30), solarDays: days), isFalse);
    expect(
        c
            .nextBoundary(DateTime.utc(2026, 10, 4, 18), false,
                solarDays: days)!
            .millisecondsSinceEpoch,
        DateTime.utc(2026, 10, 5, 3, 30).millisecondsSinceEpoch);
    expect(c.activeAt(DateTime.utc(2026, 10, 4, 18)), isFalse);
    expect(c.nextBoundary(DateTime.utc(2026, 10, 4, 18), true), isNull);
  });
  testWidgets(
      'native query failure clears permission instead of retaining a checkmark',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('cutelauncher/night');
    var failed = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (failed) throw PlatformException(code: 'unavailable');
      return {'permission': true, 'visible': false, 'running': true};
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pump();
    expect(service.overlayPermission, isTrue);
    expect(service.systemFilter, isFalse);
    failed = true;
    await service.syncSystem();
    expect(service.overlayPermission, isFalse);
    expect(service.overlayPermissionKnown, isFalse);
    service.dispose();
  });
}
