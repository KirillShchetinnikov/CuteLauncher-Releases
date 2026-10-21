import 'dart:typed_data';

/// Three small box passes soften artwork before it becomes a screen-sized texture.
/// This operates on at most 48×27 pixels; no screen-sized shader or bitmap is used.
Uint8List softenAppArtwork(Uint8List rgba, int width, int height) {
  if (width < 1 || height < 1 || width > 48 || height > 27 || rgba.length != width * height * 4) {
    throw ArgumentError('Invalid artwork dimensions');
  }
  var pixels = Uint8List(rgba.length);
  for (var i = 0; i < rgba.length; i += 4) {
    final alpha = rgba[i + 3] / 255;
    final luminance = rgba[i] * .2126 + rgba[i + 1] * .7152 + rgba[i + 2] * .0722;
    for (var c = 0; c < 3; c++) {
      pixels[i + c] = ((luminance + (rgba[i + c] - luminance) * 1.4) * alpha).round().clamp(0, 255);
    }
    pixels[i + 3] = 255;
  }
  for (var pass = 0; pass < 3; pass++) {
    for (final horizontal in [true, false]) {
      final next = Uint8List(pixels.length);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final offset = (y * width + x) * 4;
          for (var c = 0; c < 3; c++) {
            var sum = 0;
            for (var delta = -2; delta <= 2; delta++) {
              final sx = horizontal ? (x + delta).clamp(0, width - 1) : x;
              final sy = horizontal ? y : (y + delta).clamp(0, height - 1);
              sum += pixels[(sy * width + sx) * 4 + c];
            }
            next[offset + c] = (sum / 5).round();
          }
          next[offset + 3] = 255;
        }
      }
      pixels = next;
    }
  }
  return pixels;
}
