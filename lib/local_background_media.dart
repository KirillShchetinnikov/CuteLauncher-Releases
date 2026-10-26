import 'dart:io';

import 'package:video_player/video_player.dart';

import 'background_video_diagnostics.dart';
import 'background_video_recovery.dart';

const maximumBackgroundVideoBytes = 256 * 1024 * 1024;

enum BackgroundMediaKind { image, video }

enum BackgroundMediaFailure { format, videoSize, videoResolution, videoCodec }

class BackgroundMediaException implements Exception {
  final BackgroundMediaFailure reason;
  const BackgroundMediaException(this.reason);
}

/// Inspect content, not provider MIME metadata or a filename extension.
BackgroundMediaKind backgroundMediaKind(List<int> bytes) {
  bool starts(List<int> signature, [int offset = 0]) =>
      bytes.length >= offset + signature.length &&
      List.generate(
        signature.length,
        (i) => bytes[offset + i] == signature[i],
      ).every((v) => v);
  if (starts([0xFF, 0xD8, 0xFF]) ||
      starts([0x89, 0x50, 0x4E, 0x47, 13, 10, 26, 10]) ||
      starts([71, 73, 70, 56]) ||
      starts([66, 77]) ||
      (starts([82, 73, 70, 70]) && starts([87, 69, 66, 80], 8))) {
    return BackgroundMediaKind.image;
  }
  if (starts([102, 116, 121, 112], 4) || starts([0x1A, 0x45, 0xDF, 0xA3])) {
    return BackgroundMediaKind.video;
  }
  throw const BackgroundMediaException(BackgroundMediaFailure.format);
}

Future<void> validateBackgroundVideo(File file) async {
  if (await file.length() > maximumBackgroundVideoBytes) {
    throw const BackgroundMediaException(BackgroundMediaFailure.videoSize);
  }
  for (var attempt = 0; attempt < 2; attempt++) {
    final controller = VideoPlayerController.file(
      file,
      videoPlayerOptions: VideoPlayerOptions(
        mixWithOthers: true,
        preventsDisplaySleepDuringVideoPlayback: false,
      ),
    );
    final diagnostics = BackgroundVideoDiagnostics('backgroundVideoValidate');
    await diagnostics.inspect(file);
    var stage = 'videoInitialize';
    var retry = false;
    var released = false;
    try {
      await controller.initialize().timeout(const Duration(seconds: 20));
      stage = 'videoMetadata';
      final size = controller.value.size;
      if (size.isEmpty || controller.value.duration <= Duration.zero) {
        throw const BackgroundMediaException(BackgroundMediaFailure.videoCodec);
      }
      if (size.longestSide > 3840 || size.shortestSide > 2160) {
        throw const BackgroundMediaException(
          BackgroundMediaFailure.videoResolution,
        );
      }
      if (attempt == 1) {
        recordBackgroundVideoRecovery(diagnostics.attempt, 'succeeded');
      }
      return;
    } on BackgroundMediaException catch (error, stack) {
      diagnostics.failure(
        stage,
        error,
        stack,
        controller.value,
        reason: error.reason == BackgroundMediaFailure.videoResolution
            ? 'video_resolution'
            : 'video_metadata',
      );
      if (attempt == 1) {
        recordBackgroundVideoRecovery(diagnostics.attempt, 'failed');
      }
      rethrow;
    } catch (error, stack) {
      diagnostics.failure(stage, error, stack, controller.value);
      retry = attempt == 0 && canRecoverBackgroundVideo(stage);
      if (attempt == 1) {
        recordBackgroundVideoRecovery(diagnostics.attempt, 'failed');
      }
    } finally {
      try {
        await controller.dispose().timeout(const Duration(seconds: 3));
        released = true;
      } catch (error, stack) {
        diagnostics.failure('videoDispose', error, stack, controller.value);
      }
    }
    if (retry &&
        released &&
        await enableBackgroundVideoRecovery(diagnostics.attempt)) {
      continue;
    }
    throw const BackgroundMediaException(BackgroundMediaFailure.videoCodec);
  }
}
