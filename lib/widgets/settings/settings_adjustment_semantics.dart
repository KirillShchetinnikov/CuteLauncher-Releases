import 'package:flutter/material.dart';

/// Sliders and compact steppers expose the same single adjustable node.
/// The child row uses semanticContainer=false; visual labels are excluded.
class SettingsAdjustmentSemantics extends StatelessWidget {
  final String label, value;
  final String? increasedValue, decreasedValue;
  final VoidCallback? onIncrease, onDecrease;
  final bool enabled;
  final Widget child;

  const SettingsAdjustmentSemantics({
    super.key,
    required this.label,
    required this.value,
    required this.enabled,
    required this.child,
    this.increasedValue,
    this.decreasedValue,
    this.onIncrease,
    this.onDecrease,
  });

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      container: true,
      enabled: enabled,
      label: label,
      value: value,
      increasedValue: enabled ? increasedValue : null,
      decreasedValue: enabled ? decreasedValue : null,
      onIncrease: enabled ? onIncrease : null,
      onDecrease: enabled ? onDecrease : null,
      child: child,
    ),
  );
}
