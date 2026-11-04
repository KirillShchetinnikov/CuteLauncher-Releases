import 'dart:async';

import 'package:flauncher/providers/system_status_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cutelauncher/system_status');
  late SystemStatusService service;
  late DateTime now;
  late Map<String, dynamic> snapshot;
  late int reads;
  late List<bool> resets;
  late List<bool> watches;
  setUp(() {
    now = DateTime.utc(2026, 10, 30, 12);
    reads = 0;
    resets = [];
    watches = [];
    snapshot = {
      'cpuPercent': 20,
      'ramTotalBytes': 1000,
      'ramAvailableBytes': 400,
      'storageTotalBytes': 2000,
      'storageAvailableBytes': 1200,
      'uptimeMinutes': 90,
    };
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'watch') {
        watches.add(call.arguments as bool);
        return null;
      }
      reads++;
      resets.add(call.arguments as bool);
      return snapshot;
    });
    service = SystemStatusService(now: () => now);
  });
  tearDown(() async {
    service.dispose();
    await Future<void>.value();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  void check(String description, WidgetTesterCallback body) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        service.dispose();
      }
    });
  }

  Future<void> screen(bool on) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall('changed', on)),
      (_) {},
    );
  }

  check('saved interval changes cadence without hidden work or duplicate loops', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'system_update_interval': 2});
    final settings = SettingsService(await SharedPreferences.getInstance());
    service.dispose();
    service = SystemStatusService(settings: settings, now: () => now);
    try {
      expect(service.interval, const Duration(seconds: 2));
      final owner = Object();
      service.setVisible(owner, true);
      service.setVisible(Object(), true);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 2);
      await settings.setSystemUpdateInterval(10);
      await tester.pump(const Duration(seconds: 9));
      expect(reads, 2);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 3);
      expect(resets, [true, false, false]);
      // Unrelated settings must not postpone the next sample.
      await tester.pump(const Duration(seconds: 9));
      await settings.setSystemShowCpu(false);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 4);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await settings.setSystemUpdateInterval(1);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 4);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 5);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 6);
      await screen(false);
      await settings.setSystemUpdateInterval(2);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 6);
      service.dispose();
      await settings.setSystemUpdateInterval(1);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 6);
    } finally {
      service.dispose();
      settings.dispose();
    }
  });

  check('interval change during a read waits for completion without overlap', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    service.dispose();
    service = SystemStatusService(settings: settings);
    final pending = Completer<Map<String, dynamic>>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'watch') return null;
      reads++;
      return reads == 1 ? pending.future : snapshot;
    });
    try {
      service.setVisible(Object(), true);
      await tester.pump();
      await settings.setSystemUpdateInterval(1);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 1);
      pending.complete(snapshot);
      await tester.pump();
      expect(service.state.cpu, 20);
      await tester.pump(const Duration(milliseconds: 999));
      expect(reads, 1);
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, 2);
    } finally {
      service.dispose();
      settings.dispose();
    }
  });

  check('queued collection waits for Home/input and cancels hidden work', (
    tester,
  ) async {
    service.dispose();
    final queue = ForegroundWork(now: () => now);
    service = SystemStatusService(now: () => now, work: queue);
    try {
      final owner = Object();
      service.setVisible(owner, true);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 0);
      queue.homeReady();
      await tester.pump();
      expect(reads, 1);
      queue.deferForInput();
      unawaited(service.refresh());
      await tester.pump();
      expect(reads, 1);
      service.setVisible(owner, false);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 1);
      service.setVisible(owner, true);
      await tester.pump();
      expect(reads, 2);
    } finally {
      service.dispose();
      queue.dispose();
    }
  });

  check('lazy, shared sampling deduplicates values and stops at last owner', (
    tester,
  ) async {
    var notifications = 0;
    service.addListener(() => notifications++);
    await tester.pump(const Duration(seconds: 10));
    expect(reads, 0);
    final a = Object(), b = Object();
    service.setVisible(a, true);
    await tester.pump();
    expect(ramPercent(service.state), 60);
    expect(notifications, 1);
    service.setVisible(b, true);
    await tester.pump(const Duration(seconds: 5));
    expect(reads, 2);
    expect(notifications, 1);
    expect(resets, [true, false]);
    service.setVisible(a, false);
    await tester.pump(const Duration(seconds: 5));
    expect(reads, 3);
    service.setVisible(b, false);
    await tester.pump(const Duration(seconds: 20));
    expect(reads, 3);
    expect(watches, [true, false]);
  });
  check(
    'screen, lifecycle and disposal stop work; resume resets CPU and graph segment',
    (tester) async {
      final owner = Object();
      service.setVisible(owner, true);
      await tester.pump();
      final segment = service.history.last.segment;
      await screen(false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 1);
      now = now.add(const Duration(minutes: 2));
      await screen(true);
      await tester.pump();
      expect(reads, 2);
      expect(resets.last, isTrue);
      expect(service.history.last.segment, isNot(segment));
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 2);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 3);
      service.dispose();
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 3);
    },
  );
  check(
    'averages, peaks and one-hour limit use observation time; gaps stay empty',
    (tester) async {
      service.setVisible(Object(), true);
      await tester.pump();
      snapshot = {...snapshot, 'cpuPercent': 80, 'ramAvailableBytes': 200};
      await service.refresh();
      expect(service.history.single.cpu, 50);
      expect(service.history.single.cpuPeak, 80);
      expect(service.history.single.ram, 70);
      expect(service.history.single.ramPeak, 80);
      for (var i = 0; i < 80; i++) {
        now = now.add(const Duration(minutes: 1));
        await service.refresh();
      }
      expect(service.history.length, 60);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      now = now.add(const Duration(hours: 2));
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(service.history.length, 1);
    },
  );
  check(
    'invalid and unavailable values never become zero; real zero is valid',
    (tester) async {
      snapshot = {
        'cpuPercent': 101,
        'ramTotalBytes': 0,
        'ramAvailableBytes': -1,
        'storageTotalBytes': 10,
        'storageAvailableBytes': 11,
        'temperatureCelsius': double.nan,
      };
      service.setVisible(Object(), true);
      await tester.pump();
      expect(service.state.cpu, isNull);
      expect(ramPercent(service.state), isNull);
      expect(service.state.storageAvailable, isNull);
      expect(service.state.temperature, isNull);
      snapshot = {
        'cpuPercent': 0,
        'ramTotalBytes': 10,
        'ramAvailableBytes': 10,
      };
      await service.refresh();
      expect(service.state.cpu, 0);
      expect(ramPercent(service.state), 0);
    },
  );
  check(
    'pending reads do not overlap or publish after hide; return refreshes',
    (tester) async {
      final pending = Completer<Map<String, dynamic>>();
      binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'watch') return null;
        reads++;
        return reads == 1 ? pending.future : snapshot;
      });
      final owner = Object();
      service.setVisible(owner, true);
      await tester.pump();
      await service.refresh();
      expect(reads, 1);
      service.setVisible(owner, false);
      pending.complete(snapshot);
      await tester.pump();
      expect(service.state, unknownSystemStatus);
      expect(service.history, isEmpty);
      service.setVisible(owner, true);
      await tester.pump();
      expect(reads, 2);
    },
  );
  check('failures clear current values and retry at bounded intervals', (
    tester,
  ) async {
    service.setVisible(Object(), true);
    await tester.pump();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'watch') return null;
      reads++;
      throw PlatformException(code: 'unavailable');
    });
    await tester.pump(const Duration(seconds: 5));
    expect(service.state, unknownSystemStatus);
    expect(reads, 2);
    await tester.pump(const Duration(seconds: 4));
    expect(reads, 2);
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 3);
  });
}
