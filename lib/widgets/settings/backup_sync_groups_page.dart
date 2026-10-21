import 'settings_help.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../backup_sync_groups.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_page_layout.dart';

class BackupSyncGroupsPage extends StatelessWidget {
  const BackupSyncGroupsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BackupAutomationService>();
    final labels = {
      BackupSyncGroup.sections: l.sectionsAndOrder,
      BackupSyncGroup.homeOptions: l.backupSyncHomeOptions,
      BackupSyncGroup.continueWatching: l.continueWatching,
      BackupSyncGroup.topPanel: l.topPanel,
      BackupSyncGroup.background: l.backupSyncBackground,
      BackupSyncGroup.tiles: l.backupSyncTiles,
      BackupSyncGroup.accent: l.accentColor,
      BackupSyncGroup.animations: l.highlightAndAnimation,
      BackupSyncGroup.menuLayout: l.settingsMenuPosition,
      BackupSyncGroup.clockStyle: l.screensaverClockStyle,
      BackupSyncGroup.weatherSource: l.backupSyncWeatherSource,
      BackupSyncGroup.weatherDisplay: l.backupSyncWeatherDisplay,
      BackupSyncGroup.nightMode: l.nightModeTitle,
      BackupSyncGroup.brightness: l.brightnessScheduler,
      BackupSyncGroup.notificationSettings: l.backupSyncNotificationSettings,
      BackupSyncGroup.startup: l.startOnBoot,
      BackupSyncGroup.language: l.appLanguage,
      BackupSyncGroup.updates: l.appUpdates,
      BackupSyncGroup.memory: l.memorySaver,
      BackupSyncGroup.other: l.backupSyncOther,
    };
    final headings = {
      BackupSyncSection.home: l.homeScreen,
      BackupSyncSection.appearance: l.appearanceSettings,
      BackupSyncSection.weather: l.weather,
      BackupSyncSection.display: l.displayAndScreensaver,
      BackupSyncSection.notifications: l.notifications,
      BackupSyncSection.controls: l.controlAndStartup,
      BackupSyncSection.general: l.generalSettings,
    };
    return SettingsPageLayout(
      title: Text(l.backupSyncSettings),
      child: ListView(
        children: [
          SettingsHelp(text: l.backupSyncGroupsHelp),
          for (final section in backupSyncSections.entries) ...[
            if (section.key != BackupSyncSection.home) const Divider(),
            Padding(
              key: ValueKey(section.key),
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: Text(
                headings[section.key]!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final group in section.value)
              RoundedSwitchListTile(
                key: ValueKey(group),
                autofocus: group == BackupSyncGroup.sections,
                title: Text(labels[group]!),
                value: service.syncGroupEnabled(group),
                enabled: !service.busy,
                onChanged: (value) async {
                  try {
                    await service.setSyncGroupEnabled(group, value);
                  } catch (_) {
                    if (context.mounted) {
                      showActionNotice(
                        context,
                        l.backupSyncGroupsFailed,
                        error: true,
                      );
                    }
                  }
                },
              ),
          ],
        ],
      ),
    );
  }
}
