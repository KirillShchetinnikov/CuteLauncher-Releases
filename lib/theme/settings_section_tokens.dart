import 'package:flutter/material.dart';

/// Shared geometry and materials for settings groups, independent of row skin.
abstract final class SettingsSectionTokens {
  static const gap = 20.0;
  static const padding = EdgeInsets.all(6);
  static const headerPadding = EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8);
  static const headerGap = 8.0;
  static const radius = 16.0;
  static const accentWidth = 3.0;
  static const dividerWidth = 1.0;
  static const surfaceOpacity = .045;
  static const accentOpacity = .08;
  static const dividerOpacity = .12;
  static const listHeadingPadding = EdgeInsetsDirectional.fromSTEB(
    12,
    16,
    12,
    10,
  );
  static const listHeadingRuleGap = 12.0;
  static const listHeadingMinRule = 16.0;
  static const listHeadingRuleOpacity = .28;
}
