import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../volume_widget_content.dart';
import '../rounded_switch_list_tile.dart';
import 'access_settings_links.dart';
import 'focusable_settings_tile.dart';
import 'overlay_appearance_tile.dart';
import 'overlay_position_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'settings_section.dart';
import 'settings_value_stepper.dart';
import 'widget_placement_page.dart';

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
          SettingsSection(
            title: l.widgetSettings,
            children: [
              WidgetPlacementLink(id: 'audio', title: l.volumeWidgetSettings),
              SettingsValueStepper(
                autofocus: true,
                title: l.volumeUpdateInterval,
                options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
                value: settings.volumeUpdateInterval,
                label: (value) => l.autoLaunchSeconds(value as int),
                onChanged: (value) =>
                    settings.setVolumeUpdateInterval(value as int),
              ),
              SettingsChoiceTile<VolumeWidgetContent>(
                title: l.volumeWidgetContent,
                value: settings.volumeWidgetContent,
                options: VolumeWidgetContent.values,
                valueBelow: true,
                label: (content) => switch (content) {
                  VolumeWidgetContent.both => l.volumeWidgetContentBoth,
                  VolumeWidgetContent.volume => l.volumeWidgetContentVolume,
                  VolumeWidgetContent.output => l.volumeWidgetContentOutput,
                },
                onChanged: settings.setVolumeWidgetContent,
              ),
            ],
          ),
          SettingsSection(
            title: l.overAppsGroup,
            children: [
              RoundedSwitchListTile(
                title: Text(l.showVolumeOverlay),
                value: settings.showVolumeOverlay,
                onChanged: settings.setShowVolumeOverlay,
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.tune),
                title: Text(l.advancedSettings),
                onPressed: () => Navigator.of(context).push(
                  SettingsRoute<void>(
                    settings: const RouteSettings(
                      name: VolumeOverlaySettingsPage.routeName,
                    ),
                    builder: (_) => const VolumeOverlaySettingsPage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VolumeOverlaySettingsPage extends StatelessWidget {
  static const routeName = 'volume_overlay_settings';
  const VolumeOverlaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.advancedSettings),
      child: ListView(
        children: [
          SettingsSection(
            children: [
              OverlayPositionTile(
                value: settings.volumeOverlayPosition,
                onChanged: settings.setVolumeOverlayPosition,
              ),
              OverlayAppearanceTile(
                value: settings.volumeOverlayAppearance,
                onChanged: settings.setVolumeOverlayAppearance,
              ),
              if (settings.showVolumeOverlay) const AccessibilitySettingsLink(),
              SettingsHelp(text: l.volumeOverlayHelp),
            ],
          ),
        ],
      ),
    );
  }
}
