import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/recent_apps_client.dart';
import 'package:flauncher/widgets/recent_apps_panel.dart';
import 'package:flauncher/widgets/settings/recent_apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late List<MethodCall> calls;
  late List<Map<String, Object>> apps;
  late String mode;
  bool fail = false;
  Completer<Map<String, Object>>? pending;
  setUp(() {
    calls = [];
    mode = 'auto';
    fail = false;
    pending = null;
    apps = [
      {'packageName': 'tv.user', 'name': 'Player', 'userApp': true},
      {'packageName': 'tv.system', 'name': 'System TV', 'userApp': false},
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recentAppsChannel, (call) async {
          calls.add(call);
          if (fail) throw PlatformException(code: 'unavailable');
          if (call.method == 'info') {
            return {
              'mode': mode,
              'systemAvailable': false,
              'accessibility': true,
            };
          }
          if (call.method == 'mode') {
            mode = call.arguments as String;
            return true;
          }
          if (call.method == 'open') return true;
          if (call.method == 'icon') return null;
          if (call.method == 'closeAll') {
            if (pending != null) return pending!.future;
            apps.removeWhere((app) => app['userApp'] == true);
          }
          if (call.method == 'close') {
            apps.removeWhere(
              (app) => app['packageName'] == call.arguments['packageName'],
            );
          }
          return {'status': 'success', 'apps': apps};
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/remote_panel'),
          (_) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recentAppsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/remote_panel'),
          null,
        );
  });
  Future<void> open(
    WidgetTester tester, {
    Widget child = const RecentAppsPanel(),
    double scale = 1,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(body: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('close all sends one bounded request and preserves system apps', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Player'), findsOneWidget);
    pending = Completer();
    await tester.tap(find.text('Close all'));
    await tester.pump();
    expect(calls.where((call) => call.method == 'closeAll'), hasLength(1));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    pending!.complete({
      'status': 'success',
      'apps': [apps.last],
    });
    await tester.pumpAndSettle();
    expect(find.text('Player'), findsNothing);
    expect(find.text('System TV'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('operation restores the surviving action focus', (tester) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    final previousFocus = FocusManager.instance.primaryFocus;
    pending = Completer();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(calls.where((call) => call.method == 'closeAll'), hasLength(1));
    pending!.complete({'status': 'partial', 'apps': apps});
    await tester.pumpAndSettle();
    expect(FocusManager.instance.primaryFocus, same(previousFocus));
    expect(tester.takeException(), isNull);
  });
  testWidgets('switch targets the selected package, Back closes the window', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls.lastWhere((call) => call.method == 'switch').arguments, {
      'packageName': 'tv.user',
    });
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'ADB failure is visible and refresh retries without losing window controls',
    (tester) async {
      fail = true;
      await open(tester);
      expect(find.textContaining('Open apps unavailable'), findsOneWidget);
      fail = false;
      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(find.text('Player'), findsOneWidget);
      expect(find.textContaining('Open apps unavailable'), findsNothing);
    },
  );
  testWidgets('late completion after close is harmless', (tester) async {
    await open(tester);
    pending = Completer();
    await tester.tap(find.text('Close all'));
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    pending!.complete({'status': 'success', 'apps': <Object>[]});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['en', 'ru']) {
    testWidgets('panel fits TV at large text: $locale', (tester) async {
      await open(tester, scale: 1.8, locale: Locale(locale));
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('missing OEM component is not offered as a new selection', (
    tester,
  ) async {
    await open(tester, child: const RecentAppsPage());
    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle();
    expect(find.text('Built-in panel'), findsNothing);
    expect(find.text('CuteLauncher panel'), findsOneWidget);
  });
  testWidgets('settings save the mode without changing remapper assignments', (
    tester,
  ) async {
    await open(tester, child: const RecentAppsPage());
    await tester.tap(find.text('Panel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('CuteLauncher panel'));
    await tester.pumpAndSettle();
    expect(mode, 'custom');
    expect(calls.where((call) => call.method == 'mode'), hasLength(1));
    await tester.tap(find.text('Open panel'));
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'open'), hasLength(1));
  });
}
