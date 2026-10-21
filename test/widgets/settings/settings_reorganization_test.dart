import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'dart:io';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:mockito/mockito.dart';
import '../../mocks.mocks.dart';

void main() {
  late SharedPreferences prefs;
  late SettingsService settings;
  late AppearanceService appearance;
  late MockAppsService apps;
  late OnlineWallpaperService online;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    appearance = AppearanceService(prefs);
    online = OnlineWallpaperService(prefs, directory: () async => Directory.systemTemp);
    apps = MockAppsService();
    when(apps.applications).thenReturn([]);
    when(apps.categories).thenReturn([]);
  });
  tearDown(() {
    online.dispose();
    settings.dispose();
    appearance.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget page,
      {String language = 'en', double scale = 1}) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: online),
          ChangeNotifierProvider<AppsService>.value(value: apps),
        ],
        child: MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (c, child) => MediaQuery(
                data: MediaQuery.of(c)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!),
            home: Scaffold(
                body: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(width: 340, child: page))))));
    await tester.pumpAndSettle();
  }

  testWidgets('border style replaces visibility toggle and preserves legacy hidden choice',
      (tester) async {
    await settings.setHideHighlightOutlineOnHomescreen(true);
    await pump(tester, const AppearancePage(section: 'focus'));
    expect(find.text('Show highlight outline'), findsNothing);
    final style = find.widgetWithText(FocusableSettingsTile, 'Border style');
    await tester.scrollUntilVisible(style, 160);
    await tester.pumpAndSettle();
    expect(find.text('No border'), findsOneWidget);
    for (final choice in [('Outline', 'outline'), ('Glow', 'glow'), ('No border', 'none')]) {
      await tester.tap(find.text('Border style'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(choice.$1).last);
      await tester.pumpAndSettle();
      expect(AppearanceService(prefs).appearance.focusBorderStyle(), choice.$2);
    }
  });
  testWidgets('only scale enables enlargement and every effect has an optional shadow',
      (tester) async {
    await pump(tester, const AppearancePage(section: 'focus'));
    expect(appearance.appearance.showFocusShadow, isFalse);
    expect(find.text('Shadow strength'), findsNothing);
    for (final effect in ['scale', 'border', 'lift']) {
      await appearance.set('focusEffect', effect);
      await tester.pumpAndSettle();
      final enlargement = tester.widget<SettingsValueStepper>(find.byWidgetPredicate(
          (w) => w is SettingsValueStepper && w.title == 'Focus enlargement'));
      expect(enlargement.enabled, effect == 'scale');
      expect(find.text('Show shadow'), findsOneWidget);
    }
    await tester.tap(find.text('Show shadow'));
    await tester.pumpAndSettle();
    expect(AppearanceService(prefs).appearance.showFocusShadow, isTrue);
    await tester.tap(find.text('Focus effect'));
    await tester.pumpAndSettle();
    expect(find.text('No movement'), findsOneWidget);
    expect(find.text('Shadow'), findsNothing);
    Navigator.of(tester.element(find.byType(SimpleDialog))).pop();
    await tester.pumpAndSettle();
    await appearance.set('focusBorderStyle', 'glow');
    await appearance.set('opacity', .4);
    await tester.scrollUntilVisible(find.text('Reset this section'), 160);
    await tester.tap(find.text('Reset this section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset this section').last);
    await tester.pumpAndSettle();
    expect(appearance.appearance.showFocusShadow, isFalse);
    expect(appearance.appearance.focusEffect, 'scale');
    expect(appearance.appearance.focusBorderStyle(), 'outline');
    expect(appearance.appearance.opacity, .4);

  });
  testWidgets(
      'reset cancellation preserves zero values; confirm resets all appearance settings',
      (tester) async {
    await settings.setShowAppNamesBelowIcons(false);
    await settings.setShowCategoryTitles(false);
    await appearance.set('opacity', 0);
    await appearance.set('panelOpacity', 0);
    await settings.setAccentColor(ACCENT_COLOR_TEAL);
    await settings.setBackgroundSource('scheduled');
    await settings.setAppHighlightAnimationEnabled(false);
    await pump(tester, const AppearanceSettingsPage());
    final reset = find.text('Reset appearance');
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(appearance.appearance.opacity, 0);
    expect(appearance.appearance.number('panelOpacity'), 0);
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Reset appearance'));
    await tester.pumpAndSettle();
    expect(appearance.appearance.active, isFalse);
    expect(settings.themes, 'modern');
    expect(settings.showAppNamesBelowIcons, isFalse);
    expect(settings.showCategoryTitles, isFalse);
    expect(settings.backgroundSource, 'gradient');
    expect(settings.accentColorHex, ACCENT_COLOR_PURPLE);
    expect(settings.appHighlightAnimationEnabled, isTrue);
    expect(online.configuration.enabled, isFalse);
  });
  testWidgets(
      'disabled top widgets still expose weather, date, traffic and panel editors',
      (tester) async {
    await settings.setShowWeatherInStatusBar(false);
    await settings.setShowDateInStatusBar(false);
    await settings.setShowDataWidgetInStatusBar(false);
    await pump(tester, const StatusBarObjectsPage());
    for (final title in [
      'Clock appearance',
      'Date settings',
      'Weather settings',
      'Traffic counting period'
    ]) {
      await tester.scrollUntilVisible(find.text(title), 200);
      await tester.pumpAndSettle();
      expect(find.widgetWithText(FocusableSettingsTile, title), findsOneWidget);
    }
    expect(settings.showWeatherInStatusBar, isFalse);
  });
  testWidgets(
      'focus route, remote navigation and Back keep parent and focus',
      (tester) async {
    await pump(tester,
        const SettingsPanel(initialRoute: InterfaceSettingsPage.routeName));
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    final panel = find.text('Highlight and animation');
    Focus.of(tester.element(panel)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AppearancePage), findsOneWidget);
    final nav = Navigator.of(tester.element(find.byType(AppearancePage)));
    await nav.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(HomeAppearancePage), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Highlight and animation'))).hasFocus, isTrue);
    expect(find.text('Miscellaneous'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('system Back pops one settings page then closes the panel', (tester) async {
    await pump(tester, Builder(builder: (context) => TextButton(
      onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => const SettingsPanel(initialRoute: InterfaceSettingsPage.routeName))),
      child: const Text('Open settings'),
    )));
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Highlight and animation'));
    await tester.pumpAndSettle();
    expect(find.byType(AppearancePage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(HomeAppearancePage), findsOneWidget);
    expect(find.byType(SettingsPanel), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(InterfaceSettingsPage), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPanel), findsNothing);
    expect(find.text('Open settings'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['ru', 'ar']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('reorganized editors wrap at TV viewport: $language / $scale',
          (tester) async {
        for (final page in [
          const AppearanceSettingsPage(),
          const AppearancePage(),
          const MiscPanelPage(),
          StatusBarPanelPage()
        ]) {
          await pump(tester, page, language: language, scale: scale);
          await tester.drag(find.byType(ListView).first, const Offset(0, -600));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
