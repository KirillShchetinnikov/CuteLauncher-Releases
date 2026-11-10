import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/background_information_order_page.dart';
import 'package:flauncher/widgets/settings/custom_date_format_dialog.dart';
import 'package:flauncher/widgets/settings/information_preview.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/weather_text_format_dialog.dart';

void main() {
  late SettingsService settings;
  late AppearanceService appearance;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    appearance = AppearanceService(prefs);
  });
  tearDown(() {
    settings.dispose();
    appearance.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SettingsMenuLayout(
              onRight: false,
              informationObscured: true,
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(width: 390, child: page),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final entry in const <String, Widget>{
    'appearance': BackgroundInformationSettingsPage(),
    'shared formats': InformationDataSettingsPage(),
    'layout': InformationSectionPage(background: true, section: 'layout'),
    'typography': InformationSectionPage(
      background: true,
      section: 'typography',
    ),
    'colors': InformationSectionPage(background: true, section: 'colors'),
    'order': BackgroundInformationOrderPage(),
    'standalone typography': PanelClockStylePage(background: true),
  }.entries) {
    testWidgets('wallpaper ${entry.key} has no obscured preview', (
      tester,
    ) async {
      await pump(tester, entry.value);
      expect(find.byType(InformationPreview), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('wallpaper weather editor retains one preview', (tester) async {
    await appearance.set('panelInformationPlacements', {'weather': 'background'});
    await pump(tester, const InformationDataSettingsPage());
    final l = AppLocalizations.of(
      tester.element(find.byType(InformationDataSettingsPage)),
    )!;
    await tester.scrollUntilVisible(find.text(l.weatherTextFormat), 100);
    Focus.of(tester.element(find.text(l.weatherTextFormat))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(WeatherTextFormatDialog), findsOneWidget);
    expect(find.byType(InformationPreview), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(WeatherTextFormatDialog),
        matching: find.byType(InformationPreview),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final background in [false, true]) {
    testWidgets('shared date editor previews above the keyboard: background=$background', (
      tester,
    ) async {
      await appearance.set('panelInformationPlacements', {
        'date': background ? 'background' : 'panel',
      });
      await pump(tester, const InformationDataSettingsPage());
      addTearDown(tester.view.resetViewInsets);
      final original = settings.informationDateTime().encode();
      final l = AppLocalizations.of(
        tester.element(find.byType(InformationDataSettingsPage)),
      )!;
      await tester.scrollUntilVisible(find.text(l.informationDateFormat), 100);
      await tester.tap(find.text(l.informationDateFormat));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.customDateFormat));
      await tester.pumpAndSettle();
      expect(find.byType(CustomDateFormatDialog), findsOneWidget);
      expect(
        find.byKey(const ValueKey('custom-date-preview')),
        findsOneWidget,
      );
      final preview = find.byKey(const ValueKey('custom-date-preview'));
      await tester.enterText(find.byType(TextField), "'TEST' yyyy");
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(preview).textSpan!.toPlainText(), contains('TEST ${DateTime.now().year}'));
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(tester.getRect(preview).bottom, lessThanOrEqualTo(tester.getRect(find.byType(TextField)).top));
      expect(tester.getRect(find.byType(TextField)).bottom, lessThanOrEqualTo(240));
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.text(l.customDateFormatError), findsOneWidget);
      expect(tester.widget<Text>(preview).textSpan!.toPlainText(), contains(l.invalidDateFormat));
      expect(settings.informationDateTime().encode(), original);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final verticalOffset in [0, 80, 100]) {
    testWidgets(
      'all layout sliders share a smooth theme at offset $verticalOffset',
      (tester) async {
        await appearance.set(
          'panelBackgroundInformationVerticalOffset',
          verticalOffset,
        );
        await pump(
          tester,
          const InformationSectionPage(background: true, section: 'layout'),
        );
        final l = AppLocalizations.of(
          tester.element(find.byType(InformationSectionPage)),
        )!;
        SliderThemeData? firstTheme;
        for (final title in [
          l.informationBackgroundOffset,
          l.informationBackgroundVerticalOffset,
          l.informationSize,
        ]) {
          await tester.scrollUntilVisible(find.text(title), 100);
          await tester.pumpAndSettle();
          final control = find.widgetWithText(SettingsSliderTile, title);
          expect(control, findsOneWidget);
          final slider = find.descendant(
            of: control,
            matching: find.byType(Slider),
          );
          expect(slider, findsOneWidget);
          final theme = SliderTheme.of(tester.element(slider));
          expect(theme.tickMarkShape, SliderTickMarkShape.noTickMark);
          firstTheme ??= theme;
          expect(theme, firstTheme);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
