import 'package:flutter/material.dart';

/// Shares the menu side and the toolbar space reserved by top-panel settings.
class SettingsMenuLayout extends InheritedWidget {
  final bool onRight;
  final double topInset;

  const SettingsMenuLayout({
    super.key,
    required this.onRight,
    this.topInset = 0,
    required super.child,
  });

  static bool isOnRight(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SettingsMenuLayout>()
          ?.onRight ??
      false;

  static SettingsMenuLayout? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsMenuLayout>();

  @override
  bool updateShouldNotify(SettingsMenuLayout oldWidget) =>
      onRight != oldWidget.onRight || topInset != oldWidget.topInset;
}
