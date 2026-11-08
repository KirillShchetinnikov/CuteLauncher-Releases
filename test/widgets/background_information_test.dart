import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/background_information_geometry.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/information_placement.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/widgets/background_information.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/date_time_widget.dart';
import 'package:flauncher/widgets/landscape_clock_clip.dart';
import 'package:flauncher/widgets/landscape_horizon.dart';
import 'package:flauncher/widgets/landscape_wallpaper.dart';
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
    Size size = const Size(960, 540),
  }) async {
    tester.view.physicalSize = size;
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
            child: Material(child: child!),
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

  test('depth switches validate and survive reload and backup import independently', () async {
    expect(appearance.appearance.backgroundInformationAboveLandscape, isFalse);
    expect(appearance.appearance.backgroundInformationAboveWeather, isFalse);
    for (final landscape in [false, true]) {
      for (final weather in [false, true]) {
        await appearance.set('panelBackgroundInformationAboveLandscape', landscape);
        await appearance.set('panelBackgroundInformationAboveWeather', weather);
        final restored = AppearanceService(appearance.preferences);
        expect(restored.appearance.backgroundInformationAboveLandscape, landscape);
        expect(restored.appearance.backgroundInformationAboveWeather, weather);
        restored.dispose();
        final imported = compatibleSettings({
          tileAppearanceKey: appearance.preferences.getString(tileAppearanceKey)!,
        }, {});
        final value = TileAppearance.decode(imported[tileAppearanceKey]);
        expect(value.backgroundInformationAboveLandscape, landscape);
        expect(value.backgroundInformationAboveWeather, weather);
      }
    }
    final invalid = TileAppearance.validValues({
      'panelBackgroundInformationAboveLandscape': 'true',
      'panelBackgroundInformationAboveWeather': 1,
    });
    expect(invalid, isEmpty);
  });

  testWidgets('remote toggles depth switches independently for the whole block', (tester) async {
    await pump(tester, child: const BackgroundInformationSettingsPage());
    final l = AppLocalizations.of(tester.element(find.byType(BackgroundInformationSettingsPage)))!;
    expect(find.text(l.informationLayers), findsNothing);
    await tester.tap(find.text(l.informationPositionSize));
    await tester.pumpAndSettle();
    final landscape = find.text(l.informationAboveLandscape);
    final weather = find.text(l.informationAboveWeather);
    await tester.scrollUntilVisible(landscape, 120);
    await tester.pumpAndSettle();
    await tester.tap(landscape);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationAboveLandscape, isTrue);
    expect(appearance.appearance.backgroundInformationAboveWeather, isFalse);
    // The focused switch is operable with the remote's OK key.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationAboveWeather, isTrue);
    await tester.tap(weather);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationAboveLandscape, isTrue);
    expect(appearance.appearance.backgroundInformationAboveWeather, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

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
    await tester.tap(find.text(l.informationPositionSize));
    await tester.pumpAndSettle();
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
    expect(find.byType(InformationSectionPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(BackgroundInformationSettingsPage), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('remote changes offset independently of alignment; position resets offset', (tester) async {
    await appearance.set('panelBackgroundInformationContentAlignment', 'left');
    await pump(tester, child: const BackgroundInformationSettingsPage());
    final l = AppLocalizations.of(tester.element(find.byType(BackgroundInformationSettingsPage)))!;
    await tester.tap(find.text(l.informationPositionSize));
    await tester.pumpAndSettle();
    final offsetLabel = find.text(l.informationBackgroundOffset);
    Focus.of(tester.element(offsetLabel)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationOffset, 5);
    expect(find.text('+5%'), findsOneWidget);

    expect(find.text(l.informationBackgroundResetOffset), findsNothing);
    expect(find.text(l.informationAvoidOverlap), findsNothing);
    final reset = find.text(l.informationResetPositionSize);
    expect(reset.hitTestable(), findsNothing);
    bool resetFocused() => reset.evaluate().isNotEmpty &&
        Focus.of(tester.element(reset)).hasFocus;
    for (var step = 0; step < 16 && !resetFocused(); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(resetFocused(), isTrue);
    expect(reset.hitTestable(), findsOneWidget);

    await appearance.set('panelBackgroundInformationOffset', -50);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(FocusableSettingsTile, l.informationBackgroundPosition), -120,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.informationBackgroundPosition).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.settingsMenuRight).last);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationPosition, 'right');
    expect(appearance.appearance.backgroundInformationOffset, 0);
    expect(appearance.appearance.backgroundInformationAlignment, 'left');
    expect(tester.takeException(), isNull);
  });

  testWidgets('background layout reset confirms and resets only this screen', (tester) async {
    for (final entry in {
      'panelBackgroundInformationAlignment': 'right',
      'panelBackgroundInformationContentAlignment': 'left',
      'panelBackgroundInformationOffset': 65,
      'panelBackgroundInformationVerticalOffset': 35,
      'panelBackgroundInformationSize': 144,
      'panelBackgroundInformationOrder': ['time', 'weather', 'date'],
      'panelBackgroundInformationAboveLandscape': true,
      'panelBackgroundInformationAboveWeather': true,
      'panelBackgroundInformationStyle': {'font': 'serif', 'weight': 700},
      'panelInformationStyle': {'font': 'manrope', 'size': 22},
    }.entries) {
      await appearance.set(entry.key, entry.value);
    }
    await appearance.setInformationAppearance('weatherIconPack', 'circled', background: true);
    await appearance.setInformationAppearance('dateTextColor', 0xff557799, background: true);
    final saved = appearance.appearance;
    final formats = settings.exportSettingsMap();
    await pump(tester, child: const InformationSectionPage(background: true, section: 'layout'));
    final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
    final reset = find.text(l.informationResetPositionSize);
    expect(reset.hitTestable(), findsNothing);
    await tester.scrollUntilVisible(reset, 120);
    await tester.pumpAndSettle();
    expect(reset.hitTestable(), findsOneWidget);
    Focus.of(tester.element(reset)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(appearance.appearance.values, saved.values);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(LauncherAlertDialog), matching: find.text(l.informationResetPositionSize),
    ).last);
    await tester.pumpAndSettle();
    final restored = AppearanceService(appearance.preferences);
    addTearDown(restored.dispose);
    final value = restored.appearance;
    expect(value.backgroundInformationPosition, 'center');
    expect(value.backgroundInformationAlignment, 'center');
    expect(value.backgroundInformationOffset, 0);
    expect(value.backgroundInformationVerticalOffset, 0);
    expect(value.backgroundInformationSize, 96);
    expect(value.backgroundInformationOrder, ['date', 'weather', 'time']);
    expect(value.backgroundInformationAboveLandscape, isFalse);
    expect(value.backgroundInformationAboveWeather, isFalse);
    expect(value.backgroundInformationStyle.values, saved.backgroundInformationStyle.values);
    expect(value.informationStyle.values, saved.informationStyle.values);
    expect(value.values['backgroundInformationAppearance'], saved.values['backgroundInformationAppearance']);
    expect(InformationPlacement(value, settings).values, InformationPlacement(saved, settings).values);
    expect(settings.exportSettingsMap(), formats);
    expect(reset.hitTestable(), findsOneWidget);
    expect(Focus.of(tester.element(reset)).hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('vertical movement keeps size and respects toolbar and screen middle', (tester) async {
    await settings.setBackgroundSource('gradient');
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    await appearance.set('panelBackgroundInformationSize', 60);
    await pump(tester, child: const Stack(children: [
      Positioned.fill(child: BackgroundInformation()),
      Align(alignment: Alignment.topLeft, child: SizedBox(width: 390,
        child: InformationSectionPage(background: true, section: 'layout'))),
    ]));
    final block = find.byKey(const Key('background_information_block'));
    final initial = tester.getRect(block);
    final maximum = appearance.backgroundInformationMetrics.value!.maximumVerticalOffset;
    expect(initial.top, closeTo(kToolbarHeight + 8, .001));
    final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
    final vertical = find.text(l.informationBackgroundVerticalOffset);
    await tester.scrollUntilVisible(vertical, 120);
    await tester.pumpAndSettle();
    Focus.of(tester.element(vertical)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationVerticalOffset, 5);
    expect(tester.getRect(block).height, closeTo(initial.height, .001));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationVerticalOffset, 0);
    for (final offset in [0, maximum ~/ 2, maximum]) {
      await appearance.setBackgroundInformationVerticalOffset(offset);
      await tester.pumpAndSettle();
      final rect = tester.getRect(block);
      expect(rect.height, closeTo(initial.height, .001));
      expect(rect.width, closeTo(initial.width, .001));
      expect(rect.top, greaterThanOrEqualTo(kToolbarHeight + 8 - .001));
      expect(rect.bottom, lessThanOrEqualTo(270 + .001));
      expect(rect.top, closeTo(BackgroundInformationGeometry(
        const Size(960, 540), offset.toDouble()).top, .001));
      if (offset > 0) expect(rect.top, greaterThan(initial.top));
    }
    Focus.of(tester.element(vertical)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationVerticalOffset, maximum);
    expect(tester.takeException(), isNull);
    final lastMetrics = appearance.backgroundInformationMetrics.value!;
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(appearance.backgroundInformationMetrics.value, isNull);
    final firstOwner = Object(), nextOwner = Object();
    appearance.reportBackgroundInformationMetrics(firstOwner, lastMetrics);
    appearance.reportBackgroundInformationMetrics(nextOwner, lastMetrics);
    appearance.reportBackgroundInformationMetrics(firstOwner, null);
    expect(appearance.backgroundInformationMetrics.value, lastMetrics);
    appearance.reportBackgroundInformationMetrics(nextOwner, null);
    expect(appearance.backgroundInformationMetrics.value, isNull);
  });

  testWidgets('size limit is measured; growth keeps top fixed and stops at screen middle', (tester) async {
    await settings.setBackgroundSource('gradient');
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'hidden', 'weather': 'hidden',
    });
    await appearance.set('panelBackgroundInformationSize', 96);
    await appearance.set('panelBackgroundInformationVerticalOffset', 0);
    await pump(tester, child: const Stack(children: [
      Positioned.fill(child: BackgroundInformation()),
      Align(alignment: Alignment.topLeft, child: SizedBox(width: 390,
        child: InformationSectionPage(background: true, section: 'layout'))),
    ]));
    final block = find.byKey(const Key('background_information_block'));
    final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
    final label = find.text(l.informationSize);
    await tester.scrollUntilVisible(label, 120);
    await tester.pumpAndSettle();
    final control = find.ancestor(of: label, matching: find.byType(SettingsSliderTile));
    final maximum = tester.widget<SettingsSliderTile>(control).options.last as int;
    expect(maximum, greaterThan(144));
    expect(maximum, appearance.backgroundInformationMetrics.value!.maximumSize);
    Focus.of(tester.element(label)).requestFocus();
    await tester.pumpAndSettle();
    var previous = tester.getRect(block);
    for (var attempt = 0; attempt < 100 && appearance.appearance.backgroundInformationSize < maximum; attempt++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      final next = tester.getRect(block);
      expect(next.top, closeTo(kToolbarHeight + 8, .001));
      expect(next.bottom, lessThanOrEqualTo(270 + .001));
      expect(next.height, greaterThanOrEqualTo(previous.height - .001));
      previous = next;
    }
    expect(appearance.appearance.backgroundInformationSize, maximum);
    expect(previous.bottom, closeTo(270, 2));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.appearance.backgroundInformationSize, maximum);
    expect(tester.getRect(block).top, closeTo(previous.top, .001));
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    await tester.pumpAndSettle();
    expect(appearance.backgroundInformationMetrics.value!.maximumSize, lessThan(maximum));
    expect(tester.getRect(block).top, closeTo(kToolbarHeight + 8, .001));
    expect(tester.getRect(block).bottom, closeTo(270, .001));
    await appearance.set('panelBackgroundInformationSize', 48);
    await appearance.setBackgroundInformationVerticalOffset(20);
    await tester.pumpAndSettle();
    final shifted = tester.getRect(block);
    await appearance.set('panelBackgroundInformationSize', 80);
    await tester.pumpAndSettle();
    final larger = tester.getRect(block);
    expect(larger.top, closeTo(shifted.top, .001));
    expect(larger.bottom, greaterThan(shifted.bottom));
    expect(larger.bottom, lessThanOrEqualTo(270 + .001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('oversized imported endpoint stays visible and does not grow while moving up', (tester) async {
    await settings.setBackgroundSource('gradient');
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    await appearance.set('panelBackgroundInformationSize', 144);
    await appearance.set('panelBackgroundInformationVerticalOffset', 100);
    await pump(tester);
    final block = find.byKey(const Key('background_information_block'));
    final initial = tester.getRect(block);
    expect(initial.height, greaterThan(0));
    expect(initial.height, lessThanOrEqualTo(8 + .001));
    await appearance.setBackgroundInformationVerticalOffset(0);
    await tester.pumpAndSettle();
    final moved = tester.getRect(block);
    expect(moved.height, closeTo(initial.height, .001));
    expect(moved.width, closeTo(initial.width, .001));
    expect(moved.top, closeTo(kToolbarHeight + 8, .001));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the whole block moves within its zone and the screen', (tester) async {
    await settings.setBackgroundSource('gradient');
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    final block = find.byKey(const Key('background_information_block'));
    const width = 960.0;
    await pump(tester);
    for (final position in ['left', 'center', 'right']) {
      await appearance.set('panelBackgroundInformationAlignment', position);
      await tester.pumpAndSettle();
      final neutral = tester.getRect(block);
      final free = width - 48 - neutral.width;
      final (left, right) = switch (position) {
        'left' => (12.0, 24.0 + free / 4),
        'right' => (24.0 + free * .75, width - 12 - neutral.width),
        _ => (24.0 + free / 3, 24.0 + free * 2 / 3),
      };
      final original = [
        for (final id in ['clock', 'date', 'weather'])
          tester.getRect(find.byKey(Key('background_$id'))),
      ];
      for (final (offset, expected) in [(-100, left), (100, right)]) {
        await appearance.set('panelBackgroundInformationOffset', offset);
        await tester.pumpAndSettle();
        final shifted = tester.getRect(block);
        expect(appearance.informationBounds.value, shifted);
        expect(shifted.left, closeTo(expected, .01));
        for (final (index, id) in ['clock', 'date', 'weather'].indexed) {
          final element = tester.getRect(find.byKey(Key('background_$id')));
          expect(element.left - original[index].left,
              closeTo(shifted.left - neutral.left, .01));
          expect(element.top, closeTo(original[index].top, .01));
        }
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('large background content fits at either extreme on a narrow screen', (tester) async {
    await settings.setBackgroundSource('gradient');
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'background',
    });
    await appearance.set('panelBackgroundInformationSize', 144);
    const size = Size(340, 220);
    await pump(tester, locale: 'ar', scale: 2, size: size);
    for (final position in ['left', 'center', 'right']) {
      await appearance.set('panelBackgroundInformationAlignment', position);
      for (final offset in [-100, 100]) {
        await appearance.set('panelBackgroundInformationOffset', offset);
        await tester.pumpAndSettle();
        final block = tester.getRect(find.byKey(const Key('background_information_block')));
        expect(block.left, greaterThanOrEqualTo(12));
        expect(block.right, lessThanOrEqualTo(size.width - 12));
        expect(block.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(block.bottom, lessThanOrEqualTo(size.height / 2 + .001));
      }
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('content can align physically left or right in a right-side RTL block', (tester) async {
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background',
    });
    await appearance.set('panelBackgroundInformationAlignment', 'right');
    await pump(tester, locale: 'ar');
    for (final alignment in ['left', 'center', 'right']) {
      await appearance.set('panelBackgroundInformationContentAlignment', alignment);
      await tester.pumpAndSettle();
      final clock = tester.getRect(find.byKey(const Key('background_clock')));
      final date = tester.getRect(find.byKey(const Key('background_date')));
      final block = tester.getRect(find.byKey(const Key('background_information_block')));
      final double Function(Rect) alignedX = switch (alignment) {
        'left' => (rect) => rect.left,
        'right' => (rect) => rect.right,
        _ => (rect) => rect.center.dx,
      };
      expect(alignedX(date), closeTo(alignedX(clock), .01));
      expect(block.right, closeTo(936, .01));
    }
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

  testWidgets('background date uses its own color and restores the background color', (tester) async {
    await appearance.set('panelInformationPlacements', {
      'time': 'hidden', 'date': 'background', 'weather': 'hidden',
    });
    await appearance.set('panelBackgroundInformationStyle', {
      'color': 0xff88aadd, 'clockColor': 0xff66ddaa, 'glow': true,
    });
    await pump(tester);
    TextStyle dateStyle() => tester.widget<DateTimeWidget>(
      find.byKey(const Key('background_date')),
    ).textStyle!;
    expect(dateStyle().color, const Color(0xff88aadd));
    await appearance.set('dateTextColor', 0xffdd7788);
    await tester.pumpAndSettle();
    expect(dateStyle().color, const Color(0xffdd7788));
    expect(dateStyle().shadows?.single.color, const Color(0xffdd7788));
    await appearance.set('dateTextColor', null);
    await tester.pumpAndSettle();
    expect(dateStyle().color, const Color(0xff88aadd));
    await tester.pumpWidget(const SizedBox());
  });

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
    for (final members in const [ ['date'], ['weather'], ['date', 'weather'] ]) {
      testWidgets('$variant depth works without a clock for $members', (tester) async {
        const captureImages = bool.fromEnvironment('PARTIAL_DEPTH_CAPTURE');
        if (captureImages) {
          await (FontLoader('PanelSans')..addFont(rootBundle.load('assets/fonts/sans.ttf'))).load();
        }
        await settings.setBackgroundSource('landscape');
        await settings.setLandscape(LandscapeConfiguration(
          variant: variant, timeOfDay: false, motion: false,
        ));
        await appearance.set('panelInformationPlacements', {
          for (final id in InformationPlacement.ids)
            id: members.contains(id) ? 'background' : 'hidden',
        });
        await appearance.set('panelBackgroundInformationSize', 144);
        await appearance.set('panelBackgroundInformationVerticalOffset', 100);
        when(weather.weatherData).thenReturn(const WeatherData(
          currentTemp: 8, currentConditionCode: 500,
        ));
        final capture = GlobalKey();
        final sceneCapture = GlobalKey();
        await pump(tester, child: RepaintBoundary(key: sceneCapture, child: LandscapeWallpaper(
          gradient: const LinearGradient(colors: [Colors.black, Colors.black]),
          informationLayer: RepaintBoundary(key: capture, child: const BackgroundInformation()),
        )));
        final block = find.byKey(const Key('background_information_block'));
        final original = tester.getRect(block);
        expect(find.byKey(const Key('background_clock')), findsNothing);
        for (final aboveWeather in [false, true]) {
          var foregroundPixels = 0;
          for (final aboveLandscape in [true, false]) {
            await appearance.set('panelBackgroundInformationAboveLandscape', aboveLandscape);
            await appearance.set('panelBackgroundInformationAboveWeather', aboveWeather);
            await tester.pumpAndSettle();
            expect(find.byType(LandscapeSkyClip), aboveLandscape ? findsNothing : findsOneWidget);
            final scene = tester.widget<Stack>(find.ancestor(
              of: find.byKey(capture), matching: find.byType(Stack),
            ).first);
            expect(scene.children.indexWhere((child) => child.key == capture), aboveWeather ? 2 : 1);
            expect(tester.getRect(block), original);
            final painted = (await tester.runAsync(() async {
              final bitmap = await (capture.currentContext!.findRenderObject()! as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
              final pixels = (await bitmap.toByteData(format: ui.ImageByteFormat.rawRgba))!;
              var count = 0;
              for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
                if (pixels.getUint8(offset) > 0) count++;
              }
              bitmap.dispose();
              return count;
            }))!;
            // Terrain hides some or all of the low block, preserving its bounds.
            if (aboveLandscape) {
              expect(painted, greaterThan(0));
              foregroundPixels = painted;
            } else {
              expect(painted, lessThan(foregroundPixels));
            }
          }
        }
        if (captureImages && members.length == 1) {
          await appearance.set('panelBackgroundInformationVerticalOffset', 80);
          for (final above in [false, true]) {
            await appearance.set('panelBackgroundInformationAboveLandscape', above);
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              final bitmap = await (sceneCapture.currentContext!.findRenderObject()! as RenderRepaintBoundary).toImage();
              final bytes = (await bitmap.toByteData(format: ui.ImageByteFormat.png))!;
              final file = File('.local/partial-background-depth/$variant-${members.single}-${above ? 'above' : 'behind'}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes.buffer.asUint8List());
              bitmap.dispose();
            });
          }
        }
        verifyNever(weather.refresh());
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final variant in ['illustrated', 'realistic']) {
    for (final alignment in ['left', 'center', 'right']) {
      testWidgets(
        '$variant $alignment depth clips the whole block, fits large text',
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
          final clockRect = tester.getRect(
            find.byKey(const Key('background_clock')),
          );
          final blockRect = tester.getRect(find.byKey(const Key('background_information_block')));
          expect(blockRect.top, greaterThanOrEqualTo(kToolbarHeight));
          expect(blockRect.top, closeTo(kToolbarHeight + 8, .001));
          expect(blockRect.bottom, lessThanOrEqualTo(270 + .001));
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
            findsOneWidget,
          );
          expect(find.descendant(of: find.byType(LandscapeSkyClip),
            matching: find.byKey(const Key('background_date'))), findsOneWidget);
          final offset = alignment == 'right' ? -50 : 50;
          await appearance.set('panelBackgroundInformationOffset', offset);
          await tester.pumpAndSettle();
          final shifted = tester.getRect(find.byKey(const Key('background_clock')));
          expect((shifted.center.dx - clockRect.center.dx) * offset, greaterThan(0));
          expect(shifted.top, closeTo(clockRect.top, .001));
          expect(shifted.bottom, closeTo(clockRect.bottom, .001));
          expect(shifted.width, closeTo(clockRect.width, .001));
          expect(shifted.height, closeTo(clockRect.height, .001));
          expect(tester.takeException(), isNull);
          await appearance.set('panelBackgroundInformationAboveLandscape', true);
          await tester.pumpAndSettle();
          expect(find.byType(LandscapeSkyClip), findsNothing);
          expect(tester.getRect(find.byKey(const Key('background_clock'))), shifted);
          expect(find.byKey(const Key('background_date')), findsOneWidget);
          expect(find.byKey(const Key('background_weather')), findsOneWidget);
          // Weather protection is independent of terrain depth.
          await appearance.set('panelBackgroundInformationAboveLandscape', false);
          await appearance.set('panelBackgroundInformationAboveWeather', true);
          await tester.pumpAndSettle();
          expect(find.byType(LandscapeSkyClip), findsOneWidget);
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
      await appearance.set('panelBackgroundInformationVerticalOffset', 25);
      await appearance.setBackgroundInformationVerticalOffset(101);
      expect(appearance.appearance.backgroundInformationVerticalOffset, 25);
      final restored = TileAppearance.decode(
        jsonEncode(appearance.appearance.values),
      );
      expect(restored.informationOnBackground, isTrue);
      expect(restored.backgroundInformationPosition, 'right');
      expect(restored.backgroundInformationSize, 120);
      expect(restored.backgroundInformationVerticalOffset, 25);
      expect(TileAppearance.decode(jsonEncode({'panelBackgroundInformationVerticalOffset': -25}))
        .backgroundInformationVerticalOffset, 0);
      final invalid = TileAppearance.decode(
        jsonEncode({
          'panelInformationPlacement': 'invalid',
          'panelBackgroundInformationAlignment': 3,
          'panelBackgroundInformationSize': 10000,
          'panelBackgroundInformationVerticalOffset': 101,
        }),
      );
      expect(invalid.informationOnBackground, isFalse);
      expect(invalid.backgroundInformationPosition, 'center');
      expect(invalid.backgroundInformationSize, 96);
      expect(invalid.backgroundInformationVerticalOffset, 0);
    },
  );

  test('legacy position sets initial alignment and only a changed position resets offset', () async {
    await appearance.preferences.setString(
      tileAppearanceKey, '{"panelBackgroundInformationAlignment":"left"}',
    );
    expect(appearance.appearance.backgroundInformationPosition, 'left');
    expect(appearance.appearance.backgroundInformationAlignment, 'left');
    expect(appearance.appearance.backgroundInformationOffset, 0);
    await appearance.set('panelBackgroundInformationOffset', 50);
    await appearance.set('panelBackgroundInformationAlignment', 'left');
    expect(appearance.appearance.backgroundInformationOffset, 50);
    await appearance.set('panelBackgroundInformationAlignment', 'center');
    expect(appearance.appearance.backgroundInformationAlignment, 'left');
    expect(appearance.appearance.backgroundInformationOffset, 0);
    await appearance.set('panelBackgroundInformationOffset', -25);
    await appearance.set('panelBackgroundInformationAlignment', 'left');
    expect(appearance.appearance.backgroundInformationOffset, 0);
    expect(TileAppearance.validValues({
      'panelBackgroundInformationOffset': 101,
      'panelBackgroundInformationContentAlignment': 'invalid',
    }), isEmpty);
  });

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
