import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'overlay_appearance_tile.dart';
import 'overlay_position_tile.dart';
import 'remote_buttons_page.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_value_stepper.dart';

class VolumeWidgetSettingsPage extends StatelessWidget {
  static const routeName = 'volume_widget_settings';
  const VolumeWidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.volumeWidgetSettings),
      child: ListView(
        children: [
          SettingsValueStepper(
            autofocus: true,
            title: l.volumeUpdateInterval,
            options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            value: settings.volumeUpdateInterval,
            label: (value) => l.autoLaunchSeconds(value as int),
            onChanged: (value) =>
                settings.setVolumeUpdateInterval(value as int),
          ),
          RoundedSwitchListTile(
            title: Text(l.showVolumeOverlay),
            value: settings.showVolumeOverlay,
            onChanged: settings.setShowVolumeOverlay,
          ),
          OverlayPositionTile(
            value: settings.volumeOverlayPosition,
            onChanged: settings.setVolumeOverlayPosition,
          ),
          OverlayAppearanceTile(
            value: settings.volumeOverlayAppearance,
            onChanged: settings.setVolumeOverlayAppearance,
          ),
          if (settings.showVolumeOverlay)
            FocusableSettingsTile(
              title: Text(l.remoteAccessSettings),
              leading: const Icon(Icons.accessibility),
              onPressed: () => Navigator.of(context).push(
                SettingsRoute(
                  builder: (_) => const RemoteButtonsPage(section: 'access'),
                ),
              ),
            ),
          SettingsHelp(text: l.volumeOverlayHelp),
        ],
      ),
    );
  }
}
