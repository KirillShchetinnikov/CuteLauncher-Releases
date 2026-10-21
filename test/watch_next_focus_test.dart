import 'package:flauncher/custom_traversal_policy.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/category_focus.dart';
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
  for (final remember in [false, true]) {
    testWidgets('Watch Next restores visible card, remember=$remember', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setShowContinueWatching(true);
      await settings.setAppHighlightAnimationEnabled(false);
      final apps = MockAppsService(), watch = MockWatchNextService();
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
                      child: const ContinueWatchingRow(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
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
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      focus.dispose();
      anchor.dispose();
      settings.dispose();
    });
  }
}
