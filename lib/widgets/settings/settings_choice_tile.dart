import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';

import 'focusable_settings_tile.dart';
import 'settings_choice_dialog.dart';

/// Named choices share the same row and selected-item presentation.
class SettingsChoiceTile<T> extends StatelessWidget {
  final String title;
  final Widget? leading;
  final T value;
  final List<T> options;
  final String Function(T) label;
  final ValueChanged<T> onChanged;
  final bool enabled, autofocus;
  final String? valueLabel;
  final bool valueBelow;
  final TextStyle? valueStyle;
  final bool wideValue;
  const SettingsChoiceTile({
    super.key,
    required this.title,
    this.leading,
    required this.value,
    required this.options,
    required this.label,
    required this.onChanged,
    this.enabled = true,
    this.autofocus = false,
    this.valueLabel,
    this.valueBelow = false,
    this.valueStyle,
    this.wideValue = false,
  });

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    leading: leading,
    title: valueBelow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              Text(valueLabel ?? label(value), style: valueStyle),
            ],
          )
        : Text(title),
    trailing: valueBelow
        ? null
        : Text(
            valueLabel ?? label(value),
            textAlign: TextAlign.end,
            style: valueStyle,
          ),
    alignValueToEnd: true,
    wideValue: wideValue,
    enabled: enabled,
    autofocus: autofocus,
    onPressed: () async {
      final result = await showLauncherDialog<(T,)>(
        context: context,
        builder: (dialog) => SettingsChoiceDialog<T>(
          title: Text(title),
          value: value,
          options: options,
          optionBuilder: (option) => Text(label(option)),
          onSelected: (option) => Navigator.pop(dialog, (option,)),
        ),
      );
      if (result != null && context.mounted) onChanged(result.$1);
    },
  );
}
