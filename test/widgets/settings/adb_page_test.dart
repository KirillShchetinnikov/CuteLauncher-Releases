import 'dart:convert';

import 'adb_test_compatibility.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

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
    'ADB gate, commands, cancellation focus, state refresh and port reset',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const adb = MethodChannel('cutelauncher/adb');
      final calls = <MethodCall>[];
      var home = false;
      Map<String, dynamic> snapshot = {};
      const command = "cmd package set-home-activity 'own/MainActivity'";
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        calls.add(call);
        if (call.method == 'info') {
          return {
            'compatibility': supportedAdbCompatibility,
            'port': 5556,
            'homeOverride': true,
            'connectionSnapshot': jsonEncode(snapshot),
          };
        }
        if (call.method == 'port') {
          snapshot = {};
          return true;
        }
        final action = call.arguments['action'];
        if (action == 'check') {
          snapshot = {
            'status': 'ready',
            'isHome': home,
            'accessibility': false,
            'accessibilitySaved': false,
            'launchers': [],
            'restoreTarget': 'other/MainActivity',
          };
          return snapshot;
        }
        if (action == 'preview') {
          return {
            'status': 'ready',
            'commands': [command],
            'target': '',
          };
        }
        if (action == 'home') {
          home = true;
          return {'status': 'success'};
        }
        return {'status': 'unavailable'};
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
      expect(find.byType(TextField), findsNothing);
      expect(
        Focus.of(tester.element(find.text('Автозапуск').last)).hasFocus,
        isTrue,
      );
      FocusableSettingsTile tile(Finder text) => tester.widget(
        find
            .ancestor(of: text, matching: find.byType(FocusableSettingsTile))
            .first,
      );
      expect(calls.map((c) => c.method), ['info']);
      await tester.tap(find.text('Подключение АДБ'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Проверить подключение'));
      await tester.tap(find.text('Проверить подключение'));
      await tester.pumpAndSettle();
      expect(find.text('Доступ ADB подтверждён.'), findsOneWidget);
      Navigator.of(tester.element(find.text('Проверить подключение'))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Лаунчер по умолчанию'));
      await tester.pumpAndSettle();
      final assign = find.text(
        'Назначить CuteLauncher лаунчером по умолчанию по ADB',
      );
      expect(tile(assign).onPressed, isNotNull);
      await tester.ensureVisible(assign);
      await tester.tap(assign);
      await tester.pumpAndSettle();
      expect(find.text('Показать команды ADB'), findsOneWidget);
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<TextButton>()
            ?.autofocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(
        calls.where(
          (c) => c.arguments is Map && c.arguments['action'] == 'home',
        ),
        isEmpty,
      );
      await tester.tap(assign);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Назначить'));
      await tester.pumpAndSettle();
      final execution = calls.singleWhere(
        (c) => c.arguments is Map && c.arguments['action'] == 'home',
      );
      expect(execution.arguments, {
        'action': 'home',
        'port': 5556,
        'tls': false,
        'commands': [command],
      });
      expect(
        find.text('Восстановить предыдущий лаунчер по умолчанию по ADB'),
        findsOneWidget,
      );
      Navigator.of(
        tester.element(
          find.text('Восстановить предыдущий лаунчер по умолчанию по ADB'),
        ),
      ).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Подключение АДБ'));
      await tester.pumpAndSettle();
      final port = find.text('Порт ADB по TCP');
      await tester.ensureVisible(port);
      await tester.tap(port);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1');
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), '5557');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      final focusedButton = FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<TextButton>();
      expect((focusedButton?.child as Text?)?.data, 'ОК');
      await tester.tap(find.text('ОК'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('5557'), findsOneWidget);
      Navigator.of(tester.element(port)).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Лаунчер по умолчанию'));
      await tester.pumpAndSettle();
      expect(
        tile(find.text('Назначить CuteLauncher лаунчером по умолчанию по ADB'))
            .onPressed,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
