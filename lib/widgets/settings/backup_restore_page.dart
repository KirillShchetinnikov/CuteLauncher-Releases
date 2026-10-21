import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/action_notice.dart';

import 'automatic_backup_page.dart';

import 'backup_restore_actions.dart';
import 'settings_page_layout.dart';

import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../document_files.dart';
import '../../bridge_result.dart';

import 'dart:io';

class BackupRestorePage extends StatelessWidget {
  static const String routeName = "backup_restore_panel";

  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return SettingsPageLayout(
      title: Text(
        localizations.backupAndRestore,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FocusableSettingsTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(localizations.automaticBackups),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(AutomaticBackupPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.upload_file),
              title: Text(
                localizations.exportBackup,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onPressed: () => _export(context, localizations),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.download_done),
              title: Text(
                localizations.importBackup,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onPressed: () => _pickImport(context, localizations),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    Directory? stage;
    try {
      final settingsService = context.read<SettingsService>();
      final backup = context.read<BackupService>();
      stage = await (await getTemporaryDirectory()).createTemp(
        'backup-export-',
      );
      final file = File('${stage.path}/cutelauncher_backup.json');
      await backup.writeBackupTo(
        file,
        settingsService: settingsService,
        validateStructure: true,
      );
      bool? saved;
      try {
        saved = await DocumentFiles.saveBackup(file);
      } on BridgeException catch (error) {
        if (error.status != BridgeStatus.unsupported) rethrow;
        if (!context.mounted) return;
        final confirmed = await showLauncherDialog<bool>(
          context: context,
          builder: (dialogContext) => LauncherAlertDialog(
            title: Text(localizations.exportBackup),
            content: Text(localizations.backupSaveDownloads),
            actions: [
              LauncherDialogButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                isCancel: true,
                child: Text(localizations.cancel),
              ),
              LauncherDialogButton(
                autofocus: true,
                primary: true,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(localizations.backupSaveDownloads),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;
        try {
          final path = await DocumentFiles.saveBackupDownloads(file);
          if (context.mounted) {
            showActionNotice(
              context,
              path == null
                  ? localizations.backupDownloadsFailed
                  : '${localizations.backupSavedToSelectedLocation}: $path',
              error: path == null,
            );
          }
        } catch (_) {
          if (context.mounted) {
            showActionNotice(
              context,
              localizations.backupDownloadsFailed,
              error: true,
            );
          }
        }
        return;
      }
      if (!context.mounted || saved == null) return;
      showActionNotice(
        context,
        saved
            ? localizations.backupSavedToSelectedLocation
            : localizations.exportFailed,
        error: !saved,
      );
    } catch (_) {
      if (context.mounted) {
        showActionNotice(context, localizations.exportFailed, error: true);
      }
    } finally {
      try {
        await stage?.delete(recursive: true);
      } catch (_) {
        /* Private staging is eligible for later cache cleanup. */
      }
    }
  }

  Future<void> _pickImport(BuildContext context, AppLocalizations l) async {
    File? file;
    try {
      file = await DocumentFiles.pickBackup();
      if (file == null) return;
      if (!context.mounted) return;
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialogContext) => LauncherAlertDialog(
          title: Text(l.importBackup),
          content: Text(l.importConfirm),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(dialogContext, false),
              isCancel: true,
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.importAction),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await restoreBackupAndRefresh(context, file);
      if (context.mounted) {
        showActionNotice(context, l.importSuccess);
      }
    } catch (error) {
      if (context.mounted) {
        showActionNotice(context, l.importError, error: true);
      }
    } finally {
      if (file != null && await file.exists()) await file.delete();
    }
  }
}
