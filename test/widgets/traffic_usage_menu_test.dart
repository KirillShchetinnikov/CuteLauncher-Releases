import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/traffic_settings_page.dart';
import 'package:flauncher/widgets/traffic_usage_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';
import '../flauncher_test.dart' as fixture;

void main() {
  late SettingsService settings;
  late MockNetworkService network;
  setUp(() {
    settings = fixture.mkSettingsService();
    network = MockNetworkService();
    when(settings.dataUsagePeriod).thenReturn('daily');
    when(network.hasUsageStatsPermission).thenReturn(true);
    when(network.getTrafficUsage(any)).thenAnswer((call) async {
      final multiplier = switch (call.positionalArguments.single) {
        'weekly' => 10,
        'monthly' => 100,
        _ => 1,
      };
      return {
        'rxBytes': 2048 * multiplier,
        'txBytes': 1024 * multiplier,
        'totalBytes': 3072 * multiplier,
      };
    });
  });

  Future<void> pump(
    WidgetTester tester, {
    double scale = 1,
    Size size = const Size(960, 540),
    bool settle = true,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsService>.value(value: settings),
          ChangeNotifierProvider<NetworkService>.value(value: network),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showLauncherDialog<void>(
                  context: context,
                  styleDialog: false,
                  builder: (_) => const TrafficUsageMenu(
                    anchor: Rect.fromLTWH(40, 0, 80, 56),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 500));
    }
  }

  testWidgets(
    'shows day, week and month independently and restores gear focus after settings',
    (tester) async {
      await pump(tester);
      expect(find.text('Получено'), findsNWidgets(3));
      expect(find.text('Отправлено'), findsNWidgets(3));
      expect(find.text('Всего'), findsNWidgets(3));
      expect(find.text('2.00 KB'), findsOneWidget);
      expect(find.text('1.00 KB'), findsOneWidget);
      expect(find.text('3.00 KB'), findsOneWidget);
      expect(find.text('20.00 KB'), findsOneWidget);
      expect(find.text('30.00 KB'), findsOneWidget);
      expect(find.text('200.00 KB'), findsOneWidget);
      expect(find.text('300.00 KB'), findsOneWidget);
      for (final period in ['daily', 'weekly', 'monthly']) {
        verify(network.getTrafficUsage(period)).called(1);
      }
      await tester.tap(find.byType(MenuHeaderAction));
      await tester.pumpAndSettle();
      expect(find.byType(TrafficSettingsPage), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPanel), findsNothing);
      expect(
        tester
            .widget<MenuHeaderAction>(find.byType(MenuHeaderAction))
            .focusNode!
            .hasFocus,
        true,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('period cards fit without scrolling and pair receive with send', (
    tester,
  ) async {
    await pump(tester);
    final scroll = find.descendant(
      of: find.byType(TrafficUsageMenu),
      matching: find.byType(Scrollable),
    );
    expect(tester.state<ScrollableState>(scroll).position.maxScrollExtent, 0);
    for (final period in ['daily', 'weekly', 'monthly']) {
      final card = find.byKey(ValueKey('traffic_$period'));
      expect(tester.getSize(card).height, lessThan(120));
      final decoration =
          tester.widget<Container>(card).decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
      expect(decoration.color, isNot(Colors.transparent));
      final received = find.descendant(
        of: card,
        matching: find.text('Получено'),
      );
      final sent = find.descendant(of: card, matching: find.text('Отправлено'));
      expect(tester.getTopLeft(received).dy, tester.getTopLeft(sent).dy);
      expect(
        tester.getTopLeft(sent).dx,
        greaterThan(tester.getTopLeft(received).dx),
      );
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('zero is measured traffic; unavailable is not zero', (
    tester,
  ) async {
    when(
      network.getTrafficUsage(any),
    ).thenAnswer((_) async => {'rxBytes': 0, 'txBytes': -2, 'totalBytes': -2});
    await pump(tester);
    expect(find.text('0 B'), findsNWidgets(3));
    expect(find.text('—'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('periods load and fail independently of the toolbar period', (
    tester,
  ) async {
    when(settings.dataUsagePeriod).thenReturn('weekly');
    final monthly = Completer<Map<String, dynamic>>();
    when(network.getTrafficUsage('weekly'))
        .thenAnswer((_) async => throw StateError('unavailable'));
    when(network.getTrafficUsage('monthly')).thenAnswer((_) => monthly.future);
    await pump(tester, settle: false);
    await tester.pump();
    Finder inPeriod(String period, Finder matching) => find.descendant(
      of: find.byKey(ValueKey('traffic_$period')),
      matching: matching,
    );
    expect(inPeriod('daily', find.text('3.00 KB')), findsOneWidget);
    final l = AppLocalizations.of(
      tester.element(find.byType(TrafficUsageMenu)),
    )!;
    expect(inPeriod('weekly', find.text(l.networkReadFailed)), findsOneWidget);
    expect(
      inPeriod('monthly', find.byType(LinearProgressIndicator)),
      findsOneWidget,
    );
    monthly.complete({'rxBytes': 100, 'txBytes': 200, 'totalBytes': 300});
    await tester.pumpAndSettle();
    expect(inPeriod('monthly', find.text('300 B')), findsOneWidget);
    expect(inPeriod('daily', find.text('3.00 KB')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'large traffic menu scrolls with the remote while keeping gear focus',
    (tester) async {
      await pump(tester, scale: 3, size: const Size(640, 360));
      final scroll = find.descendant(
        of: find.byType(TrafficUsageMenu),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scroll).position;
      expect(position.maxScrollExtent, greaterThan(0));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(position.pixels, greaterThan(0));
      expect(
        tester
            .widget<MenuHeaderAction>(find.byType(MenuHeaderAction))
            .focusNode!
            .hasFocus,
        true,
      );
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(TrafficUsageMenu), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'query failure stays recoverable through settings; late reply after closing is ignored',
    (tester) async {
      when(network.getTrafficUsage(any))
          .thenAnswer((_) async => throw StateError('offline'));
      await pump(tester);
      expect(find.byType(MenuHeaderAction), findsOneWidget);
      expect(find.text('0 B'), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final pending = Completer<Map<String, dynamic>>();
      when(network.getTrafficUsage(any)).thenAnswer((_) => pending.future);
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      pending.complete({'rxBytes': 1, 'txBytes': 2, 'totalBytes': 3});
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
