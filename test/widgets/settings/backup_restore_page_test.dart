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
  for (final scenario in [
    'save',
    'cancel',
    'failure',
    'picker cancel',
    'write error',
  ]) {
    testWidgets('backup export fallback: $scenario', (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('backup-page-test-'),
      ))!;
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      const native = MethodChannel('me.efesser.flauncher/method');
      const paths = MethodChannel('plugins.flutter.io/path_provider');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(paths, (_) async => directory.path);
      int downloads = 0;
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method == 'saveBackupDocument') {
          if (scenario == 'picker cancel') return null;
          throw PlatformException(
            code: scenario == 'write error'
                ? 'document_failed'
                : 'document_unavailable',
          );
        }
        if (call.method == 'saveBackupDownloads') {
          downloads++;
          expect(
            await File((call.arguments as Map)['path'] as String)
                .readAsString(),
            '{}',
          );
          if (scenario == 'failure') {
            throw PlatformException(code: 'document_failed');
          }
          return 'Download/backup.json';
        }
        return null;
      });
      addTearDown(() async {
        messenger.setMockMethodCallHandler(native, null);
        messenger.setMockMethodCallHandler(paths, null);
        settings.dispose();
        await directory.delete(recursive: true);
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
        tester
            .widget<FocusableSettingsTile>(
              find.widgetWithText(FocusableSettingsTile, l.exportBackup),
            )
            .onPressed!();
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      if (scenario == 'picker cancel' || scenario == 'write error') {
        expect(find.byType(AlertDialog), findsNothing);
        expect(downloads, 0);
      } else {
        expect(
          Focus.of(
            tester.element(find.text(l.backupSaveDownloads).last),
          ).hasFocus,
          isTrue,
        );
        await tester.runAsync(() async {
          await tester.tap(
            find.widgetWithText(
              TextButton,
              scenario == 'cancel' ? l.cancel : l.backupSaveDownloads,
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
        await tester.runAsync(
          () async => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pumpAndSettle();
        expect(downloads, scenario == 'cancel' ? 0 : 1);
        if (scenario == 'save') {
          expect(find.textContaining('Download/backup.json'), findsOneWidget);
        }
        if (scenario == 'failure') {
          expect(find.text(l.backupDownloadsFailed), findsOneWidget);
        }
      }
      await tester.runAsync(
        () async => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      expect(directory.listSync(), isEmpty);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
