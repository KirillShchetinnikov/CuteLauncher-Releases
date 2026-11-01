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
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

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
