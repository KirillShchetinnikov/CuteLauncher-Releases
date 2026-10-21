import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/providers/settings_service.dart';

import '../../mocks.mocks.dart';

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
    'built-in launcher state, service grant and independent Home switch',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const adb = MethodChannel('cutelauncher/adb');
      const platform = MethodChannel('me.efesser.flauncher/method');
      var accessibility = false, override = true;
      var grants = 0;
      final operations = <String>[];
      Map<String, dynamic> snapshot = {};
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platform,
        (_) async => accessibility,
      );
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') {
          return {
            'compatibility': supportedAdbCompatibility,
            'port': 5555,
            'homeOverride': override,
            'connectionSnapshot': jsonEncode(snapshot),
          };
        }
        if (call.method == 'homeOverride') {
          override = call.arguments['enabled'];
          return true;
        }
        final action = call.arguments['action'];
        if (action == 'check') {
          snapshot = {
            'status': 'ready',
            'isHome': true,
            'accessibility': accessibility,
            'accessibilitySaved': accessibility,
            'restoreTarget': '',
            'launchers': [
              {
                'package': 'com.google.android.apps.tv.launcherx',
                'name': 'Google TV',
                'enabled': true,
                'builtin': true,
              },
              {
                'package': 'com.google.android.apps.tv.launcherx',
                'name': 'Google TV',
                'enabled': true,
                'builtin': true,
              },
              {
                'package': 'com.google.android.tvlauncher',
                'name': 'Android TV',
                'enabled': false,
                'builtin': true,
              },
            ],
          };
          return snapshot;
        }
        if (action == 'preview') {
          operations.add(call.arguments['operation']);
          return {
            'status': 'ready',
            'commands': ['settings grant service'],
          };
        }
        if (action == 'accessibility') {
          grants++;
          accessibility = true;
          return {'status': 'success'};
        }
        if (action == 'disableAccessibility') {
          accessibility = false;
          return {'status': 'success'};
        }
        return {'status': 'denied'};
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
      final settings = MockSettingsService();
      when(settings.startOnBoot).thenReturn(true);
      when(settings.appKeyClickEnabled).thenReturn(false);
      when(settings.accentColorHex).thenReturn('7C4DFF');
      await tester.pumpWidget(
        ChangeNotifierProvider<SettingsService>.value(
          value: settings,
          builder: (_, _) => const MaterialApp(
            locale: Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AdbPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Переопределять кнопку Home'), findsNothing);
      await tester.tap(find.text('Подключение АДБ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Проверить подключение'));
      await tester.tap(find.text('Проверить подключение'));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.text('Проверить подключение'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Лаунчер по умолчанию'));
      await tester.pumpAndSettle();
      expect(
        find.text('Отключить встроенный лаунчер через ADB: Google TV'),
        findsOneWidget,
      );
      expect(
        find.text('Включить встроенный лаунчер через ADB: Android TV'),
        findsOneWidget,
      );
      expect(find.text('Доступ к специальным возможностям'), findsNothing);
      expect(find.text('Ещё не применено'), findsNothing);
      final restore = find.text(
        'Восстановить предыдущий лаунчер по умолчанию по ADB',
      );
      final tile = tester.widget<FocusableSettingsTile>(
        find
            .ancestor(of: restore, matching: find.byType(FocusableSettingsTile))
            .first,
      );
      expect(tile.onPressed, isNull);
      Navigator.of(tester.element(restore)).pop();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Кнопка Home и запуск'));
      await tester.tap(find.text('Кнопка Home и запуск'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('CuteLauncher является лаунчером по умолчанию'),
        findsNothing,
      );
      final homeSwitch = find.text('Переопределять кнопку Home');
      expect(homeSwitch, findsOneWidget);
      FocusableSettingsTile switchTile() => tester.widget(
        find
            .ancestor(
              of: homeSwitch,
              matching: find.byType(FocusableSettingsTile),
            )
            .first,
      );
      expect(switchTile().enabled, isFalse);
      final boot = find.text('Запускать при включении ТВ');
      FocusableSettingsTile bootTile() => tester.widget(
        find
            .ancestor(of: boot, matching: find.byType(FocusableSettingsTile))
            .first,
      );
      expect(boot, findsOneWidget);
      expect(bootTile().enabled, isFalse);
      await tester.ensureVisible(boot);
      await tester.tap(boot);
      await tester.pumpAndSettle();
      verifyNever(settings.setStartOnBoot(any));
      final grant = find.text(
        'Включить службу специальных возможностей CuteLauncher через ADB',
      );
      await tester.ensureVisible(grant);
      await tester.tap(grant);
      await tester.pumpAndSettle();
      expect(find.text('Показать команды ADB'), findsOneWidget);
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(grants, 1);
      expect(operations, ['accessibility']);
      final toggle = find.text('Переопределять кнопку Home');
      await tester.ensureVisible(toggle);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(override, isFalse);
      expect(accessibility, isTrue);
      expect(switchTile().enabled, isTrue);
      expect(bootTile().enabled, isTrue);
      expect(find.text('Ещё не применено'), findsNothing);
      expect(grants, 1);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      final grantTile = tester.widget<FocusableSettingsTile>(
        find
            .ancestor(
              of: find.text(
                'Выключить службу специальных возможностей CuteLauncher через ADB',
              ),
              matching: find.byType(FocusableSettingsTile),
            )
            .first,
      );
      expect(grantTile.onPressed, isNotNull);
      final disable = find.text(
        'Выключить службу специальных возможностей CuteLauncher через ADB',
      );
      await tester.ensureVisible(disable);
      await tester.tap(disable);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Применить'));
      await tester.pumpAndSettle();
      expect(accessibility, isFalse);
      expect(homeSwitch, findsOneWidget);
      expect(switchTile().enabled, isFalse);
      expect(bootTile().enabled, isFalse);
      expect(settings.startOnBoot, isTrue);
      expect(operations, ['accessibility', 'disableAccessibility']);
      expect(
        find.text(
          'Включить службу специальных возможностей CuteLauncher через ADB',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
