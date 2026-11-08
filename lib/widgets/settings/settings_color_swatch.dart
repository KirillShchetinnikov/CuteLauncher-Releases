import 'package:flutter/material.dart';

import '../../theme/launcher_colors.dart';

/// The effective color stays visible while the link marks an inherited value.
class SettingsColorSwatch extends StatelessWidget {
  final Color color;
  final bool inherited;
  final String tooltip;
  const SettingsColorSwatch({
    super.key,
    required this.color,
    required this.inherited,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: Container(
      width: 30,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: inherited
          ? Icon(Icons.link, size: 15, color: LauncherColors.onAccent(color))
          : null,
    ),
  );
}
