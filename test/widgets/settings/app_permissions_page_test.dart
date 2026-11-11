import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/app_permissions_page.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('cutelauncher/app_permissions');
  late Map<String, dynamic> service;
  late List<String> methods;
  bool fail = false;
  Completer<void>? pending;
  setUp(() {
    service = {
      'component': 'example.app/example.app.Service',
      'name': 'Button Mapper',
      'service': 'Служба управления кнопками',
      'enabled': false,
      'managed': false,
      'restore': true,
      'result': 'not_managed',
      'modes': {
        'AUTO_START': 'unsupported',
        'RUN_ANY_IN_BACKGROUND': 'deny',
        'ACCESS_RESTRICTED_SETTINGS': 'default',
        'BIND_ACCESSIBILITY_SERVICE': 'unsupported',
      },
    };
    methods = [];
    fail = false;
    pending = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          methods.add(call.method);
          if (call.method == 'list') {
            return {
              'status': 'success',
              'services': [service],
            };
          }
          if (fail) return {'status': 'error'};
          if (pending != null) await pending!.future;
          switch (call.method) {
            case 'preview':
              return {
                'status': 'success',
                'token': 'consent',
                'commands': [],
                'service': service,
              };
            case 'apply':
              expect(call.arguments['token'], 'consent');
              service = {
                ...service,
                'enabled': true,
                'managed': true,
                'result': 'success',
              };
            case 'configure':
              service = {...service, 'restore': call.arguments['restore']};
            case 'disable':
              service = {
                ...service,
                'restore': false,
                'enabled': false,
                'managed': false,
              };
          }
          return {'status': 'success', 'service': service};
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Future<void> pump(
    WidgetTester tester, {
    bool detail = false,
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(380, 900);
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
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Material(
            child: Padding(padding: const EdgeInsets.all(20), child: child!),
          ),
        ),
        home: AppPermissionsPage(service: detail ? service : null),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final target = find.text(text);
    await tester.scrollUntilVisible(
      target,
      180,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'list only reads metadata; selected service opens in the same narrow route',
    (tester) async {
      await pump(tester);
      expect(methods, ['list']);
      expect(find.text('Подключение АДБ'), findsOneWidget);
      expect(find.text('Обновить'), findsOneWidget);
      await tapText(tester, 'Button Mapper');
      expect(methods, ['list', 'inspect']);
      expect(find.text('Подключение АДБ'), findsNothing);
      expect(find.text('Обновить'), findsNothing);
      await tester.scrollUntilVisible(
        find.byType(RoundedSwitchListTile),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.byType(RoundedSwitchListTile), findsOneWidget);
      expect(
        tester
            .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
            .value,
        isTrue,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Разрешения приложениям'), findsOneWidget);
      expect(methods.last, 'list');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('grant requires confirmation; cancelling performs no write', (
    tester,
  ) async {
    await pump(tester, detail: true);
    await tapText(tester, 'Выдать разрешения и включить');
    expect(methods, ['inspect', 'preview']);
    await tapText(tester, 'Отмена');
    expect(methods.contains('apply'), isFalse);
    await tapText(tester, 'Выдать разрешения и включить');
    final context = tester.element(find.byType(AppPermissionsPage));
    await tapText(tester, AppLocalizations.of(context)!.dialogApply);
    expect(methods.sublist(methods.length - 2), ['apply', 'inspect']);
    expect(service['managed'], isTrue);
    expect(service['restore'], isTrue);
  });

  testWidgets('restore switch saves separately without granting access', (
    tester,
  ) async {
    await pump(tester, detail: true);
    await tapText(tester, 'Восстанавливать при отключении');
    expect(service['restore'], isFalse);
    expect(service['managed'], isFalse);
    expect(methods, ['inspect', 'configure', 'inspect']);
  });

  testWidgets('reconnect and disable refresh the card automatically', (
    tester,
  ) async {
    service = {...service, 'enabled': true, 'managed': true};
    await pump(tester, detail: true);
    await tapText(tester, 'Переподключить службу');
    expect(methods.sublist(methods.length - 2), ['reconnect', 'inspect']);
    await tapText(tester, 'Выключить службу и восстановление');
    expect(methods.sublist(methods.length - 2), ['disable', 'inspect']);
    expect(service['enabled'], isFalse);
    expect(
      tester
          .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
          .value,
      isFalse,
    );
  });

  testWidgets(
    'failed ADB operation exposes error and retains saved preference',
    (tester) async {
      await pump(tester, detail: true);
      fail = true;
      await tapText(tester, 'Выдать разрешения и включить');
      expect(
        find.textContaining('Не удалось завершить действие'),
        findsOneWidget,
      );
      expect(service['restore'], isTrue);
      expect(methods.contains('apply'), isFalse);
    },
  );

  testWidgets(
    'large text fits 380-wide panel and unsupported autostart is explicit',
    (tester) async {
      await pump(tester, detail: true, scale: 1.4);
      expect(tester.takeException(), isNull);
      await tapText(tester, 'Восстанавливать при отключении');
      expect(tester.takeException(), isNull);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'busy action keeps focusable row and does not issue duplicate requests',
    (tester) async {
      await pump(tester, detail: true);
      final grant = find.text('Выдать разрешения и включить');
      await tester.ensureVisible(grant);
      await tester.pumpAndSettle();
      pending = Completer<void>();
      await tester.tap(grant);
      await tester.pump();
      final tile = tester.widget<FocusableSettingsTile>(
        find.ancestor(of: grant, matching: find.byType(FocusableSettingsTile)),
      );
      expect(tile.busy, isTrue);
      await tester.tap(grant);
      await tester.pump();
      expect(methods.where((m) => m == 'preview').length, 1);
      // Dispose before the delayed response: no dialog or setState may follow.
      await tester.pumpWidget(const SizedBox());
      pending!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
