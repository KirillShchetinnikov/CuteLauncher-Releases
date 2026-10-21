import 'dart:async';

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

  test('persisted scheduler applies the current slot immediately at startup', () async {
    SharedPreferences.setMockInitialValues({'brightness_scheduler_enabled': true,
      for (final slot in TimeSlot.values) 'brightness_${slot.name}': 50});
    final applied = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'checkWriteSettingsPermission') return true;
      if (call.method == 'setSystemBrightness') {
        expect(call.arguments, {'brightness': 128}); applied.complete(); return true;
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
