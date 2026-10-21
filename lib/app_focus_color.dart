import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:pool/pool.dart';

// Weak keys do not retain the image bytes after the app image cache evicts them.
final _colors = Expando<Future<Color?>>();
final _colorPool = Pool(2);

Future<Color?> appFocusColor(Uint8List bytes) =>
    _colors[bytes] ??= _colorPool.withResource(() => _averageColor(bytes));

Future<Color?> _averageColor(Uint8List bytes) async {
  ui.Codec? codec;
  ui.Image? image;
  try {
    codec = await ui.instantiateImageCodec(bytes, targetWidth: 24, targetHeight: 24);
    image = (await codec.getNextFrame()).image;
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (data == null) return null;
    final average = averageRgbaColor(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    return average == null ? null : readableAppFocusColor(average);
  } catch (_) {
    return null;
  } finally {
    image?.dispose();
    codec?.dispose();
  }
}

/// The average often matches a banner's background. Keep its hue, but move
/// lightness away from that background so an actual outline remains visible.
@visibleForTesting
Color readableAppFocusColor(Color average) {
  final hsl = HSLColor.fromColor(average);
  final luminance = average.computeLuminance();
  final brighten = luminance < .4;
  var lightness = brighten && hsl.lightness < .65 ? .65 : hsl.lightness;
  Color color = hsl.withLightness(lightness).toColor();
  for (var i = 0; i < 50; i++) {
    final value = color.computeLuminance();
    final contrast = value > luminance
        ? (value + .05) / (luminance + .05)
        : (luminance + .05) / (value + .05);
    if (contrast >= 2) break;
    lightness = (lightness + (brighten ? .02 : -.02)).clamp(0.0, 1.0);
    color = hsl.withLightness(lightness).toColor();
  }
  return color;
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
  return Color.fromARGB(255, (red / weight).round(),
      (green / weight).round(), (blue / weight).round());
}
