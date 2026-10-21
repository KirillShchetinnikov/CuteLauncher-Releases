import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/watch_next_info_panel.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../mocks.mocks.dart';

void main() {
  for (final deleted in [false, true]) {
    testWidgets('only hides card after confirmed deletion ($deleted)', (tester) async {
      final settings = MockSettingsService();
      when(settings.settingsMenuOnRight).thenReturn(false);
      final apps = MockAppsService();
      final watchNext = MockWatchNextService();
      final program = WatchNextProgram.fromMap({'id': 7, 'title': 'Movie'});
      when(apps.applications).thenReturn([]);
      when(watchNext.deleteProgram(program)).thenAnswer((_) async => deleted);
      await tester.pumpWidget(ChangeNotifierProvider<SettingsService>.value(
        value: settings,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Builder(builder: (context) => TextButton(
            onPressed: () => showDialog(context: context, builder: (_) => WatchNextInfoPanel(
              program: program, watchNextService: watchNext, appsService: apps,
            )),
            child: const Text('Open panel'),
          ))),
        ),
      ));
      await tester.tap(find.text('Open panel'));
      await tester.pumpAndSettle();
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await tester.tap(find.text('Remove from Continue Watching'));
      await tester.pumpAndSettle();
      if (deleted) {
        verify(settings.hideWatchNextProgram(7)).called(1);
        expect(find.byType(WatchNextInfoPanel), findsNothing);
      } else {
        verifyNever(settings.hideWatchNextProgram(any));
        expect(find.byType(WatchNextInfoPanel), findsOneWidget);
        expect(find.text('Could not remove the item from Continue Watching. Try again.'), findsOneWidget);
      }
    });
  }
}
