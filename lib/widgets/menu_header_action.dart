import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/settings_service.dart';
import 'panel_tooltip.dart';

/// Tooltips respond to both pointer hover and TV remote focus.
class MenuHeaderAction extends StatefulWidget {
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
  State<MenuHeaderAction> createState() => _MenuHeaderActionState();
}

class _MenuHeaderActionState extends State<MenuHeaderAction> {
  var _tooltipKey = GlobalKey<TooltipState>();
  final _buttonKey = GlobalKey();
  bool _focused = false;
  bool _tooltipsEnabled = false;
  Timer? _tooltipTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled =
        Provider.of<SettingsService?>(context)?.panelTooltipsEnabled ?? false;
    if (_tooltipsEnabled != enabled) {
      _tooltipsEnabled = enabled;
      _scheduleTooltip();
    }
  }

  void _scheduleTooltip() {
    _tooltipTimer?.cancel();
    if (!_focused || !_tooltipsEnabled) return;
    _tooltipTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && _focused && _tooltipsEnabled) {
        _tooltipKey.currentState?.ensureTooltipVisible();
      }
    });
  }

  @override
  void dispose() {
    _tooltipTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (_focused == focused) return;
      _tooltipTimer?.cancel();
      setState(() {
        _focused = focused;
        // Dispose only this tooltip; global dismissal can hide the next button's tooltip.
        _tooltipKey = GlobalKey<TooltipState>();
      });
      _scheduleTooltip();
    },
    child: PanelTooltip(
      tooltipKey: _tooltipKey,
      message: widget.tooltip,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      preferBelow: false,
      waitDuration: const Duration(seconds: 2),
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
        key: _buttonKey,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        icon: widget.icon,
        onPressed: widget.onPressed,
      ),
    ),
  );
}
