import 'dart:async';
import 'dart:io';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/cloud_backup_page.dart';
import 'package:flauncher/widgets/settings/cloud_error_message.dart';
import 'package:flauncher/widgets/settings/drive_backup_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _EmptyWebdav extends CloudBackupService {
  @override
  Future<void> refreshAccount() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/drive_account'),
          (_) async => true,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/drive_account'),
          null,
        );
  });
  for (final fields in [('', ''), ('id', ''), ('', 'secret'), (' ', ' ')]) {
    test('Drive rejects missing fields $fields before networking', () async {
      var requests = 0;
      final service = DriveBackupService(
        clientFactory: () {
          requests++;
          throw StateError('Unexpected network request');
        },
      );
      addTearDown(service.dispose);
      await expectLater(
        service.connect(fields.$1, fields.$2),
        throwsA(
          isA<CloudBackupException>().having(
            (e) => e.code,
            'code',
            'configuration',
          ),
        ),
      );
      expect(requests, 0);
      expect(service.failureCode, 'configuration');
      expect(service.busy, false);
    });
  }
  for (final language in ['ru', 'en']) {
    test('Cloud errors preserve their cause $language', () async {
      final l = await AppLocalizations.delegate.load(Locale(language));
      expect(
        cloudErrorMessage(
          l,
          const CloudBackupException('configuration'),
          drive: true,
        ),
        l.driveConfigurationError,
      );
      expect(
        cloudErrorMessage(l, const CloudBackupException('configuration')),
        l.cloudConfigurationError,
      );
      expect(
        cloudErrorMessage(
          l,
          const CloudBackupException('authorization'),
          drive: true,
        ),
        l.cloudAuthorizationError,
      );
      expect(cloudErrorMessage(l, TimeoutException('')), l.cloudNetworkError);
      expect(
        cloudErrorMessage(l, const SocketException('')),
        l.cloudNetworkError,
      );
      expect(
        cloudErrorMessage(
          l,
          const CloudBackupException('storage'),
          drive: true,
        ),
        l.cloudStorageError,
      );
      expect(cloudErrorMessage(l, StateError('')), l.cloudFailed);
      expect(
        cloudErrorMessage(
          l,
          const CloudBackupException('expired'),
          drive: true,
        ),
        l.driveCodeExpired,
      );
      expect(
        cloudErrorMessage(
          l,
          const CloudBackupException('redirect'),
          drive: true,
        ),
        l.cloudFailed,
      );
    });
    for (final drive in [true, false]) {
      testWidgets(
        'Empty ${drive ? 'Drive' : 'WebDAV'} cannot report denied access $language',
        (tester) async {
          final driveService = DriveBackupService();
          final webdav = _EmptyWebdav();
          addTearDown(driveService.dispose);
          addTearDown(webdav.dispose);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: driveService),
                ChangeNotifierProvider<CloudBackupService>.value(value: webdav),
              ],
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: drive
                      ? const DriveBackupPage()
                      : const CloudBackupPage(),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(
              find.byType(drive ? DriveBackupPage : CloudBackupPage),
            ),
          )!;
          await tester.ensureVisible(find.text(l.cloudConnect));
          final button = tester.widget<FocusableSettingsTile>(
            find.widgetWithText(FocusableSettingsTile, l.cloudConnect),
          );
          expect(button.enabled, isFalse);
          await tester.pumpAndSettle();
          if (drive) {
            await expectLater(
              driveService.connect('', ''),
              throwsA(isA<CloudBackupException>()),
            );
            await tester.pumpAndSettle();
            await tester.ensureVisible(
              find.text(l.driveConfigurationError).first,
            );
            expect(find.text(l.driveConfigurationError), findsWidgets);
          }
          expect(find.text(l.cloudAuthorizationError), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }
}
