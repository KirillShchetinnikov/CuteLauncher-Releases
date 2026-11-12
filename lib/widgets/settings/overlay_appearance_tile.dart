import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../overlay_appearance.dart';
import 'settings_choice_tile.dart';

class OverlayAppearanceTile extends StatelessWidget {
  const OverlayAppearanceTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OverlayAppearance value;
  final ValueChanged<OverlayAppearance> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsChoiceTile<OverlayAppearance>(
      title: l.overlayAppearance,
      value: value,
      options: OverlayAppearance.values,
      valueBelow: true,
      label: (appearance) => switch (appearance) {
        OverlayAppearance.topPanel => l.overlayAppearanceTopPanel,
        OverlayAppearance.dark => l.overlayAppearanceDark,
      },
      onChanged: onChanged,
    );
  }
}
