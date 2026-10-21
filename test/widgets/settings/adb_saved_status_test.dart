import 'dart:convert';

import 'adb_test_compatibility.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
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
  testWidgets(
    'saved connection enables actions; revoked access disables them on reentry',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const adb = MethodChannel('cutelauncher/adb');
      final actions = <String>[];
      var snapshot = <String, dynamic>{
        'status': 'ready',
        'isHome': false,
        'accessibility': false,
        'launchers': [],
        'restoreTarget': '',
      };
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') {
          return {
            'port': 5555,
            'compatibility': supportedAdbCompatibility,
            'launcherStatus': {'name': 'Google TV', 'isHome': false},
            'connectionSnapshot': jsonEncode(snapshot),
          };
        }
        actions.add(call.arguments['action']);
        snapshot = {'status': 'authorization'};
        return snapshot;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          adb,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AdbPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Google TV'), findsNothing);
      expect(actions, isEmpty);
      Future<void> open() async {
        await tester.ensureVisible(find.text('Лаунчер по умолчанию'));
        await tester.tap(find.text('Лаунчер по умолчанию'));
        await tester.pumpAndSettle();
      }

      final assign = find.text(
        'Назначить CuteLauncher лаунчером по умолчанию по ADB',
      );
      FocusableSettingsTile tile() => tester.widget(
        find
            .ancestor(of: assign, matching: find.byType(FocusableSettingsTile))
            .first,
      );
      await open();
      expect(find.textContaining('\nGoogle TV'), findsOneWidget);
      expect(tile().onPressed, isNotNull);
      await tester.ensureVisible(assign);
      await tester.tap(assign);
      await tester.pumpAndSettle();
      expect(actions, ['preview']);
      expect(tile().onPressed, isNull);
      expect(
        find.text('Подтвердите доступ ADB на ТВ и повторите запрос.'),
        findsOneWidget,
      );
      Navigator.of(tester.element(assign)).pop();
      await tester.pumpAndSettle();
      await open();
      expect(tile().onPressed, isNull);
      expect(actions, ['preview']);
      expect(tester.takeException(), isNull);
    },
  );
}
