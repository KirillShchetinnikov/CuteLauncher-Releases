import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/daily_data_usage_widget.dart';
import 'package:flauncher/widgets/weather_status_bar_widget.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/remote_panel_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.mocks.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    testWidgets(
      'remote objects follow availability without losing choice: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'show_weather_in_status_bar': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final panel = RemotePanelService(prefs);
        await panel.show('network', false);
        final settings = SettingsService(prefs);
        final appearance = AppearanceService(prefs);
        final network = MockNetworkService();
        final notifications = MockNotificationsService();
        final inputs = MockTvInputsService();
        final weather = MockWeatherService();
        final changes = ChangeNotifier();
        for (final dynamic source in [
          network,
          notifications,
          inputs,
          weather,
        ]) {
          when(source.addListener(any)).thenAnswer((call) {
            changes.addListener(
              call.positionalArguments.single as VoidCallback,
            );
          });
          when(source.removeListener(any)).thenAnswer((call) {
            changes.removeListener(
              call.positionalArguments.single as VoidCallback,
            );
          });
        }
        var available = false;
        when(network.hasUsageStatsPermission).thenAnswer((_) => available);
        when(network.getDataUsageForPeriod(any)).thenAnswer((_) async => 123);
        when(network.dailyDataUsage).thenReturn(123);
        when(notifications.hasPermission).thenAnswer((_) => available);
        when(notifications.notifications).thenReturn([]);
        when(inputs.hasInputs).thenAnswer((_) => available);
        when(weather.hasWeather).thenAnswer((_) => available);
        when(weather.stale).thenReturn(false);
        when(weather.weatherData)
            .thenReturn(const WeatherData(currentTemp: 20));
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: panel),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider<NetworkService>.value(value: network),
              ChangeNotifierProvider<NotificationsService>.value(
                value: notifications,
              ),
              ChangeNotifierProvider<TvInputsService>.value(value: inputs),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                appBar: FocusAwareAppBar(remotePanel: panel),
                body: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => const RemotePanelPage(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        var page = find.byType(RemotePanelPage);
        final l = AppLocalizations.of(tester.element(page))!;
        expect(find.text(l.panelClockStyle), findsNothing);
        expect(find.text(l.dateSettings), findsNothing);
        expect(find.text(l.remotePanelPreview), findsNothing);
        expect(
          find.descendant(
            of: page,
            matching: find.byType(RoundedSwitchListTile),
          ),
          findsNothing,
        );
        expect(find.byIcon(Icons.swap_vert), findsOneWidget);
        expect(find.byIcon(Icons.widgets_outlined), findsOneWidget);
        await tester.tap(find.text(l.topPanelObjects));
        await tester.pumpAndSettle();
        page = find.byType(RemotePanelObjectsPage);
        expect(page, findsOneWidget);
        expect(find.descendant(of: page, matching: find.byType(FocusableSettingsTile)), findsNWidgets(RemotePanelService.ids.length));
        expect(find.text(l.informationSettings), findsNothing);
        expect(
          find.descendant(
            of: page,
            matching: find.byType(RoundedSwitchListTile),
          ),
          findsNWidgets(RemotePanelService.ids.length),
        );
        final bar = find.byType(FocusAwareAppBar);
        const ids = ['traffic', 'notifications', 'inputs', 'weather'];
        Finder toggle(String id) =>
            find.descendant(of: page, matching: find.byKey(ValueKey(id)));
        Finder object(String id) => find.descendant(
          of: bar,
          matching: switch (id) {
            'traffic' => find.byType(DailyDataUsageWidget),
            'weather' => find.byType(WeatherStatusBarWidget),
            'inputs' => find.byIcon(Icons.tv_outlined),
            _ => find.byIcon(Icons.notifications_outlined),
          },
        );
        void expectAvailability(bool expected) {
          for (final id in ids) {
            final tile = tester.widget<RoundedSwitchListTile>(toggle(id));
            expect(tile.enabled, expected, reason: id);
            expect(tile.value, expected, reason: id);
            expect(object(id), expected ? findsOneWidget : findsNothing);
          }
        }

        expectAvailability(false);
        final before = prefs.getString(RemotePanelService.preferenceKey);
        await tester.tap(
          find.descendant(of: toggle('traffic'), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        expect(prefs.getString(RemotePanelService.preferenceKey), before);
        available = true;
        changes.notifyListeners();
        await tester.pumpAndSettle();
        expectAvailability(true);
        // Remote weather remains independent of the hidden home weather widget.
        expect(settings.showWeatherInStatusBar, isFalse);
        expect(
          find.descendant(of: bar, matching: find.text('20°C')),
          findsOneWidget,
        );
        available = false;
        changes.notifyListeners();
        await tester.pumpAndSettle();
        expectAvailability(false);
        expect(prefs.getString(RemotePanelService.preferenceKey), before);
        available = true;
        changes.notifyListeners();
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(of: toggle('traffic'), matching: find.byType(Switch)),
        );
        await tester.pumpAndSettle();
        expect(panel.visible('traffic'), isFalse);
        available = false;
        changes.notifyListeners();
        await tester.pumpAndSettle();
        available = true;
        changes.notifyListeners();
        await tester.pumpAndSettle();
        final traffic = tester.widget<RoundedSwitchListTile>(toggle('traffic'));
        expect(traffic.enabled, isTrue);
        expect(traffic.value, isFalse);
        expect(object('traffic'), findsNothing);
        final timeToggle = find.descendant(
          of: toggle('time'),
          matching: find.byType(Switch),
        );
        await tester.ensureVisible(timeToggle);
        await tester.tap(timeToggle);
        await tester.pumpAndSettle();
        expect(panel.visible('time'), isFalse);
        expect(RemotePanelService(prefs).visible('time'), isFalse);
        await tester.tap(timeToggle);
        await tester.pumpAndSettle();
        expect(panel.visible('time'), isTrue);
        await Navigator.of(tester.element(page)).maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(RemotePanelPage), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        changes.dispose();
        panel.dispose();
        appearance.dispose();
        settings.dispose();
      },
    );
  }
}
