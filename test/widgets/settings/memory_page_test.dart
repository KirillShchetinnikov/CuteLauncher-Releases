import 'dart:async';

import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/memory_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemoryChannel extends FLauncherChannel {
  int calls = 0;
  Future<Map<String, dynamic>> Function()? read;
  @override
  Future<Map<String, dynamic>> getProcessMemoryUsage() async {
    calls++;
    return read != null
        ? read!()
        : {
            'pssBytes': 20 * 1024 * 1024,
            'rssBytes': null,
            'graphicsBytes': 8 * 1024 * 1024,
            'measuredAtMillis': 1700000000000,
            'deviceRamBytes': 4000 * 1024 * 1024,
          };
  }
}

void main() {
  late SettingsService settings;
  late MemoryResources resources;
  late _MemoryChannel channel;
  late int cached;
  Future<void> mount(
    WidgetTester tester, {
    String locale = 'en',
    double width = 400,
    double scale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    settings = SettingsService(await SharedPreferences.getInstance());
    resources = MemoryResources(settings: settings);
    cached = 4 * 1024 * 1024;
    resources.register(
      Object(),
      clear: () => cached = 0,
      stats: () => MemoryCacheStats(cached, cached == 0 ? 0 : 4),
      breakdown: () => {
        MemoryCacheKind.appIcons: MemoryCacheStats(cached, cached == 0 ? 0 : 4),
      },
    );
    channel = _MemoryChannel();
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    addTearDown(() {
      resources.dispose();
      settings.dispose();
    });
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: resources),
        ],
        child: MaterialApp(
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: width,
                child: Navigator(
                  onGenerateRoute: (_) => MaterialPageRoute<void>(
                    builder: (_) => MemoryPage(channel: channel),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> press(WidgetTester tester, String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Key? focusedTile() => FocusManager.instance.primaryFocus?.context
      ?.findAncestorWidgetOfExactType<FocusableSettingsTile>()
      ?.key;

  testWidgets(
    'own memory, cache counts, clear comparison and economy persist',
    (tester) async {
      await mount(tester);
      expect(channel.calls, 1);
      expect(find.text('CuteLauncher memory'), findsOneWidget);
      expect(find.text('20.0 MiB'), findsOneWidget);
      expect(find.textContaining('4000'), findsNothing);
      expect(find.text('8.0 MiB'), findsNothing);
      expect(focusedTile(), const Key('memory-refresh'));
      await press(tester, 'memory-images');
      expect(find.text('4.0 MiB · Items: 4'), findsOneWidget);
      await press(tester, 'memory-clear');
      expect(cached, 0);
      expect(channel.calls, 3);
      expect(find.text('Image caches: 4.0 MiB → 0.0 MiB'), findsOneWidget);
      expect(find.text('20.0 MiB → 20.0 MiB'), findsOneWidget);
      expect(focusedTile(), const Key('memory-clear'));
      await press(tester, 'memory-economy');
      expect(settings.memorySaverEnabled, isTrue);
      expect(settings.exportSettingsMap()['memory_saver_enabled'], isTrue);
      expect(find.text('0.0 MiB / 16.0 MiB'), findsOneWidget);
      await press(tester, 'memory-advanced');
      await press(tester, 'memory-technical');
      expect(find.text('Unavailable'), findsOneWidget);
      expect(find.text('8.0 MiB'), findsOneWidget);
      final calls = channel.calls;
      await tester.pump(const Duration(minutes: 1));
      expect(channel.calls, calls);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'refresh keeps focus, rejects repeats and retains failed sample',
    (tester) async {
      await mount(tester);
      final pending = Completer<Map<String, dynamic>>();
      channel.read = () => pending.future;
      await press(tester, 'memory-refresh');
      expect(focusedTile(), const Key('memory-refresh'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(channel.calls, 2);
      pending.complete({});
      await tester.pumpAndSettle();
      expect(find.text('20.0 MiB'), findsOneWidget);
      expect(
        find.text(
          'Could not update memory. The previous measurement is shown.',
        ),
        findsOneWidget,
      );
      expect(focusedTile(), const Key('memory-refresh'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(focusedTile(), const Key('memory-images'));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('observation stops on collapse, background and disposal', (
    tester,
  ) async {
    await mount(tester);
    await press(tester, 'memory-advanced');
    await press(tester, 'memory-observation');
    await press(tester, 'memory-observe-toggle');
    final calls = channel.calls;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(channel.calls, calls + 1);
    await press(tester, 'memory-observation');
    final collapsed = channel.calls;
    await tester.pump(const Duration(seconds: 10));
    expect(channel.calls, collapsed);
    await press(tester, 'memory-observation');
    await press(tester, 'memory-observe-toggle');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    final paused = channel.calls;
    await tester.pump(const Duration(seconds: 10));
    expect(channel.calls, paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 10));
    expect(channel.calls, paused);
    await press(tester, 'memory-observe-toggle');
    final closing = channel.calls;
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
    expect(channel.calls, closing);
  });

  testWidgets(
    'covering the route stops sampling without restarting on return',
    (tester) async {
      await mount(tester);
      await press(tester, 'memory-advanced');
      await press(tester, 'memory-observation');
      await press(tester, 'memory-observe-toggle');
      final navigator = Navigator.of(tester.element(find.byType(MemoryPage)));
      unawaited(
        navigator.push(
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Other page')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final calls = channel.calls;
      await tester.pump(const Duration(seconds: 15));
      expect(channel.calls, calls);
      navigator.pop();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 15));
      expect(channel.calls, calls);
      expect(find.text('Observe for 1 minute'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in ['ru', 'en', 'ar']) {
    testWidgets('narrow panel and large $locale text do not overflow', (
      tester,
    ) async {
      await mount(tester, locale: locale, width: 320, scale: 1.5);
      expect(tester.takeException(), isNull);
      for (final key in [
        'memory-images',
        'memory-advanced',
        'memory-technical',
        'memory-observation',
        'memory-observe-toggle',
      ]) {
        await press(tester, key);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'advanced menu contains moved sections and Back restores opener',
    (tester) async {
      await mount(tester);
      expect(find.byKey(const Key('memory-observation')), findsNothing);
      expect(find.byKey(const Key('memory-technical')), findsNothing);
      expect(find.text('Understanding the measurements'), findsNothing);
      expect(find.text('What memory saving changes'), findsOneWidget);
      await press(tester, 'memory-images');
      await press(tester, 'memory-advanced');
      expect(find.text('Advanced diagnostics'), findsOneWidget);
      expect(find.text('What memory saving changes'), findsNothing);
      expect(find.byKey(const Key('memory-primary')), findsNothing);
      expect(find.text('Understanding the measurements'), findsOneWidget);
      expect(focusedTile(), const Key('memory-observation'));
      await press(tester, 'memory-observation');
      await press(tester, 'memory-observe-toggle');
      final navigator = Navigator.of(tester.element(find.byType(MemoryPage)));
      await navigator.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('CuteLauncher memory'), findsOneWidget);
      expect(focusedTile(), const Key('memory-advanced'));
      expect(find.text('4.0 MiB · Items: 4'), findsOneWidget);
      final calls = channel.calls;
      await tester.pump(const Duration(seconds: 15));
      expect(channel.calls, calls);
      await press(tester, 'memory-advanced');
      expect(find.text('Recording · up to 1 minute'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
