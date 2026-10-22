import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../adaptive_landscape.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'reset_style_tile.dart';

class LandscapePage extends StatelessWidget {
  const LandscapePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final config = settings.landscape;
    Widget effect(String title, String key) => RoundedSwitchListTile(
      title: Text(title),
      value: config.toJson()[key] == true,
      onChanged: (value) =>
          settings.setLandscape(settings.landscape.withValue(key, value)),
    );
    return SettingsPageLayout(
      title: Text(l.adaptiveLandscape),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            autofocus: true,
            title: l.landscapeVariant,
            value: config.variant,
            options: const ['illustrated', 'realistic'],
            label: (v) => v == 'realistic'
                ? l.landscapeRealistic
                : l.landscapeIllustrated,
            onChanged: (v) => settings.setLandscape(
              settings.landscape.withValue('variant', v),
            ),
          ),
          effect(l.landscapeTimeOfDay, 'timeOfDay'),
          effect(l.landscapeSeasons, 'seasons'),
          SettingsChoiceTile<String>(
            title: l.landscapeHemisphere,
            value: config.hemisphere,
            options: const ['auto', 'north', 'south'],
            label: (v) => switch (v) {
              'north' => l.landscapeNorth,
              'south' => l.landscapeSouth,
              _ => l.landscapeAuto,
            },
            onChanged: (v) => settings.setLandscape(
              settings.landscape.withValue('hemisphere', v),
            ),
          ),
          effect(l.landscapeClouds, 'clouds'),
          effect(l.landscapePrecipitation, 'precipitation'),
          effect(l.landscapeFog, 'fog'),
          effect(l.landscapeMotion, 'motion'),
          SettingsHelp(text: l.landscapeHelp),
          ResetStyleTile(
            onReset: () =>
                settings.setLandscape(const LandscapeConfiguration()),
          ),
        ],
      ),
    );
  }
}
