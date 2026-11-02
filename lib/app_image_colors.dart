import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pool/pool.dart';

/// Original colors, without the contrast correction used by focus outlines.
class AppImageColors {
  final Color? average, top, right, bottom, left;
  const AppImageColors({
    this.average,
    this.top,
    this.right,
    this.bottom,
    this.left,
  });
}

// Weak keys and two bounded jobs: palette work cannot retain the app catalogue.
final _colors = Expando<Future<AppImageColors>>();
final _pool = Pool(2);
Future<AppImageColors> appImageColors(Uint8List bytes) =>
    _colors[bytes] ??= _pool.withResource(() async {
      ui.Codec? codec;
      ui.Image? image;
      try {
        codec = await ui.instantiateImageCodec(
          bytes,
          targetWidth: 24,
          targetHeight: 24,
        );
        image = (await codec.getNextFrame()).image;
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        if (data == null) return const AppImageColors();
        return rgbaImageColors(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          image.width,
          image.height,
        );
      } catch (_) {
        return const AppImageColors();
      } finally {
        image?.dispose();
        codec?.dispose();
      }
    });

@visibleForTesting
AppImageColors rgbaImageColors(Uint8List pixels, int width, int height) {
  Color? edge(bool horizontal, bool reverse) {
    final depth = horizontal ? height : width;
    final length = horizontal ? width : height;
    // A transparent outer border is skipped, rather than sampled as black.
    for (var row = 0; row < depth; row++) {
      final bins = <int, List<int>>{};
      for (var n = 0; n < length; n++) {
        final d = reverse ? depth - row - 1 : row;
        final at = ((horizontal ? d : n) * width + (horizontal ? n : d)) * 4;
        final a = pixels[at + 3];
        if (a < 32) continue;
        final r = pixels[at], g = pixels[at + 1], b = pixels[at + 2];
        final bin = bins.putIfAbsent(
          (r >> 4) << 8 | (g >> 4) << 4 | (b >> 4),
          () => [0, 0, 0, 0],
        );
        bin[0] += a;
        bin[1] += r * a;
        bin[2] += g * a;
        bin[3] += b * a;
      }
      if (bins.isEmpty) continue;
      final best = bins.values.reduce((a, b) => a[0] >= b[0] ? a : b);
      return Color.fromARGB(
        255,
        (best[1] / best[0]).round(),
        (best[2] / best[0]).round(),
        (best[3] / best[0]).round(),
      );
    }
    return null;
  }

  return AppImageColors(
    average: averageRgbaColor(pixels),
    top: edge(true, false),
    bottom: edge(true, true),
    left: edge(false, false),
    right: edge(false, true),
  );
}

@visibleForTesting
Color? averageRgbaColor(Uint8List pixels) {
  double red = 0, green = 0, blue = 0, weight = 0;
  for (var i = 0; i + 3 < pixels.length; i += 4) {
    final alpha = pixels[i + 3] / 255;
    red += pixels[i] * alpha;
    green += pixels[i + 1] * alpha;
    blue += pixels[i + 2] * alpha;
    weight += alpha;
  }
  if (weight == 0) return null;
  return Color.fromARGB(
    255,
    (red / weight).round(),
    (green / weight).round(),
    (blue / weight).round(),
  );
}
