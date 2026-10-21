import 'package:flutter/material.dart';

/// Shares the menu side so the scrollbar can follow the panel.
class SettingsMenuLayout extends InheritedWidget {
  final bool onRight;

  const SettingsMenuLayout({
    super.key,
    required this.onRight,
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
      onRight != oldWidget.onRight;
}
