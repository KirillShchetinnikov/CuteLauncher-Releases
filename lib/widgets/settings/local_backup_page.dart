import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../bridge_result.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/local_backup_storage.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

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
            enabled: !service.busy,
            onPressed: () async {
              try {
                final folder = await showLauncherDialog<String>(
                  context: context,
                  builder: (dialog) => SimpleDialog(
                    title: Text(l.backupFolderPath),
                    children: [
                      SizedBox(
                        width: 400,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FocusableSettingsTile(
                              autofocus: service.localFolder == null,
                              title: Text(l.backupPrivateFolder),
                              onPressed: () => Navigator.pop(dialog, 'private'),
                            ),
                            FocusableSettingsTile(
                              autofocus:
                                  service.localFolder ==
                                  LocalBackupStorage.downloadsFolder,
                              title: Text(l.backupDownloadsFolder),
                              onPressed: () =>
                                  Navigator.pop(dialog, 'downloads'),
                            ),
                            FocusableSettingsTile(
                              title: Text(l.backupChooseFolder),
                              onPressed: () =>
                                  Navigator.pop(dialog, 'external'),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                final uri = await channel.invokeMethod<String>(
                  'pickBackupFolder',
                );
                if (uri != null) await service.setLocalFolder(uri);
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
