import 'dart:async';
import 'dart:io';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/daily_data_usage_widget.dart';

import '../mocks.mocks.dart';

void main() {
  testWidgets('periodic wallpaper must respect occupied foreground queue', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      onlineWallpaperKey: const OnlineWallpaperConfiguration(
        enabled: true,
        url: 'https://example.invalid/a.png',
        intervalHours: 1,
      ).encode(),
    });
    late OnlineWallpaperService service;
    late Directory root;
    final work = ForegroundWork()..homeReady();
    final held = Completer<void>();
    work.schedule(Object(), () => held.future, delay: Duration.zero);
    work.schedule(Object(), () => held.future, delay: Duration.zero);
    var downloads = 0;
    final preferences = await SharedPreferences.getInstance();
    await tester.runAsync(() async {
      root = await Directory.systemTemp.createTemp('cute-reaudit-');
    });
    service = OnlineWallpaperService(
      preferences,
      work: work,
      directory: () async => root,
      download: (_) async {
        downloads++;
        throw const SocketException('probe');
      },
    );
    await tester.pump();
    expect(service.initialized, isTrue);
    await tester.pump(const Duration(hours: 1));
    final foregroundDownloads = downloads;
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pump(const Duration(hours: 1));
    expect(
      downloads,
      foregroundDownloads,
      reason: 'Background correctly stops timer',
    );
    service.dispose();
    work.dispose();
    held.complete();
    await tester.pump();
    await tester.runAsync(() => root.delete(recursive: true));
    expect(
      foregroundDownloads,
      0,
      reason: 'Automatic download must wait for available ForegroundWork slot',
    );
  });

  testWidgets(
    'weekly counter must not refetch on unrelated settings notification',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setDataUsagePeriod('weekly');
      final channel = MockFLauncherChannel();
      when(channel.addNetworkChangedListener(any)).thenReturn(null);
      when(channel.getActiveNetworkInformation()).thenAnswer((_) async => {});
      when(channel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      when(channel.getDailyDataUsage()).thenAnswer((_) async => 100);
      var reads = 0, sample = 500;
      when(channel.getWeeklyDataUsage()).thenAnswer((_) async {
        reads++;
        return sample;
      });
      when(channel.getMonthlyDataUsage()).thenAnswer((_) async => 900);
      final network = NetworkService(channel, now: tester.binding.clock.now);
      await network.initialLoad;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NetworkService>.value(value: network),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Column(
                children: [DailyDataUsageWidget(), DailyDataUsageWidget()],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final initial = reads;
      await tester.pump(const Duration(seconds: 31));
      await settings.setShowContinueWatching(false);
      await tester.pumpAndSettle();
      final extra = reads - initial;
      expect(extra, 0, reason: 'No read on unrelated rebuild after cache TTL');
      sample = 600;
      await tester.pump(const Duration(minutes: 4, seconds: 29));
      await tester.pumpAndSettle();
      expect(
        reads,
        2,
        reason: 'Periodic updates weekly even when daily stays 100',
      );
      expect(
        find.textContaining('600.00 B', findRichText: true),
        findsNWidgets(2),
      );
      await settings.setDataUsagePeriod('monthly');
      await tester.pumpAndSettle();
      expect(
        find.textContaining('900.00 B', findRichText: true),
        findsNWidgets(2),
      );
      await tester.pump(const Duration(minutes: 5));
      await tester.pumpAndSettle();
      expect(
        reads,
        2,
        reason: 'No weekly poll after both consumers switched period',
      );
      final interrupted = Completer<int>();
      when(channel.getWeeklyDataUsage()).thenAnswer((_) => interrupted.future);
      await settings.setDataUsagePeriod('weekly');
      await tester.pumpAndSettle();
      network.didChangeAppLifecycleState(AppLifecycleState.paused);
      interrupted.complete(600);
      await tester.pumpAndSettle();
      expect(find.textContaining('600.00 B', findRichText: true), findsNothing);
      when(channel.getWeeklyDataUsage()).thenAnswer((_) async => 600);
      network.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('600.00 B', findRichText: true),
        findsNWidgets(2),
        reason: 'Resume restores interrupted presentation even when cached numbers are unchanged',
      );
      await tester.pumpWidget(const SizedBox());
      network.dispose();
      settings.dispose();
      expect(initial, 1, reason: 'Two counters share one period read');
      expect(
        extra,
        0,
        reason: 'Unrelated setting must not issue new native traffic reads',
      );
    },
  );

  test('period caches share reads, expire independently, force, and discard revoked replies', () {
    fakeAsync((time) {
      final channel = MockFLauncherChannel();
      when(channel.addNetworkChangedListener(any)).thenReturn(null);
      when(channel.getActiveNetworkInformation()).thenAnswer((_) async => {});
      when(channel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      var daily = 0, weekly = 0, monthly = 0;
      when(channel.getDailyDataUsage()).thenAnswer((_) async => ++daily);
      when(channel.getWeeklyDataUsage()).thenAnswer((_) async => 10 * ++weekly);
      when(channel.getMonthlyDataUsage())
          .thenAnswer((_) async => 100 * ++monthly);
      final service = NetworkService(
        channel,
        now: () => DateTime(2026).add(time.elapsed),
      );
      time.flushMicrotasks();
      final values = <int>[];
      for (final period in ['daily', 'weekly', 'monthly']) {
        service.getDataUsageForPeriod(period).then(values.add);
        service.getDataUsageForPeriod(period).then(values.add);
      }
      time.flushMicrotasks();
      expect(values, [1, 1, 10, 10, 100, 100]);
      expect([daily, weekly, monthly], [1, 1, 1]);
      service.getDataUsageForPeriod('weekly');
      time.flushMicrotasks();
      expect(weekly, 1);
      service.getDataUsageForPeriod('weekly', force: true);
      time.flushMicrotasks();
      expect(weekly, 2);
      time.elapse(const Duration(seconds: 31));
      service.getDataUsageForPeriod('monthly');
      time.flushMicrotasks();
      expect(monthly, 2);
      when(channel.getMonthlyDataUsage())
          .thenAnswer((_) async => throw StateError('offline'));
      int? failed;
      service
          .getDataUsageForPeriod('monthly', force: true)
          .then((value) => failed = value);
      time.flushMicrotasks();
      expect(failed, -1);
      service.getDataUsageForPeriod('weekly').then((value) => failed = value);
      time.flushMicrotasks();
      expect(failed, 30);
      final pending = Completer<int>();
      when(channel.getWeeklyDataUsage()).thenAnswer((_) => pending.future);
      service
          .getDataUsageForPeriod('weekly', force: true)
          .then((value) => failed = value);
      time.flushMicrotasks();
      when(channel.checkUsageStatsPermission()).thenAnswer((_) async => false);
      service.refreshPermissionAndUsage();
      time.flushMicrotasks();
      pending.complete(999);
      time.flushMicrotasks();
      expect(failed, -1);
      service.getDataUsageForPeriod('monthly').then((value) => failed = value);
      time.flushMicrotasks();
      expect(failed, -1);
      service.dispose();
    });
  });

  test('automatic weekly reads wait for input and cancel when owner hides', () {
    fakeAsync((time) {
      final channel = MockFLauncherChannel();
      when(channel.addNetworkChangedListener(any)).thenReturn(null);
      when(channel.getActiveNetworkInformation()).thenAnswer((_) async => {});
      when(channel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      when(channel.getDailyDataUsage()).thenAnswer((_) async => 1);
      when(channel.getWeeklyDataUsage()).thenAnswer((_) async => 10);
      DateTime now() => DateTime(2026).add(time.elapsed);
      final work = ForegroundWork(now: now)..homeReady();
      final service = NetworkService(channel, now: now, work: work);
      time.elapse(const Duration(milliseconds: 350));
      final owner = Object();
      service.setTrafficVisible(owner, true, period: 'weekly');
      work.deferForInput();
      int? result;
      service.getDataUsageForPeriod('weekly').then((value) => result = value);
      time.elapse(const Duration(milliseconds: 349));
      verifyNever(channel.getWeeklyDataUsage());
      service.setTrafficVisible(owner, false);
      time.elapse(const Duration(seconds: 1));
      verifyNever(channel.getWeeklyDataUsage());
      expect(result, -1);
      service
          .getDataUsageForPeriod('weekly', force: true)
          .then((value) => result = value);
      time.flushMicrotasks();
      expect(result, 10);
      service.dispose();
      work.dispose();
    });
  });

  test(
    'resume waits for obsolete native period read then obtains a fresh value',
    () {
      fakeAsync((time) {
        final channel = MockFLauncherChannel();
        when(channel.addNetworkChangedListener(any)).thenReturn(null);
        when(channel.getActiveNetworkInformation()).thenAnswer((_) async => {});
        when(channel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        final old = Completer<int>();
        var reads = 0;
        when(channel.getWeeklyDataUsage()).thenAnswer((_) {
          reads++;
          return reads == 1 ? old.future : Future.value(20);
        });
        final service = NetworkService(channel);
        time.flushMicrotasks();
        service.getDataUsageForPeriod('weekly');
        time.flushMicrotasks();
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        int? value;
        service.getDataUsageForPeriod('weekly').then((next) => value = next);
        time.flushMicrotasks();
        expect(reads, 1);
        old.complete(999);
        time.flushMicrotasks();
        expect(value, 20);
        expect(reads, 2);
        service.dispose();
      });
    },
  );

  testWidgets(
    'periodic wallpaper waits for input; explicit force stays immediate',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        onlineWallpaperKey: const OnlineWallpaperConfiguration(
          enabled: true,
          url: 'https://example.invalid/a.png',
          intervalHours: 1,
        ).encode(),
      });
      final preferences = await SharedPreferences.getInstance();
      late Directory root;
      await tester.runAsync(() async {
        root = await Directory.systemTemp.createTemp('cute-refresh-');
      });
      final work = ForegroundWork(now: tester.binding.clock.now)..homeReady();
      var downloads = 0;
      final service = OnlineWallpaperService(
        preferences,
        work: work,
        clock: tester.binding.clock.now,
        directory: () async => root,
        download: (_) async {
          downloads++;
          throw const SocketException('offline');
        },
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(downloads, 1);
      await tester.pump(const Duration(minutes: 59, seconds: 59));
      await tester.pump(const Duration(milliseconds: 900));
      work.deferForInput();
      await tester.pump(const Duration(milliseconds: 100));
      expect(downloads, 1);
      await tester.pump(const Duration(milliseconds: 250));
      expect(downloads, 2);
      final held = Completer<void>();
      work.schedule(Object(), () => held.future, delay: Duration.zero);
      work.schedule(Object(), () => held.future, delay: Duration.zero);
      await tester.pump();
      await service.refresh(force: true);
      expect(downloads, 3);
      service.dispose();
      work.dispose();
      held.complete();
      await tester.pump();
      await tester.runAsync(() => root.delete(recursive: true));
    },
  );
}
