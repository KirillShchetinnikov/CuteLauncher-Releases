import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/action_notice.dart';

import 'backup_feature_page.dart';
import '../../providers/backup_automation_service.dart';

import 'backup_restore_actions.dart';
import 'settings_page_layout.dart';
import 'settings_section.dart';
import 'settings_information.dart';

import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../document_files.dart';

import 'dart:io';

class BackupRestorePage extends StatelessWidget {
  static const String routeName = "backup_restore_panel";

  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) => SettingsPageLayout(
    title: Text(AppLocalizations.of(context)!.automaticBackups),
    child: ListView(children: const [SettingsManagementSection(autofocus: true)]),
  );
}

class SettingsManagementSection extends StatefulWidget {
  const SettingsManagementSection({super.key, this.autofocus = false});
  final bool autofocus;

  @override
  State<SettingsManagementSection> createState() => _SettingsManagementSectionState();
}

class _SettingsManagementSectionState extends State<SettingsManagementSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.appError,
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final localizations = AppLocalizations.of(context)!;

    return SettingsSection(
      title: localizations.settingsManagementGroup,
      children: [
        FocusableSettingsTile(
          autofocus: widget.autofocus,
          leading: const Icon(Icons.backup_outlined),
          title: Text(localizations.backupSaveMode),
          busy: _busy,
          onPressed: () =>
              _run(() => openBackupFeature(context, BackupMode.backup)),
        ),
        FocusableSettingsTile(
          leading: const Icon(Icons.sync),
          title: Text(localizations.backupSyncMode),
          busy: _busy,
          onPressed: () => _run(
            () => openBackupFeature(context, BackupMode.synchronization),
          ),
        ),
        FocusableSettingsTile(
          leading: const Icon(Icons.upload_file),
          title: Text(localizations.exportBackup),
          busy: _busy,
          onPressed: () => _run(() => _export(context, localizations)),
        ),
        FocusableSettingsTile(
          leading: const Icon(Icons.file_download_outlined),
          title: Text(localizations.importBackup),
          busy: _busy,
          onPressed: () =>
              _run(() => _pickImport(context, localizations)),
        ),
        if (_busy) SettingsMessage(text: localizations.loading),
      ],
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
      if (!context.mounted) return;
      String? destination;
      final saved = await DocumentFiles.saveBackup(
        file,
        context: context,
        onSaved: (path) => destination = path,
      );
      if (!context.mounted || saved == null) return;
      showActionNotice(
        context,
        saved
            ? destination == null
                  ? localizations.backupSavedToSelectedLocation
                  : localizations.fileBrowserSavedTo(destination!)
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
      file = await DocumentFiles.pickBackup(context: context);
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
