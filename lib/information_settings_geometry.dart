import 'package:flutter/painting.dart';

/// Choose the least obstructing side without changing the user's saved side.
({bool onRight, bool obscured}) informationSettingsSide({
  required Size screen,
  required double panelWidth,
  required Rect? block,
  required bool preferredRight,
}) {
  if (block == null) return (onRight: preferredRight, obscured: false);
  final width = panelWidth.clamp(0.0, screen.width - 32);
  final left = Rect.fromLTWH(
    16,
    56,
    width,
    (screen.height - 72).clamp(0.0, screen.height),
  );
  final right = left.shift(Offset(screen.width - width - 32, 0));
  double overlap(Rect panel) {
    if (!panel.overlaps(block)) return 0;
    final intersection = panel.intersect(block);
    return intersection.width * intersection.height;
  }

  final l = overlap(left), r = overlap(right);
  return (
    onRight: (l - r).abs() < 1 ? preferredRight : r < l,
    obscured: l > 0 && r > 0,
  );
}
