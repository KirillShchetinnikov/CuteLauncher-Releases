import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/tv_compatibility_report.dart';
import 'package:flauncher/tv_compatibility_diagnostics.dart';
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
      expect(jsonDecode(saved.readAsStringSync()), report);
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
