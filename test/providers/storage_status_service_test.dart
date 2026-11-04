import 'dart:async';

import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('cutelauncher/storage_status');
  late StorageStatusService service;
  late Map<String, dynamic> snapshot;
  late int reads;
  late List<MethodCall> calls;
  Future<void> changed([Object? value]) async {
    await binding.defaultBinaryMessenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(MethodCall('changed', value)),
      (_) {},
    );
  }

  setUp(() {
    reads = 0;
    calls = [];
    snapshot = {'nasSupported': true, 'nas': true, 'usb': true};
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      calls.add(call);
      if (call.method == 'snapshot') {
        reads++;
        return snapshot;
      }
      return call.method.startsWith('open') ? true : null;
    });
    service = StorageStatusService();
  });
  tearDown(() async {
    service.dispose();
    await Future<void>.value();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });
  testWidgets(
    'disconnected and unsupported NAS stay hidden; USB is independent',
    (tester) async {
      expect(service.state, noStorageStatus);
      snapshot = {'nasSupported': false, 'nas': true, 'usb': true};
      service.setVisible('panel', true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(service.state.nas, false);
      expect(service.state.usb, true);
      expect(await service.open(true), false);
      expect(await service.open(false), true);
      snapshot = {'nasSupported': true, 'nas': false, 'usb': false};
      await changed();
      await tester.pump(const Duration(milliseconds: 100));
      expect(service.state.nas, false);
      expect(service.state.usb, false);
      expect(await service.open(false), false);
      service.dispose();
    },
  );
  testWidgets(
    'one cycle for multiple owners and event bursts; unchanged state does not notify',
    (tester) async {
      var notifications = 0;
      service.addListener(() => notifications++);
      service.setVisible('home', true);
      service.setVisible('remote', true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 1);
      for (var i = 0; i < 10; i++) {
        await changed();
      }
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 2);
      expect(notifications, 1);
      expect(await service.open(true), true);
      expect(calls.last.method, 'openNas');
      service.setVisible('home', false);
      await tester.pump(const Duration(seconds: 5));
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 3);
      service.setVisible('remote', false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 3);
      expect(calls.where((c) => c.method == 'watch').map((c) => c.arguments), [
        true,
        false,
      ]);
    },
  );
  testWidgets(
    'background, screen off and dispose stop work; resume refreshes',
    (tester) async {
      service.setVisible('home', true);
      await tester.pump(const Duration(milliseconds: 100));
      await changed(false);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 1);
      await changed();
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 2);
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(service.state, noStorageStatus);
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 2);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 100));
      expect(reads, 3);
      service.dispose();
      await tester.pump(const Duration(seconds: 20));
      expect(reads, 3);
    },
  );
  testWidgets('late snapshot is discarded; outstanding reads never overlap', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>>();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'snapshot') {
        reads++;
        return pending.future;
      }
      return null;
    });
    service.setVisible('home', true);
    await tester.pump(const Duration(milliseconds: 100));
    await changed();
    await tester.pump(const Duration(milliseconds: 100));
    expect(reads, 1);
    service.setVisible('home', false);
    pending.complete(snapshot);
    await tester.pump();
    expect(service.state, noStorageStatus);
    await tester.pump(const Duration(seconds: 10));
    expect(reads, 1);
  });
  testWidgets('initial optional snapshot waits for Home readiness', (
    tester,
  ) async {
    service.dispose();
    final work = ForegroundWork(now: () => tester.binding.clock.now());
    service = StorageStatusService(work: work);
    service.setVisible('home', true);
    await tester.pump(const Duration(seconds: 1));
    expect(reads, 0);
    work.homeReady();
    await tester.pump(const Duration(milliseconds: 350));
    expect(reads, 1);
    service.setVisible('home', false);
    service.dispose();
    work.dispose();
  });

  testWidgets('unavailable data hides icons and a rejected screen returns failure', (tester) async {
    service.setVisible('home', true);
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.state.nas, true);
    binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'watch') return null;
      throw PlatformException(code: 'unavailable');
    });
    expect(await service.open(true), false);
    await changed();
    await tester.pump(const Duration(milliseconds: 100));
    expect(service.state, noStorageStatus);
    service.dispose();
  });
}
