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
  Completer<Map<String, Object>>? pendingMemory;
  bool memoryFails = false;
  bool ramFails = false;
  String appMemoryStatus = 'running';
  setUp(() {
    calls = [];
    mode = 'auto';
    fail = false;
    pending = null;
    pendingMemory = null;
    memoryFails = false;
    ramFails = false;
    appMemoryStatus = 'running';
    apps = [
      {'packageName': 'tv.user', 'name': 'Player', 'userApp': true},
      {'packageName': 'tv.system', 'name': 'System TV', 'userApp': false},
    ];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(recentAppsChannel, (call) async {
          calls.add(call);
          if (call.method == 'ram') {
            if (ramFails) return {'ramTotalBytes': 0, 'ramAvailableBytes': -1};
            return {
              'ramTotalBytes': 2147483648,
              'ramAvailableBytes': 536870912,
            };
          }
          if (call.method == 'memory') {
            if (memoryFails) throw PlatformException(code: 'unavailable');
            if (pendingMemory != null) return pendingMemory!.future;
            return call.arguments['packageName'] == 'tv.user'
                ? {
                    'status': appMemoryStatus,
                    if (appMemoryStatus == 'running') 'pssBytes': 299892736,
                  }
                : {'status': 'unavailable'};
          }
          if (call.method == 'cancelMemory') return null;
          if (fail) throw PlatformException(code: 'unavailable');
          if (call.method == 'access') {
            return {'adb': true, 'accessibility': true};
          }
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
    expect(
      find.byWidgetPredicate(
        (widget) => widget is LinearProgressIndicator && widget.value == null,
      ),
      findsOneWidget,
    );
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
  testWidgets('RAM uses available memory and app values stay right of names', (
    tester,
  ) async {
    await open(tester);
    expect(find.text('Used 1.50 GiB of 2.00 GiB · 75%'), findsOneWidget);
    expect(find.text('Available 512 MiB'), findsOneWidget);
    expect(find.text('≈ 286 MiB'), findsOneWidget);
    expect(find.text('No data'), findsOneWidget);
    final memory = find.text('≈ 286 MiB');
    expect(
      tester.getRect(memory).left,
      greaterThan(tester.getRect(find.text('Player')).right),
    );
    final count = calls.where((call) => call.method == 'memory').length;
    await tester.pump(const Duration(minutes: 1));
    expect(calls.where((call) => call.method == 'memory'), hasLength(count));
    await tester.tap(find.text('Refresh'));
    await tester.pumpAndSettle();
    expect(
      calls.where((call) => call.method == 'memory'),
      hasLength(count * 2),
    );
  });
  testWidgets(
    'slow RAM does not block closing apps and old values cannot return',
    (tester) async {
      pendingMemory = Completer<Map<String, Object>>();
      final old = pendingMemory!;
      await open(tester);
      expect(find.text('Player'), findsOneWidget);
      expect(find.text('Loading'), findsNWidgets(2));
      pendingMemory = null;
      await tester.tap(find.text('Close all'));
      await tester.pumpAndSettle();
      old.complete({'status': 'running', 'pssBytes': 777 * 1048576});
      await tester.pumpAndSettle();
      expect(find.text('Player'), findsNothing);
      expect(find.text('≈ 777 MiB'), findsNothing);
      expect(find.text('System TV'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('unavailable app memory preserves RAM and task actions', (
    tester,
  ) async {
    memoryFails = true;
    await open(tester);
    expect(find.text('No data'), findsNWidgets(2));
    expect(find.text('Available 512 MiB'), findsOneWidget);
    expect(find.textContaining('Open apps unavailable'), findsNothing);
    await tester.tap(find.text('Close all'));
    await tester.pumpAndSettle();
    expect(find.text('Player'), findsNothing);
  });
  for (final locale in ['en', 'ru']) {
    testWidgets(
      'unloaded app stays actionable and refresh restores RAM: $locale',
      (tester) async {
        appMemoryStatus = 'unloaded';
        await open(tester, locale: Locale(locale));
        final l = AppLocalizations.of(
          tester.element(find.byType(RecentAppsPanel)),
        )!;
        expect(find.text(l.recentRamUnloaded), findsOneWidget);
        expect(find.text(l.recentRamUnavailable), findsOneWidget);
        expect(find.text('Player'), findsOneWidget);
        appMemoryStatus = 'running';
        await tester.tap(find.text(l.recentAppsRefresh));
        await tester.pumpAndSettle();
        expect(find.text(l.recentRamUnloaded), findsNothing);
        expect(
          find.text(l.recentRamApp(l.recentRamMiB('286'))),
          findsOneWidget,
        );
        appMemoryStatus = 'unloaded';
        await tester.tap(find.text(l.recentAppsRefresh));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Player'));
        await tester.pumpAndSettle();
        expect(calls.lastWhere((call) => call.method == 'switch').arguments, {
          'packageName': 'tv.user',
        });
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('disposing cancels memory and does not query remaining apps', (
    tester,
  ) async {
    pendingMemory = Completer<Map<String, Object>>();
    await open(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    pendingMemory!.complete({'status': 'running', 'pssBytes': 123});
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'memory'), hasLength(1));
    expect(calls.where((call) => call.method == 'cancelMemory'), hasLength(1));
    expect(tester.takeException(), isNull);
  });
  testWidgets('invalid RAM has no fabricated percent and preserves app data', (
    tester,
  ) async {
    ramFails = true;
    await open(tester);
    expect(find.text('No data'), findsNWidgets(2));
    expect(find.text('≈ 286 MiB'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
  testWidgets('background stops collection and resume refreshes once', (
    tester,
  ) async {
    pendingMemory = Completer<Map<String, Object>>();
    final old = pendingMemory!;
    await open(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    old.complete({'status': 'running', 'pssBytes': 777 * 1048576});
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'memory'), hasLength(1));
    expect(find.text('≈ 777 MiB'), findsNothing);
    pendingMemory = null;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls.where((call) => call.method == 'list'), hasLength(2));
    expect(find.text('≈ 286 MiB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final locale in ['en', 'ru']) {
    testWidgets('access statuses sit below the title at large text: $locale', (
      tester,
    ) async {
      fail = true;
      await open(tester, scale: 1.8, locale: Locale(locale));
      final link = find.byKey(const ValueKey('recent-access-accessibility'));
      expect(link, findsOneWidget);
      expect(find.byKey(const ValueKey('recent-access-adb')), findsOneWidget);
      final l = AppLocalizations.of(
        tester.element(find.byType(RecentAppsPanel)),
      )!;
      final header = find.byKey(const ValueKey('recent_access_header'));
      final actions = find.byKey(const ValueKey('recent_actions'));
      expect(
        tester.getRect(header).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text(l.recentAppsTitle)).bottom,
        ),
      );
      expect(
        tester.getRect(header).bottom,
        lessThanOrEqualTo(tester.getRect(actions).top),
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('recent_list')),
          matching: header,
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
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
