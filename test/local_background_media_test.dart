import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flauncher/local_background_media.dart';

import 'fake_background_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('image and video signatures do not depend on an extension or MIME', () {
    for (final header in [
      [255, 216, 255],
      [137, 80, 78, 71, 13, 10, 26, 10],
      [71, 73, 70, 56],
      [66, 77],
      [82, 73, 70, 70, 0, 0, 0, 0, 87, 69, 66, 80],
    ]) {
      expect(backgroundMediaKind(header), BackgroundMediaKind.image);
    }
    for (final header in [
      [0, 0, 0, 24, 102, 116, 121, 112],
      [26, 69, 223, 163],
    ]) {
      expect(backgroundMediaKind(header), BackgroundMediaKind.video);
    }
    for (final header in [
      <int>[],
      [255],
      [1, 2, 3, 4],
      [82, 73, 70, 70],
    ]) {
      expect(
        () => backgroundMediaKind(header),
        throwsA(isA<BackgroundMediaException>()),
      );
    }
  });

  test('video validation rejects decoder errors and over-4K dimensions, releases resources', () async {
    final previous = VideoPlayerPlatform.instance;
    final fake = FakeBackgroundVideo();
    VideoPlayerPlatform.instance = fake;
    final dir = await Directory.systemTemp.createTemp('background-video-');
    final file = await File('${dir.path}/test.mp4').writeAsBytes([0]);
    try {
      await validateBackgroundVideo(file);
      expect(fake.preventsSleep, false);
      expect(fake.calls, contains('dispose'));
      fake.size = const Size(4096, 2160);
      await expectLater(
        validateBackgroundVideo(file),
        throwsA(
          isA<BackgroundMediaException>().having(
            (e) => e.reason,
            'reason',
            BackgroundMediaFailure.videoResolution,
          ),
        ),
      );
      fake.reject = true;
      await expectLater(
        validateBackgroundVideo(file),
        throwsA(
          isA<BackgroundMediaException>().having(
            (e) => e.reason,
            'reason',
            BackgroundMediaFailure.videoCodec,
          ),
        ),
      );
      expect(fake.calls.where((c) => c == 'dispose'), hasLength(3));
    } finally {
      VideoPlayerPlatform.instance = previous;
      await dir.delete(recursive: true);
    }
  });
}
