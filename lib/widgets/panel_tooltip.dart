import 'dart:async';

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

/// Shows the same hint on D-pad focus and pointer hover.
class FocusPanelTooltip extends StatefulWidget {
  const FocusPanelTooltip({
    super.key,
    required this.message,
    required this.child,
    this.preferBelow = true,
    this.positionDelegate,
  });

  final String message;
  final Widget child;
  final bool preferBelow;
  final TooltipPositionDelegate? positionDelegate;

  @override
  State<FocusPanelTooltip> createState() => _FocusPanelTooltipState();
}

class _FocusPanelTooltipState extends State<FocusPanelTooltip> {
  var _tooltipKey = GlobalKey<TooltipState>();
  final _childKey = GlobalKey();
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
      message: widget.message,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      preferBelow: widget.preferBelow,
      waitDuration: const Duration(seconds: 2),
      positionDelegate: widget.positionDelegate,
      child: KeyedSubtree(key: _childKey, child: widget.child),
    ),
  );
}
