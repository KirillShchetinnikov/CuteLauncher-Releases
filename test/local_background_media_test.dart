import 'dart:io';

import 'package:flauncher/diagnostics_store.dart';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';
import 'package:flauncher/local_background_media.dart';

import 'fake_background_video.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('me.efesser.flauncher/method');
  setUp(() {
    DiagnosticsStore.instance.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (_) async => false);
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
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
      DiagnosticsStore.instance.clear();
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
      final failure =
          (DiagnosticsStore.instance.snapshot()['failures'] as List).single;
      expect(failure['operation'], 'dart.backgroundVideoValidate');
      expect(failure['nativeCode'], 'VideoError');
      expect(failure['errorText'], contains('Unsupported codec'));
      expect(failure['details']['stage'], 'videoInitialize');
    } finally {
      VideoPlayerPlatform.instance = previous;
      await dir.delete(recursive: true);
    }
  });

  for (final secondFails in [false, true]) {
    test(
      'validation retries once after disposal, secondFails=$secondFails',
      () async {
        final previous = VideoPlayerPlatform.instance;
        final fake = FakeBackgroundVideo()
          ..failuresRemaining = secondFails ? 2 : 1;
        VideoPlayerPlatform.instance = fake;
        final dir = await Directory.systemTemp.createTemp(
          'background-recovery-',
        );
        final file = await File('${dir.path}/test.mp4').writeAsBytes([0]);
        var requests = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              expect(call.method, 'enableBackgroundVideoCompatibility');
              expect(fake.calls.where((c) => c == 'dispose'), hasLength(1));
              requests++;
              return true;
            });
        try {
          if (secondFails) {
            await expectLater(
              validateBackgroundVideo(file),
              throwsA(isA<BackgroundMediaException>()),
            );
          } else {
            await validateBackgroundVideo(file);
          }
          expect(requests, 1);
          expect(fake.streams, hasLength(2));
          expect(fake.calls.where((c) => c == 'dispose'), hasLength(2));
          final failures =
              DiagnosticsStore.instance.snapshot()['failures'] as List;
          expect(
            failures.where(
              (f) => f['operation'] == 'dart.backgroundVideoValidate',
            ),
            hasLength(secondFails ? 2 : 1),
          );
          final operations =
              DiagnosticsStore.instance.snapshot()['recentOperations'] as List;
          expect(
            operations.where(
              (op) =>
                  op['details']?['recovery'] ==
                  (secondFails ? 'failed' : 'succeeded'),
            ),
            hasLength(1),
          );
        } finally {
          VideoPlayerPlatform.instance = previous;
          await dir.delete(recursive: true);
        }
      },
    );
  }
}
