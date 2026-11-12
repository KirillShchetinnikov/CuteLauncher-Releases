import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../overlay_position.dart';
import 'settings_choice_tile.dart';

class OverlayPositionTile extends StatelessWidget {
  const OverlayPositionTile({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final OverlayPosition value;
  final ValueChanged<OverlayPosition> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsChoiceTile<OverlayPosition>(
      title: l.overlayWhereToShow,
      value: value,
      options: OverlayPosition.values,
      valueBelow: true,
      label: (position) => switch (position) {
        OverlayPosition.widget => l.overlayAtPanelWidget,
        OverlayPosition.topLeft => l.noticeTopLeft,
        OverlayPosition.topRight => l.noticeTopRight,
        OverlayPosition.bottomLeft => l.noticeBottomLeft,
        OverlayPosition.bottomRight => l.noticeBottomRight,
      },
      onChanged: onChanged,
    );
  }
}
