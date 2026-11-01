import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/widgets/weather_forecast_menu.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';

import '../mocks.mocks.dart';
import '../support/design_fixture.dart' show loadDesignFonts;

void main() {
  late AppearanceService appearance;
  late SettingsService settings;
  late MockWeatherService weather;
  final now = DateTime(2026, 10, 29, 12);
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
    weather = MockWeatherService();
    when(weather.configuration).thenReturn(const WeatherConfiguration());
    when(weather.loading).thenReturn(false);
    when(weather.failure).thenReturn(null);
    when(weather.stale).thenReturn(true);
    when(weather.updatedAt).thenReturn(now.subtract(const Duration(hours: 2)));
    when(weather.weatherData).thenReturn(
      WeatherData.fromJson({
        'location': 'Moscow',
        'timestamp': now.millisecondsSinceEpoch ~/ 1000,
        'forecasts': [
          {'minTemp': 0, 'maxTemp': 10, 'conditionCode': 800},
          {
            'minTemp': null,
            'maxTemp': 12,
            'conditionCode': 500,
            'precipProbability': 0,
          },
        ],
      }),
    );
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
  });

  Future<void> mount(
    WidgetTester tester, {
    bool both = false,
    double scale = 1,
    String locale = 'ru',
  }) async {
    await loadDesignFonts(tester);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider<WeatherService>.value(value: weather),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => RepaintBoundary(
            key: const Key('weather_preview'),
            child: MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                child: const Text('open'),
                onPressed: () => showLauncherDialog<void>(
                  context: context,
                  styleDialog: false,
                  builder: (_) => WeatherForecastMenu(
                    anchor: const Rect.fromLTWH(40, 0, 100, 56),
                    now: now,
                    showCalendar: both,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    if (weather.loading) {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    } else {
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'short stale forecast shows real dates and missing values in either format',
    (tester) async {
      await mount(tester);
      expect(find.text('Доступно дней: 2 из 5'), findsOneWidget);
      final l = AppLocalizations.of(
        tester.element(find.byType(WeatherForecastContent)),
      )!;
      expect(find.textContaining(l.weatherStale), findsOneWidget);
      expect(find.byKey(const ValueKey('forecast_2026-10-29')), findsOneWidget);
      expect(find.text('— / 12°C'), findsOneWidget);
      await appearance.set('panelForecastView', 'list');
      await tester.pumpAndSettle();
      expect(find.text('Осадки: 0%'), findsOneWidget);
      expect(find.text('Осадки: —'), findsOneWidget);
      await settings.setTemperatureUnit(TEMPERATURE_UNIT_FAHRENHEIT);
      await tester.pumpAndSettle();
      expect(find.text('32°F / 50°F'), findsOneWidget);
      verifyNever(weather.refresh());
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets(
      'calendar and missing weather fit one screen with large text: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(480, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        when(weather.weatherData).thenReturn(null);
        when(weather.failure).thenReturn(WeatherFailure.unavailable);
        await mount(tester, both: true, scale: 1.6, locale: locale);
        expect(find.byType(PanelCalendarDialog), findsOneWidget);
        expect(
          find.byKey(const Key('weather_forecast_content')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('calendar_day_29')), findsOneWidget);
        expect(find.byType(Scrollable), findsNothing);
        final weatherBounds = tester.getRect(
          find.byKey(const Key('weather_forecast_content')),
        );
        final calendarBounds = tester.getRect(
          find.byKey(const Key('embedded_calendar')),
        );
        expect(calendarBounds.top, greaterThanOrEqualTo(56));
        expect(calendarBounds.bottom, lessThanOrEqualTo(weatherBounds.top));
        expect(weatherBounds.bottom, lessThanOrEqualTo(528));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const Key('weather_forecast_content'))),
          weatherBounds,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final both in [false, true]) {
    for (final detailed in [false, true]) {
      for (final count in [3, 5, 7]) {
        testWidgets(
          '$count days fit without scrolling: both=$both list=$detailed',
          (tester) async {
            tester.view.physicalSize = const Size(960, 540);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            await appearance.set('panelForecastDays', count);
            await appearance.set(
              'panelForecastView',
              detailed ? 'list' : 'cards',
            );
            when(weather.weatherData).thenReturn(
              WeatherData(
                location: 'Санкт-Петербург',
                utcOffsetSeconds: 0,
                forecasts: [
                  for (var i = 0; i < 7; i++)
                    WeatherForecastItem(
                      date: DateTime(now.year, now.month, now.day + i),
                      minTemp: -12,
                      maxTemp: -3,
                      conditionCode: 600,
                      precipProbability: i * 10,
                    ),
                ],
              ),
            );
            await mount(tester, both: both);
            if (const bool.fromEnvironment('CAPTURE_WEATHER') && count == 7) {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const Key('weather_preview')),
              );
              await tester.runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File(
                  '.local/weather-${both ? 'combined' : 'only'}-${detailed ? 'list' : 'cards'}.png',
                ).writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            expect(find.byType(Scrollable), findsNothing);
            final bounds = <Rect>[];
            for (var i = 0; i < count; i++) {
              final day = find.byKey(
                ValueKey(
                  'forecast_${weatherDateString(DateTime(now.year, now.month, now.day + i))}',
                ),
              );
              expect(day, findsOneWidget);
              final rect = tester.getRect(day);
              expect(rect.top, greaterThanOrEqualTo(56));
              expect(rect.bottom, lessThanOrEqualTo(528));
              expect(rect.left, greaterThanOrEqualTo(12));
              expect(rect.right, lessThanOrEqualTo(948));
              // Ordinary TV text remains full size; fitting is a fallback only.
              expect(rect.width, closeTo(tester.getSize(day).width, .1));
              for (final previous in bounds) {
                expect(rect.overlaps(previous), isFalse);
              }
              bounds.add(rect);
            }
            if (detailed) {
              expect(find.text('Осадки: 0%'), findsOneWidget);
              expect(find.text('Снег'), findsNWidgets(count));
            }
            if (both) {
              final calendar = tester.getRect(
                find.byKey(const Key('embedded_calendar')),
              );
              final weather = tester.getRect(
                find.byKey(const Key('weather_forecast_content')),
              );
              expect(calendar.top, closeTo(weather.top - 13, .1));
              expect(calendar.overlaps(weather), isFalse);
              final material = MaterialLocalizations.of(
                tester.element(find.byType(PanelCalendarDialog)),
              );
              await tester.tap(find.byIcon(Icons.chevron_right));
              await tester.pumpAndSettle();
              expect(
                find.text(material.formatMonthYear(DateTime(2026, 11))),
                findsOneWidget,
              );
              await tester.tap(find.text(material.currentDateLabel));
              await tester.pumpAndSettle();
              expect(
                find.text(material.formatMonthYear(DateTime(2026, 10))),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
            verifyNever(weather.refresh());
            await tester.pumpWidget(const SizedBox());
          },
        );
      }
    }
  }

  for (final locale in ['ru', 'en', 'ar']) {
    for (final both in [false, true]) {
      testWidgets(
        'seven detailed days and controls stay visible at maximum text size: $locale both=$both',
        (tester) async {
          tester.view.physicalSize = const Size(960, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await appearance.set('panelForecastDays', 7);
          await appearance.set('panelForecastView', 'list');
          await appearance.set('settingsTextSize', 24);
          await appearance.set('settingsInterfaceFont', 'manrope');
          when(weather.weatherData).thenReturn(
            WeatherData(
              location: 'Петропавловск-Камчатский',
              utcOffsetSeconds: 0,
              forecasts: [
                for (var i = 0; i < 7; i++)
                  WeatherForecastItem(
                    date: DateTime(now.year, now.month, now.day + i),
                    minTemp: -25,
                    maxTemp: -12,
                    conditionCode: 200,
                    precipProbability: 100,
                  ),
              ],
            ),
          );
          await mount(tester, both: both, locale: locale, scale: 1.6);
          expect(find.byType(Scrollable), findsNothing);
          for (final text
              in find
                  .descendant(
                    of: find.byType(WeatherForecastMenu),
                    matching: find.byType(Text),
                  )
                  .evaluate()) {
            final rect = tester.getRect(find.byWidget(text.widget));
            expect(rect.left, greaterThanOrEqualTo(12));
            expect(rect.right, lessThanOrEqualTo(948));
            expect(rect.bottom, lessThanOrEqualTo(528));
          }
          if (both) {
            final context = tester.element(find.byType(PanelCalendarDialog));
            // Embedded calendar inherits the menu scale exactly once.
            expect(
              MediaQuery.textScalerOf(context).scale(16),
              closeTo(38.4, .01),
            );
            final material = MaterialLocalizations.of(context);
            await tester.tap(find.text(material.currentDateLabel));
            await tester.sendKeyEvent(
              locale == 'ar'
                  ? LogicalKeyboardKey.arrowLeft
                  : LogicalKeyboardKey.arrowRight,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(
              find.text(material.formatMonthYear(DateTime(2026, 11))),
              findsOneWidget,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(WeatherForecastMenu), findsNothing);
          verifyNever(weather.refresh());
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('gear opens shared information settings and restores focus', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byType(MenuHeaderAction));
    await tester.pumpAndSettle();
    expect(find.byType(InformationSettingsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<MenuHeaderAction>(find.byType(MenuHeaderAction))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'requested horizon limits actual days and loading keeps settings reachable',
    (tester) async {
      when(weather.weatherData).thenReturn(
        WeatherData.fromJson({
          'timestamp': now.millisecondsSinceEpoch ~/ 1000,
          'forecasts': [
            for (var i = 0; i < 7; i++) {'minTemp': i, 'maxTemp': i + 10},
          ],
        }),
      );
      await mount(tester);
      for (final count in [3, 5, 7]) {
        await appearance.set('panelForecastDays', count);
        await tester.pumpAndSettle();
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith('forecast_'),
          ),
          findsNWidgets(count),
        );
      }
      await tester.pumpWidget(const SizedBox());
      when(weather.weatherData).thenReturn(null);
      when(weather.loading).thenReturn(true);
      await mount(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.byType(MenuHeaderAction), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      verifyNever(weather.refresh());
      await tester.pumpWidget(const SizedBox());
    },
  );
}
