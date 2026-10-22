import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flauncher/models/tv_input.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
