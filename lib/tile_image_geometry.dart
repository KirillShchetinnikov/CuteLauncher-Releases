import 'dart:math' as math;

import 'package:flutter/painting.dart';

/// Image modes stored in appearance settings and section overrides.
enum TileImageMode { contain, cover, edgeColor, icon }

/// Centered destination before clipping, preserving the source aspect ratio.
Rect tileImageRect(Size source, Rect area, BoxFit fit) {
  final scale = fit == BoxFit.cover
      ? math.max(area.width / source.width, area.height / source.height)
      : math.min(area.width / source.width, area.height / source.height);
  return Rect.fromCenter(
    center: area.center,
    width: source.width * scale,
    height: source.height * scale,
  );
}

bool _inside(RRect shape, Rect rect) =>
    [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight].every((p) {
      // RRect.contains excludes the right/bottom boundary of a rectangle.
      final point = Offset(
        p.dx.clamp(shape.left + .00001, shape.right - .00001),
        p.dy.clamp(shape.top + .00001, shape.bottom - .00001),
      );
      return p.dx >= shape.left - .01 &&
          p.dx <= shape.right + .01 &&
          p.dy >= shape.top - .01 &&
          p.dy <= shape.bottom + .01 &&
          shape.contains(point);
    });

/// Both clipping and uncovered margins qualify, before applying a mode.
bool tileImageNeedsAdjustment(Rect original, RRect shape) =>
    !_inside(shape, original) ||
    (original.left - shape.left).abs() > .5 ||
    (original.top - shape.top).abs() > .5 ||
    (original.right - shape.right).abs() > .5 ||
    (original.bottom - shape.bottom).abs() > .5;

/// Largest whole rectangle within the real rounded mask and available area.
Rect safeTileImageRect(Size source, Rect area, RRect shape) {
  final candidate = tileImageRect(source, area, BoxFit.contain);
  if (_inside(shape, candidate)) return candidate;
  var low = 0.0, high = 1.0;
  for (var i = 0; i < 24; i++) {
    final scale = (low + high) / 2;
    final rect = Rect.fromCenter(
      center: area.center,
      width: candidate.width * scale,
      height: candidate.height * scale,
    );
    if (_inside(shape, rect)) {
      low = scale;
    } else {
      high = scale;
    }
  }
  return Rect.fromCenter(
    center: area.center,
    width: candidate.width * low,
    height: candidate.height * low,
  );
}
