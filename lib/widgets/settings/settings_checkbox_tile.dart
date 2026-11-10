import 'package:flutter/material.dart';

import '../../theme/interface_style.dart';

import 'focusable_settings_tile.dart';

/// Multiple independent choices. The row owns focus, action and checked state.
class SettingsCheckboxTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final bool value, enabled, autofocus;
  final ValueChanged<bool> onChanged;

  final bool busy;
  const SettingsCheckboxTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.leading,
    this.enabled = true,
    this.busy = false,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: title,
    leading: leading,
    checked: value,
    enabled: enabled,
    busy: busy,
    autofocus: autofocus,
    showActionChevron: false,
    onPressed: () => onChanged(!value),
    trailing: ExcludeSemantics(
      child: Icon(
        value ? Icons.check_box : Icons.check_box_outline_blank,
        color: enabled
            ? value
                  ? InterfaceSkin.of(context)
                        .selectionColor(Theme.of(context).colorScheme)
                  : Theme.of(context).colorScheme.onSurface
            : Theme.of(context).disabledColor,
      ),
    ),
  );
}
