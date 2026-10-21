import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/widgets/settings/cloud_backup_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Cloud extends CloudBackupService {
  int saves = 0;
  bool reject = false;
  _Cloud() {
    account = const CloudAccountInfo(
      configured: true,
      url: 'https://example.test/backup/',
      user: 'test-user',
    );
  }
  @override
  Future<void> refreshAccount() async {}
  @override
  Future<void> signIn(String url, String user, String password) async {
    if (reject) throw const CloudBackupException('authorization');
    expect(password, 'test-password');
    saves++;
    account = CloudAccountInfo(configured: true, url: url, user: user);
    notifyListeners();
  }

  @override
  Future<void> checkAccount() async {}
  @override
  Future<void> disconnect() async {
    account = const CloudAccountInfo();
    notifyListeners();
  }
}

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets(
      'WebDAV fields open editors, hide passwords and preserve account after failure $language',
      (tester) async {
        final service = _Cloud();
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ChangeNotifierProvider<CloudBackupService>.value(
            value: service,
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SizedBox(width: 340, child: CloudBackupPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(CloudBackupPage)),
        )!;
        expect(find.byType(TextField), findsNothing);
        expect(find.text(l.cloudHelp), findsNothing);
        Future<void> editPassword() async {
          final button = find.byKey(const ValueKey('cloud-password-button'));
          await tester.ensureVisible(button);
          await tester.tap(button);
          await tester.pumpAndSettle();
          final field = find.byKey(const ValueKey('cloud-password'));
          expect(tester.widget<TextField>(field).obscureText, true);
          await tester.enterText(field, 'test-password');
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pump();
          await tester.tap(find.widgetWithText(TextButton, l.ok));
          await tester.pumpAndSettle();
          expect(find.byType(TextField), findsNothing);
          expect(find.text('test-password'), findsNothing);
        }

        await editPassword();
        service.reject = true;
        await tester.ensureVisible(find.text(l.cloudConnect));
        await tester.tap(find.text(l.cloudConnect));
        await tester.pumpAndSettle();
        expect(find.text(l.cloudAuthorizationError), findsOneWidget);
        expect(service.saves, 0);
        expect(service.account.user, 'test-user');
        service.reject = false;
        await editPassword();
        await tester.ensureVisible(find.text(l.cloudConnect));
        await tester.tap(find.text(l.cloudConnect));
        await tester.pumpAndSettle();
        expect(service.saves, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
      },
    );
  }
}
