import 'package:flutter/material.dart';

/// Keep overflow discoverable on TV without adding remote focus targets.
class SettingsScrollBehavior extends MaterialScrollBehavior {
  const SettingsScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    if (axisDirectionToAxis(details.direction) != Axis.vertical ||
        context.findAncestorWidgetOfExactType<Scrollbar>() != null) {
      return child;
    }
    return Scrollbar(
      controller: details.controller,
      thumbVisibility: true,
      interactive: false,
      thickness: 4,
      child: child,
    );
  }
}
