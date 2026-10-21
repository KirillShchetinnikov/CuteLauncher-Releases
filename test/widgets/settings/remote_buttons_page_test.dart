import 'dart:async';

import 'adb_test_compatibility.dart';

import 'package:flauncher/widgets/settings/adb_page.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/remote_buttons_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const methods = MethodChannel('cutelauncher/remote_buttons');
  const events = MethodChannel('cutelauncher/remote_button_events');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late Map<String, dynamic> info;
  late List<String> calls;
  late List<String> streamCalls;

  setUp(() {
    info = {
      'permission': true,
      'connected': true,
      'active': false,
      'events': [],
    };
    calls = [];
    streamCalls = [];
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, (
      call,
    ) async {
      calls.add(call.method);
      if (call.method == 'start') info = {...info, 'active': true};
      if (call.method == 'stop') info = {...info, 'active': false};
      return info;
    });
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, (
      call,
    ) async {
      streamCalls.add(call.method);
      return null;
    });
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, null);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(events, null);
  });

  Future<void> open(
    WidgetTester tester, {
    String section = 'diagnostics',
  }) async {
    tester.view.physicalSize = const Size(1280, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AdbPage.routeName: (_) => const Scaffold(body: Text('ADB setup')),
        },
        home: Scaffold(body: RemoteButtonsPage(section: section)),
      ),
    );
    await tester.pumpAndSettle();
  }

  FocusableSettingsTile capture(WidgetTester tester) =>
      tester.widget(find.byKey(const ValueKey('remote-buttons-capture')));

  for (final connection in ['ready', 'unavailable']) {
    testWidgets('remapper accessibility grant via ADB: $connection', (
      tester,
    ) async {
      const adb = MethodChannel('cutelauncher/adb');
      const platform = MethodChannel('me.efesser.flauncher/method');
      final actions = <MethodCall>[];
      info = {...info, 'permission': false, 'connected': false};
      binding.defaultBinaryMessenger.setMockMethodCallHandler(platform, (
        call,
      ) async {
        expect(call.method, 'checkAccessibilityPermission');
        return info['permission'];
      });
      binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (
        call,
      ) async {
        if (call.method == 'info') {
          return {'port': 5555, 'compatibility': supportedAdbCompatibility};
        }
        actions.add(call);
        switch (call.arguments['action']) {
          case 'check':
            return {'status': connection};
          case 'preview':
            return {
              'status': 'ready',
              'commands': ['enable own accessibility service'],
            };
          case 'accessibility':
            info = {...info, 'permission': true, 'connected': true};
            return {'status': 'success'};
        }
        throw StateError('Unexpected action');
      });
      addTearDown(() {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, null);
        binding.defaultBinaryMessenger.setMockMethodCallHandler(platform, null);
      });
      await open(tester, section: 'access');
      expect(
        actions.every((call) => call.arguments['action'] == 'check'),
        isTrue,
      );
      await tester.tap(
        find.text(
          'Включить службу специальных возможностей CuteLauncher через ADB',
        ),
      );
      await tester.pumpAndSettle();
      expect(
        actions.where((call) => call.arguments['action'] == 'accessibility'),
        isEmpty,
      );
      if (connection == 'ready') {
        expect(actions.last.arguments['operation'], 'accessibility');
        await tester.tap(find.text('Применить'));
        await tester.pumpAndSettle();
        expect(actions.last.arguments, {
          'port': 5555,
          'tls': false,
          'action': 'accessibility',
          'commands': ['enable own accessibility service'],
        });
        expect(info['permission'], isTrue);
        expect(calls, ['info', 'info']);
        expect(find.text('Предоставлено'), findsOneWidget);
      } else {
        expect(find.text('ADB setup'), findsOneWidget);
        expect(
          actions.every((call) => call.arguments['action'] == 'check'),
          isTrue,
        );
      }
    });
  }

  testWidgets('main menu keeps diagnostics last and hides access actions', (
    tester,
  ) async {
    const mappings = MethodChannel('cutelauncher/remote_mappings');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      mappings,
      (_) async => {
        'enabled': false,
        'bindings': [],
        'permission': true,
        'connected': true,
      },
    );
    addTearDown(
      () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
        mappings,
        null,
      ),
    );
    await open(tester, section: 'main');
    expect(find.text('Включить переназначение'), findsOneWidget);
    expect(find.text('Настройка доступа'), findsOneWidget);
    expect(find.text('Предоставлено'), findsOneWidget);
    expect(find.text('Обновить'), findsNothing);
    expect(find.text('Подробнее'), findsNothing);
    expect(find.byKey(const ValueKey('remote-buttons-capture')), findsNothing);
    expect(
      tester.getTopLeft(find.text('Проверка кнопок')).dy,
      greaterThan(tester.getTopLeft(find.text('Назначения кнопок')).dy),
    );
    await tester.tap(find.text('Проверка кнопок'));
    await tester.pumpAndSettle();
    expect(capture(tester).enabled, isTrue);
  });

  testWidgets(
    'entry only reads status; explicit start and stop; exit detaches the stream',
    (tester) async {
      await open(tester);
      expect(calls, ['info']);
      expect(capture(tester).enabled, isTrue);
      await tester.tap(find.byKey(const ValueKey('remote-buttons-capture')));
      await tester.pumpAndSettle();
      expect(calls, ['info', 'start']);
      expect(find.text('Завершить проверку'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('remote-buttons-capture')));
      await tester.pumpAndSettle();
      expect(calls.last, 'stop');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(streamCalls, ['listen', 'cancel']);
    },
  );

  for (final field in ['permission', 'connected']) {
    testWidgets('cannot capture when $field is absent', (tester) async {
      info[field] = false;
      await open(tester, section: 'access');
      expect(calls, ['info']);
    });
  }

  testWidgets('unknown status cannot enable capture', (tester) async {
    final pending = Completer<Map<String, dynamic>>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      methods,
      (_) => pending.future,
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RemoteButtonsPage(section: 'diagnostics')),
      ),
    );
    await tester.pump();
    expect(capture(tester).enabled, isFalse);
    pending.complete(info);
    await tester.pumpAndSettle();
    expect(capture(tester).enabled, isTrue);
  });

  testWidgets('native timeout updates the screen without polling', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('remote-buttons-capture')));
    await tester.pumpAndSettle();
    expect(find.text('Завершить проверку'), findsOneWidget);
    binding.channelBuffers.push(
      events.name,
      const StandardMethodCodec().encodeSuccessEnvelope({
        ...info,
        'active': false,
      }),
      (_) {},
    );
    await tester.pumpAndSettle();
    expect(find.text('Проверить кнопки (120 с)'), findsOneWidget);
    expect(calls, ['info', 'start']);
  });

  testWidgets(
    'return from OEM app reloads expired capture and down/repeat/up history',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('remote-buttons-capture')));
      await tester.pumpAndSettle();
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      info = {
        ...info,
        'active': false,
        'events': [
          for (final (id, action, repeat) in [(1, 0, 0), (2, 0, 1), (3, 1, 0)])
            {
              'id': id,
              'keyName': 'KEYCODE_PROG_RED',
              'keyCode': 183,
              'scanCode': 398,
              'deviceId': 7,
              'source': 257,
              'action': action,
              'repeat': repeat,
              'elapsedMs': id * 50,
              'cancelled': false,
            },
        ],
      };
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(find.text('Проверить кнопки (120 с)'), findsOneWidget);
      expect(find.textContaining('KEYCODE_PROG_RED'), findsNWidgets(3));
      expect(find.textContaining('repeat=1'), findsOneWidget);
      expect(find.textContaining('UP ·'), findsOneWidget);
      expect(calls.last, 'info');
    },
  );

  testWidgets('native permission failure remains retryable', (tester) async {
    await open(tester);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(methods, (
      call,
    ) async {
      if (call.method == 'start') {
        throw PlatformException(code: 'permission_denied');
      }
      return {...info, 'permission': false, 'connected': false};
    });
    await tester.tap(find.byKey(const ValueKey('remote-buttons-capture')));
    await tester.pumpAndSettle();
    expect(find.text('Недоступно'), findsOneWidget);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(capture(tester).enabled, isFalse);
    expect(find.text('Недоступно'), findsNothing);
  });
}
