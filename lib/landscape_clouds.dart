import 'dart:ui';

/// Stable silhouettes and slow speeds shared by both landscape variants.
class LandscapeCloud {
  final double start, altitude, width, height, speed, crest;
  const LandscapeCloud(
    this.start,
    this.altitude,
    this.width,
    this.height,
    this.speed,
    this.crest,
  );

  static const all = [
    LandscapeCloud(.08, .12, .24, .075, .0011, .38),
    LandscapeCloud(.36, .20, .32, .065, .0008, .58),
    LandscapeCloud(.67, .105, .19, .09, .0013, .46),
    LandscapeCloud(.93, .24, .28, .07, .0009, .67),
    LandscapeCloud(.19, .29, .18, .055, .0012, .55),
    LandscapeCloud(.56, .31, .26, .08, .0010, .32),
    LandscapeCloud(.83, .17, .22, .06, .0007, .62),
  ];

  /// Wrap only when the entire silhouette is outside the viewport.
  Offset position(double seconds, Size size, {required bool left}) {
    final span = 1 + width;
    final x = (start + width / 2 + seconds * speed * (left ? -1 : 1)) % span;
    return Offset((x - width / 2) * size.width, altitude * size.height);
  }

  /// One filled contour avoids dark overlaps between individual cloud lobes.
  Path silhouette(Size size) {
    final w = width * size.width, h = height * size.height;
    final c = crest;
    return Path()
      ..moveTo(-w * .5, h * .22)
      ..cubicTo(-w * .5, -h * .02, -w * .40, -h * .29, -w * .28, -h * .13)
      ..cubicTo(
        -w * .29,
        -h * .65,
        w * (c - .65),
        -h * .65,
        w * (c - .5),
        -h * .25,
      )
      ..cubicTo(w * .25, -h * .51, w * .40, -h * .25, w * .37, -h * .04)
      ..cubicTo(w * .5, -h * .08, w * .5, h * .26, w * .43, h * .31)
      ..cubicTo(w * .20, h * .42, -w * .31, h * .38, -w * .5, h * .22)
      ..close();
  }
}
