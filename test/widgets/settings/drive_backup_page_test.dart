import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/drive_backup_page.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Drive extends DriveBackupService {
  int disconnects = 0;
  _Drive() {
    configured = true;
    clientId = 'test-client';
    clientSecret = 'test-secret';
  }
  @override
  Future<void> disconnect() async {
    disconnects++;
    configured = false;
    notifyListeners();
  }
}

void main() {
  testWidgets(
    'Drive disconnect requires explicit confirmation and supports cancel',
    (tester) async {
      final service = _Drive();
      addTearDown(service.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<DriveBackupService>.value(
          value: service,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: DriveBackupPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(DriveBackupPage)),
      )!;
      expect(find.text(l.backupDriveConnect), findsOneWidget);
      await tester.ensureVisible(find.text(l.cloudDisconnect));
      await tester.tap(find.text(l.cloudDisconnect));
      await tester.pumpAndSettle();
      expect(service.disconnects, 0);
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(service.configured, true);
      await tester.tap(find.text(l.cloudDisconnect));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(LauncherDialogButton),
          matching: find.text(l.cloudDisconnect),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.disconnects, 1);
      expect(service.configured, false);
    },
  );
}
