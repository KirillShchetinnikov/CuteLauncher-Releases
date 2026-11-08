import 'package:flutter/material.dart';

import '../../theme/interface_style.dart';

import 'focusable_settings_tile.dart';

/// One saved choice: the check persists while the remote focus moves elsewhere.
class SettingsOptionTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final bool selected, enabled, autofocus;
  final VoidCallback onPressed;
  const SettingsOptionTile({
    super.key,
    required this.title,
    required this.selected,
    required this.onPressed,
    this.leading,
    this.enabled = true,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: title,
    leading: leading,
    selected: selected,
    enabled: enabled,
    autofocus: autofocus,
    onPressed: onPressed,
    showActionChevron: false,
    trailing: ExcludeSemantics(
      child: SizedBox(
        width: 24,
        height: 24,
        child: selected
            ? Icon(
                Icons.check,
                color: !enabled && InterfaceSkin.of(context).calm
                    ? Theme.of(context).disabledColor
                    : InterfaceSkin.of(context)
                          .selectionColor(Theme.of(context).colorScheme),
              )
            : null,
      ),
    ),
  );
}
