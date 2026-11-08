import 'package:flauncher/file_browser_options.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/local_file_browser.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final details in [false, true]) {
    testWidgets('mixed sorted rows keep folder actions and details=$details', (
      tester,
    ) async {
      const channel = MethodChannel('me.efesser.flauncher/method');
      final requests = <Map>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        final args = call.arguments as Map;
        requests.add(args);
        final path = args['path'] ?? '/storage';
        return {
          'path': path,
          'uri': 'file://$path',
          'parent': '',
          'folders': [
            {'name': 'Z folder', 'path': '$path/Z'},
          ],
          'files': [
            {
              'name': 'A.json',
              'path': '$path/A.json',
              'size': 1024,
              'modified': 1,
            },
            {
              'name': '.hidden.json',
              'path': '$path/.hidden.json',
              'size': 1,
              'modified': 1,
            },
          ],
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: LocalFileBrowser(
              kind: FileBrowserKind.document,
              options: FileBrowserOptions(
                foldersFirst: false,
                showDetails: details,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('A.json')).dy,
        lessThan(tester.getTopLeft(find.text('Z folder')).dy),
      );
      expect(find.text('.hidden.json'), findsNothing);
      expect(
        find.textContaining('1 KiB'),
        details ? findsOneWidget : findsNothing,
      );
      await tester.tap(find.text('Z folder'));
      await tester.pumpAndSettle();
      expect(requests.last['path'], '/storage/Z');
      expect(requests.last['showHidden'], isFalse);
      expect(requests.last['initial'], isFalse);
      expect(find.byType(LocalFileBrowser), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
