import 'package:flutter/material.dart';

/// Contrast for text painted on a known opaque surface, not on wallpaper.
abstract final class LauncherColors {
  static double contrast(Color a, Color b) {
    final x = a.computeLuminance(), y = b.computeLuminance();
    return ((x > y ? x : y) + .05) / ((x > y ? y : x) + .05);
  }

  static Color onAccent(Color accent) =>
      contrast(Colors.white, accent) >= contrast(Colors.black, accent)
      ? Colors.white
      : Colors.black;
}
