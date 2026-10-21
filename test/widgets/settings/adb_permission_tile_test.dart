import 'adb_test_compatibility.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/adb_permission_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final connection in ['ready', 'authorization', 'unavailable']) {
    testWidgets('permission grant handles $connection and verifies access', (
      tester,
    ) async {
      const adb = MethodChannel('cutelauncher/adb');
      const platform = MethodChannel('me.efesser.flauncher/method');
      final actions = <MethodCall>[];
      var granted = false;
      var refreshes = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platform,
        (_) async => granted,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') return {'compatibility': supportedAdbCompatibility, 'port': 37001, 'tls': true};
        actions.add(call);
        if (call.arguments['action'] == 'check') return {'status': connection};
        if (call.arguments['action'] == 'preview') return {'status': 'ready', 'commands': ['grant overlay']};
        granted = true;
        return {'status': 'success'};
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          adb,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          platform,
          null,
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AdbPage.routeName: (_) => const Scaffold(body: Text('ADB setup')),
          },
          home: Scaffold(
            body: AdbPermissionTile(
              title: 'Grant',
              action: 'overlay',
              permissionMethod: 'checkOverlayPermission',
              onRefresh: () async {
                refreshes++;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          connection == 'ready'
              ? 'АДБ подключён · выдать разрешение'
              : connection == 'authorization'
              ? AppLocalizations.of(tester.element(find.text('Grant')))!
                    .adbAuthorization
              : 'АДБ не подключён · настроить подключение',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Grant'));
      await tester.pumpAndSettle();
      final grants = actions.where(
        (call) => call.arguments['action'] == 'overlay',
      );
      if (connection == 'ready') {
        await tester.tap(find.text('Применить')); await tester.pumpAndSettle();
        expect(grants.single.arguments, {
          'port': 37001,
          'tls': false,
          'action': 'overlay',
          'commands': ['grant overlay'],
        });
        expect(find.text('Предоставлено'), findsOneWidget);
        expect(refreshes, 1);
      } else {
        expect(grants, isEmpty);
        expect(find.text('ADB setup'), findsOneWidget);
        granted = true;
        tester.state<NavigatorState>(find.byType(Navigator)).pop();
        await tester.pumpAndSettle();
        expect(find.text('Предоставлено'), findsOneWidget);
        expect(refreshes, 1);
      }
    });
  }
  testWidgets(
    'successful shell reply without permission is denied and retry checks revoked ADB',
    (tester) async {
      const adb = MethodChannel('cutelauncher/adb');
      const platform = MethodChannel('me.efesser.flauncher/method');
      var connection = 'ready';
      var grants = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platform,
        (_) async => false,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') return {'compatibility': supportedAdbCompatibility, 'port': 5556, 'tls': false};
        if (call.arguments['action'] == 'check') return {'status': connection};
        if (call.arguments['action'] == 'preview') return {'status': 'ready', 'commands': ['grant usage']};
      grants++;
        return {'status': 'success'};
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          adb,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          platform,
          null,
        );
      });
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {
            AdbPage.routeName: (_) => const Scaffold(body: Text('ADB setup')),
          },
          home: const Scaffold(
            body: AdbPermissionTile(
              title: 'Grant',
              action: 'usage',
              permissionMethod: 'checkUsageStatsPermission',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Grant'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Применить')); await tester.pumpAndSettle();
      expect(grants, 1);
      expect(find.text('Предоставлено'), findsNothing);
      connection = 'authorization';
      await tester.tap(find.text('Grant'));
      await tester.pumpAndSettle();
      expect(grants, 1);
      expect(find.text('ADB setup'), findsOneWidget);
    },
  );
}
