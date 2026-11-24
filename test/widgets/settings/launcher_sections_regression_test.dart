import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/app_channels_order_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_read_only_value.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/section_icons.dart';
import 'package:flauncher/widgets/section_heading_icon.dart';
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
  late AppearanceService appearance;
  SettingsService? settings;

  Future<void> mount(
    WidgetTester tester, {
    int count = 3,
    CategorySort initialSort = CategorySort.manual,
    bool withApps = false,
    bool withSettings = false,
  }) async {
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      appearance = AppearanceService(await SharedPreferences.getInstance());
      settings = withSettings
          ? SettingsService(await SharedPreferences.getInstance())
          : null;
      db = FLauncherDatabase.inMemory();
      for (var i = 0; i < count; i++) {
        await db.insertCategory(
          CategoriesCompanion.insert(
            name: 'Section $i',
            order: i,
            sort: Value(initialSort),
          ),
        );
      }
      final catalog = [
        if (withApps)
          for (final package in ['a', 'b', 'c', 'd'])
            {
              'packageName': package,
              'name': package.toUpperCase(),
              'version': '1',
              'sideloaded': false,
            },
      ];
      if (withApps) {
        await db.persistApps([
          for (final package in ['a', 'b', 'c', 'd'])
            AppsCompanion.insert(
              packageName: package,
              name: package.toUpperCase(),
              version: '1',
              launchCount: Value({'a': 3, 'b': 1, 'c': 4, 'd': 2}[package]!),
              lastLaunchedAt: Value(
                DateTime(2026, 1, {'a': 2, 'b': 4, 'c': 1, 'd': 3}[package]!),
              ),
            ),
        ]);
        await db.insertAppsCategories([
          for (final entry in ['d', 'c', 'b', 'a'].asMap().entries)
            AppsCategoriesCompanion.insert(
              categoryId: 1,
              appPackageName: entry.value,
              order: entry.key,
            ),
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AppsService>.value(value: apps),
          ChangeNotifierProvider<AppearanceService>.value(value: appearance),
          if (settings != null)
            ChangeNotifierProvider<SettingsService>.value(value: settings!),
        ],
        child: MaterialApp(
          builder: (_, child) => Material(child: child),
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AppChannelsOrderPage.routeName: (_) =>
                const Scaffold(body: Text('Feed selection')),
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
      appearance.dispose();
      settings?.dispose();
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

  testWidgets('section rows follow saved icons, including hidden sections and move mode', (tester) async {
    await mount(tester, count: 1, withSettings: true);
    final category = apps.categories.singleWhere((item) => item.name == 'Section 0');
    final watchNext = ContinueWatchingSection();
    Finder rowFor(LauncherSection s) => find.byKey(ValueKey((s.runtimeType, s.id)));
    SectionIcon iconFor(LauncherSection s) => tester.widget<SectionHeadingIcon>(
      find.descendant(of: rowFor(s), matching: find.byType(SectionHeadingIcon)),
    ).icon;

    await settings!.setShowContinueWatching(false);
    await tester.pumpAndSettle();
    expect(iconFor(category), SectionIcon.folder);
    expect(iconFor(watchNext), SectionIcon.continueWatching);

    await appearance.setCategoryTitleIcon(category.id, SectionIcon.movies);
    await appearance.setCategoryTitleIcon(watchNext.id, SectionIcon.music);
    await tester.pumpAndSettle();
    expect(iconFor(category), SectionIcon.movies);
    expect(iconFor(watchNext), SectionIcon.music);

    tester.widget<FocusableSettingsTile>(rowFor(category)).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await key(tester, LogicalKeyboardKey.arrowRight);
    expect(find.descendant(of: rowFor(category), matching: find.text('Reorder')), findsOneWidget);
    expect(iconFor(category), SectionIcon.movies);
    await key(tester, LogicalKeyboardKey.enter);
    await appearance.setCategoryTitleIcon(category.id, null);
    await tester.pumpAndSettle();
    expect(iconFor(category), SectionIcon.folder);
    await finish(tester);
  });

  testWidgets(
    'app feeds edit, move and cross visibility boundary only as one section',
    (tester) async {
      await mount(tester, count: 2);
      await tester.runAsync(
        () => apps.addCategory('App Feeds', systemKey: 'app_channels'),
      );
      await tester.pumpAndSettle();
      final row = find.text('App feeds');
      expect(row, findsOneWidget);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(find.byType(LauncherSectionPanelPage), findsOneWidget);
      final l = AppLocalizations.of(
        tester.element(find.byType(LauncherSectionPanelPage)),
      )!;
      expect(find.text(l.sort), findsNothing);
      expect(find.text(l.categoryAppearance), findsOneWidget);
      final sources = find.byWidgetPredicate(
        (widget) =>
            widget is FocusableSettingsTile &&
            widget.title is Text &&
            (widget.title as Text).data == 'Feeds and order',
      );
      await tester.ensureVisible(sources);
      await tester.tap(sources);
      await tester.pumpAndSettle();
      expect(find.text('Feed selection'), findsOneWidget);
      Navigator.of(tester.element(find.text('Feed selection'))).pop();
      await tester.pumpAndSettle();
      expect(focusedTitle(tester), 'Feeds and order');
      Navigator.of(tester.element(find.byType(LauncherSectionPanelPage))).pop();
      await tester.pumpAndSettle();
      expect(focusedTitle(tester), 'App feeds');
      await key(tester, LogicalKeyboardKey.arrowRight);
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(apps.launcherSections.map((s) => (s as Category).name), [
        'Section 0',
        'App Feeds',
        'Section 1',
      ]);
      await key(tester, LogicalKeyboardKey.arrowDown);
      await key(tester, LogicalKeyboardKey.arrowDown);
      expect(
        apps.categories.singleWhere((c) => c.isAppChannels).visible,
        isFalse,
      );
      expect(focusedTitle(tester), 'App feeds');
      await key(tester, LogicalKeyboardKey.arrowUp);
      expect(
        apps.categories.singleWhere((c) => c.isAppChannels).visible,
        isTrue,
      );
      expect(focusedTitle(tester), 'App feeds');
      await key(tester, LogicalKeyboardKey.enter);
      expect(row, findsOneWidget);
      await finish(tester);
    },
  );

  testWidgets('app feeds editor keeps a fixed name without exposing sorting', (
    tester,
  ) async {
    await mount(tester, count: 2);
    await tester.runAsync(
      () => apps.addCategory('App Feeds', systemKey: 'app_channels'),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('App feeds'));
    await tester.tap(find.text('App feeds'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(
      tester.element(find.byType(LauncherSectionPanelPage)),
    )!;
    expect(find.text(l.appChannelsTitle), findsOneWidget);
    expect(find.byType(SettingsReadOnlyValue), findsNothing);
    expect(find.text(l.customName), findsNothing);
    expect(find.byType(TextField), findsNothing);
    final group = apps.categories.singleWhere((c) => c.isAppChannels);
    expect(group.name, 'App Feeds');
    expect(
      (await tester.runAsync(db.getCategories))!
          .singleWhere((c) => c.systemKey == 'app_channels')
          .name,
      'App Feeds',
    );
    expect(find.text(l.sort), findsNothing);
    await finish(tester);
  });

  testWidgets('holding Down keeps moving the selected section', (tester) async {
    await mount(tester, count: 4);
    await key(tester, LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      apps.launcherSections[2].id,
      apps.categories.firstWhere((c) => c.name == 'Section 0').id,
    );
    expect(focusedTitle(tester), 'Section 0');
    expect(find.text('Reorder'), findsOneWidget);
    await finish(tester);
  });

  testWidgets('top section has focus and add button scrolls with list', (
    tester,
  ) async {
    await mount(tester, count: 12);
    expect(focusedTitle(tester), 'Section 0');
    expect(
      find.text(AppLocalizations.of(tester.element(find.byType(LauncherSectionsPanelPage)))!.reorderSectionsHint).hitTestable(),
      findsOneWidget,
    );
    final hint = find.text(AppLocalizations.of(tester.element(find.byType(LauncherSectionsPanelPage)))!.reorderSectionsHint);
    final hintRect = tester.getRect(hint);
    final first = find.text('Section 0');
    final firstY = tester.getTopLeft(first).dy;
    final add = find.text('Add section');
    expect(tester.getTopLeft(add).dy, greaterThan(300));
    await tester.scrollUntilVisible(
      add,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.getTopLeft(add).dy, lessThan(300));
    expect(tester.getTopLeft(first).dy, lessThan(firstY));
    expect(tester.getRect(hint), hintRect);
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

  for (final withSettings in [false, true]) {
    testWidgets(
      'hiding prepends the section and showing appends it: watching=$withSettings',
      (tester) async {
        await mount(tester, count: 5, withSettings: withSettings);
        final hidden = apps.categories
            .where((c) => c.name == 'Section 0' || c.name == 'Section 1')
            .toList();
        await tester.runAsync(() async {
          for (final section in hidden) {
            await apps.setCategoryVisible(section.id, false);
          }
        });
        await tester.pumpAndSettle();
        final moving = apps.categories.firstWhere((c) => c.name == 'Section 4');
        bool isVisible() =>
            apps.categories.firstWhere((c) => c.id == moving.id).visible;
        Focus.of(tester.element(find.text('Section 4'))).requestFocus();
        await tester.pumpAndSettle();
        expect(apps.visibleLauncherSections.last.id, moving.id);
        expect(focusedTitle(tester), 'Section 4');
        await key(tester, LogicalKeyboardKey.arrowRight);
        expect(focusedTitle(tester), 'Section 4');
        await key(tester, LogicalKeyboardKey.arrowDown);
        expect(isVisible(), isFalse);
        expect(
          apps.launcherSections
              .whereType<Category>()
              .where((c) => !c.visible)
              .map((c) => c.name),
          ['Section 4', 'Section 0', 'Section 1'],
        );
        if (withSettings) expect(settings!.continueWatchingOrder, 1);
        expect(focusedTitle(tester), 'Section 4');
        await key(tester, LogicalKeyboardKey.arrowUp);
        expect(isVisible(), isTrue);
        expect(apps.visibleLauncherSections.last.id, moving.id);
        if (withSettings) expect(settings!.continueWatchingOrder, 0);
        await key(tester, LogicalKeyboardKey.arrowDown);
        expect(isVisible(), isFalse);
        await key(tester, LogicalKeyboardKey.enter);
        await tester.runAsync(apps.persistSectionsOrder);
        final stored = await tester.runAsync(db.getCategories);
        final savedHidden = stored!.where((c) => !c.visible).toList()
          ..sort((a, b) => a.order.compareTo(b.order));
        expect(savedHidden.map((c) => c.name), [
          'Section 4',
          'Section 0',
          'Section 1',
        ]);
        await finish(tester);
      },
    );
  }

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

  testWidgets(
    'a hidden grid keeps its draft across type changes and reopens with the same controls',
    (tester) async {
      await mount(tester);
      Future<void> tap(String title) async {
        final target = find.text(title).last;
        await tester.ensureVisible(target);
        await tester.tap(target);
        await tester.pumpAndSettle();
      }

      await tap('Add section');
      final l = AppLocalizations.of(
        tester.element(find.byType(LauncherSectionPanelPage)),
      )!;
      void expectFieldOrder(String name) {
        final fields = [name, l.categoryVisible, l.sort, l.layout];
        final positions = fields
            .map((title) => tester.getTopLeft(find.text(title)).dy)
            .toList();
        expect(positions, orderedEquals([...positions]..sort()));
      }

      expectFieldOrder(l.name);
      await tap(l.name);
      await tap(l.music);
      await tap(l.categoryVisible);
      await tap(l.layout);
      await tap(l.homeLayoutGrid);
      await tap(l.sort);
      await tap(l.alphabetical);
      await tap(l.type);
      await tap(l.spacer);
      expect(find.text(l.height), findsOneWidget);
      expect(find.text(l.layout), findsNothing);
      await tap(l.type);
      await tap(l.category);
      expect(find.text(l.music), findsOneWidget);
      expect(find.text(l.homeLayoutGrid), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      expect(apps.categories, hasLength(3));

      // Two OK events before a rebuild must create just one section.
      await tester.runAsync(() async {
        final save = tester
            .widget<FocusableSettingsTile>(
              find.widgetWithText(FocusableSettingsTile, l.save),
            )
            .onPressed!;
        save();
        save();
        await Future<void>.delayed(const Duration(milliseconds: 70));
      });
      await tester.pumpAndSettle();
      expect(focusedTitle(tester), l.music);
      final stored = (await tester.runAsync(db.getCategories))!;
      expect(stored, hasLength(4));
      final category = stored.singleWhere((c) => c.name == 'Music');
      expect(
        (category.visible, category.sort, category.type),
        (false, CategorySort.alphabetical, CategoryType.grid),
      );
      final layout = appearance.category(category.id);
      expect((layout.layout, layout.columns, layout.maxRows), ('grid', 6, 3));
      await tap(l.music);
      expectFieldOrder(l.music);
      expect(find.text(l.homeLayoutGrid), findsOneWidget);
      await tap(l.layout);
      await tap(l.homeLayoutRow);
      expect(appearance.category(category.id).layout, 'row');
      await appearance.setTapeRows(category.id, 3);
      await tester.pumpAndSettle();
      await tap(l.layout);
      await tap(l.homeLayoutRow);
      expect(appearance.category(category.id).layout, 'rows');
      expect(appearance.category(category.id).rows, 3);
      await tap(l.categoryAppearance);
      expect(find.text(l.homeLayoutRow), findsOneWidget);
      await tap(l.layout);
      await tap(l.homeLayoutGrid);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(l.homeLayoutGrid), findsOneWidget);
      await finish(tester);
    },
  );

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
      'app_channels',
    ]);
    expect(focusedTitle(tester), 'All applications');
    await finish(tester);
  });

  testWidgets('header rename supports presets, custom text and cancellation from the remote', (tester) async {
    await mount(tester);
    await tester.tap(find.text('Section 0'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(LauncherSectionPanelPage)))!;
    expect(find.text(l.renameCategory), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(l.music));
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();
    expect(find.text(l.music), findsOneWidget);
    for (final save in [false, true]) {
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.customSectionName));
      await tester.pumpAndSettle();
      expect(tester.widget<EditableText>(find.byType(EditableText)).controller.text, l.music);
      await tester.enterText(find.byType(TextFormField), 'My music collection');
      await tester.runAsync(() async {
        await tester.tap(find.text(save ? l.save : l.cancel));
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
      final expected = save ? 'My music collection' : l.music;
      expect(find.text(expected), findsOneWidget);
      expect((await tester.runAsync(db.getCategories))!.first.name, save ? expected : 'Music');
      expect(Focus.of(tester.element(find.byIcon(Icons.edit_outlined))).hasFocus, isTrue);
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text(l.categoryVisible))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.byIcon(Icons.edit_outlined))).hasFocus, isTrue);
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
    testWidgets(
      'repeated sorts return to initial $initial and persist every mode',
      (tester) async {
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
        for (final next in CategorySort.values.where(
          (sort) => sort != initial,
        )) {
          for (final sort in [next, initial]) {
            await tester.tap(find.text('Sort'));
            await tester.pumpAndSettle();
            await tester.runAsync(() async {
              await tester.tap(find.text(labels[sort]!));
              await Future<void>.delayed(const Duration(milliseconds: 30));
            });
            await tester.pumpAndSettle();
            expect((await tester.runAsync(db.getCategories))!.first.sort, sort);
            expect(
              apps.categories.first.applications
                  .map((app) => app.packageName)
                  .toList(),
              orders[sort],
            );
          }
        }
        await tester.runAsync(apps.refreshState);
        expect(apps.categories.first.sort, initial);
        expect(
          apps.categories.first.applications
              .map((app) => app.packageName)
              .toList(),
          orders[initial],
        );
        await finish(tester);
      },
    );
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
