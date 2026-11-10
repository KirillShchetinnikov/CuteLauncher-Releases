import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';

class FormatEditorExitGuard extends StatefulWidget {
  const FormatEditorExitGuard({super.key, required this.child});

  final Widget child;

  @override
  State<FormatEditorExitGuard> createState() => _FormatEditorExitGuardState();
}

class _FormatEditorExitGuardState extends State<FormatEditorExitGuard> {
  bool _confirming = false;

  Future<void> _confirmExit() async {
    if (_confirming) return;
    _confirming = true;
    try {
      final l = AppLocalizations.of(context)!;
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(l.discardChangesTitle),
          content: Text(l.discardChangesMessage),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              isCancel: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(l.close),
            ),
          ],
        ),
      );
      if (confirmed == true &&
          mounted &&
          ModalRoute.of(context)?.isCurrent == true) {
        Navigator.pop(context);
      }
    } finally {
      _confirming = false;
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _confirmExit();
    },
    child: widget.child,
  );
}
