import 'dart:async';
import 'dart:io';

import 'image_limits.dart';

enum WallpaperStage { initialize, metadata, download, validation, save }

enum WallpaperFailureReason {
  dns,
  connection,
  tls,
  timeout,
  http,
  redirect,
  insecureUrl,
  tooLarge,
  dimensions,
  invalidResponse,
  noImage,
  invalidImage,
  storage,
  unknown,
}

/// Structured errors only: never retain URLs, response bodies or exception text.
class WallpaperException implements Exception {
  final WallpaperFailureReason reason;
  final WallpaperStage? stage;
  final int? httpStatus;
  const WallpaperException(this.reason, {this.stage, this.httpStatus});
}

class WallpaperFailure {
  final WallpaperStage stage;
  final WallpaperFailureReason reason;
  final int? httpStatus;
  final int? osErrorCode;
  const WallpaperFailure(
    this.stage,
    this.reason, {
    this.httpStatus,
    this.osErrorCode,
  });

  factory WallpaperFailure.from(Object error, WallpaperStage stage) {
    if (error is WallpaperException) {
      return WallpaperFailure(
        error.stage ?? stage,
        error.reason,
        httpStatus: error.httpStatus,
      );
    }
    final reason = switch (error) {
      TimeoutException() => WallpaperFailureReason.timeout,
      TlsException() => WallpaperFailureReason.tls,
      HttpException() => WallpaperFailureReason.connection,
      SocketException() =>
        error.message.toLowerCase().contains('failed host lookup')
            ? WallpaperFailureReason.dns
            : WallpaperFailureReason.connection,
      FileSystemException() => WallpaperFailureReason.storage,
      ImageInputException() => switch (error.reason) {
        ImageInputFailure.bytes => WallpaperFailureReason.tooLarge,
        ImageInputFailure.dimensions => WallpaperFailureReason.dimensions,
        ImageInputFailure.invalid => WallpaperFailureReason.invalidImage,
      },
      FormatException() ||
      TypeError() ||
      RangeError() => WallpaperFailureReason.invalidResponse,
      _ =>
        stage == WallpaperStage.validation
            ? WallpaperFailureReason.invalidImage
            : WallpaperFailureReason.unknown,
    };
    return WallpaperFailure(
      stage,
      reason,
      osErrorCode: switch (error) {
        SocketException() => error.osError?.errorCode,
        FileSystemException() => error.osError?.errorCode,
        _ => null,
      },
    );
  }

  Map<String, Object> details(String source) => {
    'wallpaperSource': source,
    'stage': 'wallpaper_${stage.name}',
    'reason': 'wallpaper_${reason.name}',
    'httpStatus': ?httpStatus,
    'osErrorCode': ?osErrorCode,
  };
}
