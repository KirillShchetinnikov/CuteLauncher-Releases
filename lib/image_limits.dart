import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';

const maximumImageInputBytes = 8 * 1024 * 1024;
const maximumImagePixels = 48 * 1024 * 1024;

enum ImageInputFailure { invalid, bytes, dimensions }

class ImageInputException implements Exception {
  final ImageInputFailure reason;
  const ImageInputException([this.reason = ImageInputFailure.invalid]);
}

Future<Uint8List> readBoundedImage(
  Stream<List<int>> input, {
  int limit = maximumImageInputBytes,
}) async {
  final bytes = BytesBuilder(copy: false);
  await for (final chunk in input) {
    if (bytes.length + chunk.length > limit) {
      throw const ImageInputException(ImageInputFailure.bytes);
    }
    bytes.add(chunk);
  }
  return bytes.takeBytes();
}

Future<void> validateImageBytes(Uint8List bytes) async {
  if (bytes.isEmpty || bytes.lengthInBytes > maximumImageInputBytes) {
    throw ImageInputException(
      bytes.lengthInBytes > maximumImageInputBytes
          ? ImageInputFailure.bytes
          : ImageInputFailure.invalid,
    );
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? descriptor;
  try {
    descriptor = await ui.ImageDescriptor.encoded(buffer);
    if (descriptor.width <= 0 ||
        descriptor.height <= 0 ||
        descriptor.width > 16384 ||
        descriptor.height > 16384 ||
        descriptor.width * descriptor.height > maximumImagePixels) {
      throw const ImageInputException(ImageInputFailure.dimensions);
    }
  } on ImageInputException {
    rethrow;
  } catch (_) {
    throw ImageInputException();
  } finally {
    descriptor?.dispose();
    buffer.dispose();
  }
}

ResizeImage sizedImage(
  ImageProvider image,
  Size logicalSize,
  double pixelRatio, {
  int maximumEdge = 4096,
}) {
  int dimension(double value) =>
      (value * pixelRatio).ceil().clamp(1, maximumEdge);
  return ResizeImage(
    image,
    width: dimension(logicalSize.width),
    height: dimension(logicalSize.height),
    policy: ResizeImagePolicy.fit,
    allowUpscaling: false,
  );
}
