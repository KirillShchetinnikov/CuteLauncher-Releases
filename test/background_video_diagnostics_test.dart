import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player/video_player.dart';
import 'package:flauncher/background_video_diagnostics.dart';
import 'package:flauncher/diagnostics_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final store = DiagnosticsStore.instance;
  setUp(store.clear);

  test('captures original player error, stage and metadata while redacting private data', () async {
    final dir = await Directory.systemTemp.createTemp('video-diagnostic-');
    final file = await File('${dir.path}/private-user-video.mp4')
        .writeAsBytes([1, 2, 3]);
    try {
      final diagnostics = BackgroundVideoDiagnostics(
        'backgroundVideoValidate',
        nativeLog: () async => 'android.media.MediaCodec\$CodecException: OMX.amlogic.avc.decoder failed\n/data/user/0/private/video.mp4',
      );
      await diagnostics.inspect(file);
      diagnostics.failure(
        'videoInitialize',
        PlatformException(
          code: 'VideoError',
          message: 'androidx.media3.exoplayer.ExoPlaybackException: Decoder error\n/data/private/movie.mp4',
        ),
        StackTrace.current,
        const VideoPlayerValue(duration: Duration(seconds: 30)),
        visible: true,
      );
      await BackgroundVideoDiagnostics.flush();
      final report = store.snapshot();
      final failures = report['failures'] as List;
      expect(failures, hasLength(2));
      expect(failures.first['operation'], 'dart.backgroundVideoValidate');
      expect(failures.first['nativeCode'], 'VideoError');
      expect(failures.first['details']['stage'], 'videoInitialize');
      expect(failures.first['details']['fileBytes'], 3);
      expect(
        failures.last['details']['attempt'],
        failures.first['details']['attempt'],
      );
      final encoded = jsonEncode(report);
      expect(encoded, contains('OMX.amlogic.avc.decoder'));
      expect(encoded, contains('ExoPlaybackException'));
      expect(encoded, isNot(contains('/data/')));
      expect(encoded, isNot(contains('private-user-video')));
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('late native snapshot cannot restore diagnostics after Clear', () async {
    final pending = Completer<String?>();
    final diagnostics = BackgroundVideoDiagnostics(
      'backgroundVideoPlayback',
      nativeLog: () => pending.future,
    );
    diagnostics.failure(
      'videoPlay',
      StateError('Decoder failed'),
      null,
      const VideoPlayerValue(duration: Duration(seconds: 30)),
    );
    store.clear();
    pending.complete('MediaCodec error');
    await BackgroundVideoDiagnostics.flush();
    expect(store.snapshot()['failures'], isEmpty);
  });

  test('initialization timeout is distinguished from codec failure', () {
    BackgroundVideoDiagnostics('backgroundVideoPlayback').failure(
      'videoInitialize',
      TimeoutException('Initialization exceeded 20 seconds'),
      null,
      const VideoPlayerValue(duration: Duration.zero),
    );
    final event = (store.snapshot()['failures'] as List).single;
    expect(event['details']['reason'], 'video_timeout');
    expect(event['details']['exception'], 'timeout');
  });
}
