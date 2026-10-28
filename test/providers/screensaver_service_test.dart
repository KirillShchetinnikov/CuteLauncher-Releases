import 'dart:async';

import 'package:flauncher/providers/screensaver_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('me.efesser.flauncher/method');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late ScreensaverService service;
  setUp(() {
    service = ScreensaverService();
  });
  tearDown(() {
    service.dispose();
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('missing bridge and malformed responses stay unavailable', () async {
    await service.refresh();
    expect(service.capabilities.canChoose, isFalse);
    expect(service.capabilities.canStart, isFalse);
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => {'canChoose': 'true', 'canStart': 1},
    );
    await service.refresh();
    expect(service.capabilities.canChoose, isFalse);
    expect(service.capabilities.canStart, isFalse);
  });

  test('selection and launch are independent and unsupported actions do not call Android', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'getScreensaverCapabilities'
          ? {'canChoose': false, 'canStart': true}
          : true;
    });
    await service.refresh();
    expect(await service.openSettings(), isFalse);
    expect(await service.startAmbientMode(), isTrue);
    expect(calls, ['getScreensaverCapabilities', 'startAmbientMode']);
  });

  test(
    'resume refreshes capabilities after system configuration changes',
    () async {
      var supported = true;
      messenger.setMockMethodCallHandler(
        channel,
        (_) async => {'canChoose': supported, 'canStart': supported},
      );
      await service.refresh();
      expect(service.capabilities.canChoose, isTrue);
      supported = false;
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);
      expect(service.capabilities.canChoose, isFalse);
      expect(service.capabilities.canStart, isFalse);
    },
  );

  test(
    'late response cannot overwrite a newer result or notify after dispose',
    () async {
      final pending = Completer<Object?>();
      var count = 0;
      messenger.setMockMethodCallHandler(
        channel,
        (_) => ++count == 1
            ? pending.future
            : Future.value({'canChoose': false, 'canStart': true}),
      );
      final old = service.refresh();
      await Future<void>.delayed(Duration.zero);
      await service.refresh();
      pending.complete({'canChoose': true, 'canStart': false});
      await old;
      expect(service.capabilities.canChoose, isFalse);
      expect(service.capabilities.canStart, isTrue);
      var notifications = 0;
      service.addListener(() => notifications++);
      final late = service.refresh();
      service.dispose();
      await late;
      expect(notifications, 0);
      // tearDown owns the replacement, avoiding a second disposal.
      service = ScreensaverService();
    },
  );

  test('failed start refreshes availability instead of throwing', () async {
    var supported = true;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'getScreensaverCapabilities') {
        return {'canStart': supported};
      }
      supported = false;
      throw PlatformException(code: 'permission_denied');
    });
    await service.refresh();
    expect(await service.startAmbientMode(), isFalse);
    expect(service.capabilities.canStart, isFalse);
  });
  test('explicit Back action does not wait for the startup work gate', () async {
    final work = ForegroundWork();
    final deferred = ScreensaverService(work: work);
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'getScreensaverCapabilities' ? {'canStart': true} : true;
    });
    final pending = deferred.refresh();
    expect(await deferred.startAmbientMode(), true);
    expect(calls, ['getScreensaverCapabilities', 'startAmbientMode']);
    deferred.dispose(); work.dispose(); await pending;
  });
}
