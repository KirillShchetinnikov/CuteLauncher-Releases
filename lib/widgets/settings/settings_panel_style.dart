import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';

/// Shared appearance for settings and all side panels with settings/actions.
class SettingsPanelStyle extends StatelessWidget {
  final WidgetBuilder builder;

  const SettingsPanelStyle({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    final appearance = context.watch<AppearanceService?>()?.appearance;
    final theme = Theme.of(context);
    final textSize = appearance?.number('settingsTextSize') ?? 16;
    final foreground =
        appearance?.color('settingsTextColor') ?? theme.colorScheme.onSurface;
    final surface =
        (appearance?.color('settingsColor') ??
                theme.colorScheme.surface.withAlpha(255))
            .withValues(alpha: appearance?.number('settingsOpacity') ?? 1);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          surface: surface,
          onSurface: foreground,
        ),
        textTheme: appearance?.color('settingsTextColor') == null
            ? theme.textTheme
            : theme.textTheme.apply(
                bodyColor: foreground,
                displayColor: foreground,
              ),
        iconTheme: appearance?.color('settingsTextColor') == null
            ? theme.iconTheme
            : theme.iconTheme.copyWith(color: foreground),
      ),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(
            MediaQuery.textScalerOf(context).scale(16) / 16 * textSize / 16,
          ),
        ),
        child: Builder(builder: builder),
      ),
    );
  }
}
