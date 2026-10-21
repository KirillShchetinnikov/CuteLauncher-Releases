import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';

import 'focusable_settings_tile.dart';

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
  });

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    leading: leading,
    title: valueBelow ? Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(title), Text(valueLabel ?? label(value))]) : Text(title),
    trailing: valueBelow ? null : Text(valueLabel ?? label(value), textAlign: TextAlign.end),
    alignValueToEnd: true,
    enabled: enabled,
    autofocus: autofocus,
    onPressed: () async {
      final result = await showLauncherDialog<(T,)>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final option in options)
                    FocusableSettingsTile(
                      title: Text(label(option)),
                      autofocus:
                          option == value ||
                          (!options.contains(value) && option == options.first),
                      trailing: option == value
                          ? const Icon(Icons.check)
                          : const SizedBox.shrink(),
                      onPressed: () => Navigator.pop(dialog, (option,)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      if (result != null && context.mounted) onChanged(result.$1);
    },
  );
}
