import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'app_image_colors.dart';
export 'app_image_colors.dart' show averageRgbaColor;

final _focusColors = Expando<Future<Color?>>();
Future<Color?> appFocusColor(Uint8List bytes) =>
    _focusColors[bytes] ??= appImageColors(bytes).then(
      (colors) => colors.average == null
          ? null
          : readableAppFocusColor(colors.average!),
    );

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
