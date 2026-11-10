import 'package:flutter/material.dart';

import '../file_selection.dart';

import 'package:provider/provider.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/local_backup_storage.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_choice_dialog.dart';
import 'settings_read_only_value.dart';

class LocalBackupPage extends StatelessWidget {
  static const routeName = 'local_backup';
  const LocalBackupPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BackupAutomationService>();
    return SettingsPageLayout(
      title: Text(l.backupLocal),
      child: ListView(
        children: [
          if (service.localFolder != null &&
              service.localFolder != LocalBackupStorage.downloadsFolder)
            SettingsReadOnlyValue(
              label: l.fileBrowserCurrentFolder,
              value: Uri.decodeFull(service.localFolder!),
              textDirection: TextDirection.ltr,
            ),
          FocusableSettingsTile(
            title: Text(l.backupFolderPath),
            trailing: Text(
              service.localFolder == null
                  ? l.backupPrivateFolder
                  : service.localFolder == LocalBackupStorage.downloadsFolder
                  ? l.backupDownloadsFolder
                  : Uri.decodeComponent(
                      Uri.parse(service.localFolder!).pathSegments.last,
                    ),
            ),
            busy: service.busy,
            onPressed: () async {
              try {
                final folder = await showLauncherDialog<String>(
                  context: context,
                  builder: (dialog) => SettingsChoiceDialog<String>(
                    title: Text(l.backupFolderPath),
                    value: service.localFolder == null ? 'private'
                        : service.localFolder == LocalBackupStorage.downloadsFolder
                        ? 'downloads' : 'external',
                    options: const ['private', 'downloads', 'external'],
                    optionBuilder: (value) => Text(switch (value) {
                      'private' => l.backupPrivateFolder,
                      'downloads' => l.backupDownloadsFolder,
                      _ => l.backupChooseFolder,
                    }),
                    onSelected: (value) => Navigator.pop(dialog, value),
                  ),
                );
                if (folder == null) return;
                if (folder == 'private') {
                  await service.setLocalFolder(null);
                  return;
                }
                const channel = BridgeChannel('me.efesser.flauncher/method');
                if (folder == 'downloads') {
                  await channel.invokeMethod<Object>('backupFolderOperation', {
                    'operation': 'verify',
                    'uri': LocalBackupStorage.downloadsFolder,
                  });
                  await service.setLocalFolder(
                    LocalBackupStorage.downloadsFolder,
                  );
                  return;
                }
                if (!context.mounted) return;
                final uri = await FileSelection.select<String>(
                  context,
                  'pickBackupFolder',
                  initialPath: service.localFolder,
                );
                if (uri != null && context.mounted) {
                  await service.setLocalFolder(uri);
                }
              } on BridgeException catch (error) {
                if (context.mounted) {
                  showActionNotice(
                    context,
                    error.status == BridgeStatus.unsupported
                        ? l.backupFolderPickerUnavailable
                        : l.backupFolderFailed,
                    error: true,
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  showActionNotice(context, l.backupFolderFailed, error: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
