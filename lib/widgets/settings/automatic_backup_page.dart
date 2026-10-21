import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_value_stepper.dart';
import 'settings_time_tile.dart';
import 'settings_slider_tile.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../backup_schedule.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/automatic_backup_service.dart';
import '../../providers/backup_automation_service.dart';
import 'backup_management_block.dart';
import 'backup_sync_groups_page.dart';
import '../rounded_switch_list_tile.dart';
import 'cloud_backup_page.dart';
import 'drive_backup_page.dart';
import 'local_backup_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';

Future<T?> backupChoice<T>(
  BuildContext context,
  String title,
  Map<T, String> values,
  T current,
) => showLauncherDialog<T>(
  context: context,
  builder: (dialog) => SimpleDialog(
    title: Text(title),
    children: [
      SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in values.entries)
              FocusableSettingsTile(
                autofocus: e.key == current,
                onPressed: () => Navigator.pop(dialog, e.key),
                title: Text(e.value),
                trailing: e.key == current
                    ? const Icon(Icons.check)
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    ],
  ),
);

class AutomaticBackupPage extends StatelessWidget {
  static const routeName = 'automatic_backup';
  const AutomaticBackupPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BackupAutomationService>();
    final material = MaterialLocalizations.of(context);
    final destinations = {
      BackupDestination.webdav: 'WebDAV / Nextcloud',
      BackupDestination.googleDrive: l.backupGoogleDrive,
      BackupDestination.local: l.backupLocal,
    };
    final modes = {
      BackupMode.backup: l.backupSaveMode,
      BackupMode.synchronization: l.backupSyncMode,
    };
    final last = service.lastSuccess;
    void open(Widget page) =>
        Navigator.of(context).push(SettingsRoute(builder: (_) => page));
    Widget button(
      String label,
      VoidCallback callback, {
      String? value,
      IconData? icon,
      bool requiresStorage = false,
    }) => FocusableSettingsTile(
      leading: icon == null ? null : Icon(icon),
      title: Text(label),
      trailing: value == null ? null : Text(value),
      enabled: !service.busy && (!requiresStorage || service.configured),
      onPressed: service.busy || (requiresStorage && !service.configured)
          ? null
          : callback,
    );
    return SettingsPageLayout(
      title: Text(l.automaticBackups),
      child: ListView(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.backupLastCreated),
                  Text(
                    last == null
                        ? l.backupNever
                        : '${material.formatMediumDate(last)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(last))}',
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                button(l.backupStorage, () async {
                  final value = await backupChoice(
                    context,
                    l.backupStorage,
                    destinations,
                    service.destination,
                  );
                  if (value != null) {
                    await service.configure(destination: value);
                  }
                }, value: destinations[service.destination]),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    service.configured
                        ? l.backupConfigured
                        : l.backupNotConfigured,
                  ),
                ),
                button(
                  service.destination == BackupDestination.local
                      ? l.backupLocal
                      : l.backupConnection,
                  () => open(switch (service.destination) {
                    BackupDestination.webdav => const CloudBackupPage(),
                    BackupDestination.googleDrive => const DriveBackupPage(),
                    BackupDestination.local => const LocalBackupPage(),
                  }),
                  icon: Icons.settings_backup_restore,
                ),
              ],
            ),
          ),
          Card(
            child: Column(
              children: [
                button(l.backupMode, () async {
                  final value = await backupChoice(
                    context,
                    l.backupMode,
                    modes,
                    service.mode,
                  );
                  if (value != null) await service.configure(mode: value);
                }, value: modes[service.mode]),
                button(
                  service.mode == BackupMode.backup
                      ? l.backupOptions
                      : l.backupSyncOptions,
                  () => open(
                    BackupOptionsPage(
                      sync: service.mode == BackupMode.synchronization,
                    ),
                  ),
                  icon: Icons.tune,
                ),
              ],
            ),
          ),
          Card(
            child: button(
              l.backupManagement,
              () => open(const BackupManagementPage()),
              icon: Icons.backup_outlined,
              requiresStorage: true,
            ),
          ),
          if (service.busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class BackupOptionsPage extends StatelessWidget {
  final bool sync, localOnly;
  const BackupOptionsPage({
    super.key,
    this.sync = false,
    this.localOnly = false,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AutomaticBackupService>();
    final automation = context.watch<BackupAutomationService>();
    final schedule = service.schedule;
    final frequencies = {
      BackupFrequency.hourly: l.backupHourly,
      BackupFrequency.daily: l.backupDaily,
      BackupFrequency.weekly: l.backupWeekly,
    };
    Future<void> save({
      BackupFrequency? frequency,
      int? hour,
      int? minute,
      int? weekday,
    }) => service.setSchedule(
      BackupSchedule(
        frequency: frequency ?? schedule.frequency,
        hour: hour ?? schedule.hour,
        minute: minute ?? schedule.minute,
        weekday: weekday ?? schedule.weekday,
      ),
    );
    return SettingsPageLayout(
      title: Text(sync ? l.backupSyncOptions : l.backupOptions),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            autofocus: true,
            enabled: !automation.busy && automation.configured,
            title: Text(l.backupAutoEnabled),
            value: automation.enabled,
            onChanged: (v) => automation.configure(enabled: v),
          ),
          if (!localOnly)
            FocusableSettingsTile(
              title: Text(sync ? l.backupSyncScope : l.backupScope),
              trailing: Text(
                automation.shared ? l.backupShared : l.backupSeparate,
              ),
              enabled: !automation.busy,
              onPressed: () async {
                final value = await backupChoice(
                  context,
                  sync ? l.backupSyncScope : l.backupScope,
                  {false: l.backupSeparate, true: l.backupShared},
                  automation.shared,
                );
                if (value != null) await automation.configure(shared: value);
              },
            ),
          if (!sync)
            SettingsValueStepper(
              title: l.automaticBackupsKeep,
              value: service.keepCount,
              options: const [1, 3, 5, 10],
              enabled: !automation.busy,
              label: (v) => '$v',
              onChanged: (v) => service.setKeepCount(v as int),
            ),
          if (sync) ...[
            FocusableSettingsTile(
              title: Text(l.backupSyncSettings),
              enabled: !automation.busy,
              onPressed: automation.busy
                  ? null
                  : () => Navigator.of(context).push(
                      SettingsRoute(
                        builder: (_) => const BackupSyncGroupsPage(),
                      ),
                    ),
            ),
            SettingsValueStepper(
              title: l.backupSyncLimit,
              value: automation.syncMinutes,
              options: const [1, 5, 15, 30, 60, 180, 1440],
              label: (v) => '$v ${l.backupMinutes}',
              onChanged: (v) => automation.configure(syncMinutes: v as int),
            ),
          ] else ...[
            FocusableSettingsTile(
              title: Text(l.backupFrequency),
              trailing: Text(frequencies[schedule.frequency]!),
              onPressed: () async {
                final value = await backupChoice(
                  context,
                  l.backupFrequency,
                  frequencies,
                  schedule.frequency,
                );
                if (value != null) await save(frequency: value);
              },
            ),
            if (!localOnly)
              if (schedule.frequency == BackupFrequency.hourly)
                SettingsSliderTile(
                  title: l.backupTime,
                  value: schedule.minute,
                  options: [for (var i = 0; i < 60; i++) i],
                  label: (v) => ':${v.toInt().toString().padLeft(2, '0')}',
                  onChanged: (v) => save(minute: v.toInt()),
                )
              else
                SettingsTimeTile(
                  title: l.backupTime,
                  value: schedule.hour * 60 + schedule.minute,
                  onChanged: (v) => save(hour: v ~/ 60, minute: v % 60),
                ),
            if (!localOnly && schedule.frequency == BackupFrequency.weekly)
              FocusableSettingsTile(
                title: Text(l.backupWeekday),
                trailing: Text(
                  DateFormat.EEEE(l.localeName)
                      .format(DateTime(2026, 10, 4 + schedule.weekday)),
                ),
                onPressed: () async {
                  final day = await backupChoice(context, l.backupWeekday, {
                    for (final n in [1, 2, 3, 4, 5, 6, 7])
                      n: DateFormat.EEEE(l.localeName)
                          .format(DateTime(2026, 10, 4 + n)),
                  }, schedule.weekday);
                  if (day != null) await save(weekday: day);
                },
              ),
          ],
        ],
      ),
    );
  }
}
