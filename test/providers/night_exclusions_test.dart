import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'picture mode exclusions survive backup without changing night schedules',
    () {
      const original = NightModeConfiguration(
        enabled: true,
        scheduled: true,
        overrideMode: 'off',
        overrideUntil: 4000000000000,
        excludedPackages: ['com.example.player'],
        ignoredHdmiInputIds: ['port2'],
      );
      expect(
        NightModeConfiguration.parse(
          original.toJson()..remove('ignoredPictureModes'),
        ).ignoredPictureModes,
        isEmpty,
      );
      final selected = original.copyWith(ignoredPictureModes: [19, 51]);
      final backup = compatibleSettings({
        nightModeKey: jsonEncode(selected.toJson()),
      }, {});
      final decoded = NightModeConfiguration.decode(
        backup[nightModeKey] as String,
      );
      expect(decoded.ignoredPictureModes, [19, 51]);
      expect(decoded.copyWith(dim: 50).ignoredPictureModes, [19, 51]);
      expect(decoded.overrideMode, 'off');
      expect(decoded.excludedPackages, original.excludedPackages);
      expect(decoded.ignoredHdmiInputIds, original.ignoredHdmiInputIds);
      expect(
        NightModeConfiguration.parse(
          selected.copyWith(ignoredPictureModes: [19, 19]).toJson(),
        ).ignoredPictureModes,
        [19],
      );
      for (final invalid in [
        '19',
        [null],
        [true],
        [-1],
        [256],
        [19.0],
        List.filled(129, 19),
      ]) {
        final malformed = {
          ...original.toJson(),
          'ignoredPictureModes': invalid,
        };
        expect(
          () => NightModeConfiguration.parse(malformed),
          throwsFormatException,
        );
        expect(
          compatibleSettings({nightModeKey: jsonEncode(malformed)}, {}),
          isNot(contains(nightModeKey)),
        );
      }
    },
  );

  testWidgets(
    'picture mode suppresses local fallback without usage access and recovers on read failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      const tcl = MethodChannel('cutelauncher/tcl_blue_light');
      int? mode = 19;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'pictureMode'
            ? mode
            : {'permission': false, 'usagePermission': false},
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        tcl,
        (_) async => {'status': 'unsupported'},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await service.configure(
        const NightModeConfiguration(
          enabled: true,
          tclScheduled: false,
          ignoredPictureModes: [19, 51],
          ignoreHdmiInputs: false,
        ),
      );
      expect(service.pictureModeExcluded, isTrue);
      expect(service.active, isFalse);
      expect(service.localFilter, isFalse);
      mode = 3;
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
      expect(service.active, isTrue);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      mode = 19;
      await tester.pump(const Duration(seconds: 3));
      expect(service.pictureMode, 3);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(service.pictureMode, 19);
      expect(service.active, isFalse);
      mode = 51;
      await service.refreshPictureMode();
      expect(service.active, isFalse);
      mode = null;
      await service.refreshPictureMode();
      expect(service.active, isTrue);
      expect(service.configuration.ignoredPictureModes, [19, 51]);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'pictureMode') {
          throw PlatformException(code: 'unavailable');
        }
        return {'permission': false};
      });
      await service.refreshPictureMode();
      expect(service.pictureMode, isNull);
      expect(service.active, isTrue);
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(tcl, null);
    },
  );

  test('HDMI exclusion defaults on and survives storage and backup validation', () {
    const original = NightModeConfiguration(
      enabled: true, scheduled: true, overrideMode: 'off',
      overrideUntil: 4000000000000,
      excludedPackages: ['com.example.player'],
    );
    expect(original.ignoreHdmiInputs, isTrue);
    expect(NightModeConfiguration.parse(
      original.toJson()..remove('ignoreHdmiInputs'),
    ).ignoreHdmiInputs, isTrue);
    for (final value in [false, true]) {
      final updated = original.copyWith(ignoreHdmiInputs: value);
      final encoded = jsonEncode(updated.toJson());
      expect(NightModeConfiguration.decode(encoded).ignoreHdmiInputs, value);
      final backup = compatibleSettings({nightModeKey: encoded}, {});
      expect(NightModeConfiguration.decode(backup[nightModeKey] as String)
          .ignoreHdmiInputs, value);
      expect(updated.overrideMode, 'off');
      expect(updated.excludedPackages, original.excludedPackages);
      expect(updated.copyWith(dim: 50).ignoreHdmiInputs, value);
    }
    final malformed = {...original.toJson(), 'ignoreHdmiInputs': 'true'};
    expect(() => NightModeConfiguration.parse(malformed), throwsFormatException);
    expect(compatibleSettings({nightModeKey: jsonEncode(malformed)}, {}),
        isNot(contains(nightModeKey)));
  });
  test('exclusions persist, deduplicate, preserve overrides and reject malformed backup', () {
    const original = NightModeConfiguration(
      enabled: true,
      scheduled: true,
      overrideMode: 'off',
      overrideUntil: 4000000000000,
    );
    final c = original.copyWith(
      excludedPackages: ['com.example.player', 'com.example.player'],
    );
    final decoded = NightModeConfiguration.parse(c.toJson());
    expect(decoded.excludedPackages, ['com.example.player']);
    expect(decoded.overrideMode, 'off');
    expect(decoded.activeAt(DateTime(2026, 10, 6, 23)), isFalse);
    expect(
      compatibleSettings({
        nightModeKey: jsonEncode(c.toJson()),
      }, {}).containsKey(nightModeKey),
      isTrue,
    );
    for (final invalid in [
      ['bad-package'],
      [5],
      'com.example.player',
      List.filled(129, 'com.example.player'),
    ]) {
      final json = {...c.toJson(), 'excludedPackages': invalid};
      expect(() => NightModeConfiguration.parse(json), throwsFormatException);
      expect(
        compatibleSettings({
          nightModeKey: jsonEncode(json),
        }, {}).containsKey(nightModeKey),
        isFalse,
      );
    }
    expect(
      NightModeConfiguration.parse(
        original.toJson()..remove('excludedPackages'),
      ).excludedPackages,
      isEmpty,
    );
  });
  testWidgets(
    'local exclusion suppresses fallback and access revocation restores schedule',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      const tcl = MethodChannel('cutelauncher/tcl_blue_light');
      bool access = true;
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return {
          'permission': false,
          'usagePermission': access,
          'localExcluded': access,
        };
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        tcl,
        (_) async => {'status': 'unsupported'},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await service.configure(
        const NightModeConfiguration(
          enabled: true,
          excludedPackages: ['com.example.launcher'],
        ),
      );
      expect(service.active, isFalse);
      expect(service.usagePermission, isTrue);
      await service.requestUsagePermission();
      expect(calls.last.method, 'usagePermission');
      access = false;
      await service.syncSystem();
      expect(service.active, isTrue);
      expect(service.configuration.enabled, isTrue);
      await service.configure(service.configuration.copyWith(enabled: false));
      expect(service.active, isFalse);
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(tcl, null);
    },
  );
}
