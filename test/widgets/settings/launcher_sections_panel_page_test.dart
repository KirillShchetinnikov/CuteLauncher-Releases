/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';
import '../../support/settings_help.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Categories are displayed", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);

    await _pumpWidgetWithProviders(tester, appsService);

    expect(find.text("Favorites"), findsOneWidget);
    expect(find.text("Applications"), findsOneWidget);
  });

  for (final language in ['ru', 'en']) {
    testWidgets('section controls stay visible with help collapsed: $language', (
      tester,
    ) async {
      final apps = MockAppsService();
      when(apps.launcherSections).thenReturn([fakeCategory(name: 'Favorites')]);
      await _pumpWidgetWithProviders(tester, apps, locale: Locale(language));
      final l = AppLocalizations.of(
        tester.element(find.byType(LauncherSectionsPanelPage)),
      )!;

      final hint = find.text(l.reorderSectionsHint);
      expect(hint, findsOneWidget);
      expect(find.ancestor(of: hint, matching: find.byType(Scrollable)), findsNothing);
      expect(find.textContaining(l.sectionRulesHelp), findsNothing);
      expect(
        find.ancestor(of: hint, matching: find.byType(SettingsHelp)),
        findsNothing,
      );
      await tester.ensureVisible(hint);
      await tester.pumpAndSettle();
      expect(hint.hitTestable(), findsOneWidget);
      await toggleSettingsHelp(tester, l.sectionRulesHelp);
      expect(find.text(l.sectionRulesHelp), findsOneWidget);
      expect(hint, findsOneWidget);
      await toggleSettingsHelp(tester, l.sectionRulesHelp);
      expect(find.text(l.sectionRulesHelp), findsNothing);
      expect(hint, findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets("'Arrow down' change category order", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    // Explicitly request focus on the Focus node of the widget
    Focus.of(tester.element(find.text("Favorites"))).requestFocus();
    await tester.pumpAndSettle();

    // Enter move state and move down
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    verify(appsService.moveSectionInMemory(0, 1));
  });

  testWidgets("'Settings' opens LauncherSectionPanelPage", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    // Tap to open it
    await tester.tap(find.text("Favorites"));
    await tester.pumpAndSettle();

    expect(find.byKey(Key("LauncherSectionPanelPage")), findsOneWidget);
  });

  testWidgets("'Add Section' opens LauncherSectionPanelPage", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    await _pumpWidgetWithProviders(tester, appsService);

    // Tap "Add section" (lowercase s)
    await tester.tap(find.text("Add section"));
    await tester.pumpAndSettle();

    expect(find.byKey(Key("LauncherSectionPanelPage")), findsOneWidget);
  });

  testWidgets("Can navigate down past 6 sections using D-pad down", (tester) async {
    final appsService = MockAppsService();
    final List<LauncherSection> sections = List.generate(10, (i) => fakeCategory(name: "Section $i", order: i));
    when(appsService.launcherSections).thenReturn(sections);
    await _pumpWidgetWithProviders(tester, appsService);

    // Request focus on Section 0
    Focus.of(tester.element(find.text("Section 0"))).requestFocus();
    await tester.pumpAndSettle();

    // Navigate down through all 10 sections
    for (int i = 0; i < 9; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }

    // Section 9 should now be visible and in the tree
    expect(find.text("Section 9"), findsOneWidget);
  });

  testWidgets('D-pad follows section actions through the help row', (tester) async {
    final apps = MockAppsService();
    final names = List.generate(15, (index) => 'Section $index');
    when(apps.launcherSections).thenReturn([
      for (final name in names) fakeCategory(name: name),
    ]);
    await _pumpWidgetWithProviders(
      tester,
      apps,
      locale: const Locale('ru'),
      panelSize: const Size(320, 300),
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(LauncherSectionsPanelPage)),
    )!;

    void expectFocus(String title) {
      final focused = FocusManager.instance.primaryFocus?.context;
      final currentTitle = focused == null
          ? null
          : tester
                .widgetList<Text>(
                  find.descendant(
                    of: find.byElementPredicate((element) => element == focused),
                    matching: find.byType(Text),
                  ),
                )
                .firstOrNull
                ?.data;
      expect(currentTitle, title);
    }

    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    Future<void> goToReset() async {
      expectFocus(names.first);
      for (final title in [...names.skip(1), l.addSection, l.resetSections]) {
        await press(LogicalKeyboardKey.arrowDown);
        expectFocus(title);
      }
    }

    await goToReset();
    // The non-focusable remote guide can require several viewport steps.
    for (var step = 0; step < 8; step++) {
      if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<SettingsHelp>() != null) break;
      await press(LogicalKeyboardKey.arrowDown);
    }
    expectFocus(l.sectionsAndOrder);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expectFocus(l.resetSections);
    for (final title in [l.addSection, ...names.reversed]) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expectFocus(title);
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);

    await goToReset();
    // The non-focusable remote guide can require several viewport steps.
    for (var step = 0; step < 8; step++) {
      if (FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<SettingsHelp>() != null) break;
      await press(LogicalKeyboardKey.arrowDown);
    }
    expectFocus(l.sectionsAndOrder);
    await press(LogicalKeyboardKey.arrowDown);
    expectFocus(l.sectionsAndOrder);
  });

  testWidgets("Continue watching section is displayed when SettingsService is provided", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    when(settingsService.continueWatchingOrder).thenReturn(0);
    when(settingsService.showContinueWatching).thenReturn(true);

    await _pumpWidgetWithProviders(tester, appsService, settingsService: settingsService);

    expect(find.text("Continue Watching"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.text("Applications"), findsOneWidget);
  });

  testWidgets("Tapping 'Continue Watching' opens ContinueWatchingSettingsPage", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    when(settingsService.continueWatchingOrder).thenReturn(0);
    when(settingsService.showContinueWatching).thenReturn(true);

    await _pumpWidgetWithProviders(tester, appsService, settingsService: settingsService);

    await tester.tap(find.text("Continue Watching"));
    await tester.pumpAndSettle();

    expect(find.byKey(Key("ContinueWatchingSettingsPage")), findsOneWidget);
  });

  testWidgets("'Arrow down' on Continue Watching changes continue watching order", (tester) async {
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites"),
      fakeCategory(name: "Applications"),
    ]);
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    when(settingsService.continueWatchingOrder).thenReturn(0);
    when(settingsService.showContinueWatching).thenReturn(true);

    await _pumpWidgetWithProviders(tester, appsService, settingsService: settingsService);

    Focus.of(tester.element(find.text("Continue Watching"))).requestFocus();
    await tester.pumpAndSettle();

    // Enter move state and move down
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    verify(settingsService.setContinueWatchingOrder(1));
  });
  for (final visible in [true, false]) {
    testWidgets('Continue Watching crosses visibility boundary ($visible)', (tester) async {
      final apps = MockAppsService();
      when(apps.launcherSections).thenReturn([]);
      final settings = MockSettingsService();
      when(settings.appKeyClickEnabled).thenReturn(false);
      when(settings.continueWatchingOrder).thenReturn(0);
      when(settings.showContinueWatching).thenReturn(visible);
      await _pumpWidgetWithProviders(tester, apps, settingsService: settings);
      final row = find.text('Continue Watching');
      Focus.of(tester.element(row)).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(visible ? LogicalKeyboardKey.arrowDown : LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      verify(settings.setShowContinueWatching(!visible)).called(1);
      expect(Focus.of(tester.element(row)).hasFocus, isTrue);
    });
  }

}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  AppsService appsService, {
  SettingsService? settingsService,
  Locale? locale,
  Size? panelSize,
}) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        if (settingsService != null)
          ChangeNotifierProvider<SettingsService>.value(value: settingsService),
      ],
      builder: (_, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          LauncherSectionPanelPage.routeName: (_) => Container(key: Key("LauncherSectionPanelPage")),
          ContinueWatchingSettingsPage.routeName: (_) => Container(key: Key("ContinueWatchingSettingsPage")),
        },
        home: Scaffold(
          body: SizedBox(
            width: panelSize?.width,
            height: panelSize?.height,
            child: const LauncherSectionsPanelPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
