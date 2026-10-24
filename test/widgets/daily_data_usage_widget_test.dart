import 'dart:async';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/daily_data_usage_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  late MockNetworkService mockNetworkService;
  late MockSettingsService mockSettingsService;

  setUp(() {
    mockNetworkService = MockNetworkService();
    mockSettingsService = MockSettingsService();
    // Default fallback mock
    when(mockNetworkService.dailyDataUsage).thenReturn(0);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NetworkService>.value(value: mockNetworkService),
        ChangeNotifierProvider<SettingsService>.value(
          value: mockSettingsService,
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(body: DailyDataUsageWidget()),
        ),
      ),
    );
  }

  testWidgets('hides counter and never requests permission from the panel', (
    tester,
  ) async {
    when(mockNetworkService.hasUsageStatsPermission).thenReturn(false);
    await tester.pumpWidget(createWidgetUnderTest());
    expect(find.text('Grant Usage Permission'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(RichText), findsNothing);
    verifyNever(mockNetworkService.requestPermission());
    verifyNever(mockNetworkService.getDataUsageForPeriod(any));
  });
  testWidgets(
    'displays daily usage when permission granted and period is daily',
    (WidgetTester tester) async {
      when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
      when(mockSettingsService.dataUsagePeriod).thenReturn('daily');
      when(mockNetworkService.getDataUsageForPeriod('daily'))
          .thenAnswer((_) async => 1024 * 1024 * 5); // 5 MB

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect((span.children![0] as TextSpan).text, 'Daily: ');
      expect((span.children![1] as TextSpan).text, '5.00 MB');
    },
  );

  testWidgets(
    'displays weekly usage when permission granted and period is weekly',
    (WidgetTester tester) async {
      when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
      when(mockSettingsService.dataUsagePeriod).thenReturn('weekly');
      when(mockNetworkService.getDataUsageForPeriod('weekly'))
          .thenAnswer((_) async => 1024 * 1024 * 1024 * 2); // 2 GB

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect((span.children![0] as TextSpan).text, 'Weekly: ');
      expect((span.children![1] as TextSpan).text, '2.00 GB');
    },
  );

  testWidgets(
    'displays monthly usage when permission granted and period is monthly',
    (WidgetTester tester) async {
      when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
      when(mockSettingsService.dataUsagePeriod).thenReturn('monthly');
      when(mockNetworkService.getDataUsageForPeriod('monthly'))
          .thenAnswer((_) async => 1024 * 500); // 500 KB

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect((span.children![0] as TextSpan).text, 'Monthly: ');
      expect((span.children![1] as TextSpan).text, '500.00 KB');
    },
  );

  testWidgets(
    'falls back to networkService.dailyDataUsage if future data is null',
    (WidgetTester tester) async {
      when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
      when(mockSettingsService.dataUsagePeriod).thenReturn('daily');
      // Provide a mocked future that completes but isn't instantly available
      when(mockNetworkService.getDataUsageForPeriod('daily'))
          .thenAnswer((_) => Future.value(1024));
      when(mockNetworkService.dailyDataUsage).thenReturn(2048);

      await tester.pumpWidget(createWidgetUnderTest());

      // Wait for future to complete
      await tester.pumpAndSettle();

      expect(find.byType(RichText), findsOneWidget);
      final richText = tester.widget<RichText>(find.byType(RichText));
      final span = richText.text as TextSpan;
      expect((span.children![1] as TextSpan).text, '1.00 KB');
    },
  );

  testWidgets('formats 0 bytes correctly', (WidgetTester tester) async {
    when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
    when(mockSettingsService.dataUsagePeriod).thenReturn('daily');
    when(mockNetworkService.getDataUsageForPeriod('daily'))
        .thenAnswer((_) async => 0);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.byType(RichText), findsOneWidget);
    final richText = tester.widget<RichText>(find.byType(RichText));
    final span = richText.text as TextSpan;
    expect((span.children![1] as TextSpan).text, '0 B');
  });

  for (final period in ['weekly', 'monthly']) {
    testWidgets('$period never falls back to daily usage on loading or error', (tester) async {
      final result = Completer<int>();
      when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
      when(mockSettingsService.dataUsagePeriod).thenReturn(period);
      when(mockNetworkService.dailyDataUsage).thenReturn(5 * 1024 * 1024);
      when(mockNetworkService.getDataUsageForPeriod(period)).thenAnswer((_) => result.future);
      await tester.pumpWidget(createWidgetUnderTest());
      String value() => (tester.widget<RichText>(find.byType(RichText)).text as TextSpan)
          .children!.last.toPlainText();
      expect(value(), '—');
      result.completeError(StateError('Statistics unavailable'));
      await tester.pumpAndSettle();
      expect(value(), '—');
    });
  }

  testWidgets('daily loading shows unknown rather than an initial zero', (
    tester,
  ) async {
    when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
    when(mockNetworkService.dailyDataUsage).thenReturn(-1);
    when(mockSettingsService.dataUsagePeriod).thenReturn('daily');
    final pending = Completer<int>();
    when(mockNetworkService.getDataUsageForPeriod('daily'))
        .thenAnswer((_) => pending.future);
    await tester.pumpWidget(createWidgetUnderTest());
    expect(
      tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
      'Daily: —',
    );
    pending.complete(-2);
    await tester.pumpAndSettle();
    expect(
      tester.widget<RichText>(find.byType(RichText)).text.toPlainText(),
      'Daily: —',
    );
  });

  testWidgets('unavailable native result is not displayed as zero usage', (tester) async {
    when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
    when(mockSettingsService.dataUsagePeriod).thenReturn('monthly');
    when(mockNetworkService.getDataUsageForPeriod('monthly')).thenAnswer((_) async => -1);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(tester.widget<RichText>(find.byType(RichText)).text.toPlainText(), 'Monthly: —');
  });

  testWidgets('changing period does not retain previous period data', (tester) async {
    when(mockNetworkService.hasUsageStatsPermission).thenReturn(true);
    when(mockSettingsService.dataUsagePeriod).thenReturn('daily');
    when(mockNetworkService.getDataUsageForPeriod('daily')).thenAnswer((_) async => 1024);
    final monthly = Completer<int>();
    when(mockNetworkService.getDataUsageForPeriod('monthly')).thenAnswer((_) => monthly.future);
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();
    expect(tester.widget<RichText>(find.byType(RichText)).text.toPlainText(), 'Daily: 1.00 KB');
    when(mockSettingsService.dataUsagePeriod).thenReturn('monthly');
    await tester.pumpWidget(createWidgetUnderTest());
    expect(tester.widget<RichText>(find.byType(RichText)).text.toPlainText(), 'Monthly: —');
    monthly.complete(2048);
    await tester.pumpAndSettle();
    expect(tester.widget<RichText>(find.byType(RichText)).text.toPlainText(), 'Monthly: 2.00 KB');
  });
}
