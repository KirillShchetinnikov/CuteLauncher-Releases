import 'dart:math' as math;

import 'package:flutter/material.dart';

typedef BackgroundInformationMetrics = ({
  Size screen,
  Size natural,
  double requestedSize,
  double effectiveSize,
  int maximumSize,
  int maximumVerticalOffset,
  double verticalOffset,
});

/// A fixed top anchor, independent of size, horizontal position and terrain.
class BackgroundInformationGeometry {
  static const referenceSize = 96.0;
  static const maximumStoredSize = 4096;
  final Size screen;
  final double verticalOffset;
  const BackgroundInformationGeometry(this.screen, this.verticalOffset);
  double get middle => screen.height * .5;
  double get minimumTop => math.min(kToolbarHeight + 8, middle);
  // Imported endpoints keep a small visible area instead of hiding the block.
  double get _travel => math.max(0, middle - minimumTop - 8);
  double get top => minimumTop + _travel * verticalOffset.clamp(0, 100) / 100;
  double get availableHeight => math.max(0, middle - top);
  int maximumOffsetForHeight(double height) {
    if (_travel <= 0) return 0;
    return ((middle - height - minimumTop) / _travel * 100 + .000001)
        .floor()
        .clamp(0, 100);
  }
}
