import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/remote_mapping_configuration.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/remote_mappings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('cutelauncher/remote_mappings');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late RemoteMappingConfiguration config;
  late List<MethodCall> calls;
  bool failSave = false;
  setUp(() {
    config = const RemoteMappingConfiguration();
    calls = [];
    failSave = false;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'editing' || call.method == 'cancelLearn') return null;
      if (call.method == 'learn') return 4137;
      if (call.method == 'save') {
        if (failSave) throw PlatformException(code: 'unavailable');
        config = RemoteMappingConfiguration.fromMap(call.arguments as Map);
      }
      return {
        ...config.toMap(),
        'permission': true,
        'connected': true,
        'status': 'idle',
      };
    });
  });
  tearDown(
    () =>
        binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
  );
  Future<void> open(WidgetTester tester, {bool switchOnly = false}) async {
    tester.view.physicalSize = const Size(1280, 1440);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: RemoteMappingsPage(switchOnly: switchOnly)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'entry pauses editing without rewriting assignments; exit releases pause',
    (tester) async {
      await open(tester);
      expect(calls.where((call) => call.method == 'save'), isEmpty);
      expect(
        calls.any((call) => call.method == 'editing' && call.arguments == true),
        isTrue,
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        calls.any(
          (call) => call.method == 'editing' && call.arguments == false,
        ),
        isTrue,
      );
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      expect(calls.last.method, 'editing');
      expect(calls.last.arguments, false);
    },
  );
  testWidgets(
    'master switch waits for native save; failure does not claim enabled',
    (tester) async {
      await open(tester, switchOnly: true);
      failSave = true;
      await tester.tap(find.text('Включить переназначение'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RoundedSwitchListTile>(
              find.byType(RoundedSwitchListTile).first,
            )
            .value,
        isFalse,
      );
      expect(config.enabled, isFalse);
      failSave = false;
      await tester.tap(find.text('Включить переназначение'));
      await tester.pumpAndSettle();
      expect(config.enabled, isTrue);
    },
  );
  testWidgets('learning TCL Home saves its OEM code and default Home action', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text('Добавить назначение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Кнопка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Определить кнопку пульта'));
    await tester.pumpAndSettle();
    expect(find.text('TCL Home (4137)'), findsOneWidget);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(config.bindings.single.keyCode, 4137);
    expect(config.bindings.single.action, 'home');
    expect(config.enabled, isFalse);
  });
  testWidgets('individual switch and deletion preserve other mappings', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      enabled: true,
      bindings: [
        RemoteMapping(keyCode: 190),
        RemoteMapping(keyCode: 4137, action: 'back'),
      ],
    );
    await open(tester);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Включить переназначение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(
      config.bindings.firstWhere((item) => item.keyCode == 190).enabled,
      isFalse,
    );
    expect(config.enabled, isTrue);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    expect(config.bindings.single.keyCode, 4137);
  });

  testWidgets(
    'hold can share a button and be deleted without removing short press',
    (tester) async {
      config = const RemoteMappingConfiguration(
        enabled: true,
        bindings: [RemoteMapping(keyCode: 4137)],
      );
      await open(tester);
      await tester.tap(find.text('Добавить назначение'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тип нажатия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удержание'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Кнопка'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Определить кнопку пульта'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(config.bindings.map((item) => item.slot).toSet(), {
        '4137:press',
        '4137:hold',
      });
      await tester.tap(find.text('TCL Home — Удержание'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(config.bindings.single.slot, '4137:press');
    },
  );
  testWidgets('reset is explicit and cancel preserves saved rules', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      enabled: true,
      bindings: [RemoteMapping(keyCode: 190)],
    );
    await open(tester);
    await tester.tap(find.text('Сбросить назначения'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(config.enabled, isTrue);
    expect(config.bindings, hasLength(1));
    await tester.tap(find.text('Сбросить назначения'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(LauncherDialogButton, 'Сбросить назначения'),
    );
    await tester.pumpAndSettle();
    expect(config.enabled, isFalse);
    expect(config.bindings, isEmpty);
  });
  testWidgets('conflict preserves editor values and can be corrected to hold', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      bindings: [RemoteMapping(keyCode: 4137)],
    );
    await open(tester);
    await tester.tap(find.text('Добавить назначение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Кнопка'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Определить кнопку пульта'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('уже назначена'), findsOneWidget);
    expect(find.text('TCL Home (4137)'), findsOneWidget);
    expect(calls.where((call) => call.method == 'save'), isEmpty);
    await tester.tap(find.text('Тип нажатия'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удержание'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(config.bindings.map((item) => item.slot).toSet(), {
      '4137:press',
      '4137:hold',
    });
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets(
    'editing changes name key trigger and action; failed save keeps draft',
    (tester) async {
      config = const RemoteMappingConfiguration(
        enabled: true,
        bindings: [RemoteMapping(keyCode: 190), RemoteMapping(keyCode: 164)],
      );
      await open(tester);
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Имя'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Моя кнопка');
      await tester.tap(find.text('Сохранить').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Кнопка'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Определить кнопку пульта'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тип нажатия'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удержание'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Действие'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      failSave = true;
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Моя кнопка'), findsOneWidget);
      expect(find.text('TCL Home (4137)'), findsOneWidget);
      expect(config.bindings.first.keyCode, 190);
      failSave = false;
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      final edited = config.bindings.firstWhere((item) => item.keyCode == 4137);
      expect(edited.name, 'Моя кнопка');
      expect(edited.trigger, 'hold');
      expect(edited.action, 'back');
      expect(config.bindings.map((item) => item.keyCode).toSet(), {164, 4137});
      await tester.pump(const Duration(seconds: 5));
    },
  );

  test('UI rejects insecure public HTTP and accepts local HA webhook before leaving editor', () {
    expect(
      remoteWebhookValid('http://192.168.1.2:8123/api/webhook/secret'),
      isTrue,
    );
    expect(
      remoteWebhookValid('https://example.org/api/webhook/secret'),
      isTrue,
    );
    expect(remoteWebhookValid('http://example.org/secret'), isFalse);
    expect(
      remoteWebhookValid('https://user:password@example.org/secret'),
      isFalse,
    );
    expect(remoteWebhookValid('https://example.org/secret#fragment'), isFalse);
  });
}
