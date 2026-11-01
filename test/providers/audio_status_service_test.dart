import 'dart:async';

import 'package:flauncher/providers/audio_status_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('cutelauncher/audio_status');
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  late AudioStatusService service;
  late Map<String, dynamic> snapshot;
  late int reads;
  late List<bool> watches;
  Future<void> changed(Object? value) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall('changed', value)),
      (_) {},
    );
  }

  setUp(() {
    reads = 0;
    watches = [];
    snapshot = {
      'percent': 15,
      'muted': false,
      'outputs': ['tv'],
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
      return snapshot;
    });
    service = AudioStatusService();
  });
  tearDown(() async {
    service.dispose();
    await Future<void>.value();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  testWidgets(
    'polls only visible owners, deduplicates state and stops at last detach',
    (tester) async {
      var notifications = 0;
      service.addListener(() => notifications++);
      final first = Object(), second = Object();
      await tester.pump(const Duration(seconds: 2));
      expect(reads, 0);
      service.setVisible(first, true);
      await tester.pump();
      expect(service.state.percent, 15);
      expect(service.state.output, 'tv');
      service.setVisible(second, true);
      await tester.pump(const Duration(seconds: 3));
      expect(reads, 2);
      expect(notifications, 1);
      service.setVisible(first, false);
      snapshot = {
        ...snapshot,
        'percent': 16,
        'outputs': ['arc'],
      };
      await tester.pump(const Duration(seconds: 3));
      expect(service.state.percent, 16);
      expect(service.state.output, 'arc');
      service.setVisible(second, false);
      await tester.pump(const Duration(seconds: 3));
      expect(reads, 3);
      expect(watches, [true, false]);
      service.dispose();
    },
  );
  testWidgets(
    'screen off stops reads; wake and resume immediately read fresh state',
    (tester) async {
      service.setVisible(Object(), true);
      await tester.pump();
      await changed(false);
      await tester.pump(const Duration(seconds: 3));
      expect(reads, 1);
      snapshot = {...snapshot, 'percent': 35};
      await changed(true);
      await tester.pump();
      expect(service.state.percent, 35);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 4));
      expect(reads, 2);
      snapshot = {...snapshot, 'muted': true};
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(service.state.muted, isTrue);
      expect(reads, 3);
      expect(watches, [true, false, true]);
      service.dispose();
    },
  );
  testWidgets(
    'fixed, unknown, empty and simultaneous outputs are distinct from zero and TV',
    (tester) async {
      service.setVisible(Object(), true);
      await tester.pump();
      snapshot = {
        'percent': 100,
        'fixed': true,
        'muted': true,
        'outputs': ['arc'],
      };
      await changed(null);
      await tester.pump();
      expect(service.state.percent, isNull);
      expect(service.state.muted, isTrue);
      expect(service.state.output, 'arc');
      snapshot = {'percent': -1, 'outputs': []};
      await changed(null);
      await tester.pump();
      expect(service.state, unknownAudioStatus);
      snapshot = {
        'percent': 0,
        'muted': false,
        'outputs': ['tv', 'bluetooth'],
      };
      await changed(null);
      await tester.pump();
      expect(service.state.percent, 0);
      expect(service.state.output, 'multiple');
      snapshot = {'percent': 101};
      await changed(null);
      await tester.pump();
      expect(service.state.percent, isNull);
      service.dispose();
    },
  );
  testWidgets('bridge failure clears stale successful values and retries', (
    tester,
  ) async {
    service.setVisible(Object(), true);
    await tester.pump();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'watch') return null;
      throw PlatformException(code: 'unavailable');
    });
    await changed(null);
    await tester.pump();
    expect(service.state, unknownAudioStatus);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => snapshot,
    );
    await tester.pump(const Duration(seconds: 3));
    expect(service.state.percent, 15);
    service.dispose();
  });
  testWidgets(
    'default polling waits three seconds and unchanged snapshots do not rebuild UI',
    (tester) async {
      var notifications = 0;
      service.addListener(() => notifications++);
      service.setVisible(Object(), true);
      await tester.pump();
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(reads, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 2);
      expect(notifications, 1);
      service.dispose();
    },
  );
  testWidgets('serializes events and ignores old answers after hide and show', (
    tester,
  ) async {
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
    await changed(null);
    await changed(null);
    service.setVisible(owner, false);
    service.setVisible(owner, true);
    expect(reads, 1);
    pending.complete({
      'percent': 99,
      'outputs': ['hdmi'],
    });
    await tester.pump();
    expect(reads, 2);
    expect(service.state.percent, 15);
    expect(service.state.output, 'tv');
    service.dispose();
  });
  testWidgets('a late platform answer after dispose never updates listeners', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'snapshot' ? pending.future : null,
    );
    var notifications = 0;
    service.addListener(() => notifications++);
    service.setVisible(Object(), true);
    await tester.pump();
    service.dispose();
    pending.complete(snapshot);
    await tester.pump();
    expect(service.state, unknownAudioStatus);
    expect(notifications, 0);
    expect(tester.takeException(), isNull);
  });
}
