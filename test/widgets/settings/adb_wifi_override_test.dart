import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'adb_test_compatibility.dart';

void main() {
  for (final outcome in ['ok', 'cancel', 'back', 'confirm', 'unknown']) {
    for (final locale in ['ru', 'en']) {
      testWidgets('Wi-Fi override $outcome $locale is explicit and one-shot', (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const adb = MethodChannel('cutelauncher/adb');
        const platform = MethodChannel('me.efesser.flauncher/method');
        const auto = MethodChannel('cutelauncher/auto_launch');
        const target = 'com.google.android.tvlauncher';
        const commands = [
          "pm disable-user --user 0 'com.google.android.tungsten.setupwraith'",
          "pm disable-user --user 0 'com.google.android.tvlauncher'",
        ];
        final calls = <Map<dynamic, dynamic>>[];
        final snapshot = {
          'status': 'ready',
          'compatibility': supportedAdbCompatibility,
          'isHome': false,
          'accessibility': false,
          'launchers': [{'package': target, 'name': 'Stock TV', 'builtin': true, 'enabled': true}],
        };
        final messenger = tester.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(platform, (_) async => false);
        messenger.setMockMethodCallHandler(auto, (_) async => {'mode': 'off'});
        messenger.setMockMethodCallHandler(adb, (call) async {
          if (call.method == 'info') {
            return {'port': 5555, 'compatibility': supportedAdbCompatibility, 'connectionSnapshot': jsonEncode(snapshot)};
          }
          final args = Map<dynamic, dynamic>.from(call.arguments as Map);
          calls.add(args);
          switch (args['action']) {
            case 'check': return snapshot;
            case 'preview':
              if (args['allowOwnedWifi'] == true) {
                return outcome == 'unknown'
                    ? {'status': 'wifiUnknown'}
                    : {'status': 'ready', 'commands': commands, 'target': target};
              }
              return {'status': 'wifiOwned'};
            case 'disableSystem': return {'status': 'success'};
            default: return {'status': 'unavailable'};
          }
        });
        addTearDown(() {
          messenger.setMockMethodCallHandler(adb, null);
          messenger.setMockMethodCallHandler(platform, null);
          messenger.setMockMethodCallHandler(auto, null);
        });
        await tester.pumpWidget(MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AdbPage(section: 'launcher')),
        ));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(AdbPage)))!;
        final action = find.text('${l.adbDisableBuiltin}: Stock TV');
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(find.text(l.adbWifiOwned), findsOneWidget);
        expect(calls.where((c) => c['action'] == 'disableSystem'), isEmpty);
        if (outcome == 'ok') {
          await tester.tap(find.text(l.ok));
        } else {
          await tester.tap(find.text(l.adbWifiOverride));
          await tester.pumpAndSettle();
          expect(find.text(l.adbWifiRiskTitle), findsOneWidget);
          expect(find.text(l.adbWifiOwned), findsNothing);
          expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<TextButton>()?.autofocus, isTrue);
          expect(calls.where((c) => c['allowOwnedWifi'] == true), isEmpty);
          if (outcome == 'back') {
            await tester.binding.handlePopRoute();
          } else if (outcome == 'cancel') {
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          } else {
            await tester.tap(find.text(l.adbWifiDisable));
          }
        }
        await tester.pumpAndSettle();
        final applied = calls.where((c) => c['action'] == 'disableSystem').toList();
        if (outcome == 'confirm') {
          expect(applied, hasLength(1));
          expect(applied.single['allowOwnedWifi'], isTrue);
          expect(applied.single['target'], target);
          expect(applied.single['commands'], commands);
          // A new attempt must start with the normal guard again.
          await tester.ensureVisible(action);
          await tester.tap(action);
          await tester.pumpAndSettle();
          expect(find.text(l.adbWifiOwned), findsOneWidget);
          expect(calls.last['allowOwnedWifi'], isNull);
        } else {
          expect(applied, isEmpty);
        }
        if (outcome == 'unknown') expect(find.text(l.adbWifiUnknown), findsWidgets);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 6));
      });
    }
  }
}
