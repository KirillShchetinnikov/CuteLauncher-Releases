import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'bridge_result.dart';
import 'diagnostics_store.dart';

/// Bounded failure snapshots, no filenames, URIs or file contents.
class BackgroundVideoDiagnostics {
  static int _sequence = 0;
  static final _pending = <Future<void>>{};
  final int attempt = ++_sequence;
  final String operation;
  final Stopwatch _elapsed = Stopwatch()..start();
  int? fileBytes;
  final Future<String?> Function()? nativeLog;
  BackgroundVideoDiagnostics(this.operation, {this.nativeLog});

  static Future<void> flush() async {
    try {
      await Future.wait(_pending.toList()).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> inspect(File file) async {
    try {
      fileBytes = await file.length();
    } on FileSystemException {
      /* Retain the player error. */
    }
  }

  void failure(
    String stage,
    Object error,
    StackTrace? stack,
    VideoPlayerValue value, {
    String? reason,
    bool? visible,
    bool? resumed,
  }) {
    final details = <String, Object?>{
      'stage': stage,
      'reason':
          reason ??
          (error is TimeoutException ? 'video_timeout' : 'video_player'),
      'exception': DiagnosticsStore.exceptionKind(error),
      'attempt': attempt,
      'fileBytes': fileBytes,
      'width': value.size.width.isFinite ? value.size.width.toInt() : 0,
      'height': value.size.height.isFinite ? value.size.height.toInt() : 0,
      'durationMs': value.duration.inMilliseconds,
      'positionMs': value.position.inMilliseconds,
      'initialized': value.isInitialized,
      'playing': value.isPlaying,
      'buffering': value.isBuffering,
      'visible': visible,
      'resumed': resumed,
    };
    DiagnosticsStore.instance.record(
      'dart',
      operation,
      'error',
      'operation_failed',
      context: {
        'durationMs': _elapsed.elapsedMilliseconds,
        'nativeCode': error is PlatformException ? error.code : null,
        'details': details,
        'errorText': error.toString(),
        'errorDetails': value.errorDescription,
        'frames': DiagnosticsStore.safeFrames(stack),
      },
    );
    if (Platform.isAndroid || nativeLog != null) {
      final future = _native(details, DiagnosticsStore.instance.generation);
      _pending.add(future);
      unawaited(future.whenComplete(() => _pending.remove(future)));
    }
  }

  Future<void> _native(Map<String, Object?> details, int generation) async {
    String log;
    try {
      log =
          await (nativeLog?.call() ??
                  const BridgeChannel('me.efesser.flauncher/method')
                      .invokeMethod<String>('getVideoPlaybackLog'))
              .timeout(const Duration(seconds: 4)) ??
          'Media log unavailable';
    } catch (_) {
      log = 'Media log unavailable';
    }
    if (generation != DiagnosticsStore.instance.generation) return;
    DiagnosticsStore.instance.record(
      'dart',
      'backgroundVideoNative',
      'error',
      'operation_failed',
      context: {
        'details': details,
        'errorText': log.substring(0, log.length.clamp(0, 2000)),
        if (log.length > 2000)
          'errorDetails': log.substring(2000, log.length.clamp(2000, 4000)),
      },
    );
  }
}
