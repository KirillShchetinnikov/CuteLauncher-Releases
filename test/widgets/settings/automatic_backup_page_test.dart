import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/widgets/settings/local_backup_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Local extends ChangeNotifier implements BackupAutomationService {
  @override
  bool busy = false;
  @override
  String? localFolder;
  @override
  Future<void> setLocalFolder(String? value) async {
    localFolder = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'local settings contain only folder; selection and cancellation $language',
      (tester) async {
        final service = _Local();
        const channel = MethodChannel('me.efesser.flauncher/method');
        String? reply = 'content://provider/tree/primary%3ABackups';
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async => reply);
        addTearDown(() {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, null);
          service.dispose();
        });
        await tester.pumpWidget(
          ChangeNotifierProvider<BackupAutomationService>.value(
            value: service,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SizedBox(width: 340, child: LocalBackupPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = await AppLocalizations.delegate.load(Locale(language));
        expect(find.byType(FocusableSettingsTile), findsOneWidget);
        expect(find.text(l.backupPrivateFolder), findsOneWidget);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupFolderPath),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupChooseFolder),
        );
        await tester.pumpAndSettle();
        expect(service.localFolder, reply);
        final previous = service.localFolder;
        reply = null;
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupFolderPath),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupChooseFolder),
        );
        await tester.pumpAndSettle();
        expect(service.localFolder, previous);
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupFolderPath),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.widgetWithText(FocusableSettingsTile, l.backupPrivateFolder),
        );
        await tester.pumpAndSettle();
        expect(service.localFolder, isNull);
        expect(find.text(l.automaticBackupCreateNow), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
