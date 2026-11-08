import 'package:flutter/material.dart';

/// Non-interactive information shares geometry across every settings material.
abstract final class SettingsInfoTokens {
  static const margin = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
  static const padding = EdgeInsets.all(12);
  static const gap = 10.0;
  static const radius = 12.0;
  static const iconSize = 20.0;
  static const surfaceOpacity = .05;
  static const keyOpacity = .14;
  static const controlHintMargin = EdgeInsets.only(top: 8);
  static const controlHintPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 6,
  );
  static const controlHintGap = 6.0;
  static const controlHintIconSize = 16.0;
  static const controlHintFontSize = 12.0;
  static const controlHintLines = 3;
}
