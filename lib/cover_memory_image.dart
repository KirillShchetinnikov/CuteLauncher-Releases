import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';

import 'content_image.dart';

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
  Future<MemoryImage> obtainKey(ImageConfiguration configuration) =>
      contentImage(bytes).then(
        (content) => _CoverImageKey(content, width, height, maximumEdge),
      );

  @override
  ImageStreamCompleter loadImage(MemoryImage key, ImageDecoderCallback decode) {
    return key.loadImage(key, (buffer, {getTargetSize}) {
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

/// Encoded LRU eviction can return a new byte buffer for the same poster.
/// Share its decoded texture while keeping every decode dimension in the key.
class _CoverImageKey extends MemoryImage {
  final ContentImage content;
  final int width, height, maximumEdge;
  _CoverImageKey(this.content, this.width, this.height, this.maximumEdge)
      : super(content.bytes);

  @override
  bool operator ==(Object other) =>
      other is _CoverImageKey &&
      other.content == content &&
      other.width == width &&
      other.height == height &&
      other.maximumEdge == maximumEdge;

  @override
  int get hashCode => Object.hash(content, width, height, maximumEdge);
}
