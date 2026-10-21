import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/auto_launch_configuration.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/auto_launch_page.dart';

void main() {
  for (final savedId in ['port', 'cec']) {
    testWidgets('merged HDMI keeps saved $savedId and selects the physical port',
        (tester) async {
      const channel = MethodChannel('cutelauncher/auto_launch');
      const native = MethodChannel('me.efesser.flauncher/method');
      final messenger = tester.binding.defaultBinaryMessenger;
      final saved = <Map<dynamic, dynamic>>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'save') {
          saved.add(call.arguments as Map);
          return {'status': 'success'};
        }
        return AutoLaunchConfiguration(mode: 'hdmi', input: savedId).toMap();
      });
      messenger.setMockMethodCallHandler(native, (_) async => [
        {'id': 'port', 'label': 'HDMI 2', 'type': 1007},
        {'id': 'cec', 'label': 'XBOX', 'type': 1007, 'parentId': 'port'},
      ]);
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(native, null);
      });
      await tester.pumpWidget(const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AutoLaunchPage()),
      ));
      await tester.pumpAndSettle();
      expect(find.text('XBOX'), findsOneWidget);
      expect(find.text('HDMI 2'), findsNothing);
      await tester.tap(find.text('XBOX'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('XBOX').last);
      await tester.pumpAndSettle();
      expect(saved.single['input'], 'port');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('unavailable HDMI picker focuses Cancel after async loading', (
    tester,
  ) async {
    const channel = MethodChannel('cutelauncher/auto_launch');
    const native = MethodChannel('me.efesser.flauncher/method');
    final targets = Completer<List<Map<String, dynamic>>>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => const AutoLaunchConfiguration().toMap(),
    );
    messenger.setMockMethodCallHandler(native, (_) => targets.future);
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(native, null);
    });
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AutoLaunchPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выключен'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Переключать на выбранный HDMI'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    targets.complete([]);
    await tester.pumpAndSettle();
    final cancel = find.widgetWithText(TextButton, 'Отмена');
    expect(Focus.of(tester.element(find.text('Отмена'))).hasFocus, isTrue);
    expect(cancel, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('Выключен'), findsOneWidget);
  });

  for (final mode in ['off', 'hdmi']) {
    testWidgets('saved HDMI label loads without opening target from $mode', (
      tester,
    ) async {
      const channel = MethodChannel('cutelauncher/auto_launch');
      const native = MethodChannel('me.efesser.flauncher/method');
      const inputId = 'com.tcl.tvinput/.HDMIInputService/HW1';
      final inputs = Completer<List<Map<String, dynamic>>>();
      final calls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'save') return {'status': 'success'};
        return AutoLaunchConfiguration(mode: mode, input: inputId).toMap();
      });
      messenger.setMockMethodCallHandler(native, (call) {
        calls.add(call.method);
        return inputs.future;
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(native, null);
      });
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AutoLaunchPage()),
        ),
      );
      await tester.pumpAndSettle();
      if (mode == 'off') {
        expect(calls, isEmpty);
        await tester.tap(find.text('Выключен'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Переключать на выбранный HDMI'));
        await tester.pumpAndSettle();
      }
      expect(find.text(inputId), findsNothing);
      expect(find.text('…'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(calls, ['getTvInputs']);
      inputs.complete([
        {'id': inputId, 'label': 'HDMI 1', 'type': 1007},
      ]);
      await tester.pumpAndSettle();
      expect(find.text('HDMI 1'), findsOneWidget);
      expect(find.text(inputId), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'initial loading disables mode; completed settings focus the row and chooser',
    (tester) async {
      const channel = MethodChannel('cutelauncher/auto_launch');
      const native = MethodChannel('me.efesser.flauncher/method');
      final info = Completer<Map<String, dynamic>>();
      final calls = <String>[];
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (_) => info.future);
      messenger.setMockMethodCallHandler(native, (call) async {
        calls.add(call.method);
        return [];
      });
      addTearDown(() {
        messenger.setMockMethodCallHandler(channel, null);
        messenger.setMockMethodCallHandler(native, null);
      });
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AutoLaunchPage()),
        ),
      );
      await tester.pump();
      expect(Focus.of(tester.element(find.text('Выключен'))).hasFocus, isFalse);
      info.complete(const AutoLaunchConfiguration().toMap());
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Выключен'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        Focus.of(tester.element(find.text('Открывать выбранное приложение')))
            .hasFocus,
        isTrue,
      );
      expect(calls, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('slow target enumeration stays inside cancellable picker', (
    tester,
  ) async {
    const channel = MethodChannel('cutelauncher/auto_launch');
    const native = MethodChannel('me.efesser.flauncher/method');
    final targets = Completer<List<Map<String, dynamic>>>();
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => const AutoLaunchConfiguration().toMap(),
    );
    messenger.setMockMethodCallHandler(native, (_) => targets.future);
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      messenger.setMockMethodCallHandler(native, null);
    });
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AutoLaunchPage()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выключен'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открывать выбранное приложение'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsNothing);
    targets.complete([]);
    await tester.pumpAndSettle();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final language in ['ru', 'en']) {
    testWidgets(
      'long selected target fits narrow $language settings at 130 percent text',
      (tester) async {
        tester.view.physicalSize = const Size(680, 1500);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const channel = MethodChannel('cutelauncher/auto_launch');
        const native = MethodChannel('me.efesser.flauncher/method');
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => const AutoLaunchConfiguration(
            mode: 'app',
            app: 'sample.player',
            wake: true,
          ).toMap(),
        );
        messenger.setMockMethodCallHandler(
          native,
          (call) async => call.method == 'getApplications'
              ? [
                  {
                    'packageName': 'sample.player',
                    'name': 'Very long player application name with many words for the TV settings panel',
                  },
                ]
              : [],
        );
        addTearDown(() {
          messenger.setMockMethodCallHandler(channel, null);
          messenger.setMockMethodCallHandler(native, null);
        });
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(body: AutoLaunchPage()),
          ),
        );
        await tester.pumpAndSettle();
        final target = find.text(
          language == 'ru' ? 'Цель запуска' : 'Launch target',
        );
        await tester.scrollUntilVisible(target, 200);
        await tester.tap(target);
        await tester.pumpAndSettle();
        await tester.tap(find.text(language == 'ru' ? 'Отмена' : 'Cancel'));
        await tester.pumpAndSettle();
        expect(find.textContaining('Very long player'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'remote selects target and event without launching it; off keeps target',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 2000);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const channel = MethodChannel('cutelauncher/auto_launch');
      const apps = MethodChannel('me.efesser.flauncher/method');
      final saves = <Map>[];
      final appCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'info') {
          return {
            ...const AutoLaunchConfiguration().toMap(),
            'ownPackage': 'own.launcher',
          };
        }
        if (call.method == 'save') {
          saves.add(call.arguments as Map);
          return {'status': 'success'};
        }
        return null;
      });
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(apps, (
        call,
      ) async {
        appCalls.add(call.method);
        if (call.method == 'getApplications') {
          return [
            {'packageName': 'own.launcher', 'name': 'Own launcher'},
            {'packageName': 'sample.player', 'name': 'Player'},
          ];
        }
        if (call.method == 'getTvInputs') {
          return [
            {'id': 'hdmi/1', 'label': 'HDMI 1', 'type': 1007},
            {'id': 'tuner', 'label': 'Tuner', 'type': 0},
          ];
        }
        return false;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          apps,
          null,
        );
      });
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AutoLaunchPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(saves, isEmpty);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(appCalls, isEmpty);
      expect(find.text('Автозапуск'), findsNWidgets(2));
      expect(Focus.of(tester.element(find.text('Выключен'))).hasFocus, isTrue);
      final context = tester.element(find.byType(AutoLaunchPage));
      final hint = find.text(AppLocalizations.of(context)!.autoLaunchHint);
      expect(hint, findsNothing);
      expect(
        tester.getTopLeft(find.text(AppLocalizations.of(context)!.settingsHelp)).dy,
        greaterThan(tester.getBottomLeft(find.text('Выключен')).dy),
      );
      // Activate the target picker with remote Enter.
      Focus.of(tester.element(find.text('Выключен'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открывать выбранное приложение'));
      await tester.pumpAndSettle();
      expect(find.text('Own launcher'), findsNothing);
      expect(find.text('Player'), findsOneWidget);
      await tester.tap(find.text('Player'));
      await tester.pumpAndSettle();
      expect(saves.last['mode'], 'app');
      expect(saves.last['app'], 'sample.player');
      expect(saves.last['boot'], isFalse);
      await tester.ensureVisible(find.text('После пробуждения'));
      await tester.tap(find.text('После пробуждения'));
      await tester.pumpAndSettle();
      expect(saves.last['wake'], isTrue);
      await tester.ensureVisible(find.text('Открывать выбранное приложение'));
      await tester.tap(find.text('Открывать выбранное приложение'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выключен'));
      await tester.pumpAndSettle();
      expect(saves.last['mode'], 'off');
      expect(saves.last['app'], 'sample.player');
      await tester.tap(find.text('Выключен'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Переключать на выбранный HDMI'));
      await tester.pumpAndSettle();
      expect(find.text('Tuner'), findsNothing);
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(saves.last['mode'], 'off');
      expect(appCalls, ['getApplications', 'getTvInputs']);
      expect(tester.takeException(), isNull);
    },
  );
}
