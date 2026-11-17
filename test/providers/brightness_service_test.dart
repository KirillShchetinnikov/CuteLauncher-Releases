import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';

import 'package:flauncher/providers/brightness_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('me.efesser.flauncher/method');
  const windowChannel = MethodChannel('github.com/aaassseee/screen_brightness');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, null);
    messenger.setMockMethodCallHandler(windowChannel, null);
  });

  test('failed system writes back off at 15/30/60 seconds and successful retry clears fallback', () async {
    SharedPreferences.setMockInitialValues({
      for (final slot in TimeSlot.values) 'brightness_${slot.name}': 50,
    });
    final prefs = await SharedPreferences.getInstance();
    fakeAsync((time) {
      var writes = 0, windowWrites = 0, resets = 0;
      var success = false;
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'setSystemBrightness') { writes++; return success; }
        return false;
      });
      messenger.setMockMethodCallHandler(windowChannel, (call) async {
        if (call.method == 'setApplicationScreenBrightness') windowWrites++;
        if (call.method == 'resetApplicationScreenBrightness') resets++;
        return null;
      });
      final service = BrightnessService(prefs, now: () => DateTime(2026, 1, 1, 12).add(time.elapsed));
      service.setEnabled(true);
      time.flushMicrotasks();
      expect(writes, 1);
      time.elapse(const Duration(seconds: 14)); expect(writes, 1);
      time.elapse(const Duration(seconds: 1)); expect(writes, 2);
      time.elapse(const Duration(seconds: 29)); expect(writes, 2);
      time.elapse(const Duration(seconds: 1)); expect(writes, 3);
      time.elapse(const Duration(seconds: 60)); expect(writes, 4);
      expect(windowWrites, 1);
      success = true;
      time.elapse(const Duration(seconds: 60)); expect(writes, 5);
      expect(resets, 1);
      time.elapse(const Duration(minutes: 5)); expect(writes, 5);
      service.setEnabled(false);
      time.flushMicrotasks();
      expect(service.isEnabled, isFalse);
      service.dispose();
    });
  });

  test('brightness retry resets on target, settings, permission and resume while background schedule survives', () async {
    SharedPreferences.setMockInitialValues({
      for (final slot in TimeSlot.values) 'brightness_${slot.name}': 50,
    });
    final prefs = await SharedPreferences.getInstance();
    fakeAsync((time) {
      var writes = 0;
      var permission = false;
      final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkWriteSettingsPermission') return permission;
        if (call.method == 'setSystemBrightness') writes++;
        return false;
      });
      messenger.setMockMethodCallHandler(windowChannel, (_) async => null);
      final service = BrightnessService(prefs, now: () => DateTime(2026, 1, 1, 12).add(time.elapsed));
      service.setEnabled(true); time.flushMicrotasks(); expect(writes, 1);
      service.setBrightnessForSlot(TimeSlot.day, 60); time.flushMicrotasks(); expect(writes, 2);
      service.setTransitionMinutes(2); time.flushMicrotasks(); expect(writes, 3);
      permission = true;
      service.checkPermission(); time.flushMicrotasks(); expect(writes, 4);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      time.elapse(const Duration(seconds: 15)); expect(writes, 5);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      time.flushMicrotasks(); expect(writes, 6);
      service.dispose();
      time.elapse(const Duration(minutes: 5)); expect(writes, 6);
    });
  });

  test('persisted scheduler applies a zero level immediately at startup', () async {
    SharedPreferences.setMockInitialValues({'brightness_scheduler_enabled': true,
      for (final slot in TimeSlot.values) 'brightness_${slot.name}': 0});
    final applied = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkWriteSettingsPermission') return true;
      if (call.method == 'setSystemBrightness') {
        expect(call.arguments, {'brightness': 0}); applied.complete(); return true;
      }
      return null;
    });
    final service = BrightnessService(await SharedPreferences.getInstance());
    await applied.future.timeout(const Duration(seconds: 1));
    service.dispose();
  });

  for (final outcome in ['granted', 'denied', 'null', 'exception', 'missing']) {
    test('permission state is truthful for $outcome', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async {
        if (outcome == 'exception') throw PlatformException(code: 'unavailable');
        if (outcome == 'missing') throw MissingPluginException();
        if (outcome == 'null') return null;
        return outcome == 'granted';
      });
      final service = BrightnessService(await SharedPreferences.getInstance());
      expect(service.hasPermission, isFalse);
      await service.checkPermission();
      expect(service.hasPermission, outcome == 'granted');
      service.dispose();
    });
  }

  for (final outcome in ['success', 'false', 'null', 'exception', 'missing']) {
    test('system brightness $outcome selects the correct fallback', () async {
      final prefs = await SharedPreferences.getInstance();
      for (final slot in ['morning', 'day', 'afternoon', 'evening', 'night']) {
        await prefs.setInt('brightness_$slot', 50);
      }
      final windowCalls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method == 'checkWriteSettingsPermission') return true;
        if (call.method == 'setSystemBrightness') {
          expect(call.arguments, {'brightness': 128});
          if (outcome == 'exception') throw PlatformException(code: 'write_failed');
          if (outcome == 'missing') throw MissingPluginException();
          if (outcome == 'null') return null;
          return outcome == 'success';
        }
        return null;
      });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(windowChannel, (call) async {
        windowCalls.add(call);
        return null;
      });
      final service = BrightnessService(prefs);
      await service.checkPermission();
      try {
        await service.setEnabled(true);
        expect(windowCalls.length, outcome == 'success' ? 0 : 1);
        if (windowCalls.isNotEmpty) {
          expect(windowCalls.single.method, 'setApplicationScreenBrightness');
          expect(windowCalls.single.arguments, {'brightness': 0.5});
        }
      } finally {
        service.dispose();
      }
    });
  }

  test('disable waits for pending system write, restores baseline then resets window', () async {
    final pendingWrite = Completer<bool>();
    final calls = <String>[];
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'setSystemBrightness') return pendingWrite.future;
      return true;
    });
    messenger.setMockMethodCallHandler(windowChannel, (call) async {
      calls.add(call.method);
      return null;
    });
    final service = BrightnessService(await SharedPreferences.getInstance());
    await service.checkPermission();
    final enabling = service.setEnabled(true);
    await Future<void>.delayed(Duration.zero);
    final disabling = service.setEnabled(false);
    expect(calls, isNot(contains('restoreSystemBrightness')));
    pendingWrite.complete(true);
    await enabling;
    await disabling;
    expect(calls.indexOf('restoreSystemBrightness'), greaterThan(calls.indexOf('setSystemBrightness')));
    expect(calls.last, 'resetApplicationScreenBrightness');
    expect(service.isEnabled, isFalse);
    service.dispose();
  });

  group('BrightnessService requestPermission', () {
    test('handles successful permission request', () async {
      bool methodCalled = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'requestWriteSettingsPermission') {
            methodCalled = true;
            return null;
          }
          if (methodCall.method == 'checkWriteSettingsPermission') {
            return true;
          }
          return null;
        },
      );

      final sharedPreferences = await SharedPreferences.getInstance();
      final service = BrightnessService(sharedPreferences);

      await service.requestPermission();
      expect(methodCalled, isTrue);
    });

    test('catches and handles PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (MethodCall methodCall) async {
          if (methodCall.method == 'requestWriteSettingsPermission') {
            throw PlatformException(code: 'ERROR', message: 'Test error');
          }
          if (methodCall.method == 'checkWriteSettingsPermission') {
            return true;
          }
          return null;
        },
      );

      final sharedPreferences = await SharedPreferences.getInstance();
      final service = BrightnessService(sharedPreferences);

      // Should not throw
      await service.requestPermission();
    });
  });
}
