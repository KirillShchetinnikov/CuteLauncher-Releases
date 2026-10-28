import 'dart:async';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/sleep_timer_configuration.dart';
import 'package:flauncher/widgets/sleep_timer_menu.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/combined_information.dart';
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
    when(service.autoHideAppBarEnabled).thenReturn(false);
    when(service.showNetworkIndicatorInStatusBar).thenReturn(false);
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
