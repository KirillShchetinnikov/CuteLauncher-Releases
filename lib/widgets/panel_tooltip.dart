import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';

/// One preference for panel hints, with accessible names even while hidden.
class PanelTooltip extends StatelessWidget {
  final String message;
  final Widget child;
  final GlobalKey<TooltipState>? tooltipKey;
  final bool? preferBelow;
  final bool excludeFromSemantics;
  final Duration? waitDuration;
  final EdgeInsetsGeometry? padding;
  final TooltipPositionDelegate? positionDelegate;

  const PanelTooltip({
    super.key,
    required this.message,
    required this.child,
    this.tooltipKey,
    this.preferBelow,
    this.excludeFromSemantics = false,
    this.waitDuration,
    this.padding,
    this.positionDelegate,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SettingsService?, bool>(
      (settings) => settings?.panelTooltipsEnabled ?? false,
    );
    return Semantics(
      label: excludeFromSemantics ? null : message,
      child: TooltipVisibility(
        visible: enabled,
        child: Tooltip(
          key: tooltipKey,
          message: message,
          excludeFromSemantics: true,
          preferBelow: preferBelow,
          waitDuration: waitDuration,
          padding: padding,
          positionDelegate: positionDelegate,
          child: child,
        ),
      ),
    );
  }
}
