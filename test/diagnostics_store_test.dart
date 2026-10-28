import 'dart:convert';

import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/diagnostics_report.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/tv_compatibility_report.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('one collection contains compatibility, error history and a shared app/device header', () async {
    DiagnosticsStore.instance.clear();
    PackageInfo.setMockInitialValues(
      appName: 'CuteLauncher',
      packageName: 'test',
      version: '1.2.1',
      buildNumber: '99',
      buildSignature: '',
    );
    const channel = BridgeChannel('me.efesser.flauncher/method');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return switch (call.method) {
        'getDiagnosticEnvironment' => {'androidApi': 34, 'defaultHome': false},
        'getProcessMemoryUsage' => {'pssBytes': 1024},
        'getNativeShellDiagnostics' => {'recent': [], 'failures': []},
        'getDiagnosticApplications' => [
          {'packageName': 'example.tv', 'name': 'TV', 'version': '1', 'enabled': false, 'enabledSetting': 3},
        ],
        'getTvCompatibilityDiagnostics' => {
          'identity': {
            'manufacturer': 'DEXP',
            'model': '55MCG',
            'sdk': '34',
            'android': '14',
            'firmware': 'UKNV.260805.001',
          },
          'kind': 'physical',
          'checks': {'androidTv': 'available', 'overlay': 'notGranted'},
        },
        _ => null,
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    DiagnosticsStore.instance.record(
      'cutelauncher/adb',
      'action',
      'error',
      'operation_failed',
    );
    final report = await collectDiagnostics();
    expect(report['schemaVersion'], 3);
    expect(report['reportType'], 'diagnostics');
    expect(((report['installedApplications'] as Map)['applications'] as List).single['packageName'], 'example.tv');
    expect((report['launcherSections'] as Map)['status'], 'unavailable');
    expect(jsonEncode(publicTvCompatibilityReport(report)), isNot(contains('example.tv')));
    expect(report['app'], {'version': '1.2.1', 'build': '99'});
    expect((report['device'] as Map)['model'], '55MCG');
    expect((report['compatibility'] as Map)['status'], 'complete');
    expect((report['failures'] as List).length, 1);
    expect(report.containsKey('installedLauncher'), isFalse);
    expect(
      calls.where((method) => method == 'getTvCompatibilityDiagnostics').length,
      1,
    );
    DiagnosticsStore.instance.clear();
  });
  test('settings are captured at each failure, deduplicated and frozen across later changes', () {
    final store = DiagnosticsStore();
    final settings = <String, Object>{
      'memory_saver_enabled': false,
      'wallpaper_fit': 'blurred',
      'password': 'hunter2',
      'wallpaper_path': '/private/photo.jpg',
      'night_mode_configuration': '{"enabled":true,"warmth":0.5,"latitude":55.7,"excludedApps":["private.app"]}',
    };
    store.settingsProvider = () => settings;
    store.record('cutelauncher/adb', 'action', 'error', 'operation_failed');
    store.record('cutelauncher/adb', 'action', 'error', 'operation_failed');
    settings['memory_saver_enabled'] = true;
    store.record('dart', 'framework', 'error', 'operation_failed');
    settings['wallpaper_fit'] = 'cover';
    final report = store.snapshot();
    final snapshots = report['settingsSnapshots'] as List;
    final failures = report['failures'] as List;
    expect(snapshots.length, 2);
    expect(failures[0]['settingsRef'], failures[1]['settingsRef']);
    expect(failures[2]['settingsRef'], isNot(failures[0]['settingsRef']));
    expect(snapshots[0]['values']['memory_saver_enabled'], false);
    expect(snapshots[1]['values']['memory_saver_enabled'], true);
    expect(snapshots[1]['values']['wallpaper_fit'], 'blurred');
    expect((report['settingsAtExport'] as Map)['wallpaper_fit'], 'cover');
    final json = jsonEncode(report);
    for (final private in ['hunter2', '/private/', '55.7', 'private.app']) {
      expect(json, isNot(contains(private)));
    }
      for (var i = 0; i < 150; i++) {
        settings['wallpaper_brightness'] = i;
        store.record('dart', 'framework', 'error', 'operation_failed');
      }
      expect((store.snapshot()['settingsSnapshots'] as List).length,
          lessThanOrEqualTo(DiagnosticsStore.failureCapacity));
    store.clear();
    expect(store.snapshot()['settingsSnapshots'], isEmpty);
    store.settingsProvider = () => throw StateError('unavailable');
    store.record('dart', 'framework', 'error', 'operation_failed');
    expect(
      (store.snapshot()['failures'] as List).single['settingsStatus'],
      'unavailable',
    );
  });
  test('failures survive successful traffic and contain independent redacted context', () {
    final store = DiagnosticsStore();
    final details = {
      'reason': 'wifi_owner_missing',
      'networkCount': 2,
      'knownOwnerCount': 1,
      'ssid': 'My home',
    };
    store.record(
      'cutelauncher/adb',
      'action',
      'error',
      'operation_failed',
      context: {
        'action': 'preview',
        'requestedOperation': 'disableSystem',
        'nativeCode': 'wifiUnknown',
        'durationMs': 123,
        'details': details,
        'response': {'status': 'wifiUnknown', 'ssid': 'My home'},
      },
    );
    details['reason'] = 'wifi_owner_setup';
    for (var i = 0; i < 80; i++) {
      store.record('cutelauncher/adb', 'info', 'success', 'ok');
    }
    final report = store.snapshot();
    final failure = (report['failures'] as List).single as Map;
    expect(failure['action'], 'preview');
    expect(failure['requestedOperation'], 'disableSystem');
    expect(failure['nativeCode'], 'wifiUnknown');
    expect(failure['details']['reason'], 'wifi_owner_missing');
    expect(jsonEncode(report), isNot(contains('My home')));
    (failure['details'] as Map)['reason'] = 'mutated';
    expect(jsonEncode(store.snapshot()), isNot(contains('mutated')));
    for (var i = 0; i < 110; i++) {
      store.record('dart', 'framework', 'error', 'operation_failed');
    }
    expect(
      (store.snapshot()['failures'] as List).length,
      DiagnosticsStore.failureCapacity,
    );
    store.clear();
    expect(store.snapshot()['failures'], isEmpty);
  });
  test('all bridge scopes record errors and framework frames omit machine paths', () {
    final store = DiagnosticsStore();
    for (final scope in [
      'auto_launch',
      'cloud_account',
      'drive_account',
      'weather_location',
      'tcl_blue_light',
      'remote_buttons',
      'remote_mappings',
      'media',
      'sleep_timer',
      'tv_power',
    ]) {
      store.record('cutelauncher/$scope', 'save', 'error', 'operation_failed');
    }
    store.recordException(
      'framework',
      StateError('password=hunter2'),
      StackTrace.fromString(
        '#0 Private.name (package:flauncher/widgets/action_notice.dart:40:2)\n'
        '#1 private (file:///Users/Alice/private.dart:22:1)',
      ),
    );
    final report = store.snapshot();
    expect((report['failures'] as List).length, 11);
    final json = jsonEncode(report);
    expect(json, contains('package:flauncher/widgets/action_notice.dart:40:2'));
    expect(json, isNot(contains('Alice')));
    expect(json, isNot(contains('hunter2')));
  });
  test(
    'allowlist drops personal data, keys, addresses and arbitrary error text',
    () {
      final store = DiagnosticsStore();
      store.record('cutelauncher/adb', 'action', 'denied', 'secret-password');
      store.record(
        'me.efesser.flauncher/method',
        'https://private.example',
        'private-status',
        '/private/path',
      );
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
          'path': '/private/path',
        },
      );
      final json = jsonEncode(report);
      for (final private in [
        'secret-',
        'https://',
        '/private',
        '192.168.',
        'private.package',
        'private-channel',
        'private-status',
      ]) {
        expect(json, isNot(contains(private)));
      }
      expect(report['system'], {
        'androidApi': 14,
        'overlayAllowed': true,
        'defaultHome': false,
      });
      expect(report['memory'], {'pssBytes': 100});
      expect(report['operationCounts'], {'denied': 1, 'error': 1});
    },
  );
  test('ring is bounded, summary counts all operations and snapshots are independent', () {
    final store = DiagnosticsStore();
    for (var i = 0; i < 60; i++) {
      store.record('cutelauncher/night', 'configure', 'success', 'ok');
    }
    final report = store.snapshot(version: '1.0.0', build: '8');
    expect(
      (report['recentOperations'] as List).length,
      DiagnosticsStore.capacity,
    );
    expect(report['operationCounts'], {'success': 60});
    store.clear();
    expect(store.snapshot()['recentOperations'], isEmpty);
    expect(store.snapshot()['operationCounts'], isEmpty);
    expect(
      (report['recentOperations'] as List).length,
      DiagnosticsStore.capacity,
    );
  });
  test('real channel failure records safe status without arguments or native details', () async {
    DiagnosticsStore.instance.clear();
    const channel = BridgeChannel('me.efesser.flauncher/method');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'secret-token',
        details: {'path': '/private/file'},
      ),
    );
    await channel.invokeResult<bool>('launchApp', 'private.package');
    final json = DiagnosticsStore.instance.encode(
      DiagnosticsStore.instance.snapshot(),
    );
    expect(json, contains('permission_denied'));
    expect(json, isNot(contains('private')));
    expect(json, isNot(contains('secret')));
    messenger.setMockMethodCallHandler(channel, null);
    DiagnosticsStore.instance.clear();
  });
  test('report collection projects native environment and memory through allowlist', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Private title',
      packageName: 'private.package',
      version: '1.0.0',
      buildNumber: '8',
      buildSignature: 'private-signature',
    );
    const channel = BridgeChannel('me.efesser.flauncher/method');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (call) async => call.method == 'getDiagnosticEnvironment'
          ? {'androidApi': 34, 'defaultHome': true, 'serial': 'private-serial'}
          : {'pssBytes': 1024, 'path': '/private/file'},
    );
    final json = jsonEncode(await collectDiagnostics());
    expect(json, contains('1024'));
    expect(json, isNot(contains('private')));
    expect(json, isNot(contains('signature')));
    messenger.setMockMethodCallHandler(channel, null);
    DiagnosticsStore.instance.clear();
  });
}
