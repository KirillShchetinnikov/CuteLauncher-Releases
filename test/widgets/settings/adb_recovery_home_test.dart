import 'dart:convert';

import 'adb_test_compatibility.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/adb_action_confirmation.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const recovery =
      'com.google.android.tungsten.setupwraith';
  testWidgets('pending recovery is accessible when CuteLauncher is not HOME', (
    tester,
  ) async {
    const adb = MethodChannel('cutelauncher/adb');
    const platform = MethodChannel('me.efesser.flauncher/method');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      platform,
      (_) async => false,
    );
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      adb,
      (call) async => {
        'port': 5555,
        'compatibility': supportedAdbCompatibility,
        'connectionSnapshot': jsonEncode({
          'status': 'ready',
          'isHome': false,
          'accessibility': false,
          'homeRecoverySaved': true,
          'restoreTarget':
              'com.google.android.apps.tv.launcherx/home.HomeActivity',
          'restoreSupported': true,
          'launchers': [],
        }),
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(adb, null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        platform,
        null,
      );
    });
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: AdbPage(section: 'launcher')),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(AdbPage)))!;
    final tile = tester.widget<FocusableSettingsTile>(
      find.ancestor(
        of: find.text(l.adbRestoreDefault),
        matching: find.byType(FocusableSettingsTile),
      ),
    );
    expect(tile.onPressed, isNotNull);
    expect(find.text(l.adbAssignDefault), findsNothing);
  });
  for (final action in ['disableSystem', 'enableSystem', 'restore']) {
    testWidgets('$action explains package recovery and defaults to cancel', (
      tester,
    ) async {
      bool? confirmed;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  confirmed = await confirmAdbAction(
                    context,
                    'Google TV',
                    action,
                    ["pm ${action == 'disableSystem' ? 'disable-user' : 'enable'} --user 0 '$recovery'"],
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.text('Open')))!;
      expect(
        find.text(
          action == 'disableSystem'
              ? l.adbRecoveryHomeDisable
              : l.adbRecoveryHomeRestore,
        ),
        findsOneWidget,
      );
      expect(find.text(l.dialogCommandDetails), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(confirmed, isFalse);
    });
  }
  testWidgets('ordinary stock disable has no setup wizard explanation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmAdbAction(
                context,
                'Android TV',
                'disableSystem',
                ["pm disable-user --user 0 'com.google.android.tvlauncher'"],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.text('Open')))!;
    expect(find.text(l.adbRecoveryHomeDisable), findsNothing);
    expect(find.text(l.adbEffectDisable), findsOneWidget);
  });
}
