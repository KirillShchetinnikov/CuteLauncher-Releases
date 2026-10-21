import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
