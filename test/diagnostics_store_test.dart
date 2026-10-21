import 'dart:convert';
import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/diagnostics_report.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'allowlist drops personal data, keys, addresses and arbitrary error text',
      () {
    final store = DiagnosticsStore();
    store.record('cutelauncher/adb', 'action', 'denied', 'secret-password');
    store.record('me.efesser.flauncher/method', 'https://private.example',
        'private-status', '/private/path');
    store.record('private-channel', 'getApplications', 'success', 'ok');
    final report = store.snapshot(
        version: 'secret-version',
        build: 'secret-build',
        environment: {
          'androidApi': 14,
          'overlayAllowed': true,
          'defaultHome': false,
          'address': '192.168.1.73',
          'key': 'secret-key',
          'packages': ['private.package'],
          'notificationsAllowed': 'secret-value',
        },
        memory: {
          'pssBytes': 100,
          'rssBytes': -1,
          'graphicsBytes': double.infinity,
          'path': '/private/path'
        });
    final json = jsonEncode(report);
    for (final private in [
      'secret-',
      'https://',
      '/private',
      '192.168.',
      'private.package',
      'private-channel',
      'private-status'
    ]) {
      expect(json, isNot(contains(private)));
    }
    expect(report['system'],
        {'androidApi': 14, 'overlayAllowed': true, 'defaultHome': false});
    expect(report['memory'], {'pssBytes': 100});
    expect(report['operationCounts'], {'denied': 1, 'error': 1});
  });
  test(
      'ring is bounded, summary counts all operations and snapshots are independent',
      () {
    final store = DiagnosticsStore();
    for (var i = 0; i < 60; i++) {
      store.record('cutelauncher/night', 'configure', 'success', 'ok');
    }
    final report = store.snapshot(version: '1.0.0', build: '8');
    expect(
        (report['recentOperations'] as List).length, DiagnosticsStore.capacity);
    expect(report['operationCounts'], {'success': 60});
    store.clear();
    expect(store.snapshot()['recentOperations'], isEmpty);
    expect(store.snapshot()['operationCounts'], isEmpty);
    expect(
        (report['recentOperations'] as List).length, DiagnosticsStore.capacity);
  });
  test(
      'real channel failure records safe status without arguments or native details',
      () async {
    DiagnosticsStore.instance.clear();
    const channel = BridgeChannel('me.efesser.flauncher/method');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(
            code: 'PERMISSION_DENIED',
            message: 'secret-token',
            details: {'path': '/private/file'}));
    await channel.invokeResult<bool>('launchApp', 'private.package');
    final json =
        DiagnosticsStore.instance.encode(DiagnosticsStore.instance.snapshot());
    expect(json, contains('permission_denied'));
    expect(json, isNot(contains('private')));
    expect(json, isNot(contains('secret')));
    messenger.setMockMethodCallHandler(channel, null);
    DiagnosticsStore.instance.clear();
  });
  test(
      'report collection projects native environment and memory through allowlist',
      () async {
    PackageInfo.setMockInitialValues(
        appName: 'Private title',
        packageName: 'private.package',
        version: '1.0.0',
        buildNumber: '8',
        buildSignature: 'private-signature');
    const channel = BridgeChannel('me.efesser.flauncher/method');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
        channel,
        (call) async => call.method == 'getDiagnosticEnvironment'
            ? {
                'androidApi': 34,
                'defaultHome': true,
                'serial': 'private-serial'
              }
            : {'pssBytes': 1024, 'path': '/private/file'});
    final json = jsonEncode(await collectDiagnostics());
    expect(json, contains('1024'));
    expect(json, isNot(contains('private')));
    expect(json, isNot(contains('signature')));
    messenger.setMockMethodCallHandler(channel, null);
    DiagnosticsStore.instance.clear();
  });
}
