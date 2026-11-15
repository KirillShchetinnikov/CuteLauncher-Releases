import 'package:flutter/material.dart';

import '../bridge_result.dart';
import '../l10n/app_localizations.dart';
import 'action_notice.dart';
import 'launcher_dialog.dart';

/// Reuses the same confirmation and Android command from every launcher menu.
enum TvPowerAction {
  sleep,
  reboot,
  shutdown;

  static const channel = BridgeChannel(
    'cutelauncher/tv_power',
    preserveErrorCodes: true,
  );

  String label(AppLocalizations l) => switch (this) {
    sleep => l.quickActionsSleep,
    reboot => l.tvPowerReboot,
    shutdown => l.tvPowerOff,
  };

  Future<bool> confirmAndSend(
    BuildContext context, {
    VoidCallback? onConfirmed,
  }) async {
    final l = AppLocalizations.of(context)!;
    final actionLabel = label(l);
    final message = switch (this) {
      sleep => l.tvPowerOffConfirm,
      reboot => l.tvPowerRebootConfirm,
      shutdown => l.quickActionsShutdownConfirm,
    };
    try {
      final confirmed = await showLauncherDialog<bool>(
        context: context,
        builder: (dialog) => LauncherAlertDialog(
          title: Text(actionLabel),
          content: Text(message),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              isCancel: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              danger: true,
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(actionLabel),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return false;
      onConfirmed?.call();
      final sent = await channel.invokeMethod<bool>(name) == true;
      if (context.mounted) {
        showActionNotice(
          context,
          sent ? l.tvPowerSent : l.tvPowerFailed,
          error: !sent,
        );
      }
      return sent;
    } catch (_) {
      if (context.mounted) {
        showActionNotice(context, l.tvPowerFailed, error: true);
      }
      return false;
    }
  }
}
