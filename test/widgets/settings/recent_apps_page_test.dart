import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/recent_apps_page.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final pointer in [false, true]) {
    for (final opened in [false, true]) {
      testWidgets(
        'open keeps focus through return: pointer=$pointer opened=$opened',
        (tester) async {
          const channel = MethodChannel('cutelauncher/recent_apps');
          final openResponse = Completer<bool>();
          final reloadResponse = Completer<Map<String, Object>>();
          var infoCalls = 0;
          var openCalls = 0;
          const info = {'mode': 'custom', 'systemAvailable': false};
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (call) async {
              if (call.method == 'open') {
                openCalls++;
                return openResponse.future;
              }
              if (call.method == 'info') {
                return ++infoCalls == 1 ? info : reloadResponse.future;
              }
              throw StateError('Unexpected method: ${call.method}');
            },
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
          await tester.pumpWidget(
            MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: RecentAppsPage()),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(RecentAppsPage)),
          )!;
          final button = find.text(l.recentAppsOpen);
          if (pointer) {
            await tester.tap(button);
          } else {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          }
          await tester.pump();
          expect(openCalls, 1);
          expect(Focus.of(tester.element(button)).hasFocus, isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(openCalls, 1);

          openResponse.complete(opened);
          await tester.pumpAndSettle();
          expect(Focus.of(tester.element(button)).hasFocus, isTrue);
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.inactive,
          );
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.pump();
          expect(infoCalls, 2);
          expect(Focus.of(tester.element(button)).hasFocus, isTrue);
          reloadResponse.complete(info);
          await tester.pumpAndSettle();
          expect(Focus.of(tester.element(button)).hasFocus, isTrue);
          if (!opened) await tester.pump(const Duration(seconds: 5));
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  for (final code in ['recent_adb_required', 'recent_accessibility_required']) {
    testWidgets('open failure reports the missing access: $code', (
      tester,
    ) async {
      const channel = MethodChannel('cutelauncher/recent_apps');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        return switch (call.method) {
          'info' => {'mode': 'custom', 'systemAvailable': false},
          'access' => {'adb': true, 'accessibility': true},
          'open' => throw PlatformException(code: code),
          _ => throw StateError('Unexpected method: ${call.method}'),
        };
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: RecentAppsPage()),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(RecentAppsPage)),
      )!;
      final button = find.text(l.recentAppsOpen);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final adbMissing = code == 'recent_adb_required';
      expect(
        find.text(l.recentAppsAdbRequired),
        adbMissing ? findsOneWidget : findsNothing,
      );
      expect(
        find.text(l.recentAppsAccessibilityRequired),
        adbMissing ? findsNothing : findsOneWidget,
      );
      expect(find.text(l.recentAppsUnavailable), findsNothing);
      expect(Focus.of(tester.element(button)).hasFocus, isTrue);
      await tester.pump(const Duration(seconds: 5));
    });
  }

  testWidgets('accessibility shortcut opens settings from below ADB', (
    tester,
  ) async {
    const channel = MethodChannel('cutelauncher/recent_apps');
    var accessibilityGranted = false;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      switch (call.method) {
        case 'info':
          return {'mode': 'custom', 'systemAvailable': false};
        case 'access':
          return {'adb': true, 'accessibility': accessibilityGranted};
        default:
          throw StateError('Unexpected method: ${call.method}');
      }
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RecentAppsPage()),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(RecentAppsPage)))!;
    final adbShortcut = find.text(l.adbConnectionBlock).last;
    final accessibilityShortcut = find.text(l.accessibility).last;
    await tester.ensureVisible(adbShortcut);
    Focus.of(tester.element(adbShortcut)).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(accessibilityShortcut)).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AccessibilityPage), findsOneWidget);
    expect(find.text(l.adbAccessibilitySettings), findsOneWidget);
    accessibilityGranted = true;
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text(l.granted), findsOneWidget);
    expect(Focus.of(tester.element(accessibilityShortcut)).hasFocus, isTrue);
  });

  testWidgets('delayed initial load focuses the first setting', (tester) async {
    final response = Completer<Map<String, Object>>();
    const channel = MethodChannel('cutelauncher/recent_apps');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) => response.future,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RecentAppsPage()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete({'mode': 'custom', 'systemAvailable': false});
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(RecentAppsPage)))!;
    expect(
      Focus.of(tester.element(find.text(l.recentAppsPanelType))).hasFocus,
      isTrue,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text(l.recentAppsOpen))).hasFocus,
      isTrue,
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(
      Focus.of(tester.element(find.text(l.recentAppsOpen))).hasFocus,
      isTrue,
    );
  });

  testWidgets('retry recovers initial failure without leaving settings', (
    tester,
  ) async {
    var calls = 0;
    const channel = MethodChannel('cutelauncher/recent_apps');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'access') return {'adb': true, 'accessibility': true};
      if (++calls == 1) throw PlatformException(code: 'unavailable');
      return {'mode': 'custom', 'systemAvailable': false};
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RecentAppsPage()),
      ),
    );
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(RecentAppsPage)))!;
    expect(find.text(l.recentAppsUnavailable), findsOneWidget);
    await tester.tap(find.text(l.recentAppsRefresh));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text(l.recentAppsUnavailable), findsNothing);
    expect(
      tester
          .widget<SettingsChoiceTile<String>>(
            find.byType(SettingsChoiceTile<String>),
          )
          .value,
      'custom',
    );
  });
}
