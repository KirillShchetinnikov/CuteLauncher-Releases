import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import 'focusable_settings_tile.dart';

class ResetStyleTile extends StatelessWidget {
  final Future<void> Function() onReset;
  final String? title, hint;
  const ResetStyleTile({
    super.key,
    required this.onReset,
    this.title,
    this.hint,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FocusableSettingsTile(
      leading: const Icon(Icons.restore),
      title: Text(title ?? l.resetStyleSection),
      onPressed: () async {
        final confirmed = await showLauncherDialog<bool>(
          context: context,
          builder: (c) => LauncherAlertDialog(
            title: Text(title ?? l.resetStyleSection),
            content: Text(hint ?? l.resetStyleSectionHint),
            actions: [
              LauncherDialogButton(
                autofocus: true,
                onPressed: () => Navigator.pop(c, false),
                child: Text(MaterialLocalizations.of(c).cancelButtonLabel),
              ),
              LauncherDialogButton(
                primary: true,
                danger: true,
                onPressed: () => Navigator.pop(c, true),
                child: Text(title ?? l.resetStyleSection),
              ),
            ],
          ),
        );
        if (confirmed == true && context.mounted) await onReset();
      },
    );
  }
}
