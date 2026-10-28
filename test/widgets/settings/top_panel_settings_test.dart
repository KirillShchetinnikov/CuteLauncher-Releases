import 'package:flauncher/widgets/settings/sleep_timer_settings_page.dart';
import 'package:flauncher/widgets/traffic_usage_menu.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/panel_clock.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/tv_inputs_configuration.dart';
import 'package:flauncher/widgets/settings/night_mode_page.dart';
import 'package:flauncher/widgets/settings/inputs_settings_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/settings_help.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/widgets/appearance_surface.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/widgets/night_mode_menu.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/settings_sync.dart';
import 'package:flauncher/widgets/daily_data_usage_widget.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_panel.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/widgets/sleep_timer_menu.dart';
import 'package:flauncher/tile_appearance.dart';

import '../../mocks.mocks.dart';
import '../panel_backdrop_assertions.dart';
import 'package:flauncher/widgets/category_container_common.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsService settings;
  late AppearanceService appearance;
  late MockNetworkService network;
  late MockWeatherService weather;
  late MockNotificationsService notifications;
  late MockTvInputsService inputs;
  late MockAppsService apps;
  late SleepTimerService sleepTimer;
  void expectWidgetHighlight(WidgetTester tester, Finder button) {
    expect(tester.widget<TopPanelItem>(button).selected, isTrue);
    final backdrop = find.byType(LauncherPanelBackdrop);
    expectSinglePanelBackdrop(tester);
    final clip = find.descendant(of: backdrop, matching: find.byType(ClipPath));
    final path = tester.widget<ClipPath>(clip).clipper!.getClip(tester.getSize(clip));
    expect(path.contains(tester.getCenter(button)), isFalse);
    expect(path.contains(const Offset(4, 4)), isTrue);
  }
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('cutelauncher/night'),
            (_) async => {'permission': false, 'running': false});
    var sleepRemaining = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SleepTimerService.channel, (call) async {
          if (call.method == 'start') sleepRemaining = (call.arguments['minutes'] as int) * 60000;
          if (call.method == 'startTest') sleepRemaining = 30000;
          if (call.method == 'cancel') sleepRemaining = 0;
          return {'remainingMs': sleepRemaining, 'exactAllowed': true, 'error': ''};
        });
    sleepTimer = SleepTimerService(elapsedMilliseconds: () => 0);
    appearance = AppearanceService(prefs);
    network = MockNetworkService();
    weather = MockWeatherService();
    notifications = MockNotificationsService();
    apps = MockAppsService();
    when(apps.applications).thenReturn([]);
    when(apps.categories).thenReturn([]);
    when(apps.launcherSections).thenReturn([]);
    inputs = MockTvInputsService();
    when(network.hasUsageStatsPermission).thenReturn(false);
    when(network.networkType).thenReturn(NetworkType.Wifi);
    when(network.cellularNetworkType).thenReturn(CellularNetworkType.Unknown);
    when(network.wirelessNetworkSignalLevel).thenReturn(4);
    when(network.vpnActive).thenReturn(false);
    when(weather.hasWeather).thenReturn(false);
    when(weather.weatherData).thenReturn(null);
    when(weather.stale).thenReturn(false);
    when(notifications.hasPermission).thenReturn(false);
    when(notifications.notifications).thenReturn([]);
    when(inputs.hasInputs).thenReturn(false);
    when(inputs.initialized).thenReturn(true);
  });
  tearDown(() {
    settings.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('cutelauncher/night'), null);
    sleepTimer.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SleepTimerService.channel, null);
    appearance.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget child, {
    NightModeService? night,
    Locale locale = const Locale('ru'),
    bool largeText = false,
  }) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: sleepTimer),
          if (night != null) ChangeNotifierProvider.value(value: night),
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider<NetworkService>.value(value: network),
          ChangeNotifierProvider<WeatherService>.value(value: weather),
          ChangeNotifierProvider<NotificationsService>.value(
            value: notifications,
          ),
          ChangeNotifierProvider<TvInputsService>.value(value: inputs),
          ChangeNotifierProvider<AppsService>.value(value: apps),
        ],
        child: MaterialApp(
          locale: locale,
          builder: largeText ? (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ) : null,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('empty section opens settings with a single immediate backdrop', (tester) async {
    when(apps.categories).thenReturn([]);
    await pump(tester, Scaffold(body: Builder(builder: categoryContainerEmptyState)));
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();
    expectSinglePanelBackdrop(tester);
    await tester.pumpAndSettle();
    expectSinglePanelBackdrop(tester);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPanel), findsNothing);
  });

  for (final nightMenu in [true, false]) {
    testWidgets('${nightMenu ? 'night' : 'inputs'} menu opens settings and restores focus', (tester) async {
      final night = NightModeService(prefs);
      when(inputs.inputs).thenReturn([]);
      when(inputs.configuration).thenReturn(const TvInputsConfiguration());
      try {
        await pump(tester, const Scaffold(appBar: FocusAwareAppBar()), night: night);
        if (nightMenu) {
          await tester.tap(find.byKey(const ValueKey('night_mode_button')));
        } else {
          // Exercise the actual toolbar route and its backdrop.
          when(inputs.hasInputs).thenReturn(true);
          when(inputs.inputs).thenReturn([]);
          await pump(tester, const Scaffold(appBar: FocusAwareAppBar()), night: night);
          await tester.tap(find.ancestor(of: find.byIcon(Icons.tv_outlined), matching: find.byType(TopPanelItem)));
        }
        await tester.pumpAndSettle();
        final menu = nightMenu ? find.byType(NightModeMenu) : find.byType(InputsPanel);
        expectSinglePanelBackdrop(tester);
        final settingsButton = find.descendant(of: menu, matching: find.byType(IconButton));
        final node = tester.widget<IconButton>(settingsButton).focusNode!;
        node.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expectSinglePanelBackdrop(tester, top: nightMenu ? 0 : kToolbarHeight);
        await tester.pumpAndSettle();
        final page = nightMenu ? find.byType(NightModePage) : find.byType(InputsSettingsPage);
        expect(page, findsOneWidget);
        expect(settingsButton, findsNothing);
        expect(node.hasFocus, isFalse);
        for (final barrier in tester.widgetList<ModalBarrier>(find.byType(ModalBarrier))) {
          expect(barrier.color, anyOf(isNull, Colors.transparent));
        }
        await Navigator.of(tester.element(page), rootNavigator: true).maybePop();
        await tester.pumpAndSettle();
        expect(menu, findsOneWidget);
        expectSinglePanelBackdrop(tester);
        expect(node.hasFocus, isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(menu, findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      } finally {
        night.dispose();
      }
    });
  }

  for (final solar in [false, true]) {
    for (final locale in [const Locale('ru'), const Locale('en')]) {
      testWidgets('night menu skips transition and returns to schedule: $solar $locale', (tester) async {
        final night = NightModeService(prefs);
        try {
          final now = DateTime.now();
          final start = now.add(const Duration(minutes: 30));
          final end = start.add(const Duration(hours: 12));
          night.solarDays = [
            for (var day = 0; day < 3; day++) {
              'sunset': start.add(Duration(days: day)).millisecondsSinceEpoch,
              'sunrise': start.add(Duration(days: day, hours: -12)).millisecondsSinceEpoch,
            },
          ];
          await night.configure(NightModeConfiguration(
            enabled: true, scheduled: true, solar: solar,
            startHour: start.hour, startMinute: start.minute,
            endHour: end.hour, endMinute: end.minute,
          ));
          expect(night.intensity, greaterThan(0));
          await pump(tester, const Scaffold(appBar: FocusAwareAppBar()),
              night: night, locale: locale, largeText: true);
          final button = find.byKey(const ValueKey('night_mode_button'));
          final node = tester.widget<TopPanelItem>(button).focusNode!;
          await appearance.set('panelButtonsOrder', ['nightMode', 'settings']);
          await tester.pumpAndSettle();
          node.requestFocus();
          await settings.setAutoHideAppBarEnabled(true);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.byType(NightModeMenu), findsOneWidget);
          expectWidgetHighlight(tester, button);
          expect(tester.getSize(find.byKey(const Key('top_panel_visibility'))).height, kToolbarHeight);
          final action = find.byKey(const ValueKey('night_mode_temporary'));
          final schedule = find.byKey(const ValueKey('night_mode_schedule'));
          expect(tester.getTopLeft(schedule).dy, greaterThan(kToolbarHeight));
          expect(tester.getTopLeft(action).dy, greaterThan(tester.getTopLeft(schedule).dy));
          expect(tester.getBottomRight(action).dx, lessThanOrEqualTo(960));
          expect(tester.takeException(), isNull);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(night.configuration.overrideMode, 'off');
          expect(night.configuration.overrideUntil, greaterThan(start.millisecondsSinceEpoch));
          expect(night.configuration.intensityAt(start, solarDays: night.solarDays), 0);
          expect(find.byType(NightModeMenu), findsOneWidget);
          final l = AppLocalizations.of(tester.element(action))!;
          expect(find.text(l.nightResumeSchedule), findsOneWidget);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(night.configuration.overrideMode, 'none');
          expect(night.configuration.overrideUntil, 0);
          expect(night.intensity, greaterThan(0));
          expect(find.text(l.nightSkipUntilNext), findsOneWidget);
          await tester.sendKeyEvent(LogicalKeyboardKey.escape);
          await tester.pumpAndSettle();
          expect(find.byType(NightModeMenu), findsNothing);
          expect(node.hasFocus, isTrue);
        } finally {
          night.dispose();
        }
      });
    }
  }

  testWidgets('night button visibility persists, exports, syncs and does not change the filter', (tester) async {
    expect(settings.showNightModeInStatusBar, isTrue);
    final night = NightModeService(prefs);
    try {
      await night.configure(const NightModeConfiguration(enabled: true));
      await pump(tester, const Scaffold(appBar: FocusAwareAppBar()), night: night);
      expect(find.byKey(const ValueKey('night_mode_button')), findsOneWidget);
      await settings.setShowNightModeInStatusBar(false);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('night_mode_button')), findsNothing);
      expect(night.configuration.enabled, isTrue);
      expect(SettingsService(prefs).showNightModeInStatusBar, isFalse);
      final exported = settings.exportSettingsMap();
      await settings.setShowNightModeInStatusBar(true);
      await settings.importSettingsMap(exported);
      expect(settings.showNightModeInStatusBar, isFalse);
      expect(syncSettingsKeys, contains('show_night_mode_in_status_bar'));
      expect(backupSyncPartGroup('setting:show_night_mode_in_status_bar'), BackupSyncGroup.topPanel);
    } finally {
      night.dispose();
    }
  });

  testWidgets('night object has a visibility switch and moves with remote', (tester) async {
    await pump(tester, const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName));
    final toggle = find.widgetWithText(RoundedSwitchListTile, 'Ночной режим');
    await tester.scrollUntilVisible(toggle, 150, scrollable: find.descendant(
        of: find.byType(StatusBarObjectsPage), matching: find.byType(Scrollable)).first);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.showNightModeInStatusBar, isFalse);
    await pump(tester, const SettingsPanel(initialRoute: PanelOrderPage.routeName, key: ValueKey('night_order')));
    final item = find.byKey(const ValueKey('nightMode'));
    await tester.scrollUntilVisible(item, 150, scrollable: find.descendant(
        of: find.byType(PanelOrderPage), matching: find.byType(Scrollable)).first);
    tester.widget<FocusableSettingsTile>(item).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    final before = appearance.appearance.panelOrder('panelButtonsOrder').indexOf('nightMode');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(appearance.appearance.panelOrder('panelButtonsOrder').indexOf('nightMode'), before + 1);
    expect(tester.widget<FocusableSettingsTile>(item).focusNode!.hasFocus, isTrue);
  });

  testWidgets('night menu without solar data disables temporary action; manual mode toggles', (tester) async {
    final night = NightModeService(prefs);
    try {
      await night.configure(const NightModeConfiguration(enabled: true, scheduled: true, solar: true));
      await pump(tester, const Scaffold(appBar: FocusAwareAppBar()), night: night);
      final button = find.byKey(const ValueKey('night_mode_button'));
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(find.byKey(const ValueKey('night_mode_temporary'))).enabled, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await night.configure(const NightModeConfiguration());
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('night_mode_temporary')), findsNothing);
      await tester.tap(find.descendant(of: find.byType(NightModeMenu), matching: find.byType(RoundedSwitchListTile)));
      await tester.pumpAndSettle();
      expect(night.configuration.enabled, isTrue);
      expect(night.configuration.scheduled, isFalse);
    } finally {
      night.dispose();
    }
  });

  testWidgets('sleep menu anchors under button, restarts, cancels and restores focus', (tester) async {
    await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
    final button = find.ancestor(of: find.byIcon(Icons.timer_outlined), matching: find.byType(TopPanelItem));
    final node = tester.widget<TopPanelItem>(button).focusNode!;
    await tester.tap(button);
    await tester.pump();
    expectSinglePanelBackdrop(tester);
    await tester.pumpAndSettle();
    expect(find.byType(SleepTimerMenu), findsOneWidget);
    expectWidgetHighlight(tester, button);
    // The painted backdrop must let outside taps reach the modal barrier.
    await tester.tapAt(const Offset(2, kToolbarHeight + 4));
    await tester.pumpAndSettle();
    expect(find.byType(SleepTimerMenu), findsNothing);
    await tester.tap(button);
    await tester.pump();
    expectSinglePanelBackdrop(tester);
    expect(tester.getTopLeft(find.byKey(const ValueKey('sleep_timer_0'))).dy, greaterThan(kToolbarHeight));
    expect(find.text('30 секунд (тест)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('sleep_timer_30_seconds')));
    await tester.pumpAndSettle();
    expect(find.text('00:30'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sleep_timer_10')));
    await tester.pumpAndSettle();
    expect(find.text('10:00'), findsOneWidget);
    expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
    expect(node.hasFocus, true);
    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sleep_timer_30')));
    await tester.pumpAndSettle();
    expect(find.text('30:00'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(sleepTimer.active, true);
    expect(node.hasFocus, true);
    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sleep_timer_0')));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    expect(sleepTimer.active, false);
  });

  testWidgets('traffic button opens totals and restores remote focus on Back', (tester) async {
    await settings.setShowDataWidgetInStatusBar(true);
    when(network.hasUsageStatsPermission).thenReturn(true);
    when(network.getDataUsageForPeriod(any)).thenAnswer((_) async => 3072);
    when(network.dailyDataUsage).thenReturn(3072);
    when(network.getTrafficUsage(any)).thenAnswer((_) async => {'rxBytes': 2048, 'txBytes': 1024, 'totalBytes': 3072});
    await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
    final button = find.byKey(const ValueKey('traffic_button'));
    final node = tester.widget<TopPanelItem>(button).focusNode!;
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.byType(TrafficUsageMenu), findsOneWidget);
    expectSinglePanelBackdrop(tester);
    expectWidgetHighlight(tester, button);
    expect(find.descendant(of: find.byKey(const ValueKey('traffic_daily')),
      matching: find.text('2.00 KB')), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(TrafficUsageMenu), findsNothing);
    expect(node.hasFocus, true);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hiding sleep button preserves active alarm and persists visibility', (tester) async {
    await sleepTimer.select(10);
    await settings.setShowSleepTimerInStatusBar(false);
    await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
    expect(find.byIcon(Icons.power_settings_new), findsNothing);
    expect(sleepTimer.active, true);
    expect(SettingsService(prefs).showSleepTimerInStatusBar, false);
    final exported = settings.exportSettingsMap();
    await settings.setShowSleepTimerInStatusBar(true);
    await settings.importSettingsMap(exported);
    expect(settings.showSleepTimerInStatusBar, false);
    await sleepTimer.select(0);
  });

  testWidgets('sleep menu scrolls to six hours with remote and keeps focus on failure', (tester) async {
    await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
    await tester.tap(find.byIcon(Icons.timer_outlined));
    await tester.pumpAndSettle();
    for (var i = 0; i < SleepTimerService.durations.length + 1; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    final last = find.byKey(const ValueKey('sleep_timer_360'));
    final focusedBefore = FocusManager.instance.primaryFocus;
    expect(focusedBefore?.context?.findAncestorWidgetOfExactType<FocusableSettingsTile>()?.key, const ValueKey('sleep_timer_360'));
    expect(tester.getBottomRight(last).dy, lessThanOrEqualTo(540));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SleepTimerService.channel, (_) async => throw PlatformException(code: 'access'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(SleepTimerMenu), findsOneWidget);
    expect(find.textContaining('Включите службу'), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, focusedBefore);
    expect(sleepTimer.active, false);
  });

  testWidgets(
    'object movement follows remote keys, scrolls and Back ends movement',
    (tester) async {
      await pump(
        tester,
        const SettingsPanel(initialRoute: PanelOrderPage.routeName),
      );
      final item = find.byKey(const ValueKey('settings'));
      tester.widget<FocusableSettingsTile>(item).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(item).selected, isTrue);
      for (var i = 0; i < TileAppearance.panelButtons.length - 1; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }
      expect(
        appearance.appearance.panelOrder('panelButtonsOrder').last,
        'settings',
      );
      final scroll = find
          .descendant(
            of: find.byType(PanelOrderPage),
            matching: find.byType(Scrollable),
          )
          .first;
      expect(
        tester.state<ScrollableState>(scroll).position.pixels,
        greaterThan(0),
      );
      expect(
        tester.getBottomRight(item).dy,
        lessThanOrEqualTo(tester.getBottomRight(scroll).dy),
      );
      expect(
        tester.widget<FocusableSettingsTile>(item).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(item).selected, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await Navigator.of(tester.element(item)).maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(PanelOrderPage), findsOneWidget);
      expect(tester.widget<FocusableSettingsTile>(item).selected, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('missing inputs explain hidden icon without changing saved preference', (tester) async {
    when(inputs.initialized).thenReturn(true);
    await pump(tester, const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName));
    final l = AppLocalizations.of(tester.element(find.byType(StatusBarObjectsPage)))!;
    expect(find.text(l.inputsUnavailableHint), findsNothing);
    await toggleSettingsHelp(tester, l.inputsUnavailableHint);
    expect(find.text(l.inputsUnavailableHint), findsOneWidget);
    expect(settings.showInputsWidgetInStatusBar, isTrue);
    final toggle = find.widgetWithText(RoundedSwitchListTile, l.inputs);
    expect(tester.widget<RoundedSwitchListTile>(toggle).value, isTrue);
    expect(tester.widget<RoundedSwitchListTile>(toggle).enabled, isFalse);
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.showInputsWidgetInStatusBar, isTrue);

    when(inputs.hasInputs).thenReturn(true);
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(tester, const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName));
    await tester.scrollUntilVisible(find.widgetWithText(RoundedSwitchListTile, l.inputs), 180,
        scrollable: find.descendant(of: find.byType(StatusBarObjectsPage), matching: find.byType(Scrollable)).first);
    expect(find.text(l.inputsUnavailableHint), findsNothing);
    expect(tester.widget<RoundedSwitchListTile>(find.widgetWithText(RoundedSwitchListTile, l.inputs)).enabled, isTrue);
    expect(settings.showInputsWidgetInStatusBar, isTrue);
  });

  testWidgets('home omits notifications and objects contain settings submenu', (
    tester,
  ) async {
    await pump(
      tester,
      const SettingsPanel(initialRoute: InterfaceSettingsPage.routeName),
    );
    expect(find.text('Уведомления'), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await pump(
      tester,
      const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName),
    );
    final submenu = find.widgetWithText(FocusableSettingsTile, 'Уведомления');
    await tester.scrollUntilVisible(submenu, 180);
    await tester.pumpAndSettle();
    expect(submenu, findsOneWidget);
    expect(
      find.widgetWithText(
        RoundedSwitchListTile,
        'Скрывать значок без уведомлений',
      ),
      findsNothing,
    );
    when(notifications.checkPermission()).thenAnswer((_) async => false);
    when(notifications.checkOverlayPermission()).thenAnswer((_) async => false);
    await tester.ensureVisible(submenu);
    await tester.pumpAndSettle();
    await tester.tap(submenu);
    await tester.pumpAndSettle();
    final page = find.byType(NotificationsSettingsPage);
    final l = AppLocalizations.of(tester.element(page))!;
    expect(tester.getTopLeft(page).dy, greaterThan(kToolbarHeight));
    expect(find.text(l.autoHideNotificationBell), findsOneWidget);
    expect(find.text(l.notificationPanelLink), findsNothing);
  });

  testWidgets(
    'notification and input panels follow actual button side after moving between sides',
    (tester) async {
      when(notifications.hasPermission).thenReturn(true);
      when(notifications.hidePersistentNotifications).thenReturn(false);
      when(inputs.hasInputs).thenReturn(true);
      when(inputs.inputs).thenReturn([]);
      await settings.setAutoHideNotificationsWidget(false);
      await settings.setShowInputsWidgetInStatusBar(true);
      await settings.setShowNotificationsWidgetInStatusBar(true);
      await settings.setAutoHideAppBarEnabled(true);
      await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
      for (final swapped in [false, true]) {
        await appearance.setPanelOrder(
          swapped ? ['date', 'time', 'weather'] : ['settings', 'systemSettings', 'inputs', 'notifications'],
          swapped ? ['inputs', 'notifications', 'settings', 'systemSettings'] : ['weather', 'date', 'time'],
        );
        await tester.pumpAndSettle();
        final state = tester.state<FocusAwareAppBarState>(
          find.byType(FocusAwareAppBar),
        );
        for (final node in [
          state.notificationsFocusNode,
          state.inputsFocusNode,
        ]) {
          final button = find.byWidgetPredicate(
            (w) => w is TopPanelItem && w.focusNode == node,
          );
          node.requestFocus();
          await tester.pumpAndSettle();
          final buttonRect = tester.getRect(button);
          final right = buttonRect.center.dx > 480;
          await tester.tap(button);
          await tester.pumpAndSettle();
          expect(
            tester.getSize(find.byKey(const Key('top_panel_visibility'))).height,
            kToolbarHeight,
          );
          final surface = find.descendant(
            of: find.byType(SidePanelDialog), matching: find.byType(Material),
          ).first;
          expect(tester.getTopLeft(surface).dy, greaterThanOrEqualTo(kToolbarHeight));
          final menuRect = tester.getRect(surface);
          expectWidgetHighlight(tester, button);
          expect(menuRect.height, lessThan(300));
          expect(menuRect.left, lessThanOrEqualTo(buttonRect.right));
          expect(menuRect.right, greaterThanOrEqualTo(buttonRect.left));
          expect(menuRect.right, lessThanOrEqualTo(960));
          expect(
            tester.getTopLeft(find.byType(LauncherPanelBackdrop)).dy,
            0,
          );
          if (node == state.inputsFocusNode) {
            expect(
              tester.widget<InputsPanel>(find.byType(InputsPanel)).isRightSide,
              right,
            );
            await Navigator.of(tester.element(find.byType(InputsPanel)))
                .maybePop();
          } else {
            expect(
              tester
                  .widget<NotificationsPanel>(find.byType(NotificationsPanel))
                  .isRightSide,
              right,
            );
            expect(
              tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
              anyOf(isNull, Colors.transparent),
            );
            expect(
              find.byKey(const ValueKey('notification-backdrop')),
              findsOneWidget,
            );
            await Navigator.of(tester.element(find.byType(NotificationsPanel)))
                .maybePop();
          }
          await tester.pumpAndSettle();
          expect(node.hasFocus, true);
          expect(tester.widget<TopPanelItem>(button).selected, isFalse);
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  for (final anchorLeft in [0.0, 440.0, 900.0]) {
   for (final count in [1, 30]) {
    testWidgets('anchored inputs fit content and scroll long lists: $count at $anchorLeft', (tester) async {
      when(inputs.inputs).thenReturn([
        for (var i = 0; i < count; i++)
          TvInput(id: '$i', label: 'HDMI ${i + 1}', type: TvInputType.hdmi),
      ]);
      await pump(tester, InputsPanel(
        anchor: Rect.fromLTWH(anchorLeft, 0, 48, 56), topInset: kToolbarHeight,
      ));
      final surface = find.descendant(
        of: find.byType(SidePanelDialog), matching: find.byType(Material),
      ).first;
      final rect = tester.getRect(surface);
      expect(rect.left, (anchorLeft + 24 - rect.width / 2).clamp(16, 960 - rect.width - 16));
      expect(rect.top, 64);
      expect(rect.bottom, lessThanOrEqualTo(528));
      if (count == 1) {
        expect(rect.height, lessThan(250));
      } else {
        await tester.scrollUntilVisible(find.text('HDMI 30'), 200,
            scrollable: find.byType(Scrollable).last);
        expect(find.text('HDMI 30').hitTestable(), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
   }
  }

  testWidgets('visibility group opens common settings with separate editors', (tester) async {
    await pump(tester, const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName));
    final time = tester.getCenter(find.text('Показывать время')).dy;
    final date = tester.getCenter(find.text('Показывать дату')).dy;
    final weatherSwitch = tester.getCenter(find.text('Показывать погоду')).dy;
    final blockSettings = tester.getCenter(find.text('Настройки блока')).dy;
    expect(time, lessThan(date));
    expect(date, lessThan(weatherSwitch));
    expect(weatherSwitch, lessThan(blockSettings));
    expect(find.text('Оформление часов'), findsNothing);
    await tester.tap(find.text('Настройки блока'));
    await tester.pumpAndSettle();
    expect(find.byType(InformationSettingsPage), findsOneWidget);
    expect(find.text('Оформление часов'), findsOneWidget);
    expect(find.text('Настройки даты'), findsOneWidget);
    expect(find.text('Настройки погоды'), findsOneWidget);
    expect(find.text('Открывать календарь по нажатию на дату'), findsOneWidget);
    await tester.tap(find.text('Настройки даты'));
    await tester.pumpAndSettle();
    expect(find.text('Открывать календарь по нажатию на дату'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home and popup render and update the same shared clock style', (tester) async {
    final panel = RemotePanelService(prefs);
    addTearDown(panel.dispose);
    await panel.set('inheritAppearance', false);
    await panel.setAppearance('panelTextSize', 10);
    await panel.setAppearance('panelTextColor', 0xff000000);
    await panel.setAppearance('panelTextBackground', false);
    await pump(tester, Scaffold(body: Column(children: [
      const SizedBox(height: kToolbarHeight, child: FocusAwareAppBar()),
      SizedBox(height: kToolbarHeight, child: FocusAwareAppBar(remotePanel: panel)),
    ])));
    await appearance.set('panelClockStyle', {'font': 'serif', 'size': 30, 'inheritBackground': true});
    await tester.pumpAndSettle();
    final clocks = tester.widgetList<PanelClock>(find.byType(PanelClock));
    expect(clocks.length, 2);
    for (final clock in clocks) {
      final item = tester.widget<TopPanelItem>(find.descendant(of: find.byWidget(clock), matching: find.byType(TopPanelItem)));
      expect(item.appearance!.panelTextStyle, appearance.appearance.panelTextStyle);
      expect(item.appearance!.panelItemBackground, appearance.appearance.panelItemBackground);
      expect(clock.style.values, appearance.appearance.clockStyle.values);
      expect(clock.style.textStyle(appearance.appearance.panelTextStyle).fontFamily, 'PanelSerif');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('clock style route stays below toolbar and Back restores block settings', (tester) async {
    await pump(tester, const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName));
    await tester.tap(find.text('Настройки блока'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оформление часов'));
    await tester.pumpAndSettle();
    expect(find.byType(PanelClockStylePage), findsOneWidget);
    expect(tester.getTopLeft(find.byType(PanelClockStylePage)).dy, greaterThan(kToolbarHeight));
    await Navigator.of(tester.element(find.byType(PanelClockStylePage))).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(InformationSettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final combined in [false, true]) {
  for (final remote in [false, true]) {
    testWidgets('date calendar is opt-in, keeps panel visible and restores focus: remote=$remote combined=$combined', (tester) async {
      await appearance.set('panelCombinedInformation', combined);
      final panel = RemotePanelService(prefs);
      addTearDown(panel.dispose);
      await pump(tester, Scaffold(appBar: FocusAwareAppBar(remotePanel: remote ? panel : null)));
      final date = find.byKey(const Key('statusbar_date'));
      final item = find.ancestor(of: date, matching: find.byType(TopPanelItem));
      expect(tester.widget<TopPanelItem>(item).onPressed, isNull);
      await appearance.set('panelDateCalendar', true);
      await pump(tester, Scaffold(appBar: FocusAwareAppBar(remotePanel: remote ? panel : null)));
      final state = tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar));
      state.dateFocusNode.requestFocus();
      await tester.pumpAndSettle();
      await settings.setAutoHideAppBarEnabled(true);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(PanelCalendarDialog), findsOneWidget);
      final calendarButton = find.byWidgetPredicate(
        (w) => w is TopPanelItem && w.focusNode == state.dateFocusNode,
      );
      expectWidgetHighlight(tester, calendarButton);
      final material = MaterialLocalizations.of(tester.element(find.byType(PanelCalendarDialog)));
      expect(find.textContaining(material.formatMonthYear(DateTime.now())), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('top_panel_visibility'))).height, kToolbarHeight);
      await Navigator.of(tester.element(find.byType(PanelCalendarDialog))).maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(PanelCalendarDialog), findsNothing);
      expect(state.dateFocusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
  }

  for (final popup in [false, true]) {
    for (final locale in [const Locale('ru'), const Locale('ar')]) {
      testWidgets('panel wraps physical sides and held arrows: popup=$popup locale=$locale', (tester) async {
        final panel = RemotePanelService(prefs);
        addTearDown(panel.dispose);
        await appearance.set('panelWrapNavigation', true);
        await appearance.set('panelDateCalendar', true);
        await panel.set('dateCalendar', true);
        await panel.set('inheritAppearance', false);
        await appearance.setPanelOrder(['date'], ['settings', 'systemSettings']);
        await panel.setPanelOrder(['date'], ['settings', 'systemSettings']);
        await pump(tester, Scaffold(appBar: FocusAwareAppBar(remotePanel: popup ? panel : null)), locale: locale);
        final items = find.byWidgetPredicate((w) => w is TopPanelItem && w.onPressed != null)
          .evaluate().map((e) => e.widget as TopPanelItem).toList();
        items.sort((a, b) => tester.getCenter(find.byWidget(a)).dx.compareTo(tester.getCenter(find.byWidget(b)).dx));
        final nodes = items.map((item) => Focus.of(tester.element(find.descendant(
          of: find.byWidget(item), matching: find.byType(InkWell)).first))).toList();
        expect(nodes.length, greaterThanOrEqualTo(3));
        nodes.first.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(nodes.last.hasFocus, isTrue);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(nodes.first.hasFocus, isTrue);
        for (var i = 1; i <= nodes.length * 3; i++) {
          await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(nodes[i % nodes.length].hasFocus, isTrue);
        }
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await appearance.set('panelWrapNavigation', false);
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
        expect(nodes.first.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('remote panel renders mixed sides independently of home order', (tester) async {
    final panel = RemotePanelService(prefs);
    addTearDown(panel.dispose);
    await panel.setPanelOrder(['time', 'date'], ['settings', 'network']);
    await appearance.setPanelOrder(['network', 'settings'], ['date', 'time']);
    await pump(tester, Scaffold(appBar: FocusAwareAppBar(remotePanel: panel)));
    final clock = find.byKey(const Key('statusbar_clock'));
    final date = find.byKey(const Key('statusbar_date'));
    final settingsIcon = find.byIcon(Icons.settings_outlined);
    final networkIcon = find.byIcon(Icons.signal_wifi_4_bar);
    expect(tester.getCenter(clock).dx, lessThan(tester.getCenter(date).dx));
    expect(tester.getCenter(date).dx, lessThan(tester.getCenter(settingsIcon).dx));
    expect(tester.getCenter(settingsIcon).dx, lessThan(tester.getCenter(networkIcon).dx));
    expect(clock, findsOneWidget);
    expect(settingsIcon, findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sleep timer submenus keep toolbar space on push and Back', (tester) async {
    await pump(tester, const SettingsPanel(initialRoute: SleepTimerSettingsPage.routeName));
    final panel = find.byType(SidePanelDialog);
    final initialRect = tester.getRect(find.byType(SleepTimerSettingsPage));
    void expectToolbarSpace() {
      expect(tester.widget<SidePanelDialog>(panel).topInset, kToolbarHeight);
      expectSinglePanelBackdrop(tester, top: kToolbarHeight);
      final navigator = find.descendant(of: panel, matching: find.byType(Navigator)).first;
      expect(tester.getRect(navigator), initialRect);
      expect(tester.takeException(), isNull);
    }
    Future<void> open(String label) async {
      await tester.ensureVisible(find.text(label).last);
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expectToolbarSpace();
    }
    Future<void> back() async {
      final navigator = tester.state<NavigatorState>(
        find.descendant(of: panel, matching: find.byType(Navigator)).first,
      );
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expectToolbarSpace();
    }
    expectToolbarSpace();
    await open('Настройки');
    await open('Показывать при активном таймере');
    await back();
    await back();
    await open('Таймеры');
    await open('Добавить таймер');
    await back();
    await back();
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'top panel menu includes remote panel, reserves toolbar and restores Back',
    (tester) async {
      await pump(
        tester,
        const SettingsPanel(initialRoute: StatusBarPanelPage.routeName),
      );
      expect(find.text('Оформление'), findsOneWidget);
      expect(find.text('Объекты'), findsOneWidget);
      expect(find.text('Порядок объектов'), findsOneWidget);
      expect(find.text('Панель быстрых настроек'), findsOneWidget);
      expect(find.text('Показывать время'), findsNothing);
      expect(
        tester.getTopLeft(find.byType(StatusBarPanelPage)).dy,
        greaterThan(kToolbarHeight),
      );
      await tester.tap(find.text('Оформление'));
      await tester.pumpAndSettle();
      expect(find.byType(AppearancePage), findsOneWidget);
      expect(
        tester.getTopLeft(find.byType(AppearancePage)).dy,
        greaterThan(kToolbarHeight),
      );
      await Navigator.of(tester.element(find.byType(AppearancePage)))
          .maybePop();
      await tester.pumpAndSettle();
      expect(find.byType(StatusBarPanelPage), findsOneWidget);
    },
  );

  testWidgets(
    'panel always has independent controls and choices apply immediately',
    (tester) async {
      await appearance.set('panelTextSize', 22);
      await appearance.set('blurPanel', true);
      await appearance.set('panelStyle', 'theme');
      await pump(tester, const SettingsPanel(initialRoute: 'panel_appearance'));
      expect(find.text('Стиль верхней панели'), findsNothing);
      expect(find.text('Поменять местами левую и правую стороны'), findsNothing);
      expect(find.text('Фон панели'), findsOneWidget);
      expect(find.byType(PanelAppearanceSurface), findsNothing);
      expect(appearance.appearance.panelTextSize, 22);
      expect(appearance.appearance.blurPanel, isTrue);
      await tester.scrollUntilVisible(find.text('Размер текста и кнопок'), 180);
      await Scrollable.ensureVisible(
        tester.element(find.text('Размер текста и кнопок')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Размер текста и кнопок')))
          .requestFocus();
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();
      }
      await tester.pumpAndSettle();
      expect(AppearanceService(prefs).appearance.panelTextSize, 16);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'usage permission lives in traffic settings and never on the panel',
    (tester) async {
      await settings.setShowDataWidgetInStatusBar(false);
      await pump(
        tester,
        const SettingsPanel(initialRoute: StatusBarObjectsPage.routeName),
      );
      expect(find.text('Разрешить доступ к статистике'), findsNothing);
      final toggle = find.widgetWithText(
        RoundedSwitchListTile,
        AppLocalizations.of(tester.element(find.byType(StatusBarObjectsPage)))!
            .showTraffic,
      );
      await tester.scrollUntilVisible(toggle, 180);
      await Scrollable.ensureVisible(tester.element(toggle), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final trafficSettings = find.text(
        AppLocalizations.of(tester.element(toggle))!.trafficSettings,
      );
      await tester.ensureVisible(trafficSettings);
      await tester.tap(trafficSettings);
      await tester.pumpAndSettle();
      final permission = find.text(
        AppLocalizations.of(tester.element(trafficSettings))!.grantUsagePermission,
      );
      await tester.ensureVisible(permission);
      await tester.tap(permission);
      verify(network.requestPermission()).called(1);
      await pump(tester, const Scaffold(body: DailyDataUsageWidget()));
      expect(find.byType(TextButton), findsNothing);
      expect(find.byType(RichText), findsNothing);
    },
  );

  testWidgets(
    'moving objects preserves elements, typography updates live and settings retain auto-hidden panel',
    (tester) async {
      await settings.setShowDataWidgetInStatusBar(false);
      await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      final clock = find.byKey(const Key('statusbar_clock'));
      final networkIcon = find.byIcon(Icons.signal_wifi_4_bar);
      final date = find.byKey(const Key('statusbar_date'));
      final settingsElement = tester.element(settingsIcon);
      expect(
        tester.getCenter(settingsIcon).dx,
        lessThan(tester.getCenter(networkIcon).dx),
      );
      expect(tester.getCenter(date).dx, lessThan(tester.getCenter(clock).dx));
      expect(
        tester.getCenter(settingsIcon).dx,
        lessThan(tester.getCenter(clock).dx),
      );
      await appearance.setPanelOrder(
        appearance.appearance.panelOrder('panelInfoOrder').reversed.toList(),
        appearance.appearance.panelOrder('panelButtonsOrder').reversed.toList(),
      );
      await appearance.set('panelTextSize', 24);
      await appearance.set('panelTextColor', 0xff80cbc4);
      await appearance.set('panelFont', 'monospace');
      await tester.pumpAndSettle();
      expect(tester.element(settingsIcon), same(settingsElement));
      expect(
        tester.getCenter(settingsIcon).dx,
        greaterThan(tester.getCenter(networkIcon).dx),
      );
      expect(
        tester.getCenter(date).dx,
        greaterThan(tester.getCenter(clock).dx),
      );
      expect(
        tester.getCenter(settingsIcon).dx,
        greaterThan(tester.getCenter(clock).dx),
      );
      final barState = tester.state<FocusAwareAppBarState>(
        find.byType(FocusAwareAppBar),
      );
      barState.focusSettings();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(barState.systemSettingsFocusNode.hasFocus, isTrue);
      await appearance.set('panelButtonsOrder', [
        'network',
        'settings',
        'systemSettings',
        'inputs',
        'notifications',
        'traffic',
      ]);
      await tester.pumpAndSettle();
      expect(barState.systemSettingsFocusNode.hasFocus, isTrue);
      expect(
        tester.getCenter(settingsIcon).dx,
        greaterThan(tester.getCenter(networkIcon).dx),
      );
      for (final item in find.byType(TopPanelItem).evaluate()) {
        final textContext = find
            .descendant(
              of: find.byWidget(item.widget),
              matching: find.byType(DefaultTextStyle),
            )
            .first;
        final textStyle = tester.widget<DefaultTextStyle>(textContext).style;
        expect(textStyle.fontFamily, 'PanelMono');
        expect(textStyle.fontSize, 24);
        expect(textStyle.color, const Color(0xff80cbc4));
      }
      await settings.setAutoHideAppBarEnabled(true);
      final state = tester.state<FocusAwareAppBarState>(
        find.byType(FocusAwareAppBar),
      );
      state.focusSettings();
      await tester.pumpAndSettle();
      final panelCenter = tester.getCenter(settingsIcon).dy;
      await tester.tap(settingsIcon);
      await tester.pumpAndSettle();
      expect(tester.getCenter(settingsIcon).dy, panelCenter);
      expect(
        tester
            .widget<AnimatedContainer>(
              find.byKey(const Key('top_panel_visibility')),
            )
            .constraints!
            .maxHeight,
        kToolbarHeight,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'network and settings use identical hover and remote focus decoration',
    (tester) async {
      await settings.setShowDataWidgetInStatusBar(false);
      await pump(tester, const Scaffold(appBar: FocusAwareAppBar()));
      final settingsIcon = find.byIcon(Icons.settings_outlined);
      final wifi = find.byIcon(Icons.signal_wifi_4_bar);
      BoxDecoration decoration(Finder icon) {
        final item = find
            .ancestor(of: icon, matching: find.byType(TopPanelItem))
            .first;
        return tester
                .widget<AnimatedContainer>(
                  find.descendant(
                    of: item,
                    matching: find.byType(AnimatedContainer),
                  ),
                )
                .decoration!
            as BoxDecoration;
      }

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: const Offset(-1, -1));
      await mouse.moveTo(tester.getCenter(settingsIcon));
      await tester.pumpAndSettle();
      final settingsHover = decoration(settingsIcon);
      await mouse.moveTo(tester.getCenter(wifi));
      await tester.pumpAndSettle();
      expect(decoration(wifi), settingsHover);
      await mouse.removePointer();
      Focus.of(tester.element(settingsIcon)).requestFocus();
      await tester.pumpAndSettle();
      final settingsFocus = decoration(settingsIcon);
      Focus.of(tester.element(wifi)).requestFocus();
      await tester.pumpAndSettle();
      expect(decoration(wifi), settingsFocus);
      expect(tester.takeException(), isNull);
    },
  );
}
