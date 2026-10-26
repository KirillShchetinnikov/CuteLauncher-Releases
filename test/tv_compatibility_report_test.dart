import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/tv_compatibility_report.dart';
import 'package:flauncher/tv_compatibility_diagnostics.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../scripts/device_compatibility.dart' as catalog;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 10, 21);
  final raw = <String, dynamic>{
    'identity': {
      'manufacturer': 'TCL',
      'model': 'Smart TV Pro',
      'device': 'G10',
      'fingerprint': 'TCL/G10/G10:14/build/AU01:user/release-keys',
      'firmware': 'AU01',
      'android': '14',
      'sdk': '34',
      'abis': 'armeabi-v7a',
      'serial': 'private-serial',
      'ssid': 'private-network',
    },
    'kind': 'physical',
    'checks': {
      'androidTv': 'available',
      'overlay': 'notGranted',
      'homeSelection': 'restricted',
      'unexpected': 'private-exception',
    },
    'accounts': ['private-account'],
  };

  test(
    'profile includes firmware identity but drops private and unexpected data',
    () {
      final report = createTvCompatibilityReport(
        raw,
        capturedAt: now,
        version: '1.0.24',
        build: '73',
      );
      expect(jsonEncode(report), isNot(contains('private')));
      expect(report['scope'], 'readOnlyMetadata');
      expect((report['checks'] as Map).length, tvCompatibilityChecks.length);
      expect((report['checks'] as Map)['overlay'], 'notGranted');
      expect((report['checks'] as Map)['documentExport'], 'unknown');
      expect(parseTvCompatibilityReport(report), report);
      expect(
        () => parseTvCompatibilityReport({
          ...report,
          'scope': 'verifiedAllFunctions',
        }),
        throwsFormatException,
      );
      expect(
        () => parseTvCompatibilityReport({...report, 'capturedAt': 'bad-date'}),
        throwsFormatException,
      );
      final malformed = createTvCompatibilityReport({
        'identity': {'model': 'bad\nvalue'},
        'checks': {'overlay': 'SECRET'},
        'kind': 'SECRET',
      }, capturedAt: now);
      expect(malformed['identity'], isEmpty);
      expect((malformed['checks'] as Map)['overlay'], 'unknown');
      expect(malformed['kind'], 'unknown');
    },
  );
  test('app report can be sanitized and archived for Git without overwriting or promoting observations', () async {
    final directory = await Directory.systemTemp.createTemp('device-report-');
    try {
      final report = createTvCompatibilityReport(raw, capturedAt: now);
      final saved = catalog.archiveDeviceReport(
        {...report, 'secret': 'private'},
        directory,
        'tcl43-au01',
      );
      expect(
        jsonDecode(saved.readAsStringSync()),
        publicTvCompatibilityReport(report),
      );
      expect(catalog.validateArchivedProfiles(directory), isEmpty);
      expect(
        () => catalog.archiveDeviceReport(report, directory, 'tcl43-au01'),
        throwsA(isA<FileSystemException>()),
      );
      expect(
        () => catalog.archiveDeviceReport(report, directory, '../outside'),
        throwsFormatException,
      );
      saved.writeAsStringSync(jsonEncode({...report, 'serial': 'private'}));
      expect(catalog.validateArchivedProfiles(directory), isNotEmpty);
    } finally {
      await directory.delete(recursive: true);
    }
  });
  test('unified report shares one header and publication excludes errors and settings', () {
    final diagnostics = DiagnosticsStore().snapshot(
      version: '1.2.1',
      build: '99',
      environment: {
        'androidApi': 34,
        'device': {'manufacturer': 'DEXP', 'model': '55MCG'},
      },
    );
    final combined = combineDiagnosticsReport(
      {
        ...diagnostics,
        'failures': [
          {'errorText': 'private-log', 'settingsRef': 1},
        ],
        'settingsSnapshots': [
          {
            'id': 1,
            'values': {'memory_saver_enabled': true},
          },
        ],
        'settingsAtExport': {'show_weather_in_status_bar': true},
        'nativeShell': {'stdout': 'private-network'},
      },
      createTvCompatibilityReport(raw, capturedAt: now),
      capturedAt: DateTime.utc(2026, 10, 25, 14, 32),
    );
    expect(combined['schemaVersion'], 3);
    expect(combined.containsKey('identity'), isFalse);
    expect(combined.containsKey('installedLauncher'), isFalse);
    expect((combined['compatibility'] as Map)['status'], 'complete');
    expect(
      (combined['compatibility'] as Map)['checks']['overlay'],
      'notGranted',
    );
    expect((combined['app'] as Map)['version'], '1.2.1');
    final publication = publicTvCompatibilityReport(combined);
    final json = jsonEncode(publication);
    for (final private in [
      'private',
      'failures',
      'settings',
      'nativeShell',
      'fingerprint',
      'G10',
      '14:32',
    ]) {
      expect(json, isNot(contains(private)), reason: private);
    }
    expect((publication['checks'] as Map)['overlay'], 'unknown');
    expect((publication['checks'] as Map)['androidTv'], 'available');
    expect((publication['identity'] as Map)['model'], 'Smart TV Pro');
    expect(parseTvCompatibilityReport(publication), publication);
    final granted = publicTvCompatibilityReport({
      ...combined,
      'compatibility': {'scope': 'readOnlyMetadata', 'status': 'complete',
        'checks': {'overlay': 'available', 'defaultHome': 'available'}},
    });
    expect((granted['checks'] as Map)['overlay'], 'unknown');
    expect((granted['checks'] as Map)['defaultHome'], 'unknown');
    final incomplete = combineDiagnosticsReport(
      diagnostics,
      null,
      capturedAt: now,
    );
    expect((incomplete['compatibility'] as Map)['status'], 'unavailable');
    expect((incomplete['compatibility'] as Map)['checks'].values.toSet(), {
      'unknown',
    });
  });
  test('collector calls only the read-only snapshot and never ADB or mutating actions', () async {
    PackageInfo.setMockInitialValues(
      appName: 'CuteLauncher',
      packageName: 'test',
      version: '1.0.24',
      buildNumber: '73',
      buildSignature: 'private',
    );
    const channel = MethodChannel('me.efesser.flauncher/method');
    final calls = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return raw;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final report = await collectTvCompatibility();
    expect(calls, ['getTvCompatibilityDiagnostics']);
    expect(report['installedLauncher'], {
      'versionName': '1.0.24',
      'versionCode': '73',
    });
    expect(jsonEncode(report), isNot(contains('private')));
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(
        code: 'unavailable',
        message: 'private-error',
      ),
    );
    await expectLater(
      collectTvCompatibility(),
      throwsA(isA<PlatformException>()),
    );
  });
  testWidgets('an unresponsive read times out instead of reporting success', (
    tester,
  ) async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final messenger = tester.binding.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      channel,
      (_) => Completer<Object?>().future,
    );
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final failed = expectLater(
      collectTvCompatibility(),
      throwsA(isA<TimeoutException>()),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 16));
    await failed;
  });
  test('native compatibility collector contains no device-changing or private-data operations', () {
    final source = File(
      'android/app/src/main/java/com/leanbitlab/ltvL/TvCompatibilityDiagnostics.java',
    ).readAsStringSync();
    for (final forbidden in [
      'startActivity(',
      'startService(',
      'requestPermissions(',
      'Settings.Secure.put',
      'Settings.System.put',
      'ProcessBuilder(',
      'Runtime.getRuntime(',
      'getSerial(',
      'getAccounts(',
      'getConnectionInfo(',
    ]) {
      expect(source, isNot(contains(forbidden)));
    }
    for (final check in tvCompatibilityChecks) {
      expect(source, contains('"$check"'));
    }
  });
}
