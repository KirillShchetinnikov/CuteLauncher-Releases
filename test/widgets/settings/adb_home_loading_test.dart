import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final saved in [false, true]) {
    testWidgets('Home waits for saved value $saved without writing settings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const channel = MethodChannel('cutelauncher/adb');
      final response = Completer<Map<String, dynamic>>();
      final calls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call.method);
        if (call.method == 'info') return response.future;
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AdbPage(section: 'home')),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(RoundedSwitchListTile), findsNothing);
      expect(find.text('—'), findsOneWidget);
      expect(calls, ['info']);
      response.complete({'homeOverride': saved});
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile))
            .value,
        saved,
      );
      expect(calls, ['info']);
      expect(tester.takeException(), isNull);
    });
  }
}
