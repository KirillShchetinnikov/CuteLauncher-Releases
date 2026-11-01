import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/widgets/information_menu.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/weather_forecast_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  for (final initial in ['calendar', 'weather', 'both']) {
    for (final target in ['calendar', 'weather', 'both', 'none']) {
      testWidgets('$initial becomes $target after returning from settings', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        addTearDown(appearance.dispose);
        addTearDown(settings.dispose);
        await appearance.set('panelCombinedInformation', true);
        var currentAction = initial;
        final weather = MockWeatherService();
        when(weather.configuration).thenReturn(const WeatherConfiguration());
        when(weather.loading).thenReturn(false);
        when(weather.stale).thenReturn(false);
        when(weather.weatherData).thenReturn(null);
        when(weather.failure).thenReturn(null);
        when(weather.updatedAt).thenReturn(null);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () => showLauncherDialog<void>(
                      context: context,
                      styleDialog: false,
                      builder: (_) => InformationMenu(
                        anchor: const Rect.fromLTWH(40, 0, 100, 56),
                        initialAction: initial,
                        resolveAction: () => currentAction == 'none' ? null : currentAction,
                        weatherOrigin: false,
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        final menuState = tester.state(find.byType(InformationMenu));
        await tester.tap(find.byType(MenuHeaderAction));
        await tester.pumpAndSettle();
        expect(find.byType(InformationSettingsPage), findsOneWidget);
        currentAction = target;
        await tester.pumpAndSettle();
        // The original menu remains hidden for the whole settings visit.
        expect(find.byType(MenuHeaderAction), findsNothing);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        if (target == 'none') {
          expect(find.byType(InformationMenu), findsNothing);
          expect(find.text('open'), findsOneWidget);
        } else {
          expect(tester.state(find.byType(InformationMenu)), same(menuState));
          expect(
            find.byType(PanelCalendarDialog),
            target == 'weather' ? findsNothing : findsOneWidget,
          );
          expect(
            find.byType(WeatherForecastContent),
            target == 'calendar' ? findsNothing : findsOneWidget,
          );
          expect(
            tester
                .widget<MenuHeaderAction>(find.byType(MenuHeaderAction))
                .focusNode!
                .hasFocus,
            isTrue,
          );
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(InformationMenu), findsNothing);
        }
        verifyNever(weather.refresh());
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
