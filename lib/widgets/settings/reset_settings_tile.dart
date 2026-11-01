import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../flauncher_channel.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';

class ResetSettingsTile extends StatefulWidget {
  const ResetSettingsTile({super.key});

  @override
  State<ResetSettingsTile> createState() => _ResetSettingsTileState();
}

class _ResetSettingsTileState extends State<ResetSettingsTile> {
  bool _busy = false;
  bool _applying = false;
  bool _failed = false;
  bool _accepted = false;

  Future<void> _reset() async {
    if (_busy) return;
    _busy = true;
    try {
      final l = AppLocalizations.of(context)!;
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(l.resetLauncherSettings),
          content: Text(l.resetLauncherSettingsConfirmation),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(MaterialLocalizations.of(dialog).cancelButtonLabel),
            ),
            LauncherDialogButton(
              danger: true,
              primary: true,
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.resetLauncherSettings),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      setState(() {
        _applying = true;
        _failed = false;
      });
      if (!await FLauncherChannel().resetApplicationData()) {
        throw StateError('Application reset rejected');
      }
      // Android may kill the process before sending the reply. An accepted
      // request remains busy until shutdown and is never reported as completed.
      _accepted = true;
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (!_accepted) {
        _busy = false;
        if (mounted) setState(() => _applying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FocusableSettingsTile(
          leading: const Icon(Icons.settings_backup_restore),
          title: Text(l.resetLauncherSettings),
          trailing: _applying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const SizedBox.shrink(),
          onPressed: _reset,
        ),
        if (_failed)
          Text(
            l.resetLauncherSettingsError,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }
}
