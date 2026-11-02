import 'package:flauncher/media_capabilities.dart';
import 'package:flauncher/diagnostics_report.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final raw = {
    'display': {'status': 'available', 'data': {
      'currentMode': {'width': 3840, 'height': 2160, 'refreshRateHz': 59.94, 'serial': 'secret'},
      'modes': List.filled(100, {'width': 1920, 'height': 1080, 'refreshRateHz': 60}),
      'hdrTypes': [1, 2, 3, 4],
    }},
    'decoders': {'status': 'available', 'data': [{
      'name': 'c2.vendor.hevc.decoder', 'mime': 'video/hevc', 'status': 'available',
      'acceleration': 'hardware', 'maxWidth': 3840, 'maxHeight': 2160,
      'maxFrameRateHz': 60, 'profileLevels': [{'profile': 1, 'level': 4096}],
      'deviceName': 'secret',
    }]},
    'audioOutputs': {'status': 'available', 'data': [{
      'type': 9, 'encodings': [2, 5], 'channelCounts': [2, 6], 'sampleRatesHz': [48000],
      'address': 'secret', 'productName': 'secret',
    }]},
  };
  test('preserves bounded reported formats without device identifiers', () {
    final value = mediaCapabilities(raw);
    expect(value.toString(), isNot(contains('secret')));
    expect(((value['display'] as Map)['data'] as Map)['modes'], hasLength(64));
    final codec = ((value['decoders'] as Map)['data'] as List).single as Map;
    expect(codec['acceleration'], 'hardware');
    expect(codec['maxWidth'], 3840);
    expect(codec['profileLevels'], [{'profile': 1, 'level': 4096}]);
    expect(value['scope'], 'reportedCapabilitiesOnly');
  });
  test('missing, invalid and oversized metadata stays unavailable or bounded', () {
    expect(mediaCapabilities(null)['display'], {'status': 'unavailable'});
    final value = mediaCapabilities({'decoders': {'status': 'available', 'data': [
      {'name': 'https://private', 'mime': 'video/hevc'},
      ...List.filled(200, {'name': 'codec', 'mime': 'video/avc', 'maxWidth': double.infinity,
        'maxHeight': -1, 'maxFrameRateHz': double.nan, 'acceleration': 'secret'}),
    ]}});
    final codecs = (value['decoders'] as Map)['data'] as List;
    expect(codecs, hasLength(127));
    expect(codecs.first['acceleration'], 'unknown');
    expect(codecs.first.containsKey('maxWidth'), false);
    expect(codecs.first.containsKey('maxHeight'), false);
  });
  test('unified diagnostics includes the same sanitized capability snapshot', () async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async =>
      call.method == 'getTvCompatibilityDiagnostics' ? {'identity': {}, 'checks': {}, 'mediaCapabilities': raw} : null);
    try {
      final report = await collectDiagnostics();
      expect(report['mediaCapabilities'], mediaCapabilities(raw));
    } finally { messenger.setMockMethodCallHandler(channel, null); }
  });
}
