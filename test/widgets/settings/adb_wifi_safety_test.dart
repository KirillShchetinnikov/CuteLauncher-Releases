import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'adb_test_compatibility.dart';

void main() {
  for (final locale in ['ru', 'en']) {
    for (final status in ['wifiOwned', 'wifiUnknown']) {
      testWidgets('$locale $status blocks disable before confirmation', (tester) async {
        const adb = MethodChannel('cutelauncher/adb');
        final operations = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, (call) async {
          if (call.method == 'info') {
            return {
              'port': 5555,
              'compatibility': supportedAdbCompatibility,
              'connectionSnapshot': jsonEncode({
                'status': 'ready', 'isHome': true, 'accessibility': false,
                'launchers': [{
                  'package': 'com.google.android.apps.tv.launcherx',
                  'component': 'com.google.android.apps.tv.launcherx/home.HomeActivity',
                  'name': 'Google TV', 'enabled': true, 'builtin': true,
                }],
              }),
            };
          }
          operations.add(call.arguments['action'] as String);
          return {'status': status};
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, null));
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AdbPage(section: 'launcher')),
        ));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(AdbPage)))!;
        final disable = tester.widget<FocusableSettingsTile>(find.ancestor(
          of: find.text('${l.adbDisableBuiltin}: Google TV'),
          matching: find.byType(FocusableSettingsTile),
        ));
        disable.onPressed!();
        await tester.pumpAndSettle();
        expect(operations, ['preview']);
        expect(find.textContaining(status == 'wifiOwned' ? l.adbWifiOwned : l.adbWifiUnknown), findsWidgets);
        await tester.pump(const Duration(seconds: 6));
      });
    }
  }
}
