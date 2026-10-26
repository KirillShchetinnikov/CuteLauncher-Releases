import 'package:flauncher/tile_appearance.dart';
import 'dart:async';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/remote_panel.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final combined in [false, true]) {
    testWidgets('remote calendar opens with OK and restores date focus: combined=$combined', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final panel = RemotePanelService(prefs);
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      addTearDown(panel.dispose);
      addTearDown(appearance.dispose);
      addTearDown(settings.dispose);
      for (final id in RemotePanelService.ids) {
        if (!['settings', 'time', 'date'].contains(id)) await panel.show(id, false);
      }
      // Ignore the legacy panel-specific flag, even with custom panel appearance.
      await panel.set('dateCalendar', true);
      await panel.set('inheritAppearance', false);
      await appearance.set('panelCombinedInformation', combined);
      final inputs = MockTvInputsService();
      final notifications = MockNotificationsService();
      final weather = MockWeatherService();
      when(weather.weatherData).thenReturn(null);
      when(weather.stale).thenReturn(false);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(remotePanelChannel, (_) async => null);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(remotePanelChannel, null));
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: appearance),
        ChangeNotifierProvider.value(value: panel),
        ChangeNotifierProvider<TvInputsService>.value(value: inputs),
        ChangeNotifierProvider<NotificationsService>.value(value: notifications),
        ChangeNotifierProvider<WeatherService>.value(value: weather),
      ], child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const RemotePanel(),
      )));
      await tester.pumpAndSettle();
      final state = tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar));
      expect(state.dateFocusNode.context, isNull);
      await panel.set('dateCalendar', false);
      await appearance.set('panelDateCalendar', true);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(state.dateFocusNode.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(PanelCalendarDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(PanelCalendarDialog), findsNothing);
      expect(state.dateFocusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
  for (final closeDuringLoad in [false, true]) {
    testWidgets(
      'panel waits for initial sources before painting: close=$closeDuringLoad',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final panel = RemotePanelService(prefs);
        for (final id in ['network', 'nightMode']) {
          await panel.show(id, false);
        }
        final settings = SettingsService(prefs);
        final inputs = MockTvInputsService();
        final notifications = MockNotificationsService();
        final weather = MockWeatherService();
        final network = MockNetworkService();
        final timer = SleepTimerService();
        final timerLoad = Completer<Object?>();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SleepTimerService.channel,
          (_) => timerLoad.future,
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SleepTimerService.channel,
            null,
          );
        });
        final listeners = <VoidCallback>[];
        var inputsReady = false,
            notificationsReady = false,
            weatherLoading = false;
        when(inputs.initialized).thenAnswer((_) => inputsReady);
        when(inputs.hasInputs).thenAnswer((_) => inputsReady);
        when(notifications.initialized).thenAnswer((_) => notificationsReady);
        when(notifications.hasPermission).thenAnswer((_) => notificationsReady);
        when(notifications.notifications).thenReturn([]);
        when(weather.initialized).thenReturn(false);
        when(weather.loading).thenAnswer((_) => weatherLoading);
        when(weather.hasWeather).thenReturn(false);
        for (final dynamic source in [inputs, notifications, weather]) {
          when(source.addListener(any)).thenAnswer((call) {
            listeners.add(call.positionalArguments.single as VoidCallback);
          });
          when(source.removeListener(any)).thenAnswer((call) {
            listeners.remove(call.positionalArguments.single);
          });
        }
        final networkLoad = Completer<void>();
        when(network.initialLoad).thenAnswer((_) => networkLoad.future);
        when(network.hasUsageStatsPermission).thenReturn(false);
        final calls = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          remotePanelChannel,
          (call) async {
            calls.add(call.method);
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            remotePanelChannel,
            null,
          ),
        );
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsService>.value(value: settings),
              ChangeNotifierProvider<TvInputsService>.value(value: inputs),
              ChangeNotifierProvider<NotificationsService>.value(
                value: notifications,
              ),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
              ChangeNotifierProvider<NetworkService>.value(value: network),
              ChangeNotifierProvider<SleepTimerService>.value(value: timer),
              ChangeNotifierProvider(create: (_) => AppearanceService(prefs)),
              ChangeNotifierProvider.value(value: panel),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const RemotePanel(),
            ),
          ),
        );
        expect(find.byType(FocusAwareAppBar), findsNothing);
        expect(calls, isNot(contains('ready')));
        inputsReady = true;
        for (final listener in List<VoidCallback>.of(listeners)) {
          listener();
        }
        await tester.pump();
        expect(find.byType(FocusAwareAppBar), findsNothing);
        if (closeDuringLoad) {
          await tester.binding.handlePopRoute();
          await tester.pumpWidget(const SizedBox());
          expect(calls, contains('close'));
          expect(listeners, isEmpty);
        }
        notificationsReady = true;
        weatherLoading = true;
        for (final listener in List<VoidCallback>.of(listeners)) {
          listener();
        }
        await tester.pump();
        expect(calls, isNot(contains('ready')));
        networkLoad.complete();
        await tester.pump();
        expect(calls, isNot(contains('ready')));
        timerLoad.complete({'remainingMs': 60000, 'exactAllowed': true});
        await tester.pump();
        await tester.pump();
        if (closeDuringLoad) {
          expect(calls, isNot(contains('ready')));
        } else {
          expect(calls.where((call) => call == 'ready'), hasLength(1));
          expect(find.byIcon(Icons.tv_outlined), findsOneWidget);
          expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
          final first = tester.getRect(find.byIcon(Icons.settings_outlined));
          await tester.pump(const Duration(milliseconds: 200));
          expect(tester.getRect(find.byIcon(Icons.settings_outlined)), first);
          final state = tester.state<FocusAwareAppBarState>(
            find.byType(FocusAwareAppBar),
          );
          expect(state.settingsFocusNode.hasFocus, isTrue);
          await tester.pumpWidget(const SizedBox());
        }
        timer.dispose();
        settings.dispose();
        panel.dispose();
      },
    );
  }
  test('remote style inheritance, validation and reset preserve objects', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final panel = RemotePanelService(prefs);
    const home = TileAppearance({'panelColor': 0xff123456, 'panelTextSize': 24, 'blurPanel': true});
    expect(panel.inheritAppearance, isTrue);
    expect(panel.appearanceFor(home).panelTextSize, 24);
    expect(panel.appearanceFor(home).blurPanel, isFalse);
    await panel.show('weather', false);
    await panel.setPanelOrder(['time'], ['settings', 'date']);
    final layout = panel.layout;
    await panel.setAppearance('panelColor', 0xffabcdef);
    await panel.setAppearance('panelTextSize', 14);
    await panel.setAppearance('blurPanel', true);
    await panel.set('inheritAppearance', false);
    final restored = RemotePanelService(prefs);
    expect(restored.appearanceFor(home).panelTextSize, 14);
    expect(restored.appearanceFor(home).color('panelColor'), const Color(0xffabcdef));
    expect(restored.ownAppearance.values.containsKey('blurPanel'), isFalse);
    await restored.set('inheritAppearance', true);
    expect(restored.appearanceFor(home).panelTextSize, 24);
    await restored.resetAppearance();
    expect(restored.inheritAppearance, isTrue);
    expect(restored.ownAppearance.values, isEmpty);
    expect(restored.layout.left, layout.left);
    expect(restored.layout.right, layout.right);
    expect(restored.visible('weather'), isFalse);
    restored.dispose(); panel.dispose();
  });
  test('separate panel preferences preserve home settings and normalize order', () async {
    SharedPreferences.setMockInitialValues({'show_time_in_status_bar': false});
    final prefs = await SharedPreferences.getInstance();
    final panel = RemotePanelService(prefs);
    await panel.set('order', ['time', 'time', 'unknown', 'date']);
    await panel.show('weather', false);
    await panel.setAppearance('panelOpacity', .65);
    expect(panel.order.take(2), ['time', 'date']);
    expect(panel.order.toSet().length, RemotePanelService.ids.length);
    expect(prefs.getBool('show_time_in_status_bar'), false);
    final restored = RemotePanelService(prefs);
    expect(restored.visible('weather'), false);
    expect(restored.ownAppearance.number('panelOpacity'), .65);
    restored.dispose(); panel.dispose();
  });
  testWidgets('overlay paints full toolbar background without dimming content and Back closes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final panel = RemotePanelService(prefs);
    for (final id in RemotePanelService.ids) {
      if (!['settings', 'time', 'date'].contains(id)) await panel.show(id, false);
    }
    await panel.set('inheritAppearance', false);
    await panel.setAppearance('panelColor', 0xff123456);
    await panel.setAppearance('panelOpacity', .8);
    final settings = MockSettingsService();
    when(settings.autoHideAppBarEnabled).thenReturn(true);
    when(settings.showDateInStatusBar).thenReturn(false);
    when(settings.showTimeInStatusBar).thenReturn(false);
    when(settings.dateFormat).thenReturn(SettingsService.defaultDateFormat);
    when(settings.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
    final inputs = MockTvInputsService();
    final notifications = MockNotificationsService();
    final weather = MockWeatherService();
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(remotePanelChannel, (call) async {
      calls.add(call.method); return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(remotePanelChannel, null));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<TvInputsService>.value(value: inputs),
      ChangeNotifierProvider<NotificationsService>.value(value: notifications),
      ChangeNotifierProvider<WeatherService>.value(value: weather),
      ChangeNotifierProvider(create: (_) => AppearanceService(prefs)),
      ChangeNotifierProvider.value(value: panel),
    ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: const RemotePanel())));
    await tester.pumpAndSettle();
    expect(calls, contains('ready'));
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
    expect(find.byKey(const Key('remote_panel_dim')), findsNothing);
    final bar = tester.widget<AppBar>(find.descendant(of: find.byType(FocusAwareAppBar), matching: find.byType(AppBar)));
    expect((bar.flexibleSpace! as ColoredBox).color, const Color(0xff123456).withValues(alpha: .8));
    final background = find.byWidget(bar.flexibleSpace!);
    expect(tester.getSize(background), Size(tester.getSize(find.byType(AppBar)).width, kToolbarHeight));
    final homeAppearance = tester.element(find.byType(AppBar)).read<AppearanceService>();
    await homeAppearance.set('panelColor', 0xffabcdef);
    await homeAppearance.set('panelOpacity', .8);
    await panel.set('inheritAppearance', true);
    await tester.pumpAndSettle();
    final inheritedBar = tester.widget<AppBar>(find.byType(AppBar));
    expect((inheritedBar.flexibleSpace! as ColoredBox).color,
      const Color(0xffabcdef).withValues(alpha: .8));
    await tester.element(find.byType(AppBar)).read<AppearanceService>().set('panelColor', 0xff654321);
    await tester.pumpAndSettle();
    expect((tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace! as ColoredBox).color,
      const Color(0xff654321).withValues(alpha: .8));
    for (final opacity in [0.0, 1.0]) {
      await homeAppearance.set('panelOpacity', opacity);
      await tester.pumpAndSettle();
      expect((tester.widget<AppBar>(find.byType(AppBar)).flexibleSpace! as ColoredBox).color.a, opacity);
    }
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(calls, contains('close'));
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    panel.dispose();
  });
}
