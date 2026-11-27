import 'dart:convert';

import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/diagnostics_report.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/diagnostics/poster_loads.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/night_mode_configuration.dart';
import 'package:flauncher/tv_compatibility_report.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('basic report keeps the last 20 safe rows and skips extended platform calls', () async {
    final store = DiagnosticsStore.instance..clear();
    store.settingsProvider = () => {'memory_saver_enabled': true, 'token': 'private-value'};
    const channel = MethodChannel('me.efesser.flauncher/method');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      if (call.method == 'getQuickPanelWidgetDiagnostics') return null;
      return {'androidApi': 34, 'device': {'model': 'Smart TV Pro', 'firmware': 'test.34'}};
    });
    addTearDown(() {
      store.settingsProvider = null;
      store.clear();
      messenger.setMockMethodCallHandler(channel, null);
    });
    for (var i = 0; i < 25; i++) {
      store.record('dart', 'framework', 'error', 'operation_failed', context: {
        'durationMs': i,
        'details': {'exception': 'io'},
        'errorText': 'private-value',
      });
    }
    final report = await collectDiagnostics();
    expect(calls, ['getQuickPanelWidgetDiagnostics', 'getDiagnosticEnvironment']);
    expect(report['reportMode'], 'basic');
    expect(report['settingsAtExport'], {'memory_saver_enabled': true});
    expect((report['recentOperations'] as List).map((row) => row['durationMs']), [
      for (var i = 5; i < 25; i++) i,
    ]);
    expect((report['recentOperations'] as List).last['reason'], 'io');
    for (final key in ['failures', 'nativeShell', 'compatibility', 'installedApplications']) {
      expect(report, isNot(contains(key)));
    }
    expect(jsonEncode(report), isNot(contains('private-value')));
    final projection = sanitizedTvCompatibilityReport(report);
    expect((projection['checks'] as Map).values, everyElement('unknown'));
  });

  test('widget diagnostics keep the remote outcome and previous error after unrelated operations', () async {
    final store = DiagnosticsStore.instance..clear();
    addTearDown(store.clear);
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const metadataChannel = MethodChannel('me.efesser.flauncher/method');
    messenger.setMockMethodCallHandler(metadataChannel, (call) async =>
        call.method == 'getQuickPanelWidgetDiagnostics'
            ? '{"audio":{"inLastLayout":true,"hasRuntimeData":false}}'
            : null);
    addTearDown(() => messenger.setMockMethodCallHandler(metadataChannel, null));
    store.widgetDiagnostics.observeLayout({'remoteBattery': true, 'time': true});
    store.record('cutelauncher/remote_battery', 'snapshot', 'success', 'ok', context: {
      'response': {'batteryRead': 'bluetoothPermissionDenied', 'bluetoothPermission': false},
    });
    store.record('cutelauncher/remote_battery', 'snapshot', 'success', 'ok', context: {
      'response': {
        'batteryRead': 'noMatchingBondedRemote',
        'bluetoothPermission': true,
        'inputCandidates': 1,
        'address': 'AC:BD:EF:12:34:56',
        'name': 'private-room',
      },
    });
    store.record('cutelauncher/remote_battery', 'snapshot', 'success', 'ok', context: {
      'response': {'batteryRead': 'cancelled'},
    });
    store.record('cutelauncher/remote_battery', 'snapshot', 'success', 'ok', context: {
      'response': {'batteryRead': 'screenOff', 'screenOn': false},
    });
    for (var i = 0; i < DiagnosticsStore.basicCapacity; i++) {
      store.record('cutelauncher/audio_status', 'snapshot', 'success', 'ok');
    }
    final report = await collectDiagnostics();
    final widgets = report['widgetDiagnostics'] as Map;
    final home = widgets['home'] as Map;
    final battery = home['remoteBattery'] as Map;
    final snapshot = battery['remote_battery.snapshot'] as Map;
    expect(battery['inLastLayout'], isTrue);
    expect(home['time']['inLastLayout'], isTrue);
    expect(home['system']['inLastLayout'], isFalse);
    expect(snapshot['last']['result'], {
      'batteryRead': 'noMatchingBondedRemote',
      'bluetoothPermission': true,
      'inputCandidates': 1,
    });
    expect(snapshot['lastError']['code'], 'bluetoothPermissionDenied');
    expect(snapshot['lastError']['status'], 'denied');
    expect(widgets['quickPanel']['audio']['inLastLayout'], isTrue);
    expect(jsonEncode(report), isNot(contains('private-room')));
    expect(jsonEncode(report), isNot(contains('AC:BD:EF:12:34:56')));
  });

  test('event limit freezes the recording and leaves basic history live', () async {
    final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
    final firstPoster = store.activePosterLoads!.start(PosterSource.appChannels, 'https://example.test/poster');
    for (var i = 0; i < DiagnosticsStore.recordingEventLimit; i++) {
      store.homeTiles.returnHome();
    }
    await Future<void>.value();
    expect(store.recording.value, DiagnosticRecordingState.stopped);
    store.homeTiles.returnHome();
    firstPoster.finish(PosterOutcome.loaded);
    store.record('dart', 'framework', 'error', 'operation_failed');
    final report = store.snapshot(extended: true);
    expect((report['recording'] as Map)['stopReason'], 'eventLimit');
    expect((report['recording'] as Map)['operationsAndTileEvents'], DiagnosticsStore.recordingEventLimit);
    expect((report['posterLoads'] as Map)['recent'], isEmpty);
    expect((report['posterLoads'] as Map)['active'], hasLength(1));
    expect(report['recentOperations'], isEmpty);
    expect(report['recentBasicOperations'], hasLength(1));
  });

  test('landscape report distinguishes astronomical times from the night scheduler fallback', () {
    DateTime at(int hour, int minute) => DateTime(2026, 11, 15, hour, minute);
    final schedule = [
      {
        'sunrise': at(8, 0).millisecondsSinceEpoch,
        'sunset': at(20, 0).millisecondsSinceEpoch,
      },
    ];
    Map<String, Object> report(DateTime time, List<Map<String, dynamic>> days) =>
        landscapeLightingDiagnostics(
          time,
          const LandscapeConfiguration(),
          solarDays: days,
          demoActive: false,
        );
    final evening = report(at(18, 57), schedule);
    expect(evening['phase'], 'day');
    expect(evening['sunSource'], 'nightModeSchedule');
    expect(evening['sunset'], at(20, 0).toUtc().toIso8601String());
    expect(evening['utcOffsetMinutes'], at(18, 57).timeZoneOffset.inMinutes);
    expect(report(at(20, 40), schedule)['phase'], 'twilight');
    final night = report(at(21, 20), schedule);
    expect(night['phase'], 'night');
    expect(night['paletteFrom'], 'night');
    expect(night['paletteTo'], 'night');
    final fixedFallback = [
      {...schedule.single, 'fixedFallback': true},
    ];
    final corrected = report(at(18, 56), fixedFallback);
    expect(corrected['phase'], 'twilight');
    expect(corrected['paletteFrom'], 'twilight');
    expect(corrected['paletteTo'], 'night');
    expect(corrected['sunSource'], 'landscapeDefault');
    expect(corrected['sunset'], at(18, 0).toUtc().toIso8601String());
    expect(report(at(19, 20), fixedFallback)['phase'], 'night');
    final localFallback = report(at(19, 20), []);
    expect(localFallback['phase'], 'night');
    expect(localFallback['sunSource'], 'landscapeDefault');
  });

  test('one collection contains compatibility, error history and a shared app/device header', () async {
    DiagnosticsStore.instance..clear()..startRecording();
    addTearDown(DiagnosticsStore.instance.clear);
    PackageInfo.setMockInitialValues(
      appName: 'CuteLauncher',
      packageName: 'test',
      version: '1.8.0-test.4',
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
    DiagnosticsStore.instance.activePosterLoads!.start(PosterSource.appChannels,
        'https://private.example/image?token=secret', packageName: 'example.tv');
    SharedPreferences.setMockInitialValues({'background_source': 'landscape'});
    final settings = SettingsService(await SharedPreferences.getInstance());
    addTearDown(settings.dispose);
    final report = await collectDiagnostics(extended: true, settings: settings);
    expect(report['schemaVersion'], 3);
    expect(report['reportType'], 'diagnostics');
    expect(((report['installedApplications'] as Map)['applications'] as List).single['packageName'], 'example.tv');
    expect((report['launcherSections'] as Map)['status'], 'unavailable');
    expect(jsonEncode(sanitizedTvCompatibilityReport(report)), isNot(contains('example.tv')));
    expect((report['posterLoads'] as Map)['active'], hasLength(1));
    expect(sanitizedTvCompatibilityReport(report).containsKey('posterLoads'), false);
    expect((report['landscapeLighting'] as Map)['sunSource'], 'manualFallback');
    expect(sanitizedTvCompatibilityReport(report).containsKey('landscapeLighting'), false);
    expect(jsonEncode(report), isNot(contains('private.example')));
    expect(jsonEncode(report), isNot(contains('token=secret')));
    expect(report['app'], {'version': '1.8.0-test.4', 'build': '99'});
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
  test('location diagnostics expose only the presence of inputs', () {
    final report = locationSetupDiagnostics(
      const NightModeConfiguration(city: 'Private city', latitude: 34.567, longitude: 12.345),
      const WeatherConfiguration(locationMode: WeatherLocationMode.manual,
        manualCoordinates: (latitude: 60.123, longitude: 40.456)),
    );
    expect(report['nightMode'], {
      'cityConfigured': true,
      'coordinatesStored': true,
      'manualCoordinatesConfigured': false,
      'activeCoordinates': true,
      'automaticLocation': false,
    });
    expect((report['weather'] as Map)['cityConfigured'], false);
    expect((report['weather'] as Map)['manualCoordinatesConfigured'], true);
    final encoded = jsonEncode(report);
    for (final value in ['Private city', '34.567', '12.345', '60.123', '40.456']) {
      expect(encoded, isNot(contains(value)));
    }
  });
  test('settings are captured at each failure, deduplicated and frozen across later changes', () {
    final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
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
    final report = store.snapshot(extended: true);
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
      expect((store.snapshot(extended: true)['settingsSnapshots'] as List).length,
          lessThanOrEqualTo(DiagnosticsStore.failureCapacity));
    store.clear();
    expect(store.snapshot(extended: true)['settingsSnapshots'], isEmpty);
    store.startRecording();
    store.settingsProvider = () => throw StateError('unavailable');
    store.record('dart', 'framework', 'error', 'operation_failed');
    expect(
      (store.snapshot(extended: true)['failures'] as List).single['settingsStatus'],
      'unavailable',
    );
  });
  test('failures survive successful traffic and contain independent redacted context', () {
    final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
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
    final report = store.snapshot(extended: true);
    final failure = (report['failures'] as List).single as Map;
    expect(failure['action'], 'preview');
    expect(failure['requestedOperation'], 'disableSystem');
    expect(failure['nativeCode'], 'wifiUnknown');
    expect(failure['details']['reason'], 'wifi_owner_missing');
    expect(jsonEncode(report), isNot(contains('My home')));
    (failure['details'] as Map)['reason'] = 'mutated';
    expect(jsonEncode(store.snapshot(extended: true)), isNot(contains('mutated')));
    for (var i = 0; i < 110; i++) {
      store.record('dart', 'framework', 'error', 'operation_failed');
    }
    expect(
      (store.snapshot(extended: true)['failures'] as List).length,
      DiagnosticsStore.failureCapacity,
    );
    store.clear();
    expect(store.snapshot(extended: true)['failures'], isEmpty);
  });
  test('all bridge scopes record errors and framework frames omit machine paths', () {
    final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
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
    final report = store.snapshot(extended: true);
    expect((report['failures'] as List).length, 11);
    final json = jsonEncode(report);
    expect(json, contains('package:flauncher/widgets/action_notice.dart:40:2'));
    expect(json, isNot(contains('Alice')));
    expect(json, isNot(contains('hunter2')));
  });
  test(
    'allowlist drops personal data, keys, addresses and arbitrary error text',
    () {
      final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
      store.record('cutelauncher/adb', 'action', 'denied', 'secret-password');
      store.record(
        'me.efesser.flauncher/method',
        'https://private.example',
        'private-status',
        '/private/path',
      );
      store.record('private-channel', 'getApplications', 'success', 'ok');
      final report = store.snapshot(extended: true,
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
    final store = DiagnosticsStore()..startRecording();
    addTearDown(store.clear);
    for (var i = 0; i < 60; i++) {
      store.record('cutelauncher/night', 'configure', 'success', 'ok');
    }
    final report = store.snapshot(extended: true, version: '1.0.0', build: '8');
    expect(
      (report['recentOperations'] as List).length,
      DiagnosticsStore.capacity,
    );
    expect(report['operationCounts'], {'success': 60});
    store.clear();
    expect(store.snapshot(extended: true)['recentOperations'], isEmpty);
    expect(store.snapshot(extended: true)['operationCounts'], isEmpty);
    expect(
      (report['recentOperations'] as List).length,
      DiagnosticsStore.capacity,
    );
  });
  test('real channel failure records safe status without arguments or native details', () async {
    DiagnosticsStore.instance..clear()..startRecording();
    addTearDown(DiagnosticsStore.instance.clear);
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
      DiagnosticsStore.instance.snapshot(extended: true),
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
    final json = jsonEncode(await collectDiagnostics(extended: true));
    expect(json, contains('1024'));
    expect(json, isNot(contains('private')));
    expect(json, isNot(contains('signature')));
    messenger.setMockMethodCallHandler(channel, null);
    DiagnosticsStore.instance.clear();
  });
}
