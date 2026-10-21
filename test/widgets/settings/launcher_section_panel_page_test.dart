import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/settings_help.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  testWidgets('new category defaults to custom name first and requires a name', (tester) async {
    final service = MockAppsService();
    when(service.launcherSections).thenReturn([]);
    await _pumpWidgetWithProviders(tester, service, null);
    final context = tester.element(find.byType(LauncherSectionPanelPage));
    final l = AppLocalizations.of(context)!;
    expect(find.text(l.customName), findsOneWidget);
    expect(find.text(l.customSectionName), findsOneWidget);
    final save = tester.widget<FocusableSettingsTile>(find.widgetWithText(FocusableSettingsTile, l.save));
    expect(save.onPressed, isNull);
    await tester.tap(find.text(l.customSectionName));
    await tester.pumpAndSettle();
    final dialog = find.byType(AlertDialog);
    expect(dialog, findsOneWidget);
    final custom = find.descendant(of: dialog, matching: find.text(l.customSectionName));
    final allApps = find.descendant(of: dialog, matching: find.text(l.moviesShows));
    expect(tester.getTopLeft(custom).dy, lessThan(tester.getTopLeft(allApps).dy));
    expect(find.descendant(of: dialog, matching: find.text(l.allApplications)), findsNothing);
    expect(find.descendant(of: dialog, matching: find.text(l.favorites)), findsNothing);
    expect(Focus.of(tester.element(custom)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
  });
  testWidgets('last visible category explains protection and cannot be hidden', (tester) async {
    final service = MockAppsService();
    when(service.launcherSections).thenReturn([
      Category(name: 'All Apps', systemKey: 'all_apps', type: CategoryType.row),
      Category(name: 'TV Apps', systemKey: 'tv_apps', visible: false),
    ]);
    await _pumpWidgetWithProviders(tester, service, 0);
    expect(find.text('At least one category must remain visible.'), findsNothing);
    await toggleSettingsHelp(tester, 'At least one category must remain visible.');
    expect(find.text('At least one category must remain visible.'), findsOneWidget);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isTrue);
    expect(toggle.onChanged, isNull);
    await tester.tap(find.text('Show category'));
    await tester.pumpAndSettle();
    verifyNever(service.setCategoryVisible(any, any));
    expect(find.widgetWithText(FocusableSettingsTile, 'Delete'), findsNothing);

  });

  for (final key in ['all_apps', 'tv_apps', 'other_apps', 'favorites']) {
    testWidgets('$key has visibility control and no delete action', (tester) async {
      final service = MockAppsService();
      when(service.launcherSections).thenReturn([
        Category(id: 1, name: 'Renamed standard', systemKey: key),
        Category(id: 2, name: 'Custom'),
      ]);
      await _pumpWidgetWithProviders(tester, service, 0);
      expect(find.text('Delete'), findsNothing);
      expect(find.text('Show category'), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNotNull);
    });
  }

  testWidgets('hidden category can be shown even when only one other is visible', (tester) async {
    final service = MockAppsService();
    when(service.launcherSections).thenReturn([
      Category(name: 'All Apps', systemKey: 'all_apps'),
      Category(id: 2, name: 'TV Apps', systemKey: 'tv_apps', visible: false, type: CategoryType.row),
    ]);
    when(service.setCategoryVisible(2, true)).thenAnswer((_) async => true);
    await _pumpWidgetWithProviders(tester, service, 1);
    final toggle = tester.widget<Switch>(find.byType(Switch));
    expect(toggle.value, isFalse);
    expect(toggle.onChanged, isNotNull);
    await tester.tap(find.text('Show category'));
    await tester.pumpAndSettle();
    verify(service.setCategoryVisible(2, true)).called(1);
  });
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Category is displayed", (tester) async {
    final appsService = MockAppsService();
    final favoritesCategory =
        fakeCategory(name: "Favorites", sort: CategorySort.alphabetical, type: CategoryType.grid, columnsCount: 6);
    when(appsService.launcherSections).thenReturn([
      favoritesCategory,
      fakeCategory(name: "Applications"),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, 0);

    expect(find.text("Favorites"), findsWidgets);
  });

  testWidgets("'Delete' calls AppsService", (tester) async {
    final appsService = MockAppsService();
    final favoritesCategory =
        fakeCategory(name: "Favorites", sort: CategorySort.alphabetical, type: CategoryType.row, rowHeight: 110);
    when(appsService.launcherSections).thenReturn([
      favoritesCategory,
      fakeCategory(name: "Applications"),
    ]);

    await _pumpWidgetWithProviders(tester, appsService, 0);

    final deleteButton = find.text("Delete");
    expect(deleteButton, findsOneWidget);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    verify(appsService.deleteSection(0));
  });
}

Future<void> _pumpWidgetWithProviders(WidgetTester tester, AppsService appsService, int? sectionIndex) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, _) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: LauncherSectionPanelPage(sectionIndex: sectionIndex)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
