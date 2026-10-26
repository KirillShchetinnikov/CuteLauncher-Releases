import 'dart:async';

import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late SleepTimerService timer;
  var elapsed = 0;
  var remaining = 0;
  final calls = <MethodCall>[];
  setUp(() {
    elapsed = remaining = 0;
    calls.clear();
    messenger.setMockMethodCallHandler(SleepTimerService.channel, (call) async {
      calls.add(call);
      if (call.method == 'start') {
        remaining = (call.arguments['minutes'] as int) * 60000;
      }
      if (call.method == 'startTest') remaining = 30000;
      if (call.method == 'cancel') remaining = 0;
      return {'remainingMs': remaining, 'exactAllowed': true, 'error': ''};
    });
    timer = SleepTimerService(elapsedMilliseconds: () => elapsed);
  });
  tearDown(() {
    timer.dispose();
    messenger.setMockMethodCallHandler(SleepTimerService.channel, null);
  });

  test(
    'test timer counts 30 seconds and can be restarted or cancelled',
    () async {
      expect(await timer.selectTestTimer(), true);
      expect(calls.last.method, 'startTest');
      expect(timer.countdown, '00:30');
      elapsed = 29001;
      expect(timer.countdown, '00:01');
      elapsed = 30000;
      expect(timer.active, false);
      expect(await timer.selectTestTimer(), true);
      expect(timer.countdown, '00:30');
      expect(await timer.select(0), true);
      expect(timer.active, false);
    },
  );

  test('counts elapsed time, restarts and cancels the native alarm', () async {
    expect(await timer.select(90), true);
    expect(timer.countdown, '1:30:00');
    elapsed = 30001;
    expect(timer.countdown, '1:29:30');
    expect(await timer.select(10), true);
    expect(timer.countdown, '10:00');
    elapsed += 599001;
    expect(timer.countdown, '00:01');
    expect(await timer.select(0), true);
    expect(timer.active, false);
    expect(calls.map((c) => c.method), ['start', 'start', 'cancel']);
  });

  test('custom seconds and more than six hours are sent without truncation', () async {
    messenger.setMockMethodCallHandler(SleepTimerService.channel, (call) async {
      calls.add(call);
      return {'remainingMs': 90061000, 'exactAllowed': true, 'error': ''};
    });
    expect(await timer.selectSeconds(90061), true);
    expect(calls.single.method, 'startDuration');
    expect(calls.single.arguments, {'seconds': 90061});
    expect(timer.countdown, '25:01:01');
    expect(await timer.selectSeconds(0), false);
    expect(await timer.selectSeconds(3600000000), false);
    expect(calls.length, 1);
  });

  test(
    'resume reads native time; no foreground polling in background',
    () async {
      await timer.select(60);
      timer.didChangeAppLifecycleState(AppLifecycleState.paused);
      elapsed = 1800000;
      expect(timer.countdown, '30:00');
      remaining = 1200000;
      timer.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(timer.countdown, '20:00');
      expect(calls.where((c) => c.method == 'state').length, 1);
    },
  );

  test(
    'failure preserves existing alarm and explains missing access',
    () async {
      await timer.select(30);
      messenger.setMockMethodCallHandler(SleepTimerService.channel, (_) async {
        throw PlatformException(code: 'access');
      });
      expect(await timer.select(60), false);
      expect(timer.countdown, '30:00');
      expect(timer.error, 'access');
      expect(timer.busy, false);
      expect(await timer.select(11), false);
    },
  );

  test('late state response cannot overwrite new selection', () async {
    final delayed = Completer<Object?>();
    messenger.setMockMethodCallHandler(
      SleepTimerService.channel,
      (call) async => call.method == 'state'
          ? delayed.future
          : {'remainingMs': 600000, 'exactAllowed': true, 'error': ''},
    );
    final refresh = timer.refresh();
    await timer.select(10);
    delayed.complete({'remainingMs': 0, 'exactAllowed': true, 'error': ''});
    await refresh;
    expect(timer.countdown, '10:00');
  });

  test(
    'exact alarm access is reported and cancellation works without it',
    () async {
      messenger.setMockMethodCallHandler(SleepTimerService.channel, (
        call,
      ) async {
        if (call.method == 'start') throw PlatformException(code: 'exact');
        if (call.method == 'requestExact') return true;
        return {'remainingMs': 0, 'exactAllowed': false, 'error': ''};
      });
      await timer.refresh();
      expect(timer.exactAllowed, false);
      expect(await timer.select(10), false);
      expect(timer.error, 'exact');
      expect(timer.active, false);
      expect(await timer.requestExact(), true);
      expect(await timer.select(0), true);
      expect(timer.error, '');
    },
  );
}
