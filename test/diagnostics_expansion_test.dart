import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/bridge_result.dart';
import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/diagnostics_store.dart';
import 'package:flauncher/providers/audio_status_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('audio route export keeps distinct samples and drops device names', () {
    final store = DiagnosticsStore();
    final bluetooth = {'api': 30, 'legacyBluetooth': true, 'name': 'Private'};
    store.recordAudioRouting(bluetooth, 'bluetooth');
    store.recordAudioRouting(bluetooth, 'bluetooth');
    store.recordAudioRouting({
      'hdmiSelected': false,
      'availableOutputTypes': [2, 10, 'Private'],
    }, 'unknown');
    final samples = store.snapshot()['audioRouting'] as List;
    expect(samples, hasLength(2));
    expect(samples.first['widgetOutput'], 'bluetooth');
    expect(samples.last['availableOutputTypes'], [2, 10]);
    expect(jsonEncode(samples), isNot(contains('Private')));
    store.clear();
    expect(store.snapshot(), isNot(contains('audioRouting')));
  });

  testWidgets('diagnostic build captures the widget result and native route', (tester) async {
    final store = DiagnosticsStore.instance..clear();
    const channel = MethodChannel('cutelauncher/audio_status');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'snapshot') return null;
      expect(call.arguments, true);
      return {
        'outputs': ['bluetooth'],
        'routeDiagnostics': {'api': 30, 'legacyBluetooth': true},
      };
    });
    final service = AudioStatusService();
    addTearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      store.clear();
    });
    service.setVisible(Object(), true);
    await tester.pump();
    final sample = (store.snapshot()['audioRouting'] as List).single;
    service.dispose();
    await tester.pump();
    expect(sample['widgetOutput'], 'bluetooth');
    expect(sample['legacyBluetooth'], true);
  }, skip: !const bool.fromEnvironment('CUTE_AUDIO_ROUTE_DIAGNOSTICS'));

  test('APK verification evidence retains the legacy installer result', () async {
    final store = DiagnosticsStore.instance..clear();
    const channel = BridgeChannel('cutelauncher/updates');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => {
      'status': 'invalid_verification',
      'diagnostic': {'type': 'SecurityException', 'message': 'APK verification failed'},
    });
    addTearDown(() { messenger.setMockMethodCallHandler(channel, null); store.clear(); });
    expect(await channel.invokeMethod<String>('install'), 'invalid_verification');
    final failure = (store.snapshot()['failures'] as List).single;
    expect(failure['nativeCode'], 'invalid_verification');
    expect(failure['errorDetails'], contains('APK verification failed'));
  });

  testWidgets('failed widget sampling keeps the fallback and records its cause', (tester) async {
    final store = DiagnosticsStore.instance..clear();
    const channel = MethodChannel('cutelauncher/audio_status');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'watch') return null;
      throw PlatformException(code: 'unavailable', message: 'Audio sampling failed');
    });
    final service = AudioStatusService();
    service.setVisible(Object(), true);
    await tester.pump();
    expect(service.state, unknownAudioStatus);
    expect((store.snapshot()['failures'] as List).any((event) =>
      event['operation'] == 'audio_status.snapshot' && event['nativeCode'] == 'unavailable'), isTrue);
    service.dispose();
    await tester.pump();
    messenger.setMockMethodCallHandler(channel, null);
    store.clear();
  });

  test('transport failures retain numeric causes without private endpoints', () {
    final store = DiagnosticsStore();
    store.recordException('cloudTransfer', const SocketException(
      'Connection failed https://secret.example/private',
      osError: OSError('private network', 111), port: 443,
    ), StackTrace.current);
    store.recordException('updateCheck', TimeoutException('timeout', const Duration(seconds: 20)), StackTrace.current);
    store.recordException('backupTransfer', const FileSystemException('read failed', '/private/photo', OSError('error', 13)), null);
    store.recordException('driveConnect', const CloudBackupException('server', httpStatus: 503), null);
    final report = store.snapshot();
    final failures = report['failures'] as List;
    expect(failures[0]['details']['osErrorCode'], 111);
    expect(failures[1]['details']['timeoutMs'], 20000);
    expect(failures[2]['details']['osErrorCode'], 13);
    expect(failures[3]['errorText'], contains('HTTP 503'));
    expect(failures[0]['exceptionType'], 'SocketException');
    expect(jsonEncode(report), isNot(contains('secret.example')));
    expect(jsonEncode(report), isNot(contains('/private/photo')));
  });

  test('widget channel failures preserve operation, native cause and duration', () async {
    final store = DiagnosticsStore.instance..clear();
    const channel = BridgeChannel('cutelauncher/storage_status');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(
      code: 'unavailable', message: 'Storage failed', details: {'exception': 'security', 'message': 'Permission denied'},
    ));
    addTearDown(() { messenger.setMockMethodCallHandler(channel, null); store.clear(); });
    final result = await channel.invokeResult('snapshot');
    expect(result.isSuccess, isFalse);
    final event = (store.snapshot()['failures'] as List).single as Map;
    expect(event['operation'], 'storage_status.snapshot');
    expect(event['durationMs'], isNonNegative);
    expect(event['errorDetails'], contains('Permission denied'));
  });

  test('production method channels are journaled except private data and crash bootstrap', () {
    final pattern = RegExp(r'''(BridgeChannel|MethodChannel)\(\s*['"]([^'"]+)['"]''');
    final store = DiagnosticsStore();
    for (final file in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      if (file.path.replaceAll('\\', '/').contains('/diagnostics/')) continue;
      for (final match in pattern.allMatches(file.readAsStringSync())) {
        final name = match[2]!;
        if (name == 'cutelauncher/crash_guard') continue; // Crash-safe bootstrap, before Flutter.
        if (name == 'cutelauncher/weather_token' || name == 'cutelauncher/native_sync') {
          // Secret-store and backup-encryption arguments bypass bridge diagnostics.
          expect(match[1], 'MethodChannel', reason: '${file.path}: $name');
          store.clear();
          store.record(name, 'snapshot', 'error', 'unavailable');
          expect(store.snapshot()['failures'], isEmpty, reason: '${file.path}: $name');
          continue;
        }
        store.clear();
        store.record(name, 'snapshot', 'error', 'unavailable');
        expect(store.snapshot()['failures'], hasLength(1), reason: '${file.path}: $name');
      }
    }
  });

  test('weather secret store cannot record payloads or failures in diagnostics', () {
    final store = DiagnosticsStore();
    final before = store.snapshot()..remove('sessionElapsedMs');
    for (final method in ['has', 'save', 'read']) {
      for (final status in ['success', 'error']) {
        store.record('cutelauncher/weather_token', method, status, 'unavailable', context: {
          'arguments': {'server': 'https://private-weather.test/home', 'token': 'fixture-secret'},
          'response': 'fixture-secret',
          'errorText': 'fixture-secret',
          'errorDetails': 'https://private-weather.test/home',
        });
      }
    }
    expect(store.snapshot()..remove('sessionElapsedMs'), before);
  });
}
