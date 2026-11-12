import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../actions.dart';
import 'settings_section.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/cloud_backup_service.dart';
import '../../providers/drive_backup_service.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'automatic_backup_page.dart';
import 'backup_management_block.dart';
import 'backup_setup_wizard.dart';
import 'backup_storage_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_read_only_value.dart';
import 'settings_route.dart';
import 'sync_files_page.dart';
import 'sync_protection_page.dart';

Widget backupServiceScope(BackupAutomationService service, Widget child) =>
    MultiProvider(
      providers: [
        ChangeNotifierProvider<BackupAutomationService>.value(value: service),
        ChangeNotifierProvider<CloudBackupService>.value(
          value: service.destination == BackupDestination.smb
              ? service.smb
              : service.webdav,
        ),
        ChangeNotifierProvider<DriveBackupService>.value(
          value: service.destination == BackupDestination.yandexDisk
              ? service.yandex
              : service.drive,
        ),
      ],
      child: Builder(
        builder: (context) =>
            Actions(actions: {BackIntent: BackAction(context)}, child: child),
      ),
    );

Future<void> openBackupFeature(BuildContext context, BackupMode mode) async {
  final service = context.read<BackupAutomationService>().forMode(mode);
  await service.initialized;
  if (!context.mounted) return;
  if (!service.setupComplete) {
    final saved = await showBackupSetup(context, service);
    if (saved != true || !context.mounted) return;
  }
  await Navigator.of(context).push(
    SettingsRoute(
      builder: (_) => backupServiceScope(service, const BackupFeaturePage()),
    ),
  );
}

class BackupFeaturePage extends StatelessWidget {
  const BackupFeaturePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<BackupAutomationService>();
    final sync = s.mode == BackupMode.synchronization;
    void open(Widget page) =>
        Navigator.of(context)
            .push(SettingsRoute(builder: (_) => backupServiceScope(s, page)));
    return SettingsPageLayout(
      title: Text(sync ? l.backupSyncMode : l.backupSaveMode),
      child: ListView(
        children: [
          SettingsSection(
            title: l.settingsGroupControl,
            children: [
              SettingsReadOnlyValue(
                label: l.backupLastSuccess,
                value: s.lastSuccess == null
                    ? l.backupNever
                    : '${MaterialLocalizations.of(context).formatMediumDate(s.lastSuccess!)} ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(s.lastSuccess!))}',
                wrapLines: true,
              ),
              RoundedSwitchListTile(
                title: Text(l.backupAutoEnabled),
                value: s.enabled,
                enabled: s.configured,
                busy: s.busy,
                onChanged: (v) async {
                  if (v && sync) {
                    await showBackupSetup(context, s);
                  } else {
                    await s.configure(enabled: v);
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: l.settingsGroupStorage,
            children: [
              FocusableSettingsTile(
                title: Text(l.backupStorage),
                trailing: Text(backupDestinationLabel(l, s.destination)),
                busy: s.busy,
                onPressed: () => open(const BackupStoragePage()),
              ),
              if (s.destination != BackupDestination.local)
                SettingsReadOnlyValue(
                  label: l.backupAccount,
                  value: backupAccountLabel(l, s),
                  wrapLines: true,
                ),
              FocusableSettingsTile(
                title: Text(l.backupPassword),
                busy: s.busy,
                onPressed: () => open(const SyncProtectionPage()),
              ),
            ],
          ),
          SettingsSection(
            title: sync ? l.backupSyncOptions : l.backupOptions,
            children: [
              FocusableSettingsTile(
                title: Text(sync ? l.backupSyncOptions : l.backupOptions),
                busy: s.busy,
                onPressed: () => open(BackupOptionsPage(sync: sync)),
              ),
              FocusableSettingsTile(
                title: Text(l.backupSetupWizard),
                busy: s.busy,
                onPressed: () => showBackupSetup(context, s),
              ),
            ],
          ),
          SettingsSection(
            title: sync ? l.syncFiles : l.backupManagement,
            children: [
              FocusableSettingsTile(
                title: Text(sync ? l.backupSyncRefresh : l.backupCreateNow),
                enabled: s.configured,
                busy: s.busy,
                onPressed: () async {
                  final ok = sync && !s.enabled
                      ? await confirmBackupSynchronization(
                          context,
                          s,
                          enable: false,
                        )
                      : await s.run(manual: true);
                  if (context.mounted && (ok || s.failed)) {
                    showActionNotice(
                      context,
                      ok ? l.cloudSuccess : l.backupSyncRefreshFailed,
                      error: !ok,
                    );
                  }
                },
              ),
              FocusableSettingsTile(
                title: Text(sync ? l.syncFiles : l.backupManagement),
                enabled: s.configured,
                busy: s.busy,
                onPressed: () => open(
                  sync ? const SyncFilesPage() : const BackupManagementPage(),
                ),
              ),
              if (s.cleanupFailed) Text(l.syncCleanupFailed),
            ],
          ),
        ],
      ),
    );
  }
}
