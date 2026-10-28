import 'dart:async';
import 'dart:io';

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
  bool connected = true;
  Future<int?> Function()? learn;
  setUp(() {
    config = const RemoteMappingConfiguration();
    calls = [];
    failSave = false;
    connected = true;
    learn = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'editing' || call.method == 'cancelLearn') return null;
      if (call.method == 'learn') return learn == null ? 4137 : await learn!();
      if (call.method == 'save') {
        if (failSave) throw PlatformException(code: 'unavailable');
        config = RemoteMappingConfiguration.fromMap(call.arguments as Map);
      }
      return {
        ...config.toMap(),
        'permission': true,
        'connected': connected,
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
    'Home hold exposes recent apps and preserves protected short press',
    (tester) async {
      config = const RemoteMappingConfiguration(
        enabled: true,
        bindings: [
          RemoteMapping(keyCode: 3, trigger: 'hold', action: 'recents'),
        ],
      );
      await open(tester);
      await tester.tap(find.text('Home — Удержание'));
      await tester.pumpAndSettle();
      expect(find.text('Панель открытых приложений'), findsOneWidget);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(config.bindings.single.keyCode, 3);
      expect(config.bindings.single.trigger, 'hold');
      expect(config.bindings.single.action, 'recents');
    },
  );
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
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ОК'));
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
    expect(config.bindings, hasLength(2));
    await tester.tap(find.widgetWithText(LauncherDialogButton, 'Удалить'));
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
      await tester.tap(find.text('Назначить кнопку').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Захватить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ОК'));
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
      expect(
        find.text('Удалить назначение «TCL Home — Удержание»?'),
        findsOneWidget,
      );
      expect(config.bindings, hasLength(2));
      await tester.tap(find.widgetWithText(LauncherDialogButton, 'Удалить'));
      await tester.pumpAndSettle();
      expect(config.bindings.single.slot, '4137:press');
    },
  );
  testWidgets(
    'delete cancellation and Back preserve assignment and editor draft',
    (tester) async {
      config = const RemoteMappingConfiguration(
        enabled: true,
        bindings: [RemoteMapping(keyCode: 190, name: 'Видео')],
      );
      await open(tester);
      await tester.tap(find.text('Видео'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Имя'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Новое имя');
      await tester.tap(find.widgetWithText(LauncherDialogButton, 'Сохранить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      expect(find.text('Удалить назначение «Видео»?'), findsOneWidget);
      expect(Focus.of(tester.element(find.text('Отмена'))).hasFocus, isTrue);
      expect(calls.where((call) => call.method == 'save'), isEmpty);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(find.text('Новое имя'), findsOneWidget);
      expect(config.bindings.single.name, 'Видео');
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(LauncherAlertDialog), findsNothing);
      expect(find.text('Новое имя'), findsOneWidget);
      expect(calls.where((call) => call.method == 'save'), isEmpty);
      expect(config.enabled, isTrue);
      expect(config.bindings.single.keyCode, 190);
    },
  );

  testWidgets('failed confirmed deletion keeps editor and can be retried', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      enabled: true,
      bindings: [RemoteMapping(keyCode: 190)],
    );
    await open(tester);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    failSave = true;
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LauncherDialogButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(config.bindings.single.keyCode, 190);
    expect(find.text('Сохранить'), findsOneWidget);
    expect(calls.where((call) => call.method == 'save'), hasLength(1));
    failSave = false;
    await tester.tap(find.text('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(LauncherDialogButton, 'Удалить'));
    await tester.pumpAndSettle();
    expect(config.bindings, isEmpty);
    expect(find.text('Добавить назначение'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });

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
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ОК'));
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
      await tester.tap(find.text('Назначить кнопку').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Захватить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ОК'));
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

  testWidgets(
    'missing button and target show specific validation without saving',
    (tester) async {
      await open(tester);
      await tester.tap(find.text('Добавить назначение'));
      await tester.pumpAndSettle();
      expect(find.text('Название кнопки'), findsOneWidget);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Кнопка не назначена.'), findsOneWidget);
      expect(calls.where((c) => c.method == 'save'), isEmpty);
      await tester.tap(find.text('Назначить кнопку').first);
      await tester.pumpAndSettle();
      expect(calls.where((c) => c.method == 'learn'), isEmpty);
      await tester.tap(find.text('Захватить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Действие'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открывать выбранное приложение'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Выберите приложение для запуска.'), findsOneWidget);
      expect(calls.where((c) => c.method == 'save'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );

  testWidgets('capture failures allow retry and Home requires hold', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      bindings: [RemoteMapping(keyCode: 190)],
    );
    await open(tester);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    learn = () async => null;
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Кнопка не захвачена.'), findsOneWidget);
    expect(find.text('Захваченная кнопка: YouTube (190)'), findsOneWidget);
    learn = () async => throw PlatformException(code: 'permission_denied');
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Не удалось захватить кнопку.'), findsOneWidget);
    expect(find.text('Захваченная кнопка: YouTube (190)'), findsOneWidget);
    learn = () async => 3;
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(find.text('Удержание'), findsOneWidget);
    await tester.tap(find.text('Тип нажатия'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Короткое нажатие'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(
      find.text('Для Home выберите тип нажатия «Удержание».'),
      findsOneWidget,
    );
    expect(config.bindings.single.keyCode, 190);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  for (final target in ['', 'http://example.org/invalid']) {
    testWidgets('webhook validation identifies empty or invalid URL: $target', (
      tester,
    ) async {
      config = RemoteMappingConfiguration(
        bindings: [
          RemoteMapping(keyCode: 190, action: 'webhook', target: target),
        ],
      );
      await open(tester);
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          target.isEmpty ? 'Введите Webhook URL' : 'Неверный Webhook URL.',
        ),
        findsOneWidget,
      );
      expect(calls.where((c) => c.method == 'save'), isEmpty);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    });
  }

  testWidgets('capture repeats and cancel or Back preserve the editor button', (
    tester,
  ) async {
    config = const RemoteMappingConfiguration(
      bindings: [RemoteMapping(keyCode: 190)],
    );
    await open(tester);
    await tester.tap(find.text('YouTube'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    expect(find.text('Захваченная кнопка: TCL Home (4137)'), findsOneWidget);
    learn = () async => 164;
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    expect(find.text('Захваченная кнопка: Mute (164)'), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('YouTube (190)'), findsOneWidget);
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('YouTube (190)'), findsOneWidget);
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(find.text('Mute (164)'), findsOneWidget);
    expect(config.bindings.single.keyCode, 190);
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();
    expect(config.bindings.single.keyCode, 164);
  });

  testWidgets('closing active capture cancels and ignores a late response', (
    tester,
  ) async {
    final pending = Completer<int?>();
    learn = () => pending.future;
    await open(tester);
    await tester.tap(find.text('Добавить назначение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Назначить кнопку').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Захватить'));
    await tester.pump();
    expect(
      tester
          .widget<LauncherDialogButton>(
            find.widgetWithText(LauncherDialogButton, 'ОК'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(calls.last.method, 'cancelLearn');
    pending.complete(4137);
    await tester.pumpAndSettle();
    expect(find.text('TCL Home (4137)'), findsNothing);
    expect(config.bindings, isEmpty);
  });

  testWidgets('service unavailable gives an actionable capture error', (
    tester,
  ) async {
    connected = false;
    await open(tester);
    await tester.tap(find.text('Добавить назначение'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Назначить кнопку'));
    await tester.pumpAndSettle();
    expect(find.textContaining('подключите службу'), findsOneWidget);
    expect(calls.where((c) => c.method == 'learn'), isEmpty);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });

  testWidgets(
    'webhook import strips line breaks, masks URL and preserves draft on failure or cancel',
    (tester) async {
      const old = 'https://example.org/old';
      config = const RemoteMappingConfiguration(
        bindings: [RemoteMapping(keyCode: 190, action: 'webhook', target: old)],
      );
      const files = MethodChannel('me.efesser.flauncher/method');
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('webhook-test-'),
      ))!;
      addTearDown(
        () => tester.runAsync(() => directory.delete(recursive: true)),
      );
      String? selected;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(files, (
        call,
      ) async {
        if (call.method == 'pickWebhookDocument') return selected;
        return null;
      });
      addTearDown(
        () => binding.defaultBinaryMessenger.setMockMethodCallHandler(
          files,
          null,
        ),
      );
      await open(tester);
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      Future<void> import() async {
        await tester.runAsync(() async {
          await tester.tap(find.text('Импортировать URL из файла'));
          await Future<void>.delayed(const Duration(milliseconds: 100));
        });
        await tester.pumpAndSettle();
      }

      await import(); // cancellation
      selected = '${directory.path}/missing.txt';
      await import();
      expect(find.textContaining('Не удалось прочитать файл.'), findsOneWidget);
      final oversized = File('${directory.path}/large.txt');
      await tester.runAsync(
        () => oversized.writeAsString('x' * (64 * 1024 + 1)),
      );
      selected = oversized.path;
      await import();
      expect(await tester.runAsync(() => oversized.exists()), isFalse);
      final invalid = File('${directory.path}/invalid.txt');
      await tester.runAsync(
        () => invalid.writeAsString('curl https://example.org/api'),
      );
      selected = invalid.path;
      await import();
      expect(await tester.runAsync(() => invalid.exists()), isFalse);
      expect(find.textContaining('В файле должен быть только'), findsOneWidget);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(config.bindings.single.target, old);
      await tester.tap(find.text('YouTube'));
      await tester.pumpAndSettle();
      final valid = File('${directory.path}/valid.txt');
      await tester.runAsync(
        () =>
            valid.writeAsString('https://example.org/\r\napi/webhook/secret\n'),
      );
      selected = valid.path;
      await import();
      expect(await tester.runAsync(() => valid.exists()), isFalse);
      expect(find.text('https://example.org/api/webhook/secret'), findsNothing);
      expect(find.text('••••••'), findsOneWidget);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(
        config.bindings.single.target,
        'https://example.org/api/webhook/secret',
      );
      await tester.pump(const Duration(seconds: 5));
    },
  );

  test('text import accepts only a URL and removes line breaks', () {
    expect(
      remoteWebhookFromText('\uFEFFhttps://example.org/\r\napi/webhook/x\n'),
      'https://example.org/api/webhook/x',
    );
    for (final value in [
      '',
      'curl https://example.org/x',
      'POST https://example.org/x',
      'https://example.org/x extra',
      'http://example.org/x',
      'not a url',
      'https://example.org/x#fragment',
    ]) {
      expect(remoteWebhookFromText(value), isNull, reason: value);
    }
    expect(remoteWebhookFromText("https://example.org/${'a' * 4096}"), isNull);
  });

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
