import 'dart:async';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockFLauncherChannel mockChannel;
  late NetworkService networkService;

  setUp(() {
    mockChannel = MockFLauncherChannel();
    when(mockChannel.addNetworkChangedListener(any)).thenReturn(null);
    when(mockChannel.getActiveNetworkInformation())
        .thenAnswer((_) async => <String, dynamic>{});
    when(mockChannel.checkUsageStatsPermission())
        .thenAnswer((_) async => false);
    when(mockChannel.addNetworkChangedListener(any)).thenReturn(null);
    networkService = NetworkService(mockChannel);
  });

  tearDown(() {
    networkService.dispose();
  });

  test('a late startup snapshot cannot overwrite a newer network event', () async {
    final snapshot = Completer<Map<String, dynamic>>();
    late void Function(Map<String, dynamic>) changed;
    when(mockChannel.addNetworkChangedListener(any)).thenAnswer((call) {
      changed = call.positionalArguments.single;
      return null;
    });
    when(mockChannel.getActiveNetworkInformation()).thenAnswer((_) => snapshot.future);
    final service = NetworkService(mockChannel);
    addTearDown(service.dispose);
    changed({'name': 'NETWORK_UNAVAILABLE'});
    snapshot.complete({
      'networkType': NetworkType.Wifi.index,
      'internetAccess': true,
      'wirelessSignalLevel': 4,
      'vpnActive': true,
    });
    await service.initialNetworkLoad;
    expect(service.hasInternetAccess, isFalse);
    expect(service.networkType, NetworkType.Unknown);
    expect(service.vpnActive, isFalse);
  });

  test('unknown cellular types stay unknown without throwing', () async {
    late void Function(Map<String, dynamic>) changed;
    when(mockChannel.addNetworkChangedListener(any)).thenAnswer((call) {
      changed = call.positionalArguments.single;
      return null;
    });
    final service = NetworkService(mockChannel);
    addTearDown(service.dispose);
    await service.initialLoad;
    for (final value in [-1, 99, null, 'LTE']) {
      expect(() => changed({'name': 'CELLULAR_STATE_CHANGED', 'arguments': value}), returnsNormally);
      expect(service.cellularNetworkType, CellularNetworkType.Unknown);
    }
  });

  test('repeated network events notify only when displayed state changes', () async {
    late void Function(Map<String, dynamic>) changed;
    when(mockChannel.addNetworkChangedListener(any)).thenAnswer((call) {
      changed = call.positionalArguments.single;
      return null;
    });
    final service = NetworkService(mockChannel);
    addTearDown(service.dispose);
    await service.initialLoad;
    var notifications = 0;
    service.addListener(() => notifications++);
    final wifi = {
      'networkType': NetworkType.Wifi.index,
      'internetAccess': true,
      'wirelessSignalLevel': 3,
      'vpnActive': false,
    };
    changed({'name': 'NETWORK_AVAILABLE', 'arguments': wifi});
    for (var i = 0; i < 20; i++) {
      changed({'name': 'CAPABILITIES_CHANGED', 'arguments': Map.of(wifi)});
    }
    expect(notifications, 1);
    changed({'name': 'CELLULAR_STATE_CHANGED', 'arguments': CellularNetworkType.Lte.index});
    expect(notifications, 2);
    changed({'name': 'CELLULAR_STATE_CHANGED', 'arguments': CellularNetworkType.Lte.index});
    changed({'name': 'UNRECOGNIZED'});
    expect(notifications, 2);
    changed({'name': 'CAPABILITIES_CHANGED', 'arguments': {...wifi, 'vpnActive': true}});
    expect(notifications, 3);
    changed({'name': 'NETWORK_UNAVAILABLE'});
    changed({'name': 'NETWORK_UNAVAILABLE'});
    expect(notifications, 4);
  });

  test('unchanged permission and traffic samples do not notify listeners', () async {
    await networkService.initialLoad;
    var notifications = 0;
    networkService.addListener(() => notifications++);
    await networkService.refreshPermissionAndUsage();
    expect(notifications, 0);
    when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
    when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);
    await networkService.refreshPermissionAndUsage();
    expect(notifications, 1);
    await networkService.refreshPermissionAndUsage();
    expect(notifications, 1);
    when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 101);
    await networkService.refreshPermissionAndUsage();
    expect(notifications, 2);
    when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => false);
    await networkService.refreshPermissionAndUsage();
    expect(notifications, 3);
  });

  test('a new route still notifies VPN consumers when its displayed state matches', () async {
    late void Function(Map<String, dynamic>) changed;
    when(mockChannel.addNetworkChangedListener(any)).thenAnswer((call) {
      changed = call.positionalArguments.single;
      return null;
    });
    final service = NetworkService(mockChannel);
    addTearDown(service.dispose);
    await service.initialLoad;
    var notifications = 0;
    service.addListener(() => notifications++);
    final event = {
      'name': 'NETWORK_AVAILABLE',
      'arguments': {
        'networkType': NetworkType.Wifi.index,
        'internetAccess': true,
        'wirelessSignalLevel': 3,
        'vpnActive': true,
      },
    };
    changed(event);
    changed(event);
    expect(notifications, 2);
  });

  test('revoking usage permission clears bytes and rejects a pending sample', () {
    fakeAsync((time) {
      when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 123);
      networkService.refreshPermissionAndUsage();
      time.flushMicrotasks();
      expect(networkService.dailyDataUsage, 123);

      final pending = Completer<int>();
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) => pending.future);
      time.elapse(const Duration(minutes: 5));
      when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => false);
      networkService.refreshPermissionAndUsage();
      time.flushMicrotasks();
      expect(networkService.hasUsageStatsPermission, isFalse);
      expect(networkService.dailyDataUsage, -1);
      pending.complete(999);
      time.flushMicrotasks();
      expect(networkService.dailyDataUsage, -1);
      expect(time.periodicTimerCount, 0);
    });
  });
  test('short resumes recheck permissions but preserve fresh usage; manual refresh forces usage', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 123);
      final service = NetworkService(mockChannel, work: work);
      time.elapse(const Duration(milliseconds: 350));
      verify(mockChannel.getDailyDataUsage()).called(1);
      clearInteractions(mockChannel);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      time.elapse(const Duration(milliseconds: 350));
      verify(mockChannel.checkUsageStatsPermission()).called(1);
      verifyNever(mockChannel.getDailyDataUsage());
      service.refreshPermissionAndUsage();
      time.elapse(const Duration(milliseconds: 350));
      verify(mockChannel.getDailyDataUsage()).called(1);
      service.dispose(); work.dispose();
    });
  });

  test(
    'daily cache is unknown initially and clears stale bytes after errors',
    () async {
      expect(networkService.dailyDataUsage, -1);
      when(mockChannel.checkUsageStatsPermission())
          .thenAnswer((_) async => true);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 900);
      await networkService.refreshPermissionAndUsage();
      expect(networkService.dailyDataUsage, 900);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => -2);
      await networkService.refreshPermissionAndUsage();
      expect(networkService.dailyDataUsage, -2);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 900);
      await networkService.refreshPermissionAndUsage();
      when(mockChannel.getDailyDataUsage())
          .thenAnswer((_) async => throw StateError('unavailable'));
      await networkService.refreshPermissionAndUsage();
      expect(networkService.dailyDataUsage, -1);
    },
  );

  test('initial load waits for network and initial permitted traffic value', () async {
    final channel = MockFLauncherChannel();
    final information = Completer<Map<String, dynamic>>();
    final usage = Completer<int>();
    when(channel.addNetworkChangedListener(any)).thenReturn(null);
    when(channel.getActiveNetworkInformation()).thenAnswer((_) => information.future);
    when(channel.checkUsageStatsPermission()).thenAnswer((_) async => true);
    when(channel.getDailyDataUsage()).thenAnswer((_) => usage.future);
    final service = NetworkService(channel);
    addTearDown(service.dispose);
    var loaded = false;
    service.initialLoad.then((_) => loaded = true);
    information.complete({});
    await service.initialNetworkLoad;
    await Future<void>.delayed(Duration.zero);
    expect(loaded, isFalse);
    usage.complete(123);
    await service.initialLoad;
    expect(loaded, isTrue);
    expect(service.dailyDataUsage, 123);
  });

  test('initial load completes when network and permission queries fail', () async {
    final channel = MockFLauncherChannel();
    when(channel.addNetworkChangedListener(any)).thenReturn(null);
    when(channel.getActiveNetworkInformation()).thenAnswer((_) async => throw StateError('offline'));
    when(channel.checkUsageStatsPermission()).thenAnswer((_) async => throw StateError('unsupported'));
    final service = NetworkService(channel);
    addTearDown(service.dispose);
    await service.initialLoad;
    expect(service.hasUsageStatsPermission, isFalse);
  });

  test('detailed traffic passes the selected period and keeps unavailable distinct from zero', () async {
    when(mockChannel.getTrafficUsage('weekly')).thenAnswer((_) async => {'rxBytes': 0, 'txBytes': -2, 'totalBytes': -2});
    final snapshot = await networkService.getTrafficUsage('weekly');
    expect(snapshot, {'rxBytes': 0, 'txBytes': -2, 'totalBytes': -2});
    verify(mockChannel.getTrafficUsage('weekly')).called(1);
  });

  group('getDataUsageForPeriod', () {
    test('returns daily usage when period is "daily"', () async {
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);

      final result = await networkService.getDataUsageForPeriod('daily');

      expect(result, 100);
      verify(mockChannel.getDailyDataUsage()).called(1);
      verifyNever(mockChannel.getWeeklyDataUsage());
      verifyNever(mockChannel.getMonthlyDataUsage());
    });

    test('returns weekly usage when period is "weekly"', () async {
      when(mockChannel.getWeeklyDataUsage()).thenAnswer((_) async => 500);

      final result = await networkService.getDataUsageForPeriod('weekly');

      expect(result, 500);
      verify(mockChannel.getWeeklyDataUsage()).called(1);
      verifyNever(mockChannel.getDailyDataUsage());
      verifyNever(mockChannel.getMonthlyDataUsage());
    });

    test('returns monthly usage when period is "monthly"', () async {
      when(mockChannel.getMonthlyDataUsage()).thenAnswer((_) async => 2000);

      final result = await networkService.getDataUsageForPeriod('monthly');

      expect(result, 2000);
      verify(mockChannel.getMonthlyDataUsage()).called(1);
      verifyNever(mockChannel.getDailyDataUsage());
      verifyNever(mockChannel.getWeeklyDataUsage());
    });

    test('returns daily usage when period is unknown', () async {
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);

      final result = await networkService.getDataUsageForPeriod('unknown_period');

      expect(result, 100);
      verify(mockChannel.getDailyDataUsage()).called(1);
      verifyNever(mockChannel.getWeeklyDataUsage());
      verifyNever(mockChannel.getMonthlyDataUsage());
    });
  });

  group('refreshPermissionAndUsage', () {
    test('pause stops polling and resume refreshes and restarts it', () {
      fakeAsync((time) {
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);
        networkService.refreshPermissionAndUsage();
        time.flushMicrotasks();
        clearInteractions(mockChannel);
        networkService.didChangeAppLifecycleState(AppLifecycleState.paused);
        time.elapse(const Duration(minutes: 10));
        verifyNever(mockChannel.getDailyDataUsage());
        networkService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        time.flushMicrotasks();
        verify(mockChannel.getDailyDataUsage()).called(1);
        time.elapse(const Duration(minutes: 5));
        verify(mockChannel.getDailyDataUsage()).called(1);
      });
    });

    test('late permission and usage replies cannot restart background polling', () {
      fakeAsync((time) {
        final permission = Completer<bool>();
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) => permission.future);
        networkService.refreshPermissionAndUsage();
        networkService.didChangeAppLifecycleState(AppLifecycleState.paused);
        permission.complete(true);
        time.flushMicrotasks();
        verifyNever(mockChannel.getDailyDataUsage());
        final usage = Completer<int>();
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) => usage.future);
        networkService.didChangeAppLifecycleState(AppLifecycleState.resumed);
        time.flushMicrotasks();
        verify(mockChannel.getDailyDataUsage()).called(1);
        networkService.didChangeAppLifecycleState(AppLifecycleState.hidden);
        usage.complete(999);
        time.flushMicrotasks();
        time.elapse(const Duration(minutes: 10));
        verifyNever(mockChannel.getDailyDataUsage());
        expect(networkService.dailyDataUsage, isNot(999));
      });
    });

    test('refresh future waits for usage update', () async {
      final usage = Completer<int>();
      when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
      when(mockChannel.getDailyDataUsage()).thenAnswer((_) => usage.future);
      var completed = false;
      final refresh = networkService.refreshPermissionAndUsage().then((_) => completed = true);
      await Future<void>.delayed(Duration.zero);
      expect(completed, isFalse);
      usage.complete(777);
      await refresh;
      expect(networkService.dailyDataUsage, 777);
    });

    test('when permission granted, polls usage and notifies only for changed samples', () {
      fakeAsync((async) {
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);

        int listenerCallCount = 0;
        networkService.addListener(() {
          listenerCallCount++;
        });

        // initial call starts timer
        networkService.refreshPermissionAndUsage();

        async.flushMicrotasks();

        expect(networkService.hasUsageStatsPermission, isTrue);
        expect(networkService.dailyDataUsage, 100);
        expect(listenerCallCount, 1);
        verify(mockChannel.getDailyDataUsage()).called(1);

        // advance 5 minutes
        async.elapse(const Duration(minutes: 5));

        // Timer should have fired, calling _fetchUsage again
        verify(mockChannel.getDailyDataUsage()).called(1);
        expect(listenerCallCount, 1);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 101);
        async.elapse(const Duration(minutes: 5));
        expect(listenerCallCount, 2);
      });
    });

    test('when permission denied, cancels timer and notifies listeners', () {
      fakeAsync((async) {
        // First, simulate permission granted to start timer
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);
        networkService.refreshPermissionAndUsage();
        async.flushMicrotasks();
        expect(networkService.hasUsageStatsPermission, isTrue);

        // Advance 5 minutes to verify timer is active
        async.elapse(const Duration(minutes: 5));
        verify(mockChannel.getDailyDataUsage()).called(2);

        // Now deny it
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => false);

        int listenerCallCount = 0;
        networkService.addListener(() {
          listenerCallCount++;
        });

        networkService.refreshPermissionAndUsage();
        async.flushMicrotasks();

        expect(networkService.hasUsageStatsPermission, isFalse);
        expect(listenerCallCount, 1);

        // Advance 5 minutes, timer should NOT fire anymore
        async.elapse(const Duration(minutes: 5));

        // Shouldn't have any more calls to getDailyDataUsage since timer was cancelled
        verifyNever(mockChannel.getDailyDataUsage());
      });
    });

    test('when permission granted and timer is already active, does not start a new timer but fetches usage', () {
      fakeAsync((async) {
        when(mockChannel.checkUsageStatsPermission()).thenAnswer((_) async => true);
        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 100);

        // First call starts the timer
        networkService.refreshPermissionAndUsage();
        async.flushMicrotasks();

        // Advance 4 minutes, timer hasn't fired yet
        async.elapse(const Duration(minutes: 4));

        when(mockChannel.getDailyDataUsage()).thenAnswer((_) async => 200);

        // Second call should fetch usage but reuse the timer
        networkService.refreshPermissionAndUsage();
        async.flushMicrotasks();

        expect(networkService.dailyDataUsage, 200);
        verify(mockChannel.getDailyDataUsage()).called(2);

        // Advance another 1 minute (total 5 mins since first call)
        // If a new timer was started, it would fire 5 mins from the second call.
        // If the old timer was kept, it should fire now.
        async.elapse(const Duration(minutes: 1));

        // Timer fired!
        verify(mockChannel.getDailyDataUsage()).called(1);
      });
    });
  });
}
