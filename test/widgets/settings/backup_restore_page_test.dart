import 'dart:io';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/backup_restore_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Backup implements BackupService {
  @override
  Future<void> writeBackupTo(
    File file, {
    SettingsService? settingsService,
    bool validateStructure = false,
  }) => file.writeAsString('{}').then((_) {});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scenario in ['save', 'cancel', 'write error', 'system cancel']) {
    testWidgets('backup export through common picker: $scenario', (
      tester,
    ) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('backup-picker-test-'),
      ))!;
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      const native = MethodChannel('me.efesser.flauncher/method');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (_) async => directory.path);
      final calls = <String>[];
      String? source;
      messenger.setMockMethodCallHandler(native, (call) async {
        calls.add(call.method);
        if (call.method == 'filePickerAvailable') {
          return scenario == 'system cancel';
        }
        if (call.method == 'requestFileStorage') return true;
        if (call.method == 'browseLocalFiles') {
          return {
            'path': '/storage/main',
            'uri': 'file:///storage/main',
            'parent': '',
            'folders': [],
            'files': [],
          };
        }
        if (call.method == 'localDocumentOperation') {
          source = (call.arguments as Map)['source'] as String;
          expect(File(source!).readAsStringSync(), '{}');
          if (scenario == 'write error') {
            throw PlatformException(code: 'document_failed');
          }
          return true;
        }
        return null;
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(paths, null);
        settings.dispose();
        await tester.runAsync(() => directory.delete(recursive: true));
      });
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<BackupService>.value(value: _Backup()),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: BackupRestorePage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(BackupRestorePage)),
      )!;
      await tester.runAsync(() async {
        final export = tester
            .widget<FocusableSettingsTile>(
              find.widgetWithText(FocusableSettingsTile, l.exportBackup),
            )
            .onPressed!;
        export();
        export(); // A stale callback/rapid OK must not open a second picker.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      if (scenario == 'system cancel') {
        await tester.tap(find.text(l.filePickerSystem));
      } else if (scenario == 'cancel') {
        await tester.tap(find.byTooltip(l.close));
      } else {
        await tester.tap(find.widgetWithText(FocusableSettingsTile, l.save));
      }
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
      expect(calls, isNot(contains('saveBackupDownloads')));
      expect(
        calls.where((method) => method == 'filePickerAvailable').length,
        1,
      );
      expect(
        find.text(l.backupSavedToSelectedLocation),
        scenario == 'save' ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(l.exportFailed),
        scenario == 'write error' ? findsOneWidget : findsNothing,
      );
      if (source != null) {
        expect(
          await tester.runAsync(() => File(source!).parent.exists()),
          isFalse,
        );
      }
      expect(directory.listSync(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
