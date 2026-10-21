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
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/reset_style_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';


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
        lessThan(tester.getTopLeft(find.text('Оформление')).dy),
      );
      await pump(tester, const InterfaceSettingsPage());
      expect(find.text('Верхняя панель'), findsNothing);
      final l = AppLocalizations.of(
        tester.element(find.byType(InterfaceSettingsPage)),
      )!;
      expect(find.text(l.settingsMenuPosition), findsNothing);
      expect(find.byType(FocusableSettingsTile), findsNWidgets(3));
      expect(find.text(l.sectionsAndOrder), findsOneWidget);
      await tester.tap(find.text(l.appearanceSettings));
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
        await tester.ensureVisible(find.byType(ResetStyleTile));
        expect(tester.getTopLeft(find.text(l.homeSectionGap)).dy,
            lessThan(tester.getTopLeft(find.byType(ResetStyleTile)).dy));
      }
      Future<void> open() async {
        await tester.ensureVisible(find.text(l.categoryBackground));
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

  testWidgets('section appearance puts both resets after every setting', (tester) async {
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(CategoryAppearancePage)))!;
    expect(find.text('Оформление раздела'), findsOneWidget);
    final list = tester.widget<ListView>(find.byType(ListView));
    final children = (list.childrenDelegate as SliverChildListDelegate).children;
    expect(((children[children.length - 2] as FocusableSettingsTile).title as Text).data, l.homeResetLayout);
    expect(((children.last as FocusableSettingsTile).title as Text).data, l.homeResetSection);
    await tester.ensureVisible(find.text(l.homeResetLayout));
    await tester.tap(find.text(l.homeResetLayout));
    await tester.pumpAndSettle();
    expect(appearance.category(1).values['layout'], 'row');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('local section style has four controls and one shared reset', (tester) async {
    await appearance.set('sectionTitles', true);
    await appearance.set('sectionBackground', 0xff112233);
    await appearance.setCategoryTile(1, 'sectionTitles', false);
    await appearance.setCategoryTile(1, 'sectionIcons', true);
    await appearance.setCategoryTile(1, 'sectionPadding', 16);
    await appearance.setCategoryTile(1, 'sectionBackground', 0xffabcdef);
    await appearance.setCategoryTile(1, 'size', 144);
    await pump(tester, const CategoryAppearancePage(categoryId: 1));
    final l = AppLocalizations.of(tester.element(find.byType(CategoryAppearancePage)))!;
    expect(find.text(l.highlightAndAnimation), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pump(tester, const SectionStylePage(categoryId: 1));
    final list = tester.widget<ListView>(find.byType(ListView));
    expect((list.childrenDelegate as SliverChildListDelegate).children, hasLength(5));
    expect(find.text(l.showSectionTitles), findsOneWidget);
    expect(find.text(l.homeSectionIcons), findsOneWidget);
    expect(find.text(l.categoryPadding), findsOneWidget);
    expect(find.text(l.categoryBackground), findsOneWidget);
    expect(find.text(l.homeInactiveOpacity), findsNothing);
    expect(find.text(l.homeOwnReset), findsNothing);
    expect(find.byType(ResetStyleTile), findsOneWidget);
    await tester.tap(find.text(l.resetSectionToGlobal));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(SectionStylePage))).cancelButtonLabel));
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).number('sectionPadding'), 16);
    await tester.tap(find.text(l.resetSectionToGlobal));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l.resetSectionToGlobal).last);
    await tester.pumpAndSettle();
    expect(appearance.tilesFor(1).sectionTitles, isTrue);
    expect(appearance.tilesFor(1).values['sectionBackground'], 0xff112233);
    expect(appearance.tilesFor(1).number('sectionPadding'), isNull);
    expect(appearance.tilesFor(1).tileSize, 144);
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
