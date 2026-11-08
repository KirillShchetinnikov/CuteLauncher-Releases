import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Saved size is the preferred geometry; enlarged text has a readable minimum.
Size watchNextCardSize(BuildContext context, String preset) {
  final custom = int.tryParse(preset);
  final preferred = custom != null
      ? Size((custom * 16 / 9).roundToDouble(), custom.toDouble())
      : switch (preset) {
          'compact' => const Size(200, 112),
          'large' => const Size(280, 157),
          _ => const Size(240, 135),
        };
  final theme = Theme.of(context).textTheme;
  final scaler = MediaQuery.textScalerOf(context);
  double line(TextStyle? style, double fallback) =>
      scaler.scale(style?.fontSize ?? fallback) * (style?.height ?? 1.3);
  final title = line(theme.bodyMedium, 15);
  final detail = line(theme.bodySmall, 13);
  // Padding + border, icon/progress row, two title lines, description and progress.
  final text = math.max(title * 3, title * 2 + detail + 3);
  final minimum = (26 + math.max(24, detail) + text + 4).ceilToDouble();
  return Size(preferred.width, math.max(preferred.height, minimum));
}
