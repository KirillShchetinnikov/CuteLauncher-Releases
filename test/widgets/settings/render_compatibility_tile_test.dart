import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/render_compatibility_tile.dart';

const channel = MethodChannel('me.efesser.flauncher/method');

Future<void> mount(WidgetTester tester, {String locale = 'ru'}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: Locale(locale),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: SingleChildScrollView(child: RenderCompatibilityTile()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  testWidgets(
    'manual change saves once and waits for explicit apply; reversal cancels pending apply',
    (tester) async {
      var enabled = false;
      var saves = 0;
      var restarts = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'applyRenderCompatibility') {
          restarts++;
          return true;
        }
        if (call.method == 'setRenderCompatibility') {
          saves++;
          enabled = (call.arguments as Map)['enabled'] as bool;
        }
        return {'automatic': false, 'enabled': enabled, 'active': false};
      });
      await mount(tester);
      final title = find.text('Совместимый вывод графики').first;
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(saves, 1);
      expect(restarts, 0);
      expect(find.text('Применить и перезапустить лаунчер'), findsOneWidget);
      await tester.tap(title);
      await tester.pumpAndSettle();
      expect(find.text('Применить и перезапустить лаунчер'), findsNothing);
      await tester.tap(title);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Применить и перезапустить лаунчер'));
      await tester.pumpAndSettle();
      expect(restarts, 1);
    },
  );

  testWidgets('automatic mode is read only and help remains collapsed', (
    tester,
  ) async {
    final calls = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call.method);
      return {'automatic': true, 'enabled': true, 'active': true};
    });
    await mount(tester);
    expect(find.textContaining('Включён автоматически'), findsOneWidget);
    expect(find.byType(RoundedSwitchListTile), findsNothing);
    expect(find.textContaining('Попробуйте этот режим'), findsNothing);
    expect(calls, ['getRenderCompatibility']);
  });

  testWidgets(
    'failed save retains value and pending response after dispose is safe',
    (tester) async {
      var fail = true;
      final pending = Completer<Map<String, bool>>();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'setRenderCompatibility') {
          if (fail) throw PlatformException(code: 'save_failed');
          return pending.future;
        }
        return {'automatic': false, 'enabled': false, 'active': false};
      });
      await mount(tester);
      await tester.tap(find.text('Совместимый вывод графики').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
            .value,
        false,
      );
      expect(
        find.text('Не удалось прочитать или применить настройку'),
        findsOneWidget,
      );
      fail = false;
      await tester.tap(find.text('Совместимый вывод графики').first);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete({'automatic': false, 'enabled': true, 'active': false});
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('failed initial read can be retried in RTL', (tester) async {
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      if (reads++ == 0) throw PlatformException(code: 'unavailable');
      return {'automatic': false, 'enabled': true, 'active': true};
    });
    await mount(tester, locale: 'ar');
    await tester.tap(find.textContaining('تعذّرت قراءة الإعداد'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
          .value,
      true,
    );
    expect(tester.takeException(), isNull);
  });
}
