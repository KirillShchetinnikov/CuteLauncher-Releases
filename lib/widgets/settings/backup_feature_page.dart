import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../actions.dart';
import 'settings_section.dart';
import 'settings_information.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/cloud_backup_service.dart';
import '../../providers/drive_backup_service.dart';
import '../action_notice.dart';
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
    final last = s.lastSuccess;
    final material = MaterialLocalizations.of(context);
    void open(Widget page) =>
        Navigator.of(context)
            .push(SettingsRoute(builder: (_) => backupServiceScope(s, page)));
    final storage = SettingsSection(
      children: [
        FocusableSettingsTile(
          autofocus: !s.configured,
          leading: const Icon(Icons.storage_outlined),
          title: Text(l.backupStorage),
          trailing: Text(backupDestinationLabel(l, s.destination)),
          busy: s.busy,
          onPressed: () => open(const BackupStoragePage()),
        ),
        if (!s.configured) SettingsMessage(text: l.backupNotConfigured),
        if (s.destination != BackupDestination.local)
          SettingsReadOnlyValue(
            label: l.backupAccount,
            value: backupAccountLabel(l, s),
            wrapLines: true,
          ),
        FocusableSettingsTile(
          leading: const Icon(Icons.lock_outline),
          title: Text(l.backupPassword),
          busy: s.busy,
          onPressed: () => open(const SyncProtectionPage()),
        ),
      ],
    );
    return SettingsPageLayout(
      title: Text(sync ? l.backupSyncMode : l.backupSaveMode),
      child: ListView(
        children: [
          if (!s.configured) storage,
          SettingsReadOnlyValue(
            label: sync ? l.backupLastSync : l.backupLastCreated,
            value: last == null
                ? (sync ? l.backupNotSynced : l.backupNever)
                : '${material.formatMediumDate(last)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(last))}',
            wrapLines: true,
          ),
          SettingsSection(
            children: [
              FocusableSettingsTile(
                autofocus: s.configured,
                leading: Icon(sync ? Icons.sync : Icons.save_outlined),
                showActionChevron: false,
                title: Text(sync ? l.backupSyncNow : l.backupCreateNow),
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
                      ok
                          ? l.cloudSuccess
                          : (sync
                                ? l.backupSyncRefreshFailed
                                : l.backupCreateFailed),
                      error: !ok,
                    );
                  }
                },
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.folder_open_outlined),
                title: Text(sync ? l.syncFiles : l.backupCopyList),
                enabled: s.configured,
                busy: s.busy,
                onPressed: () => open(
                  sync ? const SyncFilesPage() : const BackupManagementPage(),
                ),
              ),
              if (s.busy) SettingsMessage(text: l.loading),
              if (s.cleanupFailed)
                SettingsMessage(
                  text: l.syncCleanupFailed,
                  kind: SettingsMessageKind.warning,
                ),
            ],
          ),
          SettingsSection(
            title: l.settingsGroupControl,
            children: [
              BackupAutomationSwitch(sync: sync),
              FocusableSettingsTile(
                leading: const Icon(Icons.tune),
                title: Text(sync ? l.backupSyncOptions : l.backupOptions),
                busy: s.busy,
                onPressed: () => open(BackupOptionsPage(sync: sync)),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.settings_suggest_outlined),
                title: Text(l.backupSetupWizard),
                busy: s.busy,
                onPressed: () => showBackupSetup(context, s),
              ),
            ],
          ),
          if (s.configured) storage,
        ],
      ),
    );
  }
}
