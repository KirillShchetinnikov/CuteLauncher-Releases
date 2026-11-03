import 'dart:async';

import 'package:flauncher/providers/foreground_work.dart';
import 'package:flauncher/providers/network_speed_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cutelauncher/network_speed');
  late NetworkSpeedService service;
  late Map<String, dynamic> snapshot;
  late int reads;
  late List<bool> watches;
  Future<Map<String, dynamic>> Function()? read;
  setUp(() {
    reads = 0;
    watches = [];
    read = null;
    snapshot = {
      'rxBytes': 1000,
      'txBytes': 2000,
      'elapsedMs': 1000,
      'screenOn': true,
    };
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'watch') {
        watches.add(call.arguments as bool);
        return null;
      }
      reads++;
      return read == null ? snapshot : await read!();
    });
    service = NetworkSpeedService();
  });
  tearDown(() async {
    service.dispose();
    await Future<void>.value();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  void check(String name, WidgetTesterCallback body) =>
      testWidgets(name, (tester) async {
        try {
          await body(tester);
        } finally {
          service.dispose();
        }
      });
  Future<void> screen(bool on) =>
      binding.defaultBinaryMessenger.handlePlatformMessage(
        channel.name,
        channel.codec.encodeMethodCall(MethodCall('changed', on)),
        (_) {},
      );

  check(
    'lazy shared polling measures actual elapsed time and deduplicates values',
    (tester) async {
      var notifications = 0;
      service.addListener(() => notifications++);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 0);
      final a = Object(), b = Object();
      service.setVisible(a, true);
      await tester.pump();
      expect(reads, 1);
      expect(service.state, unknownNetworkSpeed);
      service.setVisible(b, true);
      snapshot = {'rxBytes': 7000, 'txBytes': 5000, 'elapsedMs': 4000};
      await tester.pump(const Duration(seconds: 3));
      expect(reads, 2);
      expect(service.state, (received: 2000, sent: 1000));
      snapshot = {'rxBytes': 17000, 'txBytes': 10000, 'elapsedMs': 9000};
      await tester.pump(const Duration(seconds: 5));
      expect(reads, 3);
      expect(service.state, (received: 2000, sent: 1000));
      expect(notifications, 1);
      service.setVisible(a, false);
      await tester.pump(const Duration(seconds: 3));
      expect(reads, 4);
      service.setVisible(b, false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 4);
      expect(watches, [true, false]);
    },
  );
  check(
    'interval changes apply immediately and remain between 1 and 10 seconds',
    (tester) async {
      service.setVisible(Object(), true);
      await tester.pump();
      service.setInterval(1);
      await tester.pump();
      final start = reads;
      await tester.pump(const Duration(milliseconds: 999));
      expect(reads, start);
      await tester.pump(const Duration(milliseconds: 1));
      expect(reads, start + 1);
      service.setInterval(100);
      await tester.pump();
      final slow = reads;
      await tester.pump(const Duration(seconds: 9));
      expect(reads, slow);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, slow + 1);
      service.setInterval(0);
      await tester.pump();
      final fast = reads;
      await tester.pump(const Duration(seconds: 1));
      expect(reads, fast + 1);
    },
  );
  check(
    'screen, background, hide and disposal stop reads; resume resets baseline',
    (tester) async {
      final owner = Object();
      service.setVisible(owner, true);
      await tester.pump();
      snapshot = {'rxBytes': 4000, 'txBytes': 8000, 'elapsedMs': 4000};
      await tester.pump(const Duration(seconds: 3));
      expect(service.state, (received: 1000, sent: 2000));
      await screen(false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 2);
      await screen(true);
      await tester.pump();
      expect(reads, 3);
      expect(service.state, unknownNetworkSpeed);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 3);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(reads, 4);
      service.setVisible(owner, false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 4);
      service.setVisible(owner, true);
      await tester.pump();
      expect(reads, 5);
      service.dispose();
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 5);
    },
  );
  check(
    'unsupported, invalid, reset counters and errors stay unknown; zero is measured',
    (tester) async {
      service.setVisible(Object(), true);
      await tester.pump();
      snapshot = {'rxBytes': 1000, 'txBytes': 2000, 'elapsedMs': 4000};
      await tester.pump(const Duration(seconds: 3));
      expect(service.state, (received: 0, sent: 0));
      for (final data in [
        {'rxBytes': -1, 'txBytes': -1, 'elapsedMs': 7000},
        {'rxBytes': 'bad', 'txBytes': 2000, 'elapsedMs': 10000},
        {'rxBytes': 1000, 'txBytes': 2000, 'elapsedMs': 13000},
        {'rxBytes': 500, 'txBytes': 500, 'elapsedMs': 16000},
        {'rxBytes': 1000, 'txBytes': 2000, 'elapsedMs': 16000},
      ]) {
        snapshot = data;
        await tester.pump(const Duration(seconds: 3));
        expect(service.state, unknownNetworkSpeed);
      }
      read = () => Future.error(PlatformException(code: 'unavailable'));
      await tester.pump(const Duration(seconds: 3));
      expect(service.state, unknownNetworkSpeed);
      read = null;
      snapshot = {'rxBytes': 9000, 'txBytes': 9000, 'elapsedMs': 30000};
      await tester.pump(const Duration(seconds: 3));
      expect(service.state, unknownNetworkSpeed);
      snapshot = {'rxBytes': 9000, 'txBytes': 9000, 'elapsedMs': 33000};
      await tester.pump(const Duration(seconds: 3));
      expect(service.state, (received: 0, sent: 0));
    },
  );
  check('late reads never publish and slow requests do not overlap', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    read = () => pending.future;
    final owner = Object();
    service.setVisible(owner, true);
    await tester.pump();
    unawaited(service.refresh());
    service.setInterval(1);
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 1);
    service.setVisible(owner, false);
    pending.complete(snapshot);
    await tester.pump();
    expect(service.state, unknownNetworkSpeed);
    await tester.pump(const Duration(seconds: 20));
    expect(reads, 1);
    read = null;
    service.setVisible(owner, true);
    await tester.pump();
    expect(reads, 2);
  });
  check('Home queue delays sampling and cancels hidden work', (tester) async {
    service.dispose();
    var now = DateTime.utc(2026, 11, 3);
    final queue = ForegroundWork(now: () => now);
    service = NetworkSpeedService(work: queue);
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
    } finally {
      service.dispose();
      queue.dispose();
    }
  });
}
