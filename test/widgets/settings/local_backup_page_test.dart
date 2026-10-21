import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/providers/local_backup_storage.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/local_backup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Automation extends ChangeNotifier implements BackupAutomationService {
  @override
  bool busy = false;
  @override
  String? localFolder;
  final saved = <String?>[];
  @override
  Future<void> setLocalFolder(String? value) async {
    localFolder = value;
    saved.add(value);
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scenario in [
    'downloads',
    'failed',
    'unsupported',
    'cancel',
    'private',
  ]) {
    testWidgets('local folder selection: $scenario', (tester) async {
      final service = _Automation();
      if (scenario == 'private') {
        service.localFolder = LocalBackupStorage.downloadsFolder;
      }
      const channel = MethodChannel('me.efesser.flauncher/method');
      final calls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        if (scenario == 'failed') {
          throw PlatformException(code: 'document_failed');
        }
        if (scenario == 'unsupported') {
          throw PlatformException(code: 'document_unavailable');
        }
        return call.method == 'pickBackupFolder'
            ? null
            : LocalBackupStorage.downloadsFolder;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        service.dispose();
      });
      await tester.pumpWidget(
        ChangeNotifierProvider<BackupAutomationService>.value(
          value: service,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: LocalBackupPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(LocalBackupPage)),
      )!;
      await tester.tap(
        find.widgetWithText(FocusableSettingsTile, l.backupFolderPath),
      );
      await tester.pumpAndSettle();
      expect(find.byType(SimpleDialog), findsOneWidget);
      final choice = scenario == 'private'
          ? l.backupPrivateFolder
          : scenario == 'unsupported' || scenario == 'cancel'
          ? l.backupChooseFolder
          : l.backupDownloadsFolder;
      await tester.tap(
        find.descendant(
          of: find.byType(SimpleDialog),
          matching: find.widgetWithText(FocusableSettingsTile, choice),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario == 'downloads') {
        expect(calls.single.method, 'backupFolderOperation');
        expect(calls.single.arguments['operation'], 'verify');
        expect(service.saved, [LocalBackupStorage.downloadsFolder]);
      } else if (scenario == 'private') {
        expect(calls, isEmpty);
        expect(service.saved, [null]);
      } else {
        expect(service.saved, isEmpty);
        if (scenario == 'unsupported') {
          expect(find.text(l.backupFolderPickerUnavailable), findsOneWidget);
        }
        if (scenario == 'failed') {
          expect(find.text(l.backupFolderFailed), findsOneWidget);
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
