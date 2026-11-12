import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/backup_storage.dart';
import '../launcher_dialog.dart';
import '../action_notice.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

class SyncFilesPage extends StatefulWidget {
  const SyncFilesPage({super.key});
  @override
  State<SyncFilesPage> createState() => _SyncFilesPageState();
}

class _SyncFilesPageState extends State<SyncFilesPage> {
  List<RemoteBackupFile> _files = [];
  bool _busy = false, _failed = false;
  int _page = 0;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      final files = await context
          .read<BackupAutomationService>()
          .synchronizationFiles();
      if (mounted) {
        setState(() {
          _files = files;
          _page = _page.clamp(0, files.isEmpty ? 0 : (files.length - 1) ~/ 20);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _action(RemoteBackupFile file) async {
    final service = context.read<BackupAutomationService>();
    final l = AppLocalizations.of(context)!;
    final own =
        BackupAutomationService.copyBelongsToDevice(file, service.device) ==
        true;
    final confirmed = await showLauncherDialog<bool>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(own ? l.delete : l.syncRetire),
        content: Text(
          '${BackupAutomationService.copyDeviceLabel(file)}\n${own ? l.backupDeleteConfirm : l.syncRetireConfirm}',
        ),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            isCancel: true,
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(own ? l.delete : l.syncRetire),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _busy = true);
    try {
      if (own) {
        await service.deleteSynchronizationFile(file);
      } else if (!await service.excludeSyncDevice(file)) {
        throw StateError('Sync failed');
      }
    } catch (_) {
      if (mounted) {
        showActionNotice(context, l.backupSyncGroupsFailed, error: true);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        await _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BackupAutomationService>();
    final busy = _busy || service.busy;
    return SettingsPageLayout(
      title: Text(l.syncFiles),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            title: Text(l.backupSyncRefresh),
            busy: busy,
            onPressed: busy ? null : _load,
          ),
          FocusableSettingsTile(
            title: Text(l.syncCleanup),
            busy: busy,
            onPressed: busy
                ? null
                : () async {
                    setState(() => _busy = true);
                    try {
                      await service.cleanSynchronizationFiles();
                    } catch (_) {
                      if (context.mounted) {
                        showActionNotice(
                          context,
                          l.backupListFailed,
                          error: true,
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _busy = false);
                        await _load();
                      }
                    }
                  },
          ),
          if (_failed) Text(l.backupListFailed),
          if (service.cleanupFailed) Text(l.syncCleanupFailed),
          if (_busy) const LinearProgressIndicator(),
          for (final file in _files.skip(_page * 20).take(20))
            FocusableSettingsTile(
              title: Text(
                '${BackupAutomationService.copyDeviceLabel(file)}\n${MaterialLocalizations.of(context).formatMediumDate(BackupAutomationService.createdAt(file))}',
              ),
              busy: busy,
              onPressed: busy ? null : () => _action(file),
            ),
          if (_page > 0)
            FocusableSettingsTile(
              title: Text(
                MaterialLocalizations.of(context).previousPageTooltip,
              ),
              onPressed: () => setState(() => _page--),
            ),
          if ((_page + 1) * 20 < _files.length)
            FocusableSettingsTile(
              title: Text(MaterialLocalizations.of(context).nextPageTooltip),
              onPressed: () => setState(() => _page++),
            ),
        ],
      ),
    );
  }
}
