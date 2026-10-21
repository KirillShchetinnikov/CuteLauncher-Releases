import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../tile_appearance.dart';

/// Launcher-specific geometry and focus tokens; colors/text remain in ThemeData.
@immutable
class LauncherStyle extends ThemeExtension<LauncherStyle> {
  final double panelRadius;
  final double dialogRadius;
  final double panelMargin;
  final double panelPadding;
  final double settingsWidth;
  final double settingsBarrierOpacity;
  final double rowRadius;
  final double rowMinHeight;
  final EdgeInsets rowPadding;
  final double rowFocusWidth;
  final Color rowFocusColor;
  final Color rowFocusSurface;
  final double rowFocusTint;
  final double rowIdleOpacity;
  final Duration rowDuration;
  final Duration scrollDuration;
  final double iconRadius;
  final double iconExtent;
  final double topButtonRadius;
  final double topButtonPadding;
  final double topButtonFocusWidth;
  final double tileRadius;
  final double premiumTileRadius;
  final double capsuleTileRadius;
  final double tileOutlineInset;
  final Duration tileDuration;
  final Duration pressDuration;
  final Duration pulseDuration;

  const LauncherStyle({
    this.panelRadius = 28,
    this.dialogRadius = 24,
    this.panelMargin = 16,
    this.panelPadding = 20,
    this.settingsWidth = 380,
    this.settingsBarrierOpacity = 0.5,
    this.rowRadius = 14,
    this.rowMinHeight = 52,
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.rowFocusWidth = 1.5,
    this.rowFocusColor = const Color(0xFFE9EDF5),
    this.rowFocusSurface = const Color(0xFF343A47),
    this.rowFocusTint = 0.16,
    this.rowIdleOpacity = 0.025,
    this.rowDuration = const Duration(milliseconds: 160),
    this.scrollDuration = const Duration(milliseconds: 100),
    this.iconRadius = 10,
    this.iconExtent = 32,
    this.topButtonRadius = 16,
    this.topButtonPadding = 10,
    this.topButtonFocusWidth = 2,
    this.tileRadius = 14,
    this.premiumTileRadius = 16,
    this.capsuleTileRadius = 100,
    this.tileOutlineInset = 2,
    this.tileDuration = const Duration(milliseconds: 200),
    this.pressDuration = const Duration(milliseconds: 150),
    this.pulseDuration = const Duration(milliseconds: 1200),
  });

  static LauncherStyle of(BuildContext context) =>
      Theme.of(context).extension<LauncherStyle>() ?? const LauncherStyle();

  @override
  LauncherStyle copyWith({
    double? panelRadius,
    double? dialogRadius,
    double? panelMargin,
    double? panelPadding,
    double? settingsWidth,
    double? settingsBarrierOpacity,
    double? rowRadius,
    double? rowMinHeight,
    EdgeInsets? rowPadding,
    double? rowFocusWidth,
    Color? rowFocusColor,
    Color? rowFocusSurface,
    double? rowFocusTint,
    double? rowIdleOpacity,
    Duration? rowDuration,
    Duration? scrollDuration,
    double? iconRadius,
    double? iconExtent,
    double? topButtonRadius,
    double? topButtonPadding,
    double? topButtonFocusWidth,
    double? tileRadius,
    double? premiumTileRadius,
    double? capsuleTileRadius,
    double? tileOutlineInset,
    Duration? tileDuration,
    Duration? pressDuration,
    Duration? pulseDuration,
  }) => LauncherStyle(
    panelRadius: panelRadius ?? this.panelRadius,
    dialogRadius: dialogRadius ?? this.dialogRadius,
    panelMargin: panelMargin ?? this.panelMargin,
    panelPadding: panelPadding ?? this.panelPadding,
    settingsWidth: settingsWidth ?? this.settingsWidth,
    settingsBarrierOpacity:
        settingsBarrierOpacity ?? this.settingsBarrierOpacity,
    rowRadius: rowRadius ?? this.rowRadius,
    rowMinHeight: rowMinHeight ?? this.rowMinHeight,
    rowPadding: rowPadding ?? this.rowPadding,
    rowFocusWidth: rowFocusWidth ?? this.rowFocusWidth,
    rowFocusColor: rowFocusColor ?? this.rowFocusColor,
    rowFocusSurface: rowFocusSurface ?? this.rowFocusSurface,
    rowFocusTint: rowFocusTint ?? this.rowFocusTint,
    rowIdleOpacity: rowIdleOpacity ?? this.rowIdleOpacity,
    rowDuration: rowDuration ?? this.rowDuration,
    scrollDuration: scrollDuration ?? this.scrollDuration,
    iconRadius: iconRadius ?? this.iconRadius,
    iconExtent: iconExtent ?? this.iconExtent,
    topButtonRadius: topButtonRadius ?? this.topButtonRadius,
    topButtonPadding: topButtonPadding ?? this.topButtonPadding,
    topButtonFocusWidth: topButtonFocusWidth ?? this.topButtonFocusWidth,
    tileRadius: tileRadius ?? this.tileRadius,
    premiumTileRadius: premiumTileRadius ?? this.premiumTileRadius,
    capsuleTileRadius: capsuleTileRadius ?? this.capsuleTileRadius,
    tileOutlineInset: tileOutlineInset ?? this.tileOutlineInset,
    tileDuration: tileDuration ?? this.tileDuration,
    pressDuration: pressDuration ?? this.pressDuration,
    pulseDuration: pulseDuration ?? this.pulseDuration,
  );

