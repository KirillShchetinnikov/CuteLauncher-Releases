import 'dart:convert';

import 'adb_test_compatibility.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/adb_permission_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../support/settings_help.dart';

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
  for (final system in ['Android TV', 'Google TV']) {
    testWidgets(
      '$system blocks pinned HOME but offers safe built-in replacement',
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
          'actions': {
            ...supportedAdbCompatibility['actions'] as Map,
            'home': false,
          },
        };
        final actions = <String>[];
        Map<String, dynamic> snapshot = {};
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          platform,
          (_) async => false,
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
          actions.add(call.arguments['action']);
          snapshot = {
            'status': 'ready',
            'compatibility': compatibility,
            'isHome': false,
            'accessibility': false,
            'restoreTarget': '$pkg/Home',
            'launchers': [
              {
                'package': pkg,
                'name': system,
                'enabled': true,
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
        expect(find.text(l.adbHomeUnavailable), findsNothing);
        await toggleSettingsHelp(tester, l.adbHomeUnavailable);
        expect(find.text(l.adbHomeUnavailable), findsOneWidget);
        expect(tile(l.adbAssignDefault).onPressed, isNull);
        expect(tile('${l.adbDisableBuiltin}: $system').onPressed, isNotNull);
        expect(actions, ['check']);
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
