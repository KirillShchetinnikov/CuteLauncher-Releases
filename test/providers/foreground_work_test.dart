import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/providers/foreground_work.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('home gates work; repeated pending requests run once with the latest action', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed));
      var value = 0;
      final owner = Object();
      work.schedule(owner, () async { value = 1; });
      work.schedule(owner, () async { value = 2; });
      time.elapse(const Duration(seconds: 1));
      expect(value, 0);
      work.homeReady();
      time.elapse(const Duration(milliseconds: 350));
      expect(value, 2);
      work.dispose();
    });
  });
  test('running jobs are bounded and a newer request during an old job is retained', () {
    fakeAsync((time) {
      final work = ForegroundWork(concurrency: 1, now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final first = Completer<void>();
      final calls = <int>[];
      final owner = Object();
      work.schedule(owner, () async { calls.add(1); await first.future; }, delay: Duration.zero);
      time.flushMicrotasks();
      work.schedule(owner, () async { calls.add(2); }, delay: Duration.zero);
      work.schedule(owner, () async { calls.add(3); }, delay: Duration.zero);
      work.schedule(Object(), () async { calls.add(4); }, delay: Duration.zero);
      time.flushMicrotasks();
      expect(calls, [1]);
      first.complete();
      time.flushMicrotasks();
      expect(calls, [1, 3, 4]);
      work.dispose();
    });
  });
  test('pause suspends pending work, resume delays it and disposal cancels it', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      var count = 0;
      final owner = Object();
      work.didChangeAppLifecycleState(AppLifecycleState.paused);
      work.schedule(owner, () async { count++; });
      time.elapse(const Duration(seconds: 5));
      expect(count, 0);
      work.didChangeAppLifecycleState(AppLifecycleState.resumed);
      time.elapse(const Duration(milliseconds: 349));
      expect(count, 0);
      time.elapse(const Duration(milliseconds: 1));
      expect(count, 1);
      work.schedule(owner, () async { count++; });
      work.cancel(owner);
      time.elapse(const Duration(seconds: 1));
      expect(count, 1);
      work.dispose();
    });
  });
  test('freshness expires and errors release the queue', () {
    fakeAsync((time) {
      final work = ForegroundWork(concurrency: 1,
          now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final owner = Object();
      var count = 0;
      Future<void> run() async { count++; }
      work.schedule(owner, run, delay: Duration.zero);
      time.flushMicrotasks();
      work.schedule(owner, run, maxAge: const Duration(seconds: 1));
      time.flushMicrotasks();
      expect(count, 1);
      time.elapse(const Duration(seconds: 2));
      work.schedule(owner, run, delay: Duration.zero, maxAge: const Duration(seconds: 1));
      time.flushMicrotasks();
      expect(count, 2);
      var caught = false;
      work.schedule(Object(), () async { throw StateError('offline'); }, delay: Duration.zero)
          .catchError((Object _) { caught = true; });
      work.schedule(Object(), run, delay: Duration.zero);
      time.flushMicrotasks();
      expect(caught, true);
      expect(count, 3);
      work.dispose();
    });
  });
  test('active remote navigation delays optional work with a bounded deadline', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      var count = 0;
      work.schedule(Object(), () async { count++; });
      for (var i = 0; i < 24; i++) {
        work.deferForInput();
        time.elapse(const Duration(milliseconds: 200));
      }
      expect(count, 0);
      work.deferForInput();
      time.elapse(const Duration(milliseconds: 200));
      expect(count, 1);
      work.dispose();
    });
  });
  test('cancelling running work cannot recreate its retained freshness entry', () {
    fakeAsync((time) {
      final work = ForegroundWork(now: () => DateTime(2026).add(time.elapsed))..homeReady();
      final owner = Object(), release = Completer<void>();
      var count = 0;
      work.schedule(owner, () async { count++; await release.future; }, delay: Duration.zero);
      work.cancel(owner);
      release.complete();
      time.flushMicrotasks();
      work.schedule(owner, () async { count++; }, delay: Duration.zero, maxAge: const Duration(hours: 1));
      time.flushMicrotasks();
      expect(count, 2);
      work.dispose();
    });
  });
}
