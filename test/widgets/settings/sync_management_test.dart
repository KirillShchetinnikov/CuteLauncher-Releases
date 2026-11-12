import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/backup_data_protection.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/widgets/settings/sync_files_page.dart';
import 'package:flauncher/widgets/settings/sync_protection_page.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Protection extends BackupDataProtection {
  _Protection() : super('synchronization');
  @override
  Future<bool> configured() async => true;
}

class _Service extends ChangeNotifier implements BackupAutomationService {
  @override
  bool busy = false, cleanupFailed = false;
  @override
  final protection = _Protection();
  @override
  String get device => 'a' * 32;
  int deletes = 0, excludes = 0;
  @override
  Future<List<RemoteBackupFile>> synchronizationFiles() async => [
    RemoteBackupFile(
      'cute-sync-shared-$device-100-${'c' * 16}-Own_TV.json',
      'own',
    ),
    RemoteBackupFile(
      'cute-sync-shared-${'b' * 32}-100-${'c' * 16}-Other_TV.json',
      'other',
    ),
  ];
  @override
  Future<void> deleteSynchronizationFile(RemoteBackupFile file) async {
    deletes++;
  }

  @override
  Future<bool> excludeSyncDevice(RemoteBackupFile file) async {
    excludes++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _app(_Service service, Widget page, String locale) =>
    ChangeNotifierProvider<BackupAutomationService>.value(
      value: service,
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(body: SizedBox(width: 400, child: page)),
        ),
      ),
    );

void main() {
  for (final locale in ['ru', 'ar']) {
    testWidgets('password editor is masked and cleared on background $locale', (
      tester,
    ) async {
      final service = _Service();
      await tester.pumpWidget(
        _app(service, const SyncProtectionPage(), locale),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SettingsTextTile).first);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isTrue,
      );
      await tester.enterText(find.byType(TextField), 'test-only password');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '',
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('test-only password'), findsNothing);
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'file deletion and device exclusion default to cancel $locale',
      (tester) async {
        final service = _Service();
        await tester.pumpWidget(_app(service, const SyncFilesPage(), locale));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Own TV'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(service.deletes, 0);
        await tester.tap(find.textContaining('Other TV'));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(service.excludes, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
