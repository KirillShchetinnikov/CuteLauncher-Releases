import 'dart:async';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/sleep_timer_configuration.dart';
import 'package:flauncher/widgets/sleep_timer_menu.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/combined_information.dart';
import 'package:flauncher/widgets/weather_forecast_menu.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import '../mocks.mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;
  late MockTvInputsService mockTvInputsService;
  late MockNotificationsService mockNotificationsService;
  late MockWeatherService mockWeatherService;

  void setupSettingsDefaults(MockSettingsService service) {
    when(service.appKeyClickEnabled).thenReturn(false);
    when(service.homeKeyClickEnabled).thenReturn(false);
    final landscape = ValueNotifier<LandscapeDemoFrame?>(null);
    addTearDown(landscape.dispose);
    when(service.landscapeDemo).thenReturn(landscape);
    when(service.settingsMenuOnRight).thenReturn(false);
    when(service.autoHideAppBarEnabled).thenReturn(false);
    when(service.showNetworkIndicatorInStatusBar).thenReturn(false);
    when(service.showVolumeInStatusBar).thenReturn(false);
    when(service.showSystemInStatusBar).thenReturn(false);
    when(service.showNetworkSpeedInStatusBar).thenReturn(false);
    when(service.networkSpeedInterval).thenReturn(3);
    when(service.showDataWidgetInStatusBar).thenReturn(false);
    when(service.showDateInStatusBar).thenReturn(true);
    when(service.showTimeInStatusBar).thenReturn(true);
    when(service.showInputsWidgetInStatusBar).thenReturn(true);
    when(service.showNightModeInStatusBar).thenReturn(false);
    when(service.showSleepTimerInStatusBar).thenReturn(false);
    when(service.showSystemSettingsInStatusBar).thenReturn(true);
    when(service.showNotificationsWidgetInStatusBar).thenReturn(true);
    when(service.autoHideNotificationsWidget).thenReturn(false);
    when(service.dateFormat).thenReturn(SettingsService.defaultDateFormat);
    when(service.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
    when(service.showWeatherInStatusBar).thenReturn(false);
    when(service.showWeatherWarnings).thenReturn(false);
    when(service.useFahrenheit).thenReturn(false);
  }

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockTvInputsService = MockTvInputsService();
    mockNotificationsService = MockNotificationsService();
    mockWeatherService = MockWeatherService();

    setupSettingsDefaults(mockSettingsService);

    when(mockTvInputsService.hasInputs).thenReturn(false);
    when(mockNotificationsService.hasPermission).thenReturn(false);
    when(mockNotificationsService.notifications).thenReturn([]);
    when(mockWeatherService.hasWeather).thenReturn(false);
    when(mockWeatherService.weatherData).thenReturn(null);
    when(mockWeatherService.updatedAt).thenReturn(null);
    when(mockWeatherService.failure).thenReturn(null);
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        appBar: FocusAwareAppBar(),
        body: Container(),
      ),
    );
  }

  for (final popup in [false, true]) {
    for (final action in ['weather', 'calendar', 'both', 'none']) {
      testWidgets('legacy action=$action is ignored for time and weather: remote=$popup', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final remote = RemotePanelService(prefs);
        addTearDown(appearance.dispose); addTearDown(remote.dispose);
        await appearance.set('panelCombinedInformation', true);
        await remote.set('combinedInformation', true);
        if (popup) await appearance.set('panelInformationPlacement', 'background');
        await appearance.set('panelInformationAction', action);
        when(mockSettingsService.showDateInStatusBar).thenReturn(false);
        when(mockSettingsService.showWeatherInStatusBar).thenReturn(true);
        when(mockWeatherService.configuration).thenReturn(const WeatherConfiguration());
        when(mockWeatherService.loading).thenReturn(false);
        when(mockWeatherService.stale).thenReturn(false);
        for (final id in RemotePanelService.ids) {
          await remote.show(id, ['time', 'weather'].contains(id));
        }
        await tester.pumpWidget(MultiProvider(providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(appBar: FocusAwareAppBar(remotePanel: popup ? remote : null)))));
        await tester.pumpAndSettle();
        final item = tester.widget<TopPanelItem>(find.descendant(of: find.byType(CombinedInformation),
          matching: find.byType(TopPanelItem)));
        expect(item.onPressed, isNotNull);
        item.focusNode!.requestFocus(); await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter); await tester.pumpAndSettle();
        expect(find.byType(WeatherForecastMenu), findsOneWidget);
        expect(find.byType(PanelCalendarDialog), findsOneWidget);
        await tester.tap(find.byType(MenuHeaderAction));
        await tester.pumpAndSettle();
        expect(find.byType(InformationSettingsPage), findsOneWidget);
        await appearance.set('panelInformationAction', 'none');
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(WeatherForecastMenu), findsOneWidget);
        expect(find.byType(PanelCalendarDialog), findsOneWidget);
        expect(tester.widget<MenuHeaderAction>(find.byType(MenuHeaderAction)).focusNode!.hasFocus, isTrue);
        await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
        expect(item.focusNode!.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }


  for (final id in ['time', 'date', 'weather']) {
    testWidgets('singleton $id uses the normal panel surface and opens its widget', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      addTearDown(appearance.dispose);
      await appearance.set('panelCombinedInformation', true);
      await appearance.set('panelInformationPlacements', {
        for (final member in ['time', 'date', 'weather']) member: member == id ? 'panel' : 'background',
      });
      await appearance.set('panelInformationStyle', {
        'inheritBackground': false, 'background': true, 'backgroundColor': 0xffff0000, 'radius': 0,
      });
      when(mockWeatherService.configuration).thenReturn(const WeatherConfiguration());
      when(mockWeatherService.loading).thenReturn(false);
      when(mockWeatherService.stale).thenReturn(false);
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider.value(value: appearance),
        ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
        ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
      ], child: createWidgetUnderTest()));
      await tester.pumpAndSettle();
      expect(find.byType(CombinedInformation), findsNothing);
      final content = id == 'weather' ? find.byIcon(Icons.cloud_outlined)
          : find.byKey(Key(id == 'time' ? 'statusbar_clock' : 'statusbar_date'));
      final item = tester.widget<TopPanelItem>(find.ancestor(of: content, matching: find.byType(TopPanelItem)));
      expect(item.backgroundColor, isNull);
      expect(item.borderRadius, isNull);
      expect(item.onPressed, isNotNull);
      item.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(id == 'weather' ? WeatherForecastMenu : PanelCalendarDialog), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(item.focusNode!.hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('separate weather opens forecast with OK and restores its focus', (tester) async {
    when(mockSettingsService.showWeatherInStatusBar).thenReturn(true);
    when(mockWeatherService.configuration).thenReturn(const WeatherConfiguration());
    when(mockWeatherService.loading).thenReturn(false);
    when(mockWeatherService.stale).thenReturn(false);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
      ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
      ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
      ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
    ], child: createWidgetUnderTest()));
    await tester.pumpAndSettle();
    final item = tester.widget<TopPanelItem>(find.ancestor(of: find.byIcon(Icons.cloud_outlined),
      matching: find.byType(TopPanelItem)));
    item.focusNode!.requestFocus(); await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter); await tester.pumpAndSettle();
    expect(find.byType(WeatherForecastMenu), findsOneWidget);
    await tester.binding.handlePopRoute(); await tester.pumpAndSettle();
    expect(item.focusNode!.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  for (final inputs in [false, true]) {
    testWidgets('menu opens before refresh and Back survives a late response: inputs=$inputs', (tester) async {
      final pending = Completer<void>();
      final timerReply = Completer<Object?>();
      final timer = SleepTimerService();
      when(mockTvInputsService.hasInputs).thenReturn(inputs);
      when(mockTvInputsService.inputs).thenReturn([]);
      when(mockTvInputsService.refreshInputs()).thenAnswer((_) => pending.future);
      when(mockSettingsService.showSleepTimerInStatusBar).thenReturn(!inputs);
      when(mockSettingsService.sleepTimerConfiguration).thenReturn(SleepTimerConfiguration());
      when(mockSettingsService.settingsMenuOnRight).thenReturn(false);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SleepTimerService.channel, (_) => timerReply.future);
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SleepTimerService.channel, null));
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
        ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ChangeNotifierProvider<SleepTimerService>.value(value: timer),
      ], child: createWidgetUnderTest()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(inputs ? Icons.tv_outlined : Icons.timer_outlined));
      await tester.pumpAndSettle();
      final menu = find.byType(inputs ? InputsPanel : SleepTimerMenu);
      expect(menu, findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      pending.complete();
      timerReply.complete({'remainingMs': 0, 'exactAllowed': true});
      await tester.pumpAndSettle();
      expect(menu, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      timer.dispose();
    });
  }

  testWidgets('combined information replaces existing slots and switching back restores them', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    await appearance.setPanelOrder(['settings', 'date'], ['time', 'weather']);
    await appearance.set('panelCombinedInformation', true);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: appearance),
      ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
      ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
      ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
      ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
    ], child: createWidgetUnderTest()));
    await tester.pumpAndSettle();
    expect(find.byType(CombinedInformation), findsOneWidget);
    expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
    expect(appearance.appearance.panelLayout.left, contains('date'));
    await appearance.set('panelInformationPlacement', 'background');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statusbar_date')), findsNothing);
    expect(find.byKey(const Key('statusbar_clock')), findsNothing);
    expect(find.byType(CombinedInformation), findsNothing);
    expect(appearance.appearance.panelLayout.left, contains('date'));
    await appearance.set('panelInformationPlacement', 'panel');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
    final bar = tester.getSize(find.byType(FocusAwareAppBar));
    await appearance.set('panelCombinedInformation', false);
    await tester.pumpAndSettle();
    expect(find.byType(CombinedInformation), findsNothing);
    expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
    expect(tester.getSize(find.byType(FocusAwareAppBar)), bar);
    expect(appearance.appearance.panelLayout.left, contains('date'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('FocusAwareAppBar renders settings button and date/time widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
    expect(find.byKey(const Key('statusbar_clock')), findsOneWidget);
  });

  testWidgets('system settings button opens Android settings using remote activation', (tester) async {
    final apps = MockAppsService();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: apps),
        ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
        ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
      ],
      child: createWidgetUnderTest(),
    ));
    expect(find.byIcon(Icons.android), findsOneWidget);
    final state = tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar));
    state.focusSettings();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(state.systemSettingsFocusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    verify(apps.openSettings()).called(1);
  });

  testWidgets('system settings visibility updates without hiding launcher settings', (tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
        ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
        ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
      ],
      child: createWidgetUnderTest(),
    ));
    expect(find.byIcon(Icons.android), findsOneWidget);
    when(mockSettingsService.showSystemSettingsInStatusBar).thenReturn(false);
    final element = tester.element(find.byType(FocusAwareAppBar));
    element.markNeedsBuild();
    await tester.pump();
    expect(find.byIcon(Icons.android), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    when(mockSettingsService.showSystemSettingsInStatusBar).thenReturn(true);
    element.markNeedsBuild();
    await tester.pump();
    expect(find.byIcon(Icons.android), findsOneWidget);
  });

  testWidgets('FocusAwareAppBar auto-hide logic', (WidgetTester tester) async {
    when(mockSettingsService.autoHideAppBarEnabled).thenReturn(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    // Initial state: app bar height should be 0 because auto-hide is true and focused is false
    final animatedContainer = tester.widget<AnimatedContainer>(find.byKey(const Key('top_panel_visibility')));
    expect(animatedContainer.constraints?.maxHeight, 0);

    // Trigger focus to show app bar
    final focusWidget = tester.widget<Focus>(find.descendant(of: find.byType(FocusAwareAppBar), matching: find.byType(Focus)).first);
    focusWidget.onFocusChange?.call(true);

    await tester.pumpAndSettle();

    // After focus: app bar height should be kToolbarHeight
    final animatedContainerFocused = tester.widget<AnimatedContainer>(find.byKey(const Key('top_panel_visibility')));
    expect(animatedContainerFocused.constraints?.maxHeight, kToolbarHeight);
  });

  testWidgets('FocusAwareAppBar renders inputs button based on setting and availability', (WidgetTester tester) async {
    // Case 1: showInputsWidgetInStatusBar is true, and hasInputs is true
    when(mockSettingsService.showInputsWidgetInStatusBar).thenReturn(true);
    when(mockTvInputsService.hasInputs).thenReturn(true);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );

    expect(find.byIcon(Icons.tv_outlined), findsOneWidget);

    // Case 2: showInputsWidgetInStatusBar is false, and hasInputs is true
    await tester.pumpWidget(Container()); // fully unmount previous tree
    await tester.pumpAndSettle();

    final mockSettingsService2 = MockSettingsService();
    setupSettingsDefaults(mockSettingsService2);
    when(mockSettingsService2.showInputsWidgetInStatusBar).thenReturn(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService2),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.tv_outlined), findsNothing);
  });

  testWidgets('FocusAwareAppBar auto-hide notification bell logic', (WidgetTester tester) async {
    // Case 1: autoHideNotificationsWidget is true, notification count is 0
    when(mockSettingsService.autoHideNotificationsWidget).thenReturn(true);
    when(mockNotificationsService.hasPermission).thenReturn(true);
    when(mockNotificationsService.notifications).thenReturn([]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
    expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);

    // Case 2: autoHideNotificationsWidget is true, notification count is > 0
    await tester.pumpWidget(Container()); // fully unmount previous tree
    await tester.pumpAndSettle();

    final item = NotificationItem(
      key: '1',
      packageName: 'com.example',
      title: 'Title',
      text: 'Text',
      isClearable: true,
    );
    when(mockNotificationsService.notifications).thenReturn([item]);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: mockSettingsService),
          ChangeNotifierProvider<TvInputsService>.value(value: mockTvInputsService),
          ChangeNotifierProvider<NotificationsService>.value(value: mockNotificationsService),
          ChangeNotifierProvider<WeatherService>.value(value: mockWeatherService),
        ],
        child: createWidgetUnderTest(),
      )
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
  });
}
