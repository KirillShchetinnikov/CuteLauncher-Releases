import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import '../theme/interface_style.dart';

class RoundedSwitchListTile extends StatelessWidget {
  final bool value;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final ValueChanged<bool> onChanged;
  final Widget title;
  final Widget? secondary;

  const RoundedSwitchListTile({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.secondary,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final skin = InterfaceSkin.of(context);
    return Semantics(
      toggled: value,
      enabled: enabled,
      child: FocusableSettingsTile(
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        onPressed: enabled ? () => onChanged(!value) : null,
        leading: secondary,
        title: title,
        trailing: Container(
          constraints: BoxConstraints(maxHeight: skin.standard ? 16 : 26),
          child: ExcludeFocus(
            child: ExcludeSemantics(
              child: skin.standard ? Switch(
                value: value,
                onChanged: enabled ? onChanged : null,
              ) : SkinSwitch(value: value, enabled: enabled),
            ),
          ),
        ),
      ),
    );
  }
}
