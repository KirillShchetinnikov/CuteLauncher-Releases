import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/information_placement.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/widgets/background_information.dart';
import 'package:flauncher/widgets/landscape_clock_clip.dart';
import 'package:flauncher/widgets/landscape_horizon.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/background_information_order_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';

import '../mocks.mocks.dart';

void main() {
  late AppearanceService appearance;
  late SettingsService settings;
  late MockWeatherService weather;
  late ChangeNotifier weatherChanges;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
    weather = MockWeatherService();
    weatherChanges = ChangeNotifier();
    when(weather.addListener(any)).thenAnswer((call) =>
        weatherChanges.addListener(call.positionalArguments.first as VoidCallback));
    when(weather.removeListener(any)).thenAnswer((call) =>
        weatherChanges.removeListener(call.positionalArguments.first as VoidCallback));
    when(weather.weatherData).thenReturn(null);
    when(weather.stale).thenReturn(false);
    when(weather.configuration).thenReturn(const WeatherConfiguration());
    await appearance.set('panelInformationPlacement', 'background');
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
    weatherChanges.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    Widget? child,
    String locale = 'ru',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
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
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          // Wallpaper information lives outside Scaffold in the real launcher.
          home: child == null
              ? const SizedBox.expand(child: BackgroundInformation())
              : Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('background order validates and survives reload and backup import', () async {
    expect(appearance.appearance.backgroundInformationOrder, ['date', 'weather', 'time']);
    await appearance.set('panelBackgroundInformationOrder', ['time', 'bogus', 'time', 42, 'weather']);
    final restored = AppearanceService(appearance.preferences);
    expect(restored.appearance.backgroundInformationOrder, ['time', 'weather', 'date']);
    final imported = compatibleSettings({
      tileAppearanceKey: appearance.preferences.getString(tileAppearanceKey)!,
    }, {});
    expect(TileAppearance.decode(imported[tileAppearanceKey]).backgroundInformationOrder,
        ['time', 'weather', 'date']);
    expect(restored.appearance.panelLayout.left, appearance.appearance.panelLayout.left);
    restored.dispose();
  });

  testWidgets('remote reorders background, keeps focus and stops at boundaries', (tester) async {
    await pump(tester, child: const BackgroundInformationOrderPage());
    final tile = find.byKey(const ValueKey('time'));
    final node = tester.widget<FocusableSettingsTile>(tile).focusNode!;
    node.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    for (var i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(appearance.appearance.backgroundInformationOrder, ['time', 'date', 'weather']);
    expect(node.hasFocus, isTrue);
    expect(tester.getTopLeft(tile).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey('date'))).dy));
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationOrder, ['time', 'date', 'weather']);
    expect(tester.widget<FocusableSettingsTile>(find.byKey(const ValueKey('date'))).focusNode!.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('background appearance opens order editor; Back finishes moving before leaving', (tester) async {
    await pump(tester, child: const BackgroundInformationSettingsPage());
    final l = AppLocalizations.of(tester.element(find.byType(BackgroundInformationSettingsPage)))!;
    await tester.tap(find.text(l.panelObjectOrder));
    await tester.pumpAndSettle();
    final date = find.byKey(const ValueKey('date'));
    tester.widget<FocusableSettingsTile>(date).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BackgroundInformationOrderPage), findsOneWidget);
    expect(tester.widget<FocusableSettingsTile>(date).selected, isFalse);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BackgroundInformationOrderPage), findsNothing);
    expect(find.byType(BackgroundInformationSettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('saved order controls rendered positions and survives hidden members', (tester) async {
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    for (final order in [
      ['date', 'weather', 'time'],
      ['time', 'date', 'weather'],
      ['weather', 'time', 'date'],
    ]) {
      await appearance.set('panelBackgroundInformationOrder', order);
      await pump(tester);
      double y(String id) => tester.getCenter(find.byKey(Key('background_${id == 'time' ? 'clock' : id}'))).dy;
      expect(y(order[0]), lessThan(y(order[1])));
      expect(y(order[1]), lessThan(y(order[2])));
      await appearance.set('panelInformationPlacements', {
        'time': 'background', 'date': 'hidden', 'weather': 'background',
      });
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('background_date')), findsNothing);
      expect(appearance.appearance.backgroundInformationOrder, order);
      await appearance.set('panelInformationPlacements', {
        'time': 'background', 'date': 'background', 'weather': 'background',
      });
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets('background warning follows switch and freshness: $locale', (tester) async {
      await appearance.set('panelInformationPlacements', {
        'time': 'background', 'date': 'background', 'weather': 'background',
      });
      when(weather.weatherData).thenReturn(const WeatherData(
        currentTemp: 20, currentConditionCode: 800,
        hasWarning: true, warningType: WeatherWarningType.rain,
        warningPrecipProbability: 80, warningDayIndex: 1,
      ));
      await settings.setShowWeatherWarnings(true);
      await appearance.set('panelBackgroundInformationSize', 144);
      await pump(tester, locale: locale, scale: 1.8);
      final text = find.textContaining('20°C • ');
      expect(text, findsOneWidget);
      expect(tester.getRect(text).left, greaterThanOrEqualTo(0));
      expect(tester.getRect(text).right, lessThanOrEqualTo(960));
      await settings.setShowWeatherWarnings(false);
      await tester.pumpAndSettle();
      expect(find.text('20°C'), findsOneWidget);
      expect(text, findsNothing);
      await settings.setShowWeatherWarnings(true);
      when(weather.stale).thenReturn(true);
      weatherChanges.notifyListeners();
      await tester.pumpAndSettle();
      expect(text, findsNothing);
      when(weather.stale).thenReturn(false);
      when(weather.weatherData).thenReturn(null);
      weatherChanges.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
      expect(text, findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final time in ['hidden', 'panel', 'background']) {
    for (final date in ['hidden', 'panel', 'background']) {
      for (final weather in ['hidden', 'panel', 'background']) {
        testWidgets('independent destinations $time/$date/$weather', (
          tester,
        ) async {
          final placements = {'time': time, 'date': date, 'weather': weather};
          await appearance.set('panelInformationPlacements', placements);
          final restored = AppearanceService(appearance.preferences);
          final resolved = InformationPlacement(restored.appearance, settings);
          expect(resolved.values, placements);
          for (final entry in placements.entries) {
            expect(resolved.onPanel(entry.key), entry.value == 'panel');
            expect(
              resolved.excludedFromPanel.contains(entry.key),
              entry.value != 'panel',
            );
          }
          restored.dispose();
          await pump(tester);
          for (final rich in tester.widgetList<RichText>(
            find.descendant(of: find.byType(BackgroundInformation), matching: find.byType(RichText)),
          )) {
            expect(rich.text.style?.decoration, anyOf(isNull, TextDecoration.none));
          }
          for (final entry in placements.entries) {
            final name = entry.key == 'time' ? 'clock' : entry.key;
            expect(
              find.byKey(Key('background_$name')),
              entry.value == 'background' ? findsOneWidget : findsNothing,
            );
          }
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        });
      }
    }
  }

  test(
    'legacy background style stays independent after editing panel style',
    () async {
      await appearance.preferences.setString(
        tileAppearanceKey,
        jsonEncode({
          'panelInformationPlacement': 'background',
          'panelInformationStyle': {'color': 0xffff0000, 'animate': false},
        }),
      );
      final legacy = appearance.appearance.backgroundInformationStyle.values;
      await appearance.set('panelInformationStyle', {
        'color': 0xff00ff00,
        'animate': true,
      });
      expect(appearance.appearance.backgroundInformationStyle.values, legacy);
      await appearance.set('panelBackgroundInformationStyle', {
        'color': 0xff0000ff,
      });
      expect(
        appearance.appearance.informationStyle.values['color'],
        0xff00ff00,
      );
      expect(
        appearance.appearance.backgroundInformationStyle.values['color'],
        0xff0000ff,
      );
    },
  );

  test('invalid destination entries fall back to legacy visibility', () {
    final imported = TileAppearance.decode(
      jsonEncode({
        'panelInformationPlacement': 'background',
        'panelInformationPlacements': {
          'time': 'other',
          'date': 'panel',
          'weather': 3,
          'unknown': 'panel',
        },
      }),
    );
    expect(imported.informationPlacement('time', visible: true), 'background');
    expect(imported.informationPlacement('weather', visible: false), 'hidden');
    expect(imported.informationPlacement('date', visible: false), 'panel');
    expect(imported.values['panelInformationPlacements'], {'date': 'panel'});
  });

  for (var mask = 0; mask < 8; mask++) {
    testWidgets('independent background parts $mask, no weather request', (
      tester,
    ) async {
      await settings.setShowTimeInStatusBar(mask & 1 != 0);
      await settings.setShowDateInStatusBar(mask & 2 != 0);
      await settings.setShowWeatherInStatusBar(mask & 4 != 0);
      await pump(tester);
      for (final (bit, name) in [(1, 'clock'), (2, 'date'), (4, 'weather')]) {
        expect(
          find.byKey(Key('background_$name')),
          mask & bit != 0 ? findsOneWidget : findsNothing,
        );
      }
      expect(
        find.descendant(
          of: find.byType(BackgroundInformation),
          matching: find.byType(TextButton),
        ),
        findsNothing,
      );
      expect(find.byType(LandscapeSkyClip), findsNothing);
      expect(tester.takeException(), isNull);
      await appearance.set('panelInformationPlacement', 'panel');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('background_clock')), findsNothing);
      expect(settings.showTimeInStatusBar, mask & 1 != 0);
      verifyNever(weather.refresh());
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final variant in ['illustrated', 'realistic']) {
    for (final alignment in ['left', 'center', 'right']) {
      testWidgets(
        '$variant $alignment depth only clips the clock, fits large text',
        (tester) async {
          await settings.setBackgroundSource('landscape');
          await settings.setLandscape(LandscapeConfiguration(variant: variant));
          await settings.setShowWeatherInStatusBar(true);
          await appearance.set(
            'panelBackgroundInformationAlignment',
            alignment,
          );
          await appearance.set('panelBackgroundInformationSize', 144);
          await pump(tester, locale: 'ar', scale: 1.8);
          expect(find.byType(LandscapeSkyClip), findsOneWidget);
          final skyline = tester
              .widget<LandscapeSkyClip>(find.byType(LandscapeSkyClip))
              .horizon;
          final clockRect = tester.getRect(
            find.byKey(const Key('background_clock')),
          );
          final ridge = skyline.heightAt(clockRect.center.dx);
          expect(ridge, greaterThan(clockRect.top));
          expect(ridge, lessThan(clockRect.bottom));
          expect(
            find.descendant(
              of: find.byType(LandscapeSkyClip),
              matching: find.byKey(const Key('background_clock')),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(LandscapeSkyClip),
              matching: find.byKey(const Key('background_weather')),
            ),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          await settings.setBackgroundSource('gradient');
          await tester.pumpAndSettle();
          expect(find.byType(LandscapeSkyClip), findsNothing);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  test(
    'placement and layout persist, invalid imported values are discarded',
    () async {
      await appearance.set('panelBackgroundInformationAlignment', 'right');
      await appearance.set('panelBackgroundInformationSize', 120);
      final restored = TileAppearance.decode(
        jsonEncode(appearance.appearance.values),
      );
      expect(restored.informationOnBackground, isTrue);
      expect(restored.backgroundInformationAlignment, 'right');
      expect(restored.backgroundInformationSize, 120);
      final invalid = TileAppearance.decode(
        jsonEncode({
          'panelInformationPlacement': 'invalid',
          'panelBackgroundInformationAlignment': 3,
          'panelBackgroundInformationSize': 10000,
        }),
      );
      expect(invalid.informationOnBackground, isFalse);
      expect(invalid.backgroundInformationAlignment, 'center');
      expect(invalid.backgroundInformationSize, 96);
    },
  );

  testWidgets(
    'background settings expose visibility, hide irrelevant panel controls',
    (tester) async {
      await pump(
        tester,
        child: const SizedBox(width: 390, child: InformationSettingsPage()),
      );
      expect(find.byType(SettingsHelp), findsNothing);
      expect(find.byType(InformationVisibility), findsOneWidget);
      final l = AppLocalizations.of(
        tester.element(find.byType(InformationSettingsPage)),
      )!;
      expect(find.text(l.combinedInformation), findsNothing);
      final visibility = find.byKey(const ValueKey('date'));
      await tester.ensureVisible(visibility);
      await tester.tap(visibility);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.disabled).last);
      await tester.pumpAndSettle();
      expect(
        appearance.appearance.informationPlacement('date', visible: true),
        'hidden',
      );
      await pump(
        tester,
        child: const SizedBox(
          width: 390,
          child: PanelClockStylePage(combined: true, background: true),
        ),
      );
      expect(find.text(l.clockSharedBackground), findsNothing);
      expect(find.text(l.informationPosition), findsNothing);
      expect(find.text(l.informationSize), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('sky clip follows screen coordinates including scaled clock', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final capture = GlobalKey();
    final horizon = LandscapeHorizon(
      const Size(400, 300),
      LandscapeSeason.summer,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: capture,
          child: ColoredBox(
            color: Colors.black,
            child: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 50,
                  child: Transform.scale(
                    scale: 1.5,
                    alignment: Alignment.topLeft,
                    child: LandscapeSkyClip(
                      horizon: horizon,
                      child: const SizedBox(
                        width: 100,
                        height: 150,
                        child: ColoredBox(color: Colors.red),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (capture.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      int red(int x, int y) => pixels.getUint8((y * image.width + x) * 4);
      for (final x in [110, 180, 240]) {
        final y = horizon.heightAt(x.toDouble()).round();
        expect(red(x, y - 4), 244);
        expect(red(x, y + 4), 0);
      }
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
  });
}
