import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/night_mode_service.dart';

void main() {
  const channel = MethodChannel('cutelauncher/tcl_blue_light');
  testWidgets(
      'reads native state, verifies writes and refreshes external changes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    var enabled = true;
    var reject = false;
    final writes = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (call) async {
      if (call.method == 'set') {
        writes.add(call.arguments['enabled'] as bool);
        if (reject) return {'status': 'error'};
        enabled = call.arguments['enabled'] as bool;
      }
      return {'status': 'success', 'enabled': enabled};
    });
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('cutelauncher/night'),
        (_) async => {'permission': false});
    addTearDown(() {
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('cutelauncher/night'), null);
    });
    final service = NightModeService(await SharedPreferences.getInstance());
    await tester.pump();
    expect(service.tclFilterAvailable, isTrue);
    expect(service.tclFilterEnabled, isTrue);
    expect(writes, isEmpty);
    await service.setTclFilter(false);
    expect(service.tclFilterEnabled, isFalse);
    expect(service.configuration.enabled, isFalse);
    enabled = true;
    await service.refreshTclFilter();
    expect(service.tclFilterEnabled, isTrue);
    reject = true;
    await service.setTclFilter(false);
    expect(service.tclFilterEnabled, isTrue);
    expect(service.tclFilterAvailable, isFalse);
    expect(service.tclFilterStatus, 'error');
    expect(service.tclFilterBusy, isFalse);
    service.dispose();
  });
}