  @override
  LauncherStyle lerp(covariant LauncherStyle? other, double t) {
    if (other == null) return this;
    return LauncherStyle(
      panelRadius: lerpDouble(panelRadius, other.panelRadius, t)!,
      dialogRadius: lerpDouble(dialogRadius, other.dialogRadius, t)!,
      panelMargin: lerpDouble(panelMargin, other.panelMargin, t)!,
      panelPadding: lerpDouble(panelPadding, other.panelPadding, t)!,
      settingsWidth: lerpDouble(settingsWidth, other.settingsWidth, t)!,
      settingsBarrierOpacity: lerpDouble(
        settingsBarrierOpacity,
        other.settingsBarrierOpacity,
        t,
      )!,
      rowRadius: lerpDouble(rowRadius, other.rowRadius, t)!,
      rowMinHeight: lerpDouble(rowMinHeight, other.rowMinHeight, t)!,
      rowPadding: EdgeInsets.lerp(rowPadding, other.rowPadding, t)!,
      rowFocusWidth: lerpDouble(rowFocusWidth, other.rowFocusWidth, t)!,
      rowFocusColor: Color.lerp(rowFocusColor, other.rowFocusColor, t)!,
      rowFocusSurface: Color.lerp(rowFocusSurface, other.rowFocusSurface, t)!,
      rowFocusTint: lerpDouble(rowFocusTint, other.rowFocusTint, t)!,
      rowIdleOpacity: lerpDouble(rowIdleOpacity, other.rowIdleOpacity, t)!,
      rowDuration: Duration(
        microseconds: lerpDouble(
          rowDuration.inMicroseconds,
          other.rowDuration.inMicroseconds,
          t,
        )!.round(),
      ),
      scrollDuration: Duration(
        microseconds: lerpDouble(
          scrollDuration.inMicroseconds,
          other.scrollDuration.inMicroseconds,
          t,
        )!.round(),
      ),
      iconRadius: lerpDouble(iconRadius, other.iconRadius, t)!,
      iconExtent: lerpDouble(iconExtent, other.iconExtent, t)!,
      topButtonRadius: lerpDouble(topButtonRadius, other.topButtonRadius, t)!,
      topButtonPadding: lerpDouble(
        topButtonPadding,
        other.topButtonPadding,
        t,
      )!,
      topButtonFocusWidth: lerpDouble(
        topButtonFocusWidth,
        other.topButtonFocusWidth,
        t,
      )!,
      tileRadius: lerpDouble(tileRadius, other.tileRadius, t)!,
      premiumTileRadius: lerpDouble(
        premiumTileRadius,
        other.premiumTileRadius,
        t,
      )!,
      capsuleTileRadius: lerpDouble(
        capsuleTileRadius,
        other.capsuleTileRadius,
        t,
      )!,
      tileOutlineInset: lerpDouble(
        tileOutlineInset,
        other.tileOutlineInset,
        t,
      )!,
      tileDuration: Duration(
        microseconds: lerpDouble(
          tileDuration.inMicroseconds,
          other.tileDuration.inMicroseconds,
          t,
        )!.round(),
      ),
      pressDuration: Duration(
        microseconds: lerpDouble(
          pressDuration.inMicroseconds,
          other.pressDuration.inMicroseconds,
          t,
        )!.round(),
      ),
      pulseDuration: Duration(
        microseconds: lerpDouble(
          pulseDuration.inMicroseconds,
          other.pulseDuration.inMicroseconds,
          t,
        )!.round(),
      ),
    );
  }

  /// Base style в†’ tile theme в†’ explicit appearance override (including zero).
  BorderRadius tileCorners(String theme, {double? radius}) =>
      BorderRadius.circular(
        radius ??
            switch (theme) {
              'classic' => 0,
              'premium' => premiumTileRadius,
              'capsule' => capsuleTileRadius,
              _ => tileRadius,
            },
      );

  BorderRadius tileInnerCorners(String theme, {double? radius}) {
    final outer = tileCorners(theme, radius: radius).topLeft.x;
    return BorderRadius.circular(
      (outer - tileOutlineInset).clamp(0, double.infinity),
    );
  }

  double tileElevation(String theme, bool focused) =>
      focused ? (theme == 'classic' ? 8 : 12) : 0;

  /// Same focus growth and collision limit for a real tile and its preview.
  double tileFocusScale(
    String theme,
    TileAppearance appearance, {
    required double width,
    required bool focused,
  }) {
    if (!focused) return 1;
    var scale = appearance.focusEffect != 'theme'
        ? 1 + appearance.focusScale
        : switch (theme) {
            'premium' => 1.15,
            'classic' => 1.0,
            _ => 1.1,
          };
    if (width > 0 && appearance.number('focusScale') == null && appearance.number('focusStrength') == null) {
      final growth = appearance.active
          ? (appearance.horizontalGap - 4).clamp(
              0,
              (appearance.verticalGap - 4) * appearance.aspectRatio,
            )
          : 28.0;
      scale = scale.clamp(1, 1 + growth / width);
    }
    return scale;
  }

  TextStyle? tileLabelStyle(
    BuildContext context,
    TileAppearance appearance,
    bool focused,
  ) => appearance.active
      ? appearance.labelStyle
      : Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 13,
          color: Colors.white.withValues(alpha: focused ? 1 : .85),
        );
}
