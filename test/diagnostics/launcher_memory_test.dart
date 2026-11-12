import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flauncher/diagnostics/launcher_memory.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flutter_test/flutter_test.dart';

class _Channel extends FLauncherChannel {
  int calls = 0;
  Future<Map<String, dynamic>> Function() read = () async => {'pssBytes': 100};
  @override
  Future<Map<String, dynamic>> getProcessMemoryUsage() {
    calls++;
    return read();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Channel channel;
  late MemoryResources resources;
  late LauncherMemory memory;
  setUp(() {
    channel = _Channel();
    resources = MemoryResources();
    memory = LauncherMemory(resources: resources, channel: channel);
  });
  tearDown(() {
    memory.dispose();
    resources.dispose();
  });

  test('only valid own-process metrics are accepted', () {
    final now = DateTime(2026);
    for (final bad in [null, -1, double.nan, double.infinity, '100']) {
      expect(LauncherMemorySnapshot.parse({'pssBytes': bad}, now), isNull);
    }
    final snapshot = LauncherMemorySnapshot.parse({
      'pssBytes': 10,
      'rssBytes': -1,
      'graphicsBytes': double.nan,
      'deviceRamBytes': 4000,
      'measuredAtMillis': 999999999999999999,
    }, now)!;
    expect(snapshot.pssBytes, 10);
    expect(snapshot.rssBytes, isNull);
    expect(snapshot.graphicsBytes, isNull);
    expect(snapshot.measuredAt, now);
  });

  test('failed refresh retains timestamp and value, recovery compares valid samples', () async {
    await memory.refresh();
    final before = memory.snapshot;
    channel.read = () async => throw StateError('unavailable');
    await memory.refresh();
    expect(memory.failed, isTrue);
    expect(memory.snapshot, same(before));
    channel.read = () async => {'pssBytes': 80};
    await memory.refresh();
    expect(memory.failed, isFalse);
    expect(memory.deltaBytes, -20);
  });

  test(
    'clear immediately reports cache result while process result is pending',
    () async {
      var cache = 40;
      resources.register(
        Object(),
        clear: () => cache = 0,
        stats: () => MemoryCacheStats(cache, cache == 0 ? 0 : 1),
      );
      final after = Completer<Map<String, dynamic>>();
      channel.read = () =>
          channel.calls == 1 ? Future.value({'pssBytes': 100}) : after.future;
      final clearing = memory.clearCaches();
      await Future<void>.delayed(Duration.zero);
      expect(memory.clearedCacheBefore, 40);
      expect(memory.clearedCacheAfter, 0);
      expect(memory.clearedProcessBefore, 100);
      expect(memory.clearedProcessAfter, isNull);
      expect(memory.busy, isTrue);
      await memory.clearCaches();
      await memory.refresh();
      expect(channel.calls, 2);
      after.complete({'pssBytes': 110});
      await clearing;
      expect(
        memory.clearedProcessAfter,
        110,
      ); // No invented promise of RAM freed.
      expect(memory.deltaBytes, 10);
      expect(memory.busy, isFalse);
    },
  );

  test(
    'cache clearing still works when native metrics are unavailable',
    () async {
      var cache = 10;
      resources.register(
        Object(),
        clear: () => cache = 0,
        stats: () => MemoryCacheStats(cache, 1),
      );
      channel.read = () async => {};
      await memory.clearCaches();
      expect(cache, 0);
      expect(memory.clearedProcessBefore, isNull);
      expect(memory.clearedProcessAfter, isNull);
      expect(memory.failed, isTrue);
    },
  );

  test(
    'no idle polling; observation is bounded and stops after one minute',
    () {
      fakeAsync((async) {
        async.elapse(const Duration(minutes: 1));
        expect(channel.calls, 0);
        memory.startObservation();
        async.flushMicrotasks();
        expect(channel.calls, 1);
        async.elapse(const Duration(seconds: 4));
        expect(channel.calls, 1);
        async.elapse(const Duration(seconds: 1));
        expect(channel.calls, 2);
        async.elapse(const Duration(seconds: 55));
        expect(memory.observing, isFalse);
        expect(memory.points.length, inInclusiveRange(12, 13));
        final calls = channel.calls;
        async.elapse(const Duration(minutes: 2));
        expect(channel.calls, calls);
        expect(async.periodicTimerCount, 0);
      });
    },
  );

  test(
    'slow requests do not overlap and hidden page discards late responses',
    () {
      fakeAsync((async) {
        final pending = Completer<Map<String, dynamic>>();
        channel.read = () => pending.future;
        memory.startObservation();
        async.elapse(const Duration(seconds: 20));
        expect(channel.calls, 1);
        memory.setActive(false);
        pending.complete({'pssBytes': 500});
        async.flushMicrotasks();
        expect(memory.snapshot, isNull);
        expect(memory.points, isEmpty);
        expect(memory.busy, isFalse);
        memory.setActive(true);
        async.elapse(const Duration(minutes: 1));
        expect(channel.calls, 1);
        expect(memory.observing, isFalse);
      });
    },
  );

  test(
    'failed samples are gaps; manual refresh cannot grow history without bound',
    () async {
      memory.startObservation();
      await Future<void>.delayed(Duration.zero);
      channel.read = () async => {};
      await memory.refresh();
      expect(memory.points.last.bytes, isNull);
      channel.read = () async => {'pssBytes': 80};
      for (var i = 0; i < 30; i++) {
        await memory.refresh();
      }
      expect(memory.points.length, LauncherMemory.maxPoints);
      memory.stopObservation();
    },
  );

  test('dispose cancels timers and ignores pending native work', () {
    fakeAsync((async) {
      final local = LauncherMemory(resources: resources, channel: channel);
      final pending = Completer<Map<String, dynamic>>();
      channel.read = () => pending.future;
      local.startObservation();
      local.dispose();
      pending.complete({'pssBytes': 100});
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 2));
      expect(channel.calls, 1);
      expect(async.periodicTimerCount, 0);
      expect(async.nonPeriodicTimerCount, 0);
    });
  });
}
