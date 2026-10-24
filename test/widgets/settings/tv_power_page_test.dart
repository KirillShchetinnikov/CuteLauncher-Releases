import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/tv_power_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: TvPowerPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(TvPowerPage.channel, null);
  });

  testWidgets('cancel and Back never send power commands', (tester) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      TvPowerPage.channel,
      (call) async {
        calls.add(call.method);
        return true;
      },
    );
    await open(tester);
    await tester.tap(find.text('Выключить ТВ'));
    await tester.pumpAndSettle();
    expect(find.byType(LauncherAlertDialog), findsOneWidget);
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Перезагрузить ТВ'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(calls, isEmpty);
  });

  testWidgets(
    'confirmed requests use fixed methods and ignore repeated activation',
    (tester) async {
      final calls = <String>[];
      final pending = Completer<bool>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        TvPowerPage.channel,
        (call) {
          calls.add(call.method);
          return pending.future;
        },
      );
      await open(tester);
      await tester.tap(find.text('Выключить ТВ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выключить ТВ').last);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, ['sleep']);
      await tester.tap(find.text('Перезагрузить ТВ'));
      await tester.pump();
      expect(find.byType(LauncherAlertDialog), findsNothing);
      pending.complete(true);
      await tester.pumpAndSettle();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        TvPowerPage.channel,
        (call) async {
          calls.add(call.method);
          throw PlatformException(code: 'unavailable');
        },
      );
      await tester.tap(find.text('Перезагрузить ТВ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Перезагрузить ТВ').last);
      await tester.pumpAndSettle();
      expect(calls, ['sleep', 'reboot']);
      expect(
        find.textContaining('Не удалось отправить команду'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
