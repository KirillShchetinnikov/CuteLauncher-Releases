import 'package:flutter/material.dart';

import 'panel_tooltip.dart';

/// Tooltips respond to both pointer hover and TV remote focus.
class MenuHeaderAction extends StatelessWidget {
  final FocusNode? focusNode;
  final bool autofocus;
  final String tooltip;
  final Widget icon;
  final VoidCallback? onPressed;

  const MenuHeaderAction({
    super.key,
    this.focusNode,
    this.autofocus = false,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FocusPanelTooltip(
    message: tooltip,
    preferBelow: false,
    positionDelegate: (position) => Offset(
      (position.target.dx - position.tooltipSize.width / 2).clamp(
        0.0,
        (position.overlaySize.width - position.tooltipSize.width).clamp(
          0.0,
          double.infinity,
        ),
      ),
      (position.target.dy -
              position.targetSize.height / 2 -
              position.tooltipSize.height -
              4)
          .clamp(0.0, double.infinity),
    ),
    child: IconButton(
      focusNode: focusNode,
      autofocus: autofocus,
      icon: icon,
      onPressed: onPressed,
    ),
  );
}
