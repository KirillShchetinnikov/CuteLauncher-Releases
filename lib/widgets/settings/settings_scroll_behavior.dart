import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../tile_appearance.dart';

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
    return SettingsScrollbar(
      controller: details.controller,
      thickness: 4,
      child: child,
    );
  }
}

/// Applies the current mode without replacing the scrollable's widget tree.
class SettingsScrollbar extends StatelessWidget {
  final ScrollController? controller;
  final ScrollbarOrientation? scrollbarOrientation;
  final double? thickness;
  final bool? interactive;
  final bool hasScrollPosition;
  final Widget child;

  const SettingsScrollbar({
    super.key,
    this.controller,
    this.scrollbarOrientation,
    this.thickness,
    this.interactive = false,
    this.hasScrollPosition = true,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final mode = context.select<AppearanceService?, SettingsScrollbarMode>(
      (service) =>
          service?.appearance.settingsScrollbarMode ?? SettingsScrollbarMode.always,
    );
    final hidden = mode == SettingsScrollbarMode.hidden;
    final theme = ScrollbarTheme.of(context);
    return ScrollbarTheme(
      data: hidden
          ? theme.copyWith(
              thumbColor: const WidgetStatePropertyAll(Colors.transparent),
              trackVisibility: const WidgetStatePropertyAll(false),
            )
          : theme,
      child: Scrollbar(
        controller: controller,
        scrollbarOrientation: scrollbarOrientation,
        thickness: thickness,
        interactive: hidden ? false : interactive,
        thumbVisibility:
            hasScrollPosition && mode == SettingsScrollbarMode.always,
        child: child,
      ),
    );
  }
}
