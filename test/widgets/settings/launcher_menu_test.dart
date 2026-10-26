import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/auto_launch_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/remote_buttons_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/settings_help.dart';

void main() {
  const adb = MethodChannel('cutelauncher/adb');
  const autoLaunch = MethodChannel('cutelauncher/auto_launch');
  const platform = MethodChannel('me.efesser.flauncher/method');
  late Map<String, dynamic> info, config;
  late bool? accessibility;
  late List<MethodCall> adbCalls;

  setUp(() {
    info = {
      'homeOverride': true,
      'launcherStatus': {'isHome': true},
    };
    config = {
      'mode': 'app',
      'app': 'org.example.player',
      'boot': true,
      'wake': false,
    };
    accessibility = true;
    adbCalls = [];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(adb, (call) async {
      adbCalls.add(call);
      return info;
    });
    messenger.setMockMethodCallHandler(autoLaunch, (_) async => config);
    messenger.setMockMethodCallHandler(platform, (_) async => accessibility);
  });

  tearDown(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [adb, autoLaunch, platform]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  IconData? status(WidgetTester tester, String title) {
    final icons = find.descendant(
      of: find.ancestor(
        of: find.text(title),
        matching: find.byType(FocusableSettingsTile),
      ),
      matching: find.byWidgetPredicate(
        (widget) => widget is Icon && widget.semanticLabel != null,
      ),
    );
    return icons.evaluate().isEmpty ? null : tester.widget<Icon>(icons).icon;
  }

  Future<void> pumpMenu(WidgetTester tester, {bool large = false}) async {
    tester.view.physicalSize = const Size(440, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(large ? 1.4 : 1)),
          child: child!,
        ),
        routes: {
          for (final route in [
            AutoLaunchPage.routeName,
            RemoteButtonsPage.routeName,
          ])
            route: (context) => Scaffold(
              body: TextButton(
                onPressed: () {
                  config = {'mode': 'off'};
                  accessibility = false;
                  Navigator.pop(context);
                },
                child: const Text('Вернуться'),
              ),
            ),
        },
        home: const Scaffold(body: AdbPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'seven destinations including TV power and cleaner keep D-pad focus',
    (tester) async {
      info['connectionSnapshot'] = jsonEncode({
        'status': 'ready',
        'launchers': [],
      });
      await pumpMenu(tester, large: true);
      expect(find.byType(FocusableSettingsTile), findsNWidgets(7));
      expect(find.text('Менеджер очистки ТВ'), findsOneWidget);
      expect(find.text('Проверить подключение'), findsNothing);
      expect(find.textContaining('Включите отладку'), findsNothing);
      expect(find.text('Автозапуск'), findsOneWidget);
      expect(status(tester, 'Автозапуск'), isNull);
      expect(status(tester, 'Подключение АДБ'), Icons.check_circle_outline);
      expect(
        status(tester, 'Лаунчер по умолчанию'),
        Icons.check_circle_outline,
      );
      expect(
        status(tester, 'Кнопка Home и запуск'),
        Icons.check_circle_outline,
      );
      expect(
        status(tester, 'Ремаппер кнопок пульта'),
        Icons.check_circle_outline,
      );
      expect(
        Focus.of(tester.element(find.text('Автозапуск'))).hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text('Управление питанием'))).hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text('Подключение АДБ'))).hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Проверить подключение'), findsOneWidget);
      expect(find.textContaining('Включите отладку'), findsNothing);
      await toggleSettingsHelp(tester, 'Включите отладку');
      expect(find.textContaining('Включите отладку'), findsOneWidget);
      Navigator.of(tester.element(find.text('Проверить подключение'))).pop();
      await tester.pumpAndSettle();
      expect(
        Focus.of(tester.element(find.text('Подключение АДБ'))).hasFocus,
        isTrue,
      );
      expect(adbCalls.every((call) => call.method == 'info'), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'unknown states stay unknown until loaded; disabled prerequisites show crosses',
    (tester) async {
      info = {};
      accessibility = null;
      await pumpMenu(tester);
      for (final title in [
        'Подключение АДБ',
        'Лаунчер по умолчанию',
        'Кнопка Home и запуск',
        'Ремаппер кнопок пульта',
      ]) {
        expect(status(tester, title), Icons.help_outline);
      }
      expect(status(tester, 'Автозапуск'), isNull);
      expect(tester.takeException(), isNull);
    },
  );

  for (final title in ['Автозапуск', 'Ремаппер кнопок пульта']) {
    testWidgets(
      'return from $title refreshes states without toggling on entry',
      (tester) async {
        await pumpMenu(tester);
        if (title == 'Ремаппер кнопок пульта') {
          for (var step = 0; step < 5; step++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
          }
        }
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(config['mode'], 'app');
        expect(accessibility, isTrue);
        await tester.tap(find.text('Вернуться'));
        await tester.pumpAndSettle();
        expect(status(tester, 'Автозапуск'), isNull);
        expect(status(tester, 'Кнопка Home и запуск'), Icons.cancel_outlined);
        expect(status(tester, 'Ремаппер кнопок пульта'), Icons.cancel_outlined);
        expect(Focus.of(tester.element(find.text(title))).hasFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
