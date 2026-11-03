import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

/// Keeps enough source pixels for cover cropping, including focus growth.
/// Dimensions participate in the cache key; focus itself does not.
class CoverMemoryImage extends MemoryImage {
  final int width;
  final int height;
  final int maximumEdge;

  CoverMemoryImage(
    super.bytes, {
    required Size logicalSize,
    required double pixelRatio,
    required double focusScale,
    this.maximumEdge = 2048,
  }) : width = (logicalSize.width * pixelRatio * focusScale).ceil().clamp(
         1,
         maximumEdge,
       ),
       height = (logicalSize.height * pixelRatio * focusScale).ceil().clamp(
         1,
         maximumEdge,
       );

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return super.loadImage(key, (buffer, {getTargetSize}) {
      return decode(
        buffer,
        getTargetSize: (sourceWidth, sourceHeight) {
          final cover = math.max(width / sourceWidth, height / sourceHeight);
          final factor = math.min(
            math.min(1.0, cover),
            maximumEdge / math.max(sourceWidth, sourceHeight),
          );
          return ui.TargetImageSize(
            width: (sourceWidth * factor).ceil().clamp(1, maximumEdge),
            height: (sourceHeight * factor).ceil().clamp(1, maximumEdge),
          );
        },
      );
    });
  }

  @override
  bool operator ==(Object other) =>
      other is CoverMemoryImage &&
      other.bytes == bytes &&
      other.width == width &&
      other.height == height &&
      other.maximumEdge == maximumEdge;

  @override
  int get hashCode => Object.hash(bytes, width, height, maximumEdge);
}
