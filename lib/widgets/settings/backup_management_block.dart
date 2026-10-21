import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/backup_automation_service.dart';
import '../../providers/backup_storage.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_value_stepper.dart';
import 'settings_page_layout.dart';

class BackupManagementPage extends StatelessWidget {
  const BackupManagementPage({super.key});

  @override
  Widget build(BuildContext context) => SettingsPageLayout(
    title: Text(AppLocalizations.of(context)!.backupManagement),
    child: const SingleChildScrollView(child: BackupManagementBlock()),
  );
}

class BackupManagementBlock extends StatefulWidget {
  const BackupManagementBlock({super.key});
  @override
  State<BackupManagementBlock> createState() => _BackupManagementBlockState();
}

class _BackupManagementBlockState extends State<BackupManagementBlock> {
  List<RemoteBackupFile> _copies = [];
  String? _signature;
  bool _loading = false;
  bool _waitForIdle = false;
  int _request = 0;
  int _page = 0;
  String signature(BackupAutomationService s) =>
      '${s.destination}/${s.mode}/${s.scope}/${s.localFolder}/${s.configured}/${s.lastSuccess}';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.watch<BackupAutomationService>();
    final next = signature(service);
    if (_signature != next || (_waitForIdle && !service.busy)) {
      _waitForIdle = false;
      _signature = next;
      _copies = [];
      _page = 0;
      final request = ++_request;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && request == _request) _load();
      });
    }
  }

  Future<void> _load() async {
    final service = context.read<BackupAutomationService>();
    if (service.busy) {
      _waitForIdle = true;
      return;
    }
    if (_loading || !service.configured) return;
    final request = _request;
    setState(() => _loading = true);
    try {
      final copies = await service.availableCopies();
      if (mounted && request == _request) {
        setState(() {
          _copies = copies;
          _page = _page.clamp(
            0,
            copies.isEmpty ? 0 : (copies.length - 1) ~/ 20,
          );
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        showActionNotice(
          context,
          AppLocalizations.of(context)!.backupListFailed,
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        if (request != _request) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _load();
          });
        }
      }
    }
  }

  Future<void> _action(RemoteBackupFile copy, bool delete) async {
    final l = AppLocalizations.of(context)!;
    final service = context.read<BackupAutomationService>();
    final confirmed = await showLauncherDialog<bool>(
      context: context,
      builder: (dialog) => LauncherAlertDialog(
        title: Text(delete ? l.delete : l.backupRestoreCopy),
        content: Text(
          delete ? l.backupDeleteConfirm : l.backupCloudImportConfirm,
        ),
        actions: [
          LauncherDialogButton(
            autofocus: true,
            onPressed: () => Navigator.pop(dialog, false),
            isCancel: true,
            child: Text(l.cancel),
          ),
          LauncherDialogButton(
            primary: true,
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(delete ? l.delete : l.importAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (delete) {
        await service.deleteCopy(copy);
      } else {
        await service.importLatest(selected: copy);
      }
      if (mounted) {
        showActionNotice(context, delete ? l.actionCompleted : l.importSuccess);
      }
    } catch (_) {
      if (mounted) {
        showActionNotice(
          context,
          delete ? l.backupDeleteFailed : l.importError,
          error: true,
        );
      }
    }
    if (mounted) await _load();
  }

  Future<void> _chooseAction(RemoteBackupFile copy, String label) async {
    final l = AppLocalizations.of(context)!;
    final delete = await showLauncherDialog<bool>(
      context: context,
      builder: (dialog) => SimpleDialog(
        title: Text(label),
        children: [
          SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  title: Text(l.backupRestoreCopy),
                  leading: const Icon(Icons.restore),
                  onPressed: () => Navigator.pop(dialog, false),
                ),
                FocusableSettingsTile(
                  title: Text(l.delete),
                  leading: const Icon(Icons.delete_outline),
                  onPressed: () => Navigator.pop(dialog, true),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (delete != null && mounted) await _action(copy, delete);
  }

  String _label(RemoteBackupFile copy, MaterialLocalizations material) {
    final created = BackupAutomationService.createdAt(copy);
    return '${material.formatMediumDate(created)} ${material.formatTimeOfDay(TimeOfDay.fromDateTime(created))} · TV ${copy.name.split('-')[3].substring(0, 6)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<BackupAutomationService>();
    final material = MaterialLocalizations.of(context);
    final enabled = !service.busy && service.configured && !_loading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableSettingsTile(
          title: Text(l.backupCreateNow),
          leading: const Icon(Icons.save_outlined),
          enabled: enabled,
          onPressed: () async {
            final saved = await service.run(manual: true);
            if (!context.mounted) return;
            showActionNotice(
              context,
              saved ? l.cloudSuccess : l.backupCreateFailed,
              error: !saved,
            );
            if (mounted) await _load();
          },
        ),
        FocusableSettingsTile(
          title: Text(l.backupRefreshCopyList),
          leading: const Icon(Icons.refresh),
          enabled: enabled,
          onPressed: _load,
        ),
        if (_loading) const LinearProgressIndicator(),
        if (!_loading && _copies.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l.noRestorePoints),
          ),
        for (final copy in _copies.skip(_page * 20).take(20))
          FocusableSettingsTile(
            key: ValueKey(copy.name),
            title: Text(_label(copy, material)),
            leading: const Icon(Icons.description_outlined),
            enabled: enabled,
            onPressed: () => _chooseAction(copy, _label(copy, material)),
          ),
        if (_copies.length > 20)
          SettingsValueStepper(
            title: l.backupCopyList,
            value: _page,
            options: [for (var i = 0; i < (_copies.length + 19) ~/ 20; i++) i],
            enabled: enabled,
            label: (v) => '${(v as int) + 1} / ${(_copies.length + 19) ~/ 20}',
            onChanged: (v) => setState(() => _page = v as int),
          ),
      ],
    );
  }
}
