import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/apps_grid.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'package:flauncher/widgets/settings/category_appearance_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/section_style_page.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/home_style_setting.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/reset_style_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';


void main() {
  test('fixed rows distribute every app evenly without empty rows', () {
    expect(balancedRowCounts(23, 3), [8, 8, 7]);
    expect(balancedRowCounts(2, 10), [1, 1]);
    expect(balancedRowCounts(0, 3), isEmpty);
    expect(balancedRowCounts(12, 3), [4, 4, 4]);
  });

  late AppearanceService appearance;
  late SettingsService settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget page) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          routes: {SettingsStylePage.routeName: (_) => const SettingsStylePage(), WallpaperPanelPage.routeName: (_) => const Scaffold(body: Text('wallpaper destination'))},
          builder: (_, child) => Material(child: child),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: page),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'top panel follows home in root menu; click sounds end home menu',
    (tester) async {
      await pump(tester, const SettingsPanelPage());
      expect(
        tester.getTopLeft(find.text('Верхняя панель')).dy,
        greaterThan(tester.getTopLeft(find.text('Главный экран')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Верхняя панель')).dy,
        lessThan(tester.getTopLeft(find.text('Стиль интерфейса')).dy),
      );
      await pump(tester, const InterfaceSettingsPage());
      expect(find.text('Верхняя панель'), findsNothing);
      final l = AppLocalizations.of(
        tester.element(find.byType(InterfaceSettingsPage)),
      )!;
      expect(find.text(l.settingsMenuPosition), findsNothing);
      expect(find.byType(FocusableSettingsTile), findsNWidgets(3));
      expect(find.text(l.sectionsAndOrder), findsOneWidget);
      expect(find.text(l.appChannelsTitle), findsNothing);
      await tester.tap(find.text('${l.homeScreen} · ${l.appearanceSettings}'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeAppearancePage), findsOneWidget);
      final entries = tester.widgetList<FocusableSettingsTile>(find.byType(FocusableSettingsTile)).toList();
      expect((entries.first.title as Text).data, l.background);
      expect(entries.first.autofocus, isTrue);
      await tester.tap(find.text(l.background));
      await tester.pumpAndSettle();
      expect(find.text('wallpaper destination'), findsOneWidget);
      Navigator.of(tester.element(find.text('wallpaper destination'))).pop();
      await tester.pumpAndSettle();
      expect(find.text(l.tilesAndLabels), findsOneWidget);
      expect(find.text(l.highlightAndAnimation), findsOneWidget);
      await tester.tap(find.text(l.launcherSections));
      await tester.pumpAndSettle();
      expect(find.byType(SectionStylePage), findsOneWidget);
      expect(find.text(l.homeScrollMode), findsOneWidget);
      expect(find.text(l.homeSectionPosition), findsOneWidget);
      Navigator.of(tester.element(find.byType(SectionStylePage)) ).pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(HomeAppearancePage))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.homeParameters));
      await tester.pumpAndSettle();
      expect(find.byType(HomeParametersPage), findsOneWidget);
      expect(find.text(l.homeScrollMode), findsNothing);
      expect(tester.getTopLeft(find.text(l.appKeyClick)).dy,
          greaterThan(tester.getTopLeft(find.text(l.backButtonAction)).dy));
      expect(settings.homeKeyClickEnabled, isFalse);
      expect(settings.appKeyClickEnabled, isFalse);
      await tester.tap(find.text(l.appKeyClick));
      await tester.pumpAndSettle();
      expect(settings.homeKeyClickEnabled, isTrue);
      expect(settings.appKeyClickEnabled, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('settings side lives in appearance style and remains editable', (
    tester,
  ) async {
    await pump(tester, const AppearanceSettingsPage());
    expect(find.text('Стиль настроек'), findsOneWidget);
    expect(find.text('Фон'), findsNothing);
    await tester.tap(find.text('Стиль настроек'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsStylePage), findsOneWidget);
    final l = AppLocalizations.of(
      tester.element(find.byType(SettingsStylePage)),
    )!;
    expect(find.text(l.appKeyClick), findsOneWidget);
    await tester.tap(find.text(l.appKeyClick));
    await tester.pumpAndSettle();
    expect(settings.appKeyClickEnabled, isTrue);
    expect(settings.homeKeyClickEnabled, isFalse);
    await tester.tap(find.text(l.settingsMenuPosition));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.settingsMenuRight));
    await tester.pumpAndSettle();
    expect(settings.settingsMenuOnRight, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('local tile controls change only the selected category', (
    tester,
  ) async {
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(
      tester.element(find.byType(CategoryAppearancePage)),
    )!;
    await tester.tap(find.text(l.tilesAndLabels));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).tileSize, 136);
    expect(appearance.tilesFor(2).tileSize, 128);
    expect(find.text(l.tileVerticalGap), findsOneWidget);
    await tester.scrollUntilVisible(find.text(l.homeLabelMode), 200,
        scrollable: find.byType(Scrollable).last);
    expect(find.text(l.homeLabelMode), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('section background palette saves, cancels and clears locally', (tester) async {
    for (final id in <int?>[null, 1]) {
      await pump(tester, SectionStylePage(categoryId: id));
      final l = AppLocalizations.of(tester.element(find.byType(SectionStylePage)))!;
      expect(find.text(l.categoryPadding), id == null ? findsNothing : findsOneWidget);
      if (id == null) {
        await tester.scrollUntilVisible(find.byType(ResetStyleTile), 150);
        expect(tester.getTopLeft(find.text(l.homeSectionGap)).dy,
            lessThan(tester.getTopLeft(find.byType(ResetStyleTile)).dy));
      }
      Future<void> open() async {
        await tester.scrollUntilVisible(find.text(l.categoryBackground), -150);
        await tester.tap(find.text(l.categoryBackground));
        await tester.pumpAndSettle();
      }
      await open();
      expect(find.byType(ColorPaletteDialog), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      final style = id == null ? appearance.appearance : appearance.tilesFor(id);
      expect(style.values['sectionBackground'], appearancePalette[1]);
      if (id != null) expect(appearance.tilesFor(2).values['sectionBackground'], 0);
      await open();
      Navigator.of(tester.element(find.byType(ColorPaletteDialog))).pop();
      await tester.pumpAndSettle();
      expect((id == null ? appearance.appearance : appearance.tilesFor(id)).values['sectionBackground'], appearancePalette[1]);
      await open();
      await tester.tap(find.text(l.categoryTransparent));
      await tester.pumpAndSettle();
      expect((id == null ? appearance.appearance : appearance.tilesFor(id)).values['sectionBackground'], 0);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('section background sliders save, inherit and preserve color', (tester) async {
    for (final id in <int?>[null, 1]) {
      await pump(tester, SectionStylePage(categoryId: id));
      final l = AppLocalizations.of(tester.element(find.byType(SectionStylePage)))!;
      Finder slider(String title) => find.byWidgetPredicate(
        (w) => w is SettingsSliderTile && w.title == title);
      expect(tester.widget<SettingsSliderTile>(slider(l.tileOpacity)).enabled, isFalse);
      expect(tester.widget<SettingsSliderTile>(slider(l.tileCornerRadius)).enabled, isFalse);
      if (id == null) {
        await appearance.set('sectionBackground', 0xff123456);
      } else {
        await appearance.setCategoryTile(id, 'sectionBackground', 0xff123456);
      }
      await tester.pumpAndSettle();
      for (final title in [l.tileOpacity, l.tileCornerRadius]) {
        final control = slider(title);
        expect(tester.widget<SettingsSliderTile>(control).enabled, isTrue);
        await tester.ensureVisible(control);
        Focus.of(tester.element(find.descendant(of: control, matching: find.byType(Text)).first)).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(title == l.tileOpacity
            ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        final focus = FocusManager.instance.primaryFocus;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, isNot(same(focus)));
      }
      final style = id == null ? appearance.appearance : appearance.tilesFor(id);
      expect(style.sectionOpacity, .99);
      expect(style.sectionRadius, 1);
      expect(style.values['sectionBackground'], 0xff123456);
      if (id != null) {
        expect(appearance.tilesFor(2).sectionOpacity, 1);
        expect(appearance.tilesFor(2).sectionRadius, 0);
      }
      await appearance.resetFields(['sectionBackground'], categoryId: id);
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsSliderTile>(slider(l.tileOpacity)).enabled, isFalse);
      expect((id == null ? appearance.appearance : appearance.tilesFor(id)).sectionOpacity, .99);
      await appearance.resetFields(['sectionOpacity', 'sectionRadius'], categoryId: id);
      expect((id == null ? appearance.appearance : appearance.tilesFor(id)).sectionOpacity, 1);
      expect((id == null ? appearance.appearance : appearance.tilesFor(id)).sectionRadius, 0);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    }
  });

  testWidgets('section controls share one layout and appearance reset', (tester) async {
    await appearance.set('sectionTitles', true);
    await appearance.set('sectionBackground', 0xff112233);
    await appearance.setCategoryTile(1, 'sectionTitles', false);
    await appearance.setCategoryTile(1, 'sectionIcons', true);
    await appearance.setCategoryTile(1, 'sectionPadding', 16);
    await appearance.setCategoryTile(1, 'sectionBackground', 0xffabcdef);
    await appearance.setCategoryTile(1, 'size', 144);
    await appearance.setCategoryTile(2, 'size', 160);
    await appearance.setCategory(1, 'columns', 4);
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(CategoryAppearancePage)))!;
    final list = tester.widget<ListView>(find.byType(ListView));
    final children = (list.childrenDelegate as SliverChildListDelegate).children;
    expect(children.whereType<ResetStyleTile>(), hasLength(1));
    expect((children.last as ResetStyleTile).title, l.homeResetLayout);
    expect(find.text(l.homeSectionStyle), findsNothing);
    expect(find.text(l.homeResetSection), findsNothing);
    await tester.scrollUntilVisible(find.text(l.homeSectionIcons), 100);
    expect(tester.widget<RoundedSwitchListTile>(find.widgetWithText(RoundedSwitchListTile, l.homeSectionIcons)).enabled, isFalse);
    await tester.scrollUntilVisible(find.text(l.homeResetLayout), 100);
    await tester.tap(find.text(l.homeResetLayout));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(CategoryAppearancePage))).cancelButtonLabel));
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).tileSize, 144);
    expect(appearance.category(1).columns, 4);
    await tester.tap(find.text(l.homeResetLayout));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.homeResetLayout).last);
    await tester.pumpAndSettle();
    expect(appearance.category(1).layout, 'row');
    expect(appearance.category(1).columns, 0);
    expect(appearance.tilesFor(1).sectionTitles, isTrue);
    expect(appearance.tilesFor(1).values['sectionBackground'], 0xff112233);
    expect(appearance.tilesFor(1).number('sectionPadding'), isNull);
    expect(appearance.tilesFor(1).tileSize, 128);
    expect(appearance.tilesFor(2).tileSize, 160);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tile source updates immediately without losing remote focus', (tester) async {
    await appearance.set('size', 144);
    await appearance.setCategoryTile(1, 'sectionPadding', 16);
    await appearance.setCategory(1, 'columns', 0);
    await pump(tester, const AppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(AppearancePage)))!;
    final size = find.byWidgetPredicate((w) => w is HomeStyleSetting && w.field == 'size');
    Finder marker() => find.descendant(of: size, matching: find.byIcon(Icons.link));
    expect(marker(), findsOneWidget);
    expect(find.text(l.homeInherited), findsOneWidget);
    expect(find.text(l.homeOwnReset), findsNothing); // The shared button is below the viewport.
    final focus = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).tileSize, 136);
    expect(marker(), findsNothing);
    expect(FocusManager.instance.primaryFocus, same(focus));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(marker(), findsOneWidget);
    expect(FocusManager.instance.primaryFocus, same(focus));
    await appearance.set('size', 192);
    await tester.pumpAndSettle();
    expect(tester.widget<SettingsValueStepper>(find.descendant(of: size, matching: find.byType(SettingsValueStepper))).value, 192);
    await appearance.setCategoryTile(1, 'size', 160);
    await appearance.setCategoryTile(1, 'labels', 'all');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(l.homeOwnReset), 200);
      await tester.ensureVisible(find.text(l.homeOwnReset));
      await tester.pumpAndSettle();
    expect(find.byType(ResetStyleTile), findsOneWidget);
    expect(find.text(l.resetStyleSection), findsNothing);
    await tester.tap(find.text(l.homeOwnReset));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.homeOwnReset).last);
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).tileSize, 192);
    expect(appearance.tilesFor(1).labels, 'none');
    expect(appearance.tilesFor(1).number('sectionPadding'), 16);
    expect(appearance.category(1).columns, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tape offers row count while layout has only tape and grid', (tester) async {
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(CategoryAppearancePage)))!;
    final rowCount = find.widgetWithText(SettingsValueStepper, l.tileRowCount);
    expect(tester.widget<SettingsValueStepper>(rowCount).value, 1);
    await tester.tap(find.text(l.layout));
    await tester.pumpAndSettle();
    expect(find.text(l.homeLayoutRows), findsNothing);
    expect(find.text(l.homeLayoutRow), findsWidgets);
    expect(find.text(l.homeLayoutGrid), findsOneWidget);
    Navigator.of(tester.element(find.text(l.homeLayoutGrid))).pop();
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text(l.tileRowCount))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.category(1).rows, 2);
    expect(appearance.category(1).layout, 'rows');
    expect(tester.widget<SettingsValueStepper>(rowCount).value, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(appearance.category(1).layout, 'row');
    expect(tester.widget<SettingsValueStepper>(rowCount).value, 1);
    await appearance.setCategory(1, 'layout', 'rows');
    await appearance.setCategory(1, 'rows', 3);
    await tester.pumpAndSettle();
    expect(find.text(l.homeLayoutRow), findsOneWidget);
    expect(tester.widget<SettingsValueStepper>(rowCount).value, 3);
    await appearance.setCategory(1, 'layout', 'grid');
    await tester.pumpAndSettle();
    expect(find.text(l.tileRowCount), findsNothing);
    expect(find.text(l.categoryMaxRows), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('card count uses arrows from Auto to 12 without a dialog', (tester) async {
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(CategoryAppearancePage)))!;
    final stepper = find.widgetWithText(SettingsValueStepper, l.homeCardCount);
    expect(tester.widget<SettingsValueStepper>(stepper).useSlider, isFalse);
    expect(find.descendant(of: stepper, matching: find.byIcon(Icons.chevron_left)), findsOneWidget);
    expect(find.descendant(of: stepper, matching: find.byIcon(Icons.chevron_right)), findsOneWidget);
    Focus.of(tester.element(find.text(l.homeCardCount))).requestFocus();
    await tester.pumpAndSettle();
    for (var i = 1; i <= 12; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(appearance.category(1).columns, i);
      expect(find.byType(AlertDialog), findsNothing);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(appearance.category(1).columns, 12);
    for (var i = 0; i < 13; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }
    expect(appearance.category(1).columns, 0);
    expect(tester.widget<SettingsValueStepper>(stepper).label(0), startsWith(l.homeAuto));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

}
