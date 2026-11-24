import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/category_focus.dart';
import 'package:flauncher/widgets/app_content_row.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/appearance_surface.dart';
import 'package:flauncher/widgets/continue_watching_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

import 'mocks.mocks.dart';

void main() {
  testWidgets('only the focused row preloads offscreen artwork within its selected window', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    await settings.setAppHighlightAnimationEnabled(false);
    final programs = List.generate(40, (i) => WatchNextProgram.fromMap({
      'id': i, 'title': 'Movie $i', 'posterArtUri': 'content://covers/$i',
    }));
    final focus = CategoryFocusController()..configure(programs.map((p) => p.id.toString()));
    final requested = <int>[];
    const style = TileAppearance();
    await tester.pumpWidget(ChangeNotifierProvider.value(value: settings, child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CategoryFocus(controller: focus, child: ContentPreviewRow(
        title: 'Feed', aspectRatio: 1.5, style: style, programs: programs,
        preload: (program, priority) async {
          expect(priority(), 0);
          requested.add(program.id);
          return null;
        },
        card: (p, size) => ContentPreviewCard(program: p, title: p.title, style: style,
            size: size, onOpen: (_) async {}),
      ))),
    )));
    await tester.pumpAndSettle();
    expect(requested, isEmpty);
    focus.nodeFor('0')!.requestFocus();
    await tester.pumpAndSettle();
    expect(requested, contains(31));
    expect(requested, isNot(contains(32)));
    expect(requested, isNot(contains(0)));
    requested.clear();
    await settings.setMemoryLimit(MemoryLimit.preload, 16);
    await tester.pumpAndSettle();
    expect(requested, contains(15));
    expect(requested.every((id) => id < 16), isTrue);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
    settings.dispose();
  });

  for (final remember in [false, true]) {
    testWidgets('Watch Next restores visible card, remember=$remember', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      addTearDown(appearance.dispose);
      await appearance.set('sectionTitleSize', 40);
      await settings.setShowContinueWatching(true);
      await settings.setAppHighlightAnimationEnabled(false);
      final apps = MockAppsService(), watch = MockWatchNextService();
      when(apps.getApp(any)).thenReturn(null);
      when(apps.imageRevisionFor(any)).thenReturn((0, 0));
      when(apps.applications).thenReturn([]);
      when(apps.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
      when(watch.hasPermission).thenReturn(true);
      when(watch.programs).thenReturn([
        for (var id = 0; id < 3; id++)
          WatchNextProgram.fromMap({
            'id': id,
            'title': 'Movie $id',
            'packageName': 'video',
          }),
      ]);
      final focus = CategoryFocusController()..rememberLast = remember;
      final anchor = FocusNode();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: appearance),
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider<WatchNextService>.value(value: watch),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: FocusTraversalGroup(
                policy: RowByRowTraversalPolicy(),
                child: Column(
                  children: [
                    Focus(
                      focusNode: anchor,
                      child: const SizedBox(width: 80, height: 80),
                    ),
                    CategoryFocus(
                      controller: focus,
                      child: Consumer<SettingsService>(
                        builder: (_, settings, _) => ContinueWatchingRow(
                          programs: ContinueWatchingRow.visiblePrograms(
                            settings, apps, watch,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Continue Watching')).style!.fontSize, 40);
      await appearance.setCategoryTile(ContinueWatchingSection.sectionId, 'size', 144);
      await appearance.setCategoryTile(ContinueWatchingSection.sectionId, 'sectionTitleSize', 32);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Continue Watching')).style!.fontSize, 32);
      expect(tester.widget<WatchNextCard>(find.byType(WatchNextCard).first).size.height, 144);
      expect(appearance.appearance.tileSize, 128);
      bool selected(int id) => tester
          .widget<InkWell>(
            find
                .descendant(
                  of: find.byWidgetPredicate(
                    (w) => w is WatchNextCard && w.program.id == id,
                  ),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .focusNode!
          .hasFocus;
      anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(selected(0), isTrue);
      for (var i = 0; i < 2; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(selected(2), isTrue);
      anchor.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(selected(remember ? 2 : 0), isTrue);
      anchor.requestFocus();
      await tester.pump();
      await settings.hideWatchNextProgram(2);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(selected(0), isTrue);
      await appearance.set('size', 96);
      await appearance.set('aspectRatio', 1);
      await appearance.set('labels', 'all');
      await appearance.set('labelPosition', 'inside');
      await appearance.setCategoryTile(ContinueWatchingSection.sectionId, 'contentAppTileStyle', true);
      await tester.pumpAndSettle();
      expect(selected(0), isTrue);
      final card = find.byType(WatchNextCard).first;
      expect(tester.widget<WatchNextCard>(card).size, const Size(96, 96));
      expect(find.descendant(
        of: find.descendant(of: card, matching: find.byType(AppearanceSurface)),
        matching: find.text('Movie 0'),
      ), findsOneWidget);
      await appearance.set('labels', 'selected');
      await tester.pumpAndSettle();
      expect(find.text('Movie 0'), findsOneWidget);
      expect(find.descendant(of: card, matching: find.text('Movie 0')), findsNothing);
      expect(selected(0), isTrue);
      await appearance.setCategoryTile(ContinueWatchingSection.sectionId, 'contentAppTileStyle', false);
      await tester.pumpAndSettle();
      expect(tester.widget<WatchNextCard>(card).size.height, 144);
      expect(selected(0), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      anchor.dispose();
      settings.dispose();
    });
  }
}
