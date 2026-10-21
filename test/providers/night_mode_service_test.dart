import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  testWidgets('changing dim keeps an established fallback during native sync',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('cutelauncher/night');
    Completer<Map<String, dynamic>>? pending;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (_) async => pending == null
            ? {'permission': true, 'visible': false}
            : await pending.future);
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await service.configure(
        const NightModeConfiguration(enabled: true, dim: 40, warmth: 0));
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.localFilter, isTrue);
    final visibility = <bool>[];
    service.addListener(() => visibility.add(service.localFilter));
    pending = Completer<Map<String, dynamic>>();
    final change = service.configure(service.configuration.copyWith(dim: 60));
    await tester.pump();
    expect(service.configuration.dim, 60);
    expect(service.localFilter, isTrue);
    pending.complete({'permission': true, 'visible': false});
    await change;
    await tester.pump(const Duration(milliseconds: 500));
    expect(visibility, isNotEmpty);
    expect(visibility, everyElement(isTrue));
    service.dispose();
  });

  testWidgets('local dim retargets smoothly without resetting to transparent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('cutelauncher/night');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (_) async => {'permission': false});
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await service.configure(
        const NightModeConfiguration(enabled: true, dim: 40, warmth: 0));
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListenableBuilder(
        listenable: service,
        builder: (_, _) => NightModeFilter(
            service: service, child: const SizedBox.expand()),
      ),
    ));
    double alpha() =>
        tester.widget<ColoredBox>(find.byType(ColoredBox).last).color.a;
    expect(alpha(), closeTo(.4, .005));
    await service.configure(service.configuration.copyWith(dim: 60));
    await tester.pump();
    expect(alpha(), closeTo(.4, .005));
    await tester.pump(const Duration(milliseconds: 90));
    final halfway = alpha();
    expect(halfway, closeTo(.5, .01));
    await service.configure(service.configuration.copyWith(dim: 80));
    await tester.pump();
    expect(alpha(), closeTo(halfway, .005));
    await tester.pump(const Duration(milliseconds: 90));
    expect(alpha(), greaterThan(halfway));
    expect(alpha(), lessThan(.8));
    await tester.pump(const Duration(milliseconds: 90));
    expect(alpha(), closeTo(.8, .005));
    await tester.pumpWidget(const SizedBox());
    service.dispose();
  });

  testWidgets(
    'temporary off during solar transition persists next sunset to native',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      Map<dynamic, dynamic>? nativeConfiguration;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'configure') {
          nativeConfiguration = call.arguments as Map;
        }
        return {'permission': false};
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      final service = NightModeService(prefs);

      final now = DateTime.now();
      final sunset = now.add(const Duration(minutes: 30));
      final nextSunset = sunset.add(const Duration(days: 1));
      service.solarDays = [
        for (var day = 0; day < 3; day++)
          {
            'sunset': sunset.add(Duration(days: day)).millisecondsSinceEpoch,
            'sunrise': sunset
                .add(Duration(days: day, hours: -12))
                .millisecondsSinceEpoch,
          },
      ];
      await service.configure(
        const NightModeConfiguration(
          enabled: true,
          scheduled: true,
          solar: true,
        ),
      );
      expect(service.intensity, closeTo(.5, .01));
      await service.temporaryMode(false);
      expect(service.active, isFalse);
      final saved = NightModeConfiguration.decode(
        prefs.getString(nightModeKey),
      );
      expect(saved.overrideUntil, nextSunset.millisecondsSinceEpoch);
      expect(nativeConfiguration?['overrideUntil'], saved.overrideUntil);
      expect(nativeConfiguration?['overrideMode'], 'off');
      expect(saved.intensityAt(sunset, solarDays: service.solarDays), 0);
      expect(saved.intensityAt(nextSunset, solarDays: service.solarDays), 1);
      service.dispose();
    },
  );
  testWidgets(
    'native startup suppresses fallback until visibility and failure restores it',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      const channel = MethodChannel('cutelauncher/night');
      var visible = false;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => {'permission': true, 'visible': visible},
      );
      final service = NightModeService(await SharedPreferences.getInstance());
      await service.syncSystem();
      await service.configure(
        const NightModeConfiguration(enabled: true, dim: 75, warmth: 40),
      );
      expect(service.localFilter, isFalse);
      visible = true;
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.systemFilter, isTrue);
      expect(service.localFilter, isFalse);
      visible = false;
      await service.configure(service.configuration);
      await tester.pump(const Duration(milliseconds: 500));
      expect(service.localFilter, isTrue);
      service.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
  testWidgets('battery exemption refreshes on resume and failed settings do not enable night mode',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('cutelauncher/night');
    var exempt = false;
    var opened = 'unavailable';
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async => call.method == 'batterySettings'
            ? opened : {'batteryExempt': exempt});
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(await SharedPreferences.getInstance());
    await service.syncSystem();
    expect(service.batteryExempt, isFalse);
    await service.openBatterySettings();
    expect(service.batterySettingsUnavailable, isTrue);
    opened = 'opened';
    await service.openBatterySettings();
    expect(service.batterySettingsUnavailable, isFalse);
    exempt = true;
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump();
    expect(service.batteryExempt, isTrue);
    expect(service.configuration.enabled, isFalse);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (_) async => throw PlatformException(code: 'denied'));
    await service.openBatterySettings();
    expect(service.batterySettingsUnavailable, isTrue);
    await service.syncSystem();
    expect(service.batteryExempt, isNull);
    service.dispose();
  });
  testWidgets('notification disable is reloaded without restarting the filter',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const channel = MethodChannel('cutelauncher/night');
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return {'permission': true, 'notifications': true};
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(prefs);
    await service.configure(const NightModeConfiguration(enabled: true));
    expect(service.notificationsAllowed, isTrue);
    // Native notification action writes the shared configuration while Flutter is paused.
    await prefs.setString(
        nightModeKey, jsonEncode(const NightModeConfiguration().toJson()));
    await service.refreshSystem();
    expect(service.configuration.enabled, isFalse);
    expect(service.active, isFalse);
    expect(service.systemFilter, isFalse);
    expect(calls.last.arguments['enabled'], isFalse);
    service.dispose();
  });
  testWidgets(
      'system filter suppresses local layer and revocation restores fallback',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    const channel = MethodChannel('cutelauncher/night');
    var permission = true;
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      calls.add(call);
      return {
        'permission': permission,
        'running': permission,
        'visible': permission
      };
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final service = NightModeService(prefs);
    await service.configure(
        const NightModeConfiguration(enabled: true, dim: 60, warmth: 30));
    Widget app() => MaterialApp(
        home:
            NightModeFilter(service: service, child: const SizedBox.expand()));
    await tester.pumpWidget(app());
    expect(service.systemFilter, isTrue);
    expect(find.descendant(of: find.byType(NightModeFilter), matching: find.byType(ColoredBox)), findsNothing);
    expect(calls.last.arguments['dim'], 60);
    permission = false;
    await service.syncSystem();
    await tester.pumpWidget(app());
    expect(service.systemFilter, isFalse);
    expect(find.descendant(of: find.byType(NightModeFilter), matching: find.byType(ColoredBox)), findsNWidgets(2));
    final layers = tester.widgetList<ColoredBox>(find.descendant(of: find.byType(NightModeFilter), matching: find.byType(ColoredBox))).toList();
    expect(layers.last.color, const Color(0xFF000000).withValues(alpha: .6));
    expect(layers.first.color, service.configuration.filterColor.withValues(alpha: .3));
    await service.configure(const NightModeConfiguration());
    expect(calls.last.arguments['enabled'], isFalse);
    service.dispose();
  });
  test('overnight schedule includes start and excludes end', () {
    const c = NightModeConfiguration(enabled: true, scheduled: true);
    for (final hour in [22, 23, 0, 6]) {
      expect(c.activeAt(DateTime(2026, 10, 3, hour)), isTrue);
    }
    for (final hour in [7, 12, 21]) {
      expect(c.activeAt(DateTime(2026, 10, 3, hour)), isFalse);
    }
    expect(
        const NightModeConfiguration(
                enabled: true, scheduled: true, startHour: 7, endHour: 7)
            .activeAt(DateTime(2026)),
        isFalse);
    expect(const NightModeConfiguration().activeAt(DateTime(2026)), isFalse);
  });

  test(
      'backup rejects excessive dimming and preserves valid arbitrary percentages',
      () {
    final valid =
        jsonEncode(const NightModeConfiguration(dim: 7, warmth: 3).toJson());
    expect(compatibleSettings({nightModeKey: valid}, {})[nightModeKey], valid);
    final invalid = jsonEncode(
        const NightModeConfiguration(enabled: true, dim: 100).toJson());
    expect(compatibleSettings({nightModeKey: invalid}, {}), isEmpty);
  });

  testWidgets(
      'filter leaves controls interactive and persisted disable removes it',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    const channel = MethodChannel('cutelauncher/night');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel, (_) async => {'permission': false, 'running': false});
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));
    final prefs = await SharedPreferences.getInstance();
    final service = NightModeService(prefs);

    await service.configure(const NightModeConfiguration(enabled: true));
    var taps = 0;
    Widget app() => MaterialApp(
        home: NightModeFilter(
            service: service,
            child: Scaffold(
                body: Center(
                    child: TextButton(
                        onPressed: () => taps++,
                        child: const Text('Control'))))));
    await tester.pumpWidget(app());
    await tester.tap(find.text('Control'));
    expect(taps, 1);
    expect(find.byType(IgnorePointer), findsWidgets);
    await service.configure(const NightModeConfiguration());
    await tester.pumpWidget(app());
    expect(service.active, isFalse);
    expect(NightModeConfiguration.decode(prefs.getString(nightModeKey)).enabled,
        isFalse);
    await tester.tap(find.text('Control'));
    expect(taps, 2);
    service.dispose();
  });
}
