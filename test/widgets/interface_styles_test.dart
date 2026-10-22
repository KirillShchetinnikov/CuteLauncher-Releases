import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/combined_information.dart';
import 'package:flauncher/widgets/adaptive_landscape_background.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/landscape_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';
import '../support/design_fixture.dart';

void main() {
  test(
    'materials preserve custom background opacity, including transparent glass',
    () {
      for (final style in InterfaceStyle.values) {
        for (final alpha in [0.0, .3, 1.0]) {
          final surface = InterfaceSkin(style)
              .surface(Colors.green.withValues(alpha: alpha), Colors.white);
          if (surface.gradient != null) {
            for (final color in surface.gradient!.colors) {
              expect(color.a, closeTo(alpha, .001));
            }
          } else {
            expect(surface.color!.a, closeTo(alpha, .001));
          }
        }
      }
    },
  );
  testWidgets(
    'changing skin in an open settings route updates it without replacing focus',
    (tester) async {
      final shadows = debugDisableShadows;
      addTearDown(() => debugDisableShadows = shadows);
      final fixture = await pumpDesignFixture(tester);
      final context = tester.element(find.byIcon(Icons.settings_outlined));
      showLauncherDialog<void>(
        context: context,
        styleDialog: false,
        builder: (_) =>
            const SettingsPanel(initialRoute: SettingsStylePage.routeName),
      );
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      for (final skin in ['glass', 'soft', 'outline', 'standard']) {
        await fixture.appearance.set('settingsInterfaceStyle', skin);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<MaterialApp>(find.byType(MaterialApp))
              .theme!
              .extension<InterfaceSkin>()!
              .style
              .name,
          skin,
          reason: 'root theme must follow appearance',
        );
        final pageContext = tester.element(find.byType(SettingsStylePage));
        expect(InterfaceSkin.of(pageContext).style.name, skin);
        expect(FocusManager.instance.primaryFocus, same(focus));
      }
      expect(tester.takeException(), isNull);
      debugDisableShadows = shadows;
    },
  );
  testWidgets(
    'font changes rendered settings text while its dialog stays open',
    (tester) async {
      final shadows = debugDisableShadows;
      addTearDown(() => debugDisableShadows = shadows);
      final fixture = await pumpDesignFixture(tester);
      final context = tester.element(find.byIcon(Icons.settings_outlined));
      showLauncherDialog<void>(
        context: context,
        styleDialog: false,
        builder: (_) =>
            const SettingsPanel(initialRoute: SettingsStylePage.routeName),
      );
      await tester.pumpAndSettle();
      final focus = FocusManager.instance.primaryFocus;
      for (final (id, family) in [
        ('google-sans', 'Google Sans'),
        ('onest', 'Onest'),
        ('manrope', 'Manrope'),
        ('system', 'Roboto'),
      ]) {
        await fixture.appearance.set('settingsInterfaceFont', id);
        await tester.pumpAndSettle();
        final label = find.text('Стиль интерфейса');
        expect(
          Theme.of(tester.element(label)).textTheme.bodyMedium!.fontFamily,
          family,
        );
        final paragraph = tester.renderObject<RenderParagraph>(
          find.descendant(of: label, matching: find.byType(RichText)),
        );
        expect(paragraph.text.style!.fontFamily, family);
        expect(FocusManager.instance.primaryFocus, same(focus));
      }
      expect(tester.takeException(), isNull);
      debugDisableShadows = shadows;
    },
  );

  testWidgets('weather motion stops for hidden Home, background and economy', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final launcher = LauncherState();
    final weather = MockWeatherService();
    when(weather.stale).thenReturn(false);
    when(weather.configuration).thenReturn(const WeatherConfiguration());
    when(weather.weatherData)
        .thenReturn(const WeatherData(currentConditionCode: 501));
    await settings.setLandscape(const LandscapeConfiguration(motion: true));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: launcher),
          ChangeNotifierProvider<WeatherService>.value(value: weather),
        ],
        child: const MaterialApp(home: AdaptiveLandscapeBackground()),
      ),
    );
    LandscapeEffectsPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((w) => w.painter)
        .whereType<LandscapeEffectsPainter>()
        .single;
    await tester.pump(const Duration(milliseconds: 300));
    expect(painter().frame.value, greaterThan(0));
    launcher.toggleLauncherVisibility();
    await tester.pump();
    final hidden = painter().frame.value;
    await tester.pump(const Duration(seconds: 1));
    expect(painter().frame.value, hidden);
    launcher.showLauncher();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(painter().frame.value, greaterThan(hidden));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final paused = painter().frame.value;
    await tester.pump(const Duration(seconds: 1));
    expect(painter().frame.value, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settings.setMemorySaverEnabled(true);
    await tester.pump();
    final saved = painter().frame.value;
    await tester.pump(const Duration(seconds: 1));
    expect(painter().frame.value, saved);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    settings.dispose();
    launcher.dispose();
    weather.dispose();
  });
  test(
    'style and information choices validate without activating tile overrides',
    () {
      final values = TileAppearance.validValues({
        'settingsInterfaceStyle': 'glass',
        'settingsInterfaceFont': 'outfit',
        'panelCombinedInformation': true,
        'panelFont': 'outfit',
      });
      final a = TileAppearance(values);
      expect(a.active, false);
      expect(a.interfaceStyle, 'glass');
      expect(a.combinedInformation, true);
      expect(a.panelTextStyle.fontFamily, 'Outfit');
      expect(
        TileAppearance.validValues({
          'settingsInterfaceStyle': 'bad',
          'panelCombinedInformation': 1,
        }),
        isEmpty,
      );
    },
  );

  for (final variant in InterfaceStyle.values) {
    testWidgets(
      '$variant preserves bounds, colours and remote slider/switch control',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        addTearDown(settings.dispose);
        final skin = InterfaceSkin(variant);
        final colors = ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        );
        final theme = skin.apply(
          ThemeData(
            colorScheme: colors,
            extensions: [skin, const LauncherStyle()],
          ),
        );
        expect(theme.colorScheme.primary, colors.primary);
        double slider = 50;
        var toggled = false;
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              theme: theme,
              home: Scaffold(
                body: SizedBox(
                  width: 340,
                  child: StatefulBuilder(
                    builder: (context, set) => Column(
                      children: [
                        FocusableSettingsTile(
                          title: const Text('Фокус'),
                          onPressed: () {},
                        ),
                        RoundedSwitchListTile(
                          title: const Text('Погода'),
                          value: toggled,
                          onChanged: (v) => set(() => toggled = v),
                        ),
                        SettingsSliderTile(
                          title: 'Затемнение',
                          options: const [0, 25, 50, 75, 100],
                          value: slider,
                          label: (v) => '$v',
                          onChanged: (v) => set(() => slider = v.toDouble()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        final first = tester.getRect(find.byType(FocusableSettingsTile).first);
        expect(first.width, 340);
        expect(first.height, 58);
        await tester.tap(find.text('Погода'));
        await tester.pumpAndSettle();
        expect(toggled, true);
        Focus.of(tester.element(find.text('Затемнение'))).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(slider, 75);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final showTime in [true, false]) {
    testWidgets(
      'combined block keeps calendar, visibility and toolbar height ($showTime)',
      (tester) async {
        var opened = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: SizedBox(
                height: kToolbarHeight,
                child: CombinedInformation(
                  appearance: const TileAppearance(),
                  showTime: showTime,
                  showDate: true,
                  showWeather: false,
                  timeFormat: 'HH:mm',
                  dateFormat: 'dd.MM.yyyy',
                  onCalendar: () => opened = true,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('statusbar_clock')),
          showTime ? findsOneWidget : findsNothing,
        );
        expect(find.byKey(const Key('statusbar_date')), findsOneWidget);
        expect(find.byType(TopPanelItem), findsOneWidget);
        await tester.tap(find.byType(TopPanelItem));
        await tester.pump();
        expect(opened, true);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  testWidgets('source parameters persist each effect independently', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final appearance = AppearanceService(prefs);
    addTearDown(settings.dispose);
    addTearDown(appearance.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(
            body: SizedBox(width: 380, child: LandscapePage()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Облака'));
    await tester.pumpAndSettle();
    expect(settings.landscape.clouds, false);
    expect(settings.landscape.precipitation, true);
    expect(settings.landscape.timeOfDay, true);
    expect(
      LandscapeConfiguration.decode(prefs.getString(landscapeSettingsKey))
          .clouds,
      false,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
