import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.mocks.dart';

void main() {
  late FLauncherDatabase db;
  late AppsService apps;

  Future<void> mount(WidgetTester tester, {
    int count = 3,
    CategorySort initialSort = CategorySort.manual,
    bool withApps = false,
  }) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      db = FLauncherDatabase.inMemory();
      for (var i = 0; i < count; i++) {
        await db.insertCategory(
          CategoriesCompanion.insert(name: 'Section $i', order: i, sort: Value(initialSort)),
        );
      }
      final catalog = [
        if (withApps)
          for (final package in ['a', 'b', 'c', 'd'])
            {'packageName': package, 'name': package.toUpperCase(), 'version': '1', 'sideloaded': false},
      ];
      if (withApps) {
        await db.persistApps([
          for (final package in ['a', 'b', 'c', 'd'])
            AppsCompanion.insert(
              packageName: package, name: package.toUpperCase(), version: '1',
              launchCount: Value({'a': 3, 'b': 1, 'c': 4, 'd': 2}[package]!),
              lastLaunchedAt: Value(DateTime(2026, 1, {'a': 2, 'b': 4, 'c': 1, 'd': 3}[package]!)),
            ),
        ]);
        await db.insertAppsCategories([
          for (final entry in ['d', 'c', 'b', 'a'].asMap().entries)
            AppsCategoriesCompanion.insert(categoryId: 1, appPackageName: entry.value, order: entry.key),
        ]);
      }
      final channel = MockFLauncherChannel();
      when(channel.getApplications()).thenAnswer((_) async => catalog);
      when(channel.addAppsChangedListener(any)).thenReturn(null);
      apps = AppsService(channel, db);
      while (!apps.initialized) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    });
    await tester.pumpWidget(
      ChangeNotifierProvider<AppsService>.value(
        value: apps,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            LauncherSectionPanelPage.routeName: (context) => Scaffold(
              body: LauncherSectionPanelPage(
                sectionIndex:
                    ModalRoute.of(context)!.settings.arguments as int?,
              ),
            ),
          },
          home: const Scaffold(
            body: SizedBox(
              width: 380,
              height: 300,
              child: LauncherSectionsPanelPage(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> finish(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const SizedBox());
      await apps.persistSectionsOrder();
      apps.dispose();
      await db.close();
    });
  }

  Future<void> key(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.runAsync(() async {
      await tester.sendKeyEvent(key);
      await Future<void>.delayed(const Duration(milliseconds: 70));
    });
    await tester.pump(const Duration(milliseconds: 80));
    await tester.pumpAndSettle();
  }

  String focusedTitle(WidgetTester tester) => tester
      .widget<Text>(
        find
            .descendant(
              of: find.byWidgetPredicate(
                (w) => w is Focus && w.focusNode?.hasPrimaryFocus == true,
              ),
              matching: find.byType(Text),
            )
            .first,
      )
      .data!;

  testWidgets('top section has focus and add button scrolls with list', (
    tester,
  ) async {
    await mount(tester, count: 12);
    expect(focusedTitle(tester), 'Section 0');
    expect(find.textContaining('Cross the list boundary'), findsOneWidget);
    final help = find.textContaining('Cross the list boundary');
    final hintY = tester.getTopLeft(help).dy;
    final add = find.text('Add section');
    expect(tester.getTopLeft(add).dy, greaterThan(300));
    await tester.scrollUntilVisible(
      add,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getTopLeft(add).dy, lessThan(hintY));
    expect(tester.getTopLeft(help).dy, lessThan(hintY));
    await finish(tester);
  });

  testWidgets(
    'moving scrolls, crosses visibility boundary, and preserves focus',
    (tester) async {
      await mount(tester, count: 7);
      await key(tester, LogicalKeyboardKey.arrowRight);
      for (var i = 0; i < 6; i++) {
        await key(tester, LogicalKeyboardKey.arrowDown);
      }
      expect(focusedTitle(tester), 'Section 0');
      final node = FocusManager.instance.primaryFocus!;
      expect(
        tester
            .getRect(
              find.byWidgetPredicate((w) => w is Focus && w.focusNode == node),
            )
            .bottom,
        lessThanOrEqualTo(300),
      );
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        apps.categories.firstWhere((c) => c.name == 'Section 0').visible,
        isFalse,
      );
      expect(focusedTitle(tester), 'Section 0');
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(
        apps.categories.firstWhere((c) => c.name == 'Section 0').visible,
        isTrue,
      );
      expect(focusedTitle(tester), 'Section 0');
      await finish(tester);
    },
  );

  testWidgets('navigation uses the new order after ending a move', (
    tester,
  ) async {
    await mount(tester, count: 4);
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focusedTitle(tester), 'Section 1');
    await key(tester, LogicalKeyboardKey.arrowRight);
    await key(tester, LogicalKeyboardKey.arrowDown);
    await key(tester, LogicalKeyboardKey.enter);
    await key(tester, LogicalKeyboardKey.arrowUp);
    expect(focusedTitle(tester), 'Section 2');
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focusedTitle(tester), 'Section 1');
    await key(tester, LogicalKeyboardKey.arrowDown);
    expect(focusedTitle(tester), 'Section 3');
    await finish(tester);
  });

  testWidgets('creation returns to sections with focus on new section', (
    tester,
  ) async {
    await mount(tester);
    await tester.ensureVisible(find.text('Add section'));
    await tester.tap(find.text('Add section'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Custom Name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'My category');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.runAsync(() async {
      await tester.tap(find.text('Save'));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    expect(focusedTitle(tester), 'My category');
    await finish(tester);
  });

  testWidgets('reset at list bottom confirms, cancels and restores focus', (
    tester,
  ) async {
    await mount(tester);
    await tester.runAsync(() => apps.addSpacer(250));
    await tester.pumpAndSettle();
    final reset = find.text('Reset section settings');
    await tester.ensureVisible(reset);
    await tester.runAsync(() => tester.tap(reset));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(apps.launcherSections, hasLength(4));
    await tester.ensureVisible(reset);
    await tester.pumpAndSettle();
    await tester.runAsync(() => tester.tap(reset));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(
        find.widgetWithText(TextButton, 'Reset section settings'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
    });
    await tester.pumpAndSettle();
    expect(apps.launcherSections.whereType<LauncherSpacer>(), isEmpty);
    expect(apps.categories.map((c) => c.systemKey), [
      'all_apps',
      'tv_apps',
      'other_apps',
      'favorites',
    ]);
    expect(focusedTitle(tester), 'All applications');
    await finish(tester);
  });

  testWidgets('section editor focuses its first field', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Section 0'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(
      tester.widget<AlertDialog>(find.byType(AlertDialog)).title,
      isA<Text>().having((t) => t.data, 'title', 'Name'),
    );
    await finish(tester);
  });

  testWidgets('category sort saves immediately without Save', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Section 0'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    await tester.tap(find.text('Sort'));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await tester.tap(find.text('Launch frequency'));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect(
      (await tester.runAsync(db.getCategories))!.first.sort,
      CategorySort.mostUsed,
    );
    await finish(tester);
  });

  for (final initial in CategorySort.values) {
    testWidgets('repeated sorts return to initial $initial and persist every mode', (tester) async {
      await mount(tester, count: 1, initialSort: initial, withApps: true);
      await tester.tap(find.text('Section 0'));
      await tester.pumpAndSettle();
      const labels = {
        CategorySort.manual: 'Manual',
        CategorySort.alphabetical: 'Alphabetical',
        CategorySort.lastUsed: 'Last Used',
        CategorySort.mostUsed: 'Launch frequency',
      };
      const orders = {
        CategorySort.manual: ['d', 'c', 'b', 'a'],
        CategorySort.alphabetical: ['a', 'b', 'c', 'd'],
        CategorySort.lastUsed: ['b', 'd', 'a', 'c'],
        CategorySort.mostUsed: ['c', 'a', 'd', 'b'],
      };
      for (final next in CategorySort.values.where((sort) => sort != initial)) {
        for (final sort in [next, initial]) {
          await tester.tap(find.text('Sort'));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            await tester.tap(find.text(labels[sort]!));
            await Future<void>.delayed(const Duration(milliseconds: 30));
          });
          await tester.pumpAndSettle();
          expect((await tester.runAsync(db.getCategories))!.first.sort, sort);
          expect(apps.categories.first.applications.map((app) => app.packageName).toList(), orders[sort]);
        }
      }
      await tester.runAsync(apps.refreshState);
      expect(apps.categories.first.sort, initial);
      expect(apps.categories.first.applications.map((app) => app.packageName).toList(), orders[initial]);
      await finish(tester);
    });
  }

  testWidgets('existing spacer saves immediately and offers 250 height', (
    tester,
  ) async {
    await mount(tester);
    await tester.runAsync(() => apps.addSpacer(100));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Spacer'));
    await tester.tap(find.text('Spacer'));
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsNothing);
    expect(FocusManager.instance.primaryFocus, isNotNull);
    final slider = find.byType(Slider);
    final options = tester
        .widget<SettingsSliderTile>(find.byType(SettingsSliderTile))
        .options;
    expect(options, containsAll([125, 175, 200, 250]));
    final rect = tester.getRect(slider);
    await tester.runAsync(() async {
      await tester.tapAt(Offset(rect.right - 25, rect.center.dy));
      await Future<void>.delayed(const Duration(milliseconds: 30));
    });
    await tester.pumpAndSettle();
    expect((await tester.runAsync(db.getLauncherSpacers))!.single.height, 250);
    await finish(tester);
  });
}
