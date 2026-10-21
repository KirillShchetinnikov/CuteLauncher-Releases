import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/cloud_backup_page.dart';
import 'package:flauncher/widgets/settings/drive_backup_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Drive extends ChangeNotifier implements DriveBackupService {
  @override
  String clientId = '', clientSecret = '', code = '', verificationUrl = '';
  @override
  bool configured = false, busy = false, failed = false;
  @override
  void cancel() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Cloud extends ChangeNotifier implements CloudBackupService {
  @override
  bool busy = false;
  @override
  CloudAccountInfo account = const CloudAccountInfo();
  @override
  Future<void> refreshAccount() async {}
  @override
  void cancel() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final google in [true, false]) {
    testWidgets(
      'provider buttons require credentials and saved account: google=$google',
      (tester) async {
        final drive = _Drive(), cloud = _Cloud();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<DriveBackupService>.value(value: drive),
              ChangeNotifierProvider<CloudBackupService>.value(value: cloud),
            ],
            child: MaterialApp(
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: google
                    ? const DriveBackupPage()
                    : const CloudBackupPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        FocusableSettingsTile button(String label) =>
            tester.widget<FocusableSettingsTile>(
              find.widgetWithText(FocusableSettingsTile, label),
            );
        void expectEnabled(String label, bool enabled) {
          expect(button(label).enabled, enabled);
          expect(button(label).onPressed, enabled ? isNotNull : isNull);
        }

        Future<void> edit(String label, String value) async {
          button(label).onPressed!();
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), value);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          await tester.tap(find.widgetWithText(TextButton, l.ok));
          await tester.pumpAndSettle();
        }

        expectEnabled(l.cloudConnect, false);
        expectEnabled(l.cloudDisconnect, false);
        await edit(
          google ? l.backupClientId : l.cloudUrl,
          google ? 'test-client' : 'https://example.test/backup',
        );
        expectEnabled(l.cloudConnect, false);
        if (!google) {
          await edit(l.cloudUser, 'test-user');
          expectEnabled(l.cloudConnect, false);
        }
        final secret = google ? l.backupClientSecret : l.cloudPassword;
        await edit(secret, '   ');
        expectEnabled(l.cloudConnect, false);
        await edit(secret, 'test-secret');
        expectEnabled(l.cloudConnect, true);
        expectEnabled(l.cloudDisconnect, false);
        if (google) {
          drive.configured = true;
          drive.notifyListeners();
        } else {
          cloud.account = const CloudAccountInfo(
            configured: true,
            url: 'https://example.test/backup',
            user: 'test-user',
          );
          cloud.notifyListeners();
        }
        await tester.pumpAndSettle();
        expectEnabled(l.cloudDisconnect, true);
        if (google) {
          drive.busy = true;
          drive.notifyListeners();
        } else {
          cloud.busy = true;
          cloud.notifyListeners();
        }
        await tester.pump();
        expectEnabled(l.cloudConnect, false);
        expectEnabled(l.cloudDisconnect, false);
        await tester.pumpWidget(const SizedBox());
        drive.dispose();
        cloud.dispose();
      },
    );
  }
}
