import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final state in [AppLifecycleState.inactive, AppLifecycleState.hidden]) {
    testWidgets('$state detaches and blocks explicit background reads', (
      tester,
    ) async {
      const channel = MethodChannel('me.efesser.flauncher/method');
      final changes = StreamController<dynamic>.broadcast();
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        _,
      ) async {
        reads++;
        return [];
      });
      final service = TvInputsService(
        FLauncherChannel(),
        changes: changes.stream,
      );
      try {
        await tester.pumpAndSettle();
        service.didChangeAppLifecycleState(state);
        changes.add(true);
        await service.refreshInputs();
        await tester.pump(const Duration(milliseconds: 200));
        expect(changes.hasListener, isFalse);
        expect(reads, 1);
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(reads, 2);
      } finally {
        service.dispose();
        await changes.close();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    });
  }

  testWidgets(
    'failed initial reading finishes loading and recovers on resume',
    (tester) async {
      const channel = MethodChannel('me.efesser.flauncher/method');
      final changes = StreamController<dynamic>.broadcast();
      var fail = true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        _,
      ) async {
        if (fail) throw PlatformException(code: 'UNAVAILABLE');
        return [
          {'id': 'port', 'label': 'HDMI 1', 'type': 1007},
        ];
      });
      final service = TvInputsService(
        FLauncherChannel(),
        changes: changes.stream,
      );
      try {
        await tester.pumpAndSettle();
        expect(service.initialized, isTrue);
        expect(service.inputs, isEmpty);
        service.didChangeAppLifecycleState(AppLifecycleState.paused);
        fail = false;
        service.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(service.inputs.single.id, 'port');
      } finally {
        service.dispose();
        await changes.close();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    },
  );

  testWidgets('creation while paused defers input subscription and reading', (
    tester,
  ) async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final changes = StreamController<dynamic>.broadcast();
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      reads++;
      return [
        {'id': 'port', 'label': 'HDMI 1', 'type': 1007},
      ];
    });
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final service = TvInputsService(
      FLauncherChannel(),
      changes: changes.stream,
    );
    try {
      await tester.pump();
      expect(reads, 0);
      expect(changes.hasListener, isFalse);
      expect(service.initialized, isFalse);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(changes.hasListener, isTrue);
      expect(service.initialized, isTrue);
      expect(service.inputs.single.id, 'port');
    } finally {
      service.dispose();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await changes.close();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    }
  });

  testWidgets('resume retries an initial read invalidated by backgrounding', (
    tester,
  ) async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final changes = StreamController<dynamic>.broadcast();
    final pending = Completer<List<Map<String, dynamic>>>();
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      if (++reads == 1) return pending.future;
      return [
        {'id': 'fresh', 'label': 'HDMI 2', 'type': 1007},
      ];
    });
    final service = TvInputsService(
      FLauncherChannel(),
      changes: changes.stream,
    );
    try {
      await tester.pump();
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      pending.complete([
        {'id': 'old', 'label': 'HDMI 1', 'type': 1007},
      ]);
      await tester.pumpAndSettle();
      expect(reads, 2);
      expect(service.inputs.single.id, 'fresh');
      expect(service.initialized, isTrue);
    } finally {
      service.dispose();
      await changes.close();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    }
  });

  testWidgets('queued initialization stays idle after the service is paused', (
    tester,
  ) async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final changes = StreamController<dynamic>.broadcast();
    final work = ForegroundWork(now: () => tester.binding.clock.now())
      ..homeReady();
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      reads++;
      return [];
    });
    final service = TvInputsService(
      FLauncherChannel(),
      changes: changes.stream,
      work: work,
    );
    try {
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 1));
      expect(reads, 0);
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(reads, 1);
      expect(service.initialized, isTrue);
    } finally {
      service.dispose();
      work.dispose();
      await changes.close();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    }
  });

  testWidgets('callbacks update connection; background and dispose detach', (
    tester,
  ) async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final changes = StreamController<dynamic>.broadcast();
    var state = 0;
    var reads = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      _,
    ) async {
      reads++;
      return [
        {'id': 'port', 'label': 'HDMI 1', 'type': 1007, 'state': state},
      ];
    });
    final service = TvInputsService(
      FLauncherChannel(),
      changes: changes.stream,
    );
    await tester.pumpAndSettle();
    expect(service.inputs.single.connection, TvInputConnection.connected);
    state = 1;
    changes.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 110));
    await tester.pumpAndSettle();
    expect(service.inputs.single.connection, TvInputConnection.standby);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    final before = reads;
    state = 2;
    changes.add(true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(reads, before);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(service.inputs.single.connection, TvInputConnection.disconnected);
    service.dispose();
    changes.add(true);
    await tester.pump(const Duration(milliseconds: 200));
    expect(reads, before + 1);
    await changes.close();
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  testWidgets(
    'refresh replaces a named CEC device with its port after removal',
    (tester) async {
      const channel = MethodChannel('me.efesser.flauncher/method');
      var connected = true;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        (_) async => [
          {'id': 'port', 'label': 'HDMI 2', 'type': 1007},
          if (connected)
            {'id': 'cec', 'label': 'XBOX', 'parentId': 'port', 'type': 1007},
        ],
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      final service = TvInputsService(FLauncherChannel());
      addTearDown(service.dispose);
      await tester.pumpAndSettle();
      expect(service.inputs.single.label, 'XBOX');
      expect(service.inputs.single.id, 'port');
      connected = false;
      await service.refreshInputs();
      expect(service.inputs.single.label, 'HDMI 2');
      expect(service.inputs.single.id, 'port');
      expect(service.inputs.single.aliases, isEmpty);
    },
  );
}
