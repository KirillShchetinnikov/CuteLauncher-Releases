import 'dart:convert';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/access_settings_links.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'adb_test_compatibility.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const adb = MethodChannel('cutelauncher/adb');
  const platform = MethodChannel('me.efesser.flauncher/method');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  var checked = false;
  var enabled = false;
  var systemOpens = 0;
  final applied = <String>[];
  Map<String, dynamic> snapshot() => {
    'status': 'ready',
    'isHome': false,
    'accessibility': enabled,
    'launchers': [],
  };
  setUp(() {
    checked = false;
    enabled = false;
    systemOpens = 0;
    applied.clear();
    messenger.setMockMethodCallHandler(platform, (call) async {
      if (call.method == 'requestAccessibilityPermission') {
        systemOpens++;
        return true;
      }
      if (call.method == 'checkAccessibilityPermission') return enabled;
      return false;
    });
    messenger.setMockMethodCallHandler(adb, (call) async {
      if (call.method == 'info') {
        return {
          'port': 5555,
          'compatibility': supportedAdbCompatibility,
          'connectionSnapshot': checked ? jsonEncode(snapshot()) : '',
        };
      }
      final action = call.arguments['action'] as String;
      switch (action) {
        case 'check':
          checked = true;
          return snapshot();
        case 'preview':
          return {
            'status': 'ready',
            'commands': ['accessibility fixture'],
          };
        case 'accessibility':
        case 'disableAccessibility':
          applied.add(action);
          enabled = action == 'accessibility';
          return {'status': 'success'};
        default:
          return {'status': 'unsupported'};
      }
    });
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(adb, null);
    messenger.setMockMethodCallHandler(platform, null);
  });

  Future<AppLocalizations> openPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AccessibilitySettingsLink()),
      ),
    );
    final l = AppLocalizations.of(
      tester.element(find.byType(AccessibilitySettingsLink)),
    )!;
    await tester.tap(find.text(l.accessibility));
    await tester.pumpAndSettle();
    expect(find.byType(AccessibilityPage), findsOneWidget);
    return l;
  }

  testWidgets(
    'Back from the guide stays in the hub, only the Android button opens settings',
    (tester) async {
      final l = await openPage(tester);
      await tester.tap(find.text(l.adbAccessibilitySettings));
      await tester.pumpAndSettle();
      expect(find.text(l.adbAccessibilityGuide), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(systemOpens, 0);
      expect(find.text(l.adbAccessibilityGuide), findsNothing);
      expect(
        Focus.of(tester.element(find.text(l.adbAccessibilitySettings)))
            .hasFocus,
        isTrue,
      );

      await tester.tap(find.text(l.adbAccessibilitySettings));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.openAndroidSettings));
      await tester.pumpAndSettle();
      expect(systemOpens, 1);
      expect(find.byType(AccessibilityPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hub checks the connection then confirms and verifies the service grant',
    (tester) async {
      final l = await openPage(tester);
      FocusableSettingsTile grant() => tester.widget(
        find
            .ancestor(
              of: find.text(l.adbEnableService),
              matching: find.byType(FocusableSettingsTile),
            )
            .first,
      );
      expect(grant().onPressed, isNull);
      await tester.tap(find.text(l.adbConnectionBlock));
      await tester.pumpAndSettle();
      expect(find.text(l.adbPort), findsOneWidget);
      await tester.tap(find.text(l.adbCheck));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(grant().onPressed, isNotNull);
      await tester.tap(find.text(l.adbEnableService));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.cancel));
      await tester.pumpAndSettle();
      expect(applied, isEmpty);
      await tester.tap(find.text(l.adbEnableService));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.dialogApply));
      await tester.pumpAndSettle();
      expect(applied, ['accessibility']);
      expect(find.text(l.adbDisableService), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
