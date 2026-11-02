import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/tile_image_geometry.dart';
import 'package:flauncher/app_image_colors.dart';

void main() {
  test('trigger distinguishes fitting image, cropping and empty edges', () {
    final box = RRect.fromRectAndRadius(
      const Rect.fromLTWH(0, 0, 160, 90),
      Radius.zero,
    );
    expect(tileImageNeedsAdjustment(box.outerRect, box), false);
    expect(
      tileImageNeedsAdjustment(const Rect.fromLTWH(-10, 0, 180, 90), box),
      true,
    );
    expect(
      tileImageNeedsAdjustment(const Rect.fromLTWH(10, 0, 140, 90), box),
      true,
    );
    final round = RRect.fromRectAndRadius(
      box.outerRect,
      const Radius.circular(20),
    );
    expect(tileImageNeedsAdjustment(box.outerRect, round), true);
  });
  test(
    'whole rectangles stay within circle, capsule and asymmetric corners',
    () {
      for (final size in [const Size(100, 100), const Size(200, 100)]) {
        for (final corners in [
          BorderRadius.circular(100),
          const BorderRadius.only(topLeft: Radius.circular(50)),
        ]) {
          final shape = corners.toRRect(Offset.zero & size).scaleRadii();
          for (final source in [
            const Size(160, 90),
            const Size(90, 160),
            const Size(100, 100),
          ]) {
            final rect = safeTileImageRect(source, shape.outerRect, shape);
            expect(
              rect.width / rect.height,
              closeTo(source.aspectRatio, .0001),
            );
            for (final p in [
              rect.topLeft,
              rect.topRight,
              rect.bottomLeft,
              rect.bottomRight,
            ]) {
              expect(
                shape.inflate(.001).contains(p),
                true,
                reason: '$size $source $p',
              );
            }
            if (size == const Size(100, 100) &&
                corners == BorderRadius.circular(100) &&
                source.aspectRatio == 1) {
              expect(rect.width, closeTo(100 / math.sqrt(2), .01));
            }
          }
        }
      }
    },
  );
  test(
    'edges use their dominant original colors and skip transparent borders',
    () {
      final pixels = Uint8List(6 * 6 * 4);
      void pixel(int x, int y, Color color) {
        final offset = (y * 6 + x) * 4;
        final argb = color.toARGB32();
        pixels.setRange(offset, offset + 4, [
          (argb >> 16) & 255,
          (argb >> 8) & 255,
          argb & 255,
          argb >> 24,
        ]);
      }

      for (var y = 1; y < 5; y++) {
        for (var x = 1; x < 5; x++) {
          pixel(x, y, const Color(0xff121212));
        }
      }
      for (var x = 1; x < 5; x++) {
        pixel(x, 1, const Color(0xffaa2200));
      }
      final colors = rgbaImageColors(pixels, 6, 6);
      expect(colors.top, const Color(0xffaa2200));
      expect(colors.bottom, const Color(0xff121212));
      expect(colors.left, const Color(0xff121212));
      expect(colors.right, const Color(0xff121212));
      expect(rgbaImageColors(Uint8List(16), 2, 2).top, isNull);
    },
  );
  test('palette cache shares work, including failed decoding', () async {
    final bytes = Uint8List.fromList([0, 1, 2]);
    final first = appImageColors(bytes);
    expect(identical(first, appImageColors(bytes)), true);
    expect((await first).average, isNull);
  });
}
