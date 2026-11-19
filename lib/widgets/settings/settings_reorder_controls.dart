import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/interface_style.dart';

/// The row owns TV focus and toggle semantics; the handle also accepts a pointer.
class SettingsReorderControls extends StatelessWidget {
  final bool? value;
  final bool enabled;
  final bool moving;
  final VoidCallback? onReorder;
  const SettingsReorderControls({
    super.key,
    this.value,
    this.enabled = true,
    required this.moving,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    final skin = InterfaceSkin.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!moving && value != null)
          ExcludeFocus(
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: skin.standard ? 16 : 26,
                  ),
                  child: skin.standard
                      ? Switch(
                          value: value!,
                          onChanged: enabled ? (_) {} : null,
                        )
                      : SkinSwitch(value: value!, enabled: enabled),
                ),
              ),
            ),
          ),
        ExcludeFocus(
          child: IconButton(
            tooltip: AppLocalizations.of(context)!.reorder,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints.tightFor(width: 28, height: 28),
            padding: EdgeInsets.zero,
            icon: Icon(moving ? Icons.unfold_more : Icons.swap_vert),
            onPressed: onReorder,
          ),
        ),
      ],
    );
  }
}
