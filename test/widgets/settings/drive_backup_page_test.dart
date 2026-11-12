import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/widgets/settings/drive_backup_page.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _Drive extends DriveBackupService {
  int disconnects = 0;
  final connections = <(String, String)>[];
  _Drive({super.yandex}) {
    configured = true;
    clientId = 'test-client';
    clientSecret = 'test-secret';
  }
  @override
  Future<void> connect(String id, String secret) async {
    connections.add((id, secret));
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
    'Yandex connection page uses Yandex labels and has no Google JSON import',
    (tester) async {
      final service = _Drive(yandex: true);
      addTearDown(service.dispose);
      await tester.pumpWidget(
        ChangeNotifierProvider<DriveBackupService>.value(
          value: service,
          child: const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: DriveBackupPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Яндекс Диск'), findsOneWidget);
      expect(find.text('Состояние подключения Яндекс Диска'), findsOneWidget);
      expect(
        find.text('Импортировать Client ID и Secret из JSON'),
        findsNothing,
      );
      await tester.scrollUntilVisible(
        find.text('Переподключить Яндекс Диск'),
        100,
      );
      await tester.tap(find.text('Переподключить Яндекс Диск'));
      await tester.pumpAndSettle();
      expect(service.connections, [('test-client', 'test-secret')]);
      expect(tester.takeException(), isNull);
    },
  );
  for (final configured in [false, true]) {
    for (final locale in ['ru', 'en', 'ar']) {
      testWidgets(
        'labelled Drive status and bottom help: $configured/$locale',
        (tester) async {
          final service = _Drive()..configured = configured;
          addTearDown(service.dispose);
          await tester.pumpWidget(
            ChangeNotifierProvider<DriveBackupService>.value(
              value: service,
              child: MaterialApp(
                locale: Locale(locale),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: MediaQuery(
                  data: const MediaQueryData(
                    textScaler: TextScaler.linear(1.5),
                  ),
                  child: const Scaffold(
                    body: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 360, child: DriveBackupPage()),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(DriveBackupPage)),
          )!;
          expect(
            find.descendant(
              of: find.byType(Card),
              matching: find.text(l.backupDriveConnectionStatus),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: find.byType(Card),
              matching: find.text(
                configured ? l.backupConfigured : l.backupNotConfigured,
              ),
            ),
            findsOneWidget,
          );
          await tester.scrollUntilVisible(
            find.text(
              configured ? l.backupDriveReconnect : l.backupDriveConnect,
            ),
            150,
          );
          expect(
            find.text(
              configured ? l.backupDriveConnect : l.backupDriveReconnect,
            ),
            findsNothing,
          );
          await tester.scrollUntilVisible(find.text(l.backupManagement), 150);
          await tester.pumpAndSettle();
          expect(
            tester.getTopLeft(find.text(l.backupManagement)).dy,
            greaterThan(tester.getTopLeft(find.text(l.cloudDisconnect)).dy),
          );
          expect(find.text(l.backupDriveHelp), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets(
    'client JSON fills masked draft; invalid input and cancellation preserve it',
    (tester) async {
      final service = _Drive();
      addTearDown(service.dispose);
      String? selected;
      await tester.pumpWidget(
        ChangeNotifierProvider<DriveBackupService>.value(
          value: service,
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DriveBackupPage(pickClient: (_) async => selected),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(DriveBackupPage)),
      )!;
      Future<void> import(String? content) async {
        selected = content;
        await tester.ensureVisible(find.text(l.backupDriveClientImport));
        await tester.tap(find.text(l.backupDriveClientImport));
        await tester.pumpAndSettle();
      }

      await import(
        '{"installed":{"client_id":"imported-id","client_secret":"imported-secret"}}',
      );
      expect(find.text('imported-id'), findsOneWidget);
      final clientLabel = tester.widget<Text>(find.text('imported-id'));
      expect(clientLabel.maxLines, 1);
      expect(clientLabel.overflow, TextOverflow.ellipsis);
      expect(clientLabel.textDirection, TextDirection.ltr);
      expect(find.text('imported-secret'), findsNothing);
      expect(service.connections, isEmpty);
      expect(service.clientId, 'test-client');
      await import('{"installed":{"client_id":"replacement"}}');
      expect(find.text(l.backupDriveClientImportFailed), findsOneWidget);
      expect(find.text('imported-id'), findsOneWidget);
      await import(null);
      expect(find.text('imported-id'), findsOneWidget);
      await tester.ensureVisible(find.text(l.backupDriveReconnect));
      await tester.tap(find.text(l.backupDriveReconnect));
      await tester.pumpAndSettle();
      expect(service.connections, [('imported-id', 'imported-secret')]);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

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
      expect(find.text(l.backupDriveReconnect), findsOneWidget);
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
      expect(find.text(l.backupDriveReconnect), findsNothing);
      await tester.ensureVisible(find.text(l.backupDriveConnect));
      expect(find.text(l.backupDriveConnect), findsOneWidget);
      expect(find.text(l.backupNotConfigured), findsOneWidget);
    },
  );
}
