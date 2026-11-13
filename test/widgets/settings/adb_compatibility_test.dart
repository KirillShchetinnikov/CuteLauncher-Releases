import 'dart:convert';

import 'adb_test_compatibility.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/adb_permission_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const autoLaunch = MethodChannel('cutelauncher/auto_launch');
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(autoLaunch, (_) async => {'mode': 'off'});
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(autoLaunch, null);
  });
  const adb = MethodChannel('cutelauncher/adb');
  const platform = MethodChannel('me.efesser.flauncher/method');
  for (final status in ['operation_failed', 'unavailable']) {
    testWidgets('connection check reports $status accurately', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platform,
        (_) async => false,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') {
          return {'port': 5555, 'compatibility': supportedAdbCompatibility};
        }
        return {'status': status};
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
          home: const Scaffold(body: AdbPage(section: 'connection')),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(AdbPage)))!;
      await tester.ensureVisible(find.text(l.adbCheck));
      await tester.tap(find.text(l.adbCheck));
      await tester.pumpAndSettle();
      final message = status == 'operation_failed'
          ? l.appError
          : l.adbUnavailable;
      expect(find.text('${l.adbCheck}: $message'), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      if (status == 'operation_failed') {
        expect(find.text(l.adbUnavailable), findsNothing);
      }
    });
  }
  for (final system in ['Android TV', 'Google TV']) {
    testWidgets(
      '$system has two controls and the ADB button changes to restore',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pkg = system == 'Google TV'
            ? 'com.google.android.apps.tv.launcherx'
            : 'com.google.android.tvlauncher';
        final compatibility = {
          ...supportedAdbCompatibility,
          'system': system,
        };
        final actions = <String>[];
        final commands = [
          "pm disable-user --user 0 '$pkg'",
          "cmd package set-home-activity 'own/MainActivity'",
        ];
        final restoreCommands = ["pm default-state --user 0 '$pkg'"];
        var isHome = false;
        final systemCalls = <String>[];
        Map<String, dynamic> snapshot = {};
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          platform,
          (call) async {
            systemCalls.add(call.method);
            return false;
          },
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
          call,
        ) async {
          if (call.method == 'info') {
            return {
              'port': 5555,
              'compatibility': compatibility,
              'connectionSnapshot': jsonEncode(snapshot),
            };
          }
          final action = call.arguments['action'] as String;
          actions.add(action);
          if (action == 'preview') {
            expect(call.arguments['operation'], isHome ? 'restore' : 'home');
            return {
              'status': 'ready',
              'commands': isHome ? restoreCommands : commands,
              'target': isHome ? '$pkg/Home' : pkg,
              'targetName': system,
            };
          }
          if (action == 'home') {
            expect(call.arguments['commands'], commands);
            isHome = true;
            return {'status': 'success'};
          }
          if (action == 'restore') {
            expect(call.arguments['commands'], restoreCommands);
            isHome = false;
            return {'status': 'success'};
          }
          expect(action, 'check');
          snapshot = {
            'status': 'ready',
            'compatibility': compatibility,
            'isHome': isHome,
            'homeRecoverySaved': isHome,
            'accessibility': false,
            'restoreTarget': '$pkg/Home',
            'launchers': [
              {
                'package': pkg,
                'name': system,
                'enabled': !isHome,
                'priority': 2,
                'builtin': true,
              },
            ],
          };
          return snapshot;
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
            home: const Scaffold(body: AdbPage()),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(AdbPage)))!;
        FocusableSettingsTile tile(String title) => tester.widget(
          find
              .ancestor(
                of: find.text(title),
                matching: find.byType(FocusableSettingsTile),
              )
              .first,
        );
        expect(actions, isEmpty); // Detection never probes ADB.
        await tester.tap(find.text(l.adbConnectionBlock));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(l.adbCheck));
        await tester.tap(find.text(l.adbCheck));
        await tester.pumpAndSettle();
        Navigator.of(tester.element(find.text(l.adbCheck))).pop();
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.adbDefaultBlock));
        await tester.pumpAndSettle();
        expect(actions, ['check']);
        expect(find.byType(FocusableSettingsTile), findsNWidgets(2));
        expect(tester.getTopLeft(find.text(l.adbAssignDefault)).dy,
            lessThan(tester.getTopLeft(find.text(l.adbSystemDefault)).dy));
        expect(tile(l.adbAssignDefault).onPressed, isNotNull);
        await tester.ensureVisible(find.text(l.adbAssignDefault));
        await tester.tap(find.text(l.adbAssignDefault));
        await tester.pumpAndSettle();
        expect(find.text(l.adbEffectHome), findsOneWidget);
        expect(find.text(l.adbEffectDisable), findsOneWidget);
        await tester.tap(find.text(l.dialogAssign));
        await tester.pumpAndSettle();
        expect(find.byType(FocusableSettingsTile), findsNWidgets(2));
        expect(find.text(l.adbAssignDefault), findsNothing);
        expect(
          Focus.of(tester.element(find.text(l.adbRestoreDefault))).hasFocus,
          isTrue,
        );
        await tester.tap(find.text(l.adbRestoreDefault));
        await tester.pumpAndSettle();
        expect(find.text(l.adbEffectRestore), findsOneWidget);
        await tester.tap(find.text(l.dialogApply));
        await tester.pumpAndSettle();
        expect(actions, ['check', 'preview', 'home', 'check', 'preview', 'restore', 'check']);
        expect(find.text(l.adbAssignDefault), findsOneWidget);
        expect(find.text(l.adbRestoreDefault), findsNothing);
        await tester.tap(find.text(l.adbSystemDefault));
        await tester.pumpAndSettle();
        expect(systemCalls, contains('openDefaultLauncherSettings'));
      },
    );
  }
  for (final metadata in [
    null,
    {
      'system': 'Android TV',
      'actions': {'watchNext': false},
    },
  ]) {
    testWidgets(
      'unsupported or missing metadata blocks permission execution: $metadata',
      (tester) async {
        final calls = <MethodCall>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          platform,
          (_) async => false,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
          call,
        ) async {
          calls.add(call);
          return {'port': 5555, 'compatibility': metadata};
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
            home: const Scaffold(
              body: AdbPermissionTile(
                title: 'Watch Next',
                action: 'watchNext',
                permissionMethod: 'checkWatchNextPermission',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(AdbPermissionTile)),
        )!;
        expect(find.text(l.adbUnsupported), findsOneWidget);
        expect(
          tester
              .widget<FocusableSettingsTile>(find.byType(FocusableSettingsTile))
              .onPressed,
          isNull,
        );
        await tester.tap(find.text('Watch Next'));
        await tester.pumpAndSettle();
        expect(calls.map((call) => call.method), ['info']);
      },
    );
  }
}
