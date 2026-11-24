import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/recent_apps_client.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flauncher/widgets/recent_apps_access.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var adb = false, accessibility = false, fail = false;
  final calls = <MethodCall>[];
  Completer<Map<String, bool>>? pending;
  setUp(() {
    adb = accessibility = fail = false;
    pending = null;
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recentAppsChannel, (call) async {
          calls.add(call);
          if (fail) throw PlatformException(code: 'unavailable');
          if (call.method == 'access') {
            return pending?.future ??
                Future.value({'adb': adb, 'accessibility': accessibility});
          }
          throw StateError('Unexpected method ${call.method}');
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recentAppsChannel, null),
  );
  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: RecentAppsAccess()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final connected in [false, true]) {
    for (final granted in [false, true]) {
      testWidgets(
        'statuses and setup links: adb=$connected accessibility=$granted',
        (tester) async {
          adb = connected;
          accessibility = granted;
          await mount(tester);
          expect(
            find.byKey(const ValueKey('recent-access-adb')),
            connected ? findsNothing : findsOneWidget,
          );
          expect(
            find.byKey(const ValueKey('recent-access-accessibility')),
            granted ? findsNothing : findsOneWidget,
          );
          expect(calls.where((call) => call.method == 'access'), hasLength(1));
          await tester.pump(const Duration(seconds: 30));
          expect(calls, hasLength(1));
          if (!granted) {
            await tester.tap(
              find.byKey(const ValueKey('recent-access-accessibility')),
            );
            await tester.pumpAndSettle();
            expect(find.byType(AccessibilityPage), findsOneWidget);
            expect(calls.where((call) => call.method == 'setup'), isEmpty);
          }
        },
      );
    }
  }

  testWidgets('return to settings rechecks access', (tester) async {
    await mount(tester);
    adb = accessibility = true;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('recent-access-adb')), findsNothing);
    expect(calls.where((call) => call.method == 'access'), hasLength(2));
  });

  testWidgets(
    'return from the accessibility hub refreshes the status', (tester) async {
      await mount(tester);
      final link = find.byKey(const ValueKey('recent-access-accessibility'));
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(AccessibilityPage), findsOneWidget);
      accessibility = true;
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(link, findsNothing);
      expect(calls.where((call) => call.method == 'access'), hasLength(2));
    },
  );

  testWidgets('settings link opens the local ADB connection page', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(find.byKey(const ValueKey('recent-access-adb')));
    await tester.pumpAndSettle();
    expect(find.byType(AdbPage), findsOneWidget);
    expect(tester.widget<AdbPage>(find.byType(AdbPage)).section, 'connection');
    expect(calls.where((call) => call.method == 'setup'), isEmpty);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byType(RecentAppsAccess), findsOneWidget);
  });

  testWidgets(
    'unknown access keeps setup links and late response is harmless',
    (tester) async {
      fail = true;
      await mount(tester);
      expect(find.byKey(const ValueKey('recent-access-adb')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('recent-access-accessibility')),
        findsOneWidget,
      );
      fail = false;
      pending = Completer();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: const RecentAppsAccess(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending!.complete({'adb': true, 'accessibility': true});
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
