import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/remote_battery_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/remote_battery_preferences.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/widgets/remote_battery_widget.dart';
import 'package:flauncher/widgets/settings/remote_battery_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/widget_placement_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cutelauncher/remote_battery');
  const debounce = Duration(milliseconds: 150);

  Future<void> changed(bool? screenOn) =>
      binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall('changed', screenOn)),
        (_) {},
      );

  testWidgets('Home readiness and foreground gate the shared reads', (
    tester,
  ) async {
    final work = ForegroundWork(now: tester.binding.clock.now);
    final service = RemoteBatteryService(channel: channel, work: work);
    final messenger = binding.defaultBinaryMessenger;
    var reads = 0, notifications = 0;
    service.addListener(() => notifications++);
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'snapshot') return null;
      reads++;
      return {'percent': 60};
    });
    addTearDown(() {
      service.dispose();
      work.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });

    const queueDelay = Duration(milliseconds: 350);
    service.setVisible('home', true);
    await tester.pump(queueDelay);
    expect(reads, 0);
    work.homeReady();
    await tester.pump(queueDelay);
    expect(reads, 1);
    expect(notifications, 1);

    await changed(null);
    await changed(null);
    await tester.pump(queueDelay);
    expect(reads, 2);
    expect(notifications, 1);

    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(minutes: 6));
    expect(reads, 2);
    expect(service.percent, isNull);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(queueDelay);
    expect(reads, 3);
    service.setVisible('home', false);
  });

  testWidgets(
    'visible copies share a read, then pause with the screen or last owner',
    (tester) async {
      final service = RemoteBatteryService(channel: channel);
      final calls = <MethodCall>[];
      final messenger = binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return call.method == 'snapshot' ? {'percent': 0} : null;
      });
      addTearDown(() {
        service.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });

      Future<void> show({required bool first, required bool second}) =>
          tester.pumpWidget(
            ChangeNotifierProvider.value(
              value: service,
              child: MaterialApp(
                locale: const Locale('ru'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Row(
                    children: [
                      RemoteBatteryWidget(visible: first),
                      RemoteBatteryWidget(visible: second),
                    ],
                  ),
                ),
              ),
            ),
          );

      await show(first: false, second: false);
      await tester.pump(debounce);
      expect(calls, isEmpty);
      expect(find.text('—'), findsNWidgets(2));

      await show(first: true, second: true);
      await tester.pump(debounce);
      expect(calls.map((call) => call.method), ['watch', 'snapshot']);
      expect(find.text('0%'), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(RemoteBatteryWidget),
          matching: find.byType(CustomPaint),
        ),
        findsNWidgets(2),
      );

      await changed(false);
      await tester.pump(const Duration(minutes: 6));
      expect(find.text('—'), findsNWidgets(2));
      expect(calls.where((call) => call.method == 'snapshot'), hasLength(1));

      await changed(true);
      await tester.pump(debounce);
      expect(calls.where((call) => call.method == 'snapshot'), hasLength(2));
      await show(first: false, second: false);
      await tester.pump(const Duration(minutes: 6));
      expect(calls.map((call) => call.method), [
        'watch',
        'snapshot',
        'snapshot',
        'watch',
      ]);
      expect(calls.last.arguments, false);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'battery level and warning follow the shared display preferences',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final battery = RemoteBatteryService(channel: channel);
      final messenger = binding.defaultBinaryMessenger;
      var percent = 9;
      messenger.setMockMethodCallHandler(channel, (call) async {
        return call.method == 'snapshot' ? {'percent': percent} : null;
      });
      addTearDown(settings.dispose);
      addTearDown(() {
        battery.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: battery),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: RemoteBatteryWidget()),
          ),
        ),
      );
      await tester.pump(debounce);
      await tester.pump();
      final glyph = find.descendant(
        of: find.byType(RemoteBatteryWidget),
        matching: find.byType(CustomPaint),
      );
      final low = tester.widget<Text>(find.text('9%')).style!.color;
      expect(low, isNotNull);

      percent = 10;
      await changed(null);
      await tester.pump(debounce);
      await tester.pump();
      expect(tester.widget<Text>(find.text('10%')).style?.color, isNull);
      await settings.setRemoteBatteryLowThreshold(11);
      await tester.pump();
      expect(tester.widget<Text>(find.text('10%')).style?.color, low);
      final colored = tester.widget<CustomPaint>(glyph).painter!;

      await settings.setShowRemoteBatteryPercent(false);
      await tester.pump();
      expect(find.text('10%'), findsNothing);
      expect(glyph, findsOneWidget);
      await settings.setRemoteBatteryLowColorEnabled(false);
      await tester.pump();
      expect(
        tester.widget<CustomPaint>(glyph).painter!.shouldRepaint(colored),
        isTrue,
      );

      await settings.setShowRemoteBatteryPercent(true);
      await tester.pump();
      expect(tester.widget<Text>(find.text('10%')).style?.color, isNull);
      expect(settings.remoteBatteryLowThreshold, 11);
      await settings.setRemoteBatteryLowColorEnabled(true);
      await tester.pump();
      expect(tester.widget<Text>(find.text('10%')).style?.color, low);
      expect(
        compatibleSettings({
          showRemoteBatteryPercentKey: false,
          remoteBatteryLowThresholdKey: 31,
        }, settings.exportSettingsMap()),
        {showRemoteBatteryPercentKey: false},
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'a legacy zero threshold keeps the warning off on update and import',
    () async {
      SharedPreferences.setMockInitialValues({remoteBatteryLowThresholdKey: 0});
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      expect(settings.remoteBatteryLowColorEnabled, isFalse);
      expect(
        settings.remoteBatteryLowThreshold,
        remoteBatteryDefaultLowThreshold,
      );
      expect(
        compatibleSettings({
          remoteBatteryLowThresholdKey: 0,
        }, settings.exportSettingsMap()),
        {
          remoteBatteryLowThresholdKey: 0,
          remoteBatteryLowColorEnabledKey: false,
        },
      );
      await settings.setRemoteBatteryLowColorEnabled(true);
      expect(settings.remoteBatteryLowColorEnabled, isTrue);
      expect(
        settings.remoteBatteryLowThreshold,
        remoteBatteryDefaultLowThreshold,
      );
    },
  );

  testWidgets(
    'a read cancelled before screen wake never supplies a stale value',
    (tester) async {
      final firstRead = Completer<Map<String, Object?>>();
      final messenger = binding.defaultBinaryMessenger;
      var reads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'snapshot') return null;
        return ++reads == 1 ? firstRead.future : {'percent': 67};
      });
      final service = RemoteBatteryService(channel: channel);
      addTearDown(() {
        service.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });

      service.setVisible('panel', true);
      await tester.pump(debounce);
      expect(reads, 1);
      await changed(false);
      await changed(true);
      await tester.pump(debounce);
      expect(reads, 1);

      firstRead.complete({'percent': 20});
      await tester.pump();
      expect(service.percent, isNull);
      await tester.pump(debounce);
      expect(reads, 2);
      expect(service.percent, 67);
      service.setVisible('panel', false);
    },
  );

  testWidgets('battery settings open a separate placement submenu', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'remote_panel_configuration': '{"hidden":[],"leftOrder":["settings"]}',
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final remote = RemotePanelService(prefs);
    final battery = RemoteBatteryService(channel: channel);
    var permission = false;
    var permissionRequests = 0;
    String? selected;
    final messenger = binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'bluetoothPermission':
          return permission;
        case 'requestBluetoothPermission':
          permissionRequests++;
          permission = true;
        case 'selectDevice':
          selected = call.arguments as String?;
          return true;
        case 'snapshot':
          return {
            'devices': [
              {'id': 'keyboard', 'name': 'UR02 Keyboard'},
            ],
            'selectedId': ?selected,
            if (selected != null) 'selectedName': 'UR02 Keyboard',
          };
      }
      return null;
    });
    addTearDown(settings.dispose);
    addTearDown(remote.dispose);
    addTearDown(() {
      battery.dispose();
      messenger.setMockMethodCallHandler(channel, null);
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: remote),
          ChangeNotifierProvider.value(value: battery),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsPanel(
              initialRoute: RemoteBatterySettingsPage.routeName,
            ),
          ),
        ),
      ),
    );
    expect(settings.showRemoteBatteryInStatusBar, isFalse);
    expect(remote.visible('remoteBattery'), isFalse);
    final l = AppLocalizations.of(
      tester.element(find.byType(RemoteBatterySettingsPage)),
    )!;
    await tester.pumpAndSettle();
    expect(find.text(l.remoteBatteryBluetoothPermission), findsOneWidget);
    expect(find.text(l.requestPermission), findsOneWidget);
    expect(find.text(l.homeAuto), findsOneWidget);
    await tester.tap(find.text(l.remoteBatteryDevice));
    await tester.pumpAndSettle();
    await tester.tap(find.text('UR02 Keyboard'));
    await tester.pumpAndSettle();
    expect(selected, 'keyboard');
    expect(find.text('UR02 Keyboard'), findsOneWidget);
    await tester.tap(find.text(l.remoteBatteryShowPercent));
    await tester.pumpAndSettle();
    expect(settings.showRemoteBatteryPercent, isFalse);
    final slider = find.byType(SettingsSliderTile);
    expect(
      tester.widget<SettingsSliderTile>(slider).options,
      List<int>.generate(30, (i) => i + 1),
    );
    final sliderTitle = find.text(l.remoteBatteryLowThreshold);
    await tester.ensureVisible(sliderTitle);
    Focus.of(tester.element(sliderTitle)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(settings.remoteBatteryLowThreshold, 11);
    final colorSwitch = find.text(l.remoteBatteryColorLowCharge);
    await tester.ensureVisible(colorSwitch);
    await tester.tap(colorSwitch);
    await tester.pumpAndSettle();
    expect(settings.remoteBatteryLowColorEnabled, isFalse);
    expect(tester.widget<SettingsSliderTile>(slider).enabled, isFalse);
    expect(settings.remoteBatteryLowThreshold, 11);
    await tester.tap(colorSwitch);
    await tester.pumpAndSettle();
    expect(settings.remoteBatteryLowColorEnabled, isTrue);
    expect(tester.widget<SettingsSliderTile>(slider).enabled, isTrue);
    expect(settings.remoteBatteryLowThreshold, 11);
    expect(find.text(l.topPanel), findsNothing);
    expect(find.text(l.remotePanel), findsNothing);
    final placementLink = find.text(l.informationObjectPlacement);
    await tester.ensureVisible(placementLink);
    await tester.pumpAndSettle();
    final placementFocus = Focus.of(tester.element(placementLink));
    await tester.tap(placementLink);
    await tester.pumpAndSettle();
    expect(
      tester.widget<WidgetPlacementPage>(find.byType(WidgetPlacementPage)).id,
      'remoteBattery',
    );
    expect(slider, findsNothing);
    expect(find.byType(RemoteBatteryDeviceButton), findsNothing);
    await tester.tap(find.text(l.topPanel));
    await tester.pumpAndSettle();
    expect(settings.showRemoteBatteryInStatusBar, isTrue);
    expect(remote.visible('remoteBattery'), isFalse);
    await tester.tap(find.text(l.remotePanel));
    await tester.pumpAndSettle();
    expect(remote.visible('remoteBattery'), isTrue);
    expect(
      settings.exportSettingsMap()['show_remote_battery_in_status_bar'],
      isTrue,
    );
    final restored = RemotePanelService(prefs);
    addTearDown(restored.dispose);
    expect(restored.visible('remoteBattery'), isTrue);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(placementFocus.hasPrimaryFocus, isTrue);
    expect(permissionRequests, 0);
    await tester.ensureVisible(find.text(l.remoteBatteryBluetoothPermission));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.remoteBatteryBluetoothPermission));
    await tester.pumpAndSettle();
    expect(permissionRequests, 1);
    expect(find.text(l.granted), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
