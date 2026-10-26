import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';

void showAdbNotice(BuildContext context, String? status, {String? title}) {
  final l = AppLocalizations.of(context)!;
  if (status == 'wifiOwned') {
    unawaited(
      showLauncherDialog<void>(
        context: context,
        builder: (ctx) => LauncherAlertDialog(
          title: Text(title ?? l.adbWifiOwnedTitle),
          content: SingleChildScrollView(child: Text(l.adbWifiOwned)),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text(l.ok),
            ),
          ],
        ),
      ),
    );
    return;
  }
  final success = status == 'success' || status == 'ready';
  final text = switch (status) {
    'success' => l.actionCompleted,
    'ready' => l.adbReady,
    'authorization' => l.adbAuthorization,
    'denied' => l.adbDenied,
    'invalid' => l.adbInvalid,
    'noRecovery' => l.adbNoRecovery,
    'changed' => l.adbChanged,
    'unsupported' => l.adbUnsupported,
    'wifiOwned' => l.adbWifiOwned,
    'wifiUnknown' => l.adbWifiUnknown,
    _ => l.adbUnavailable,
  };
  showActionNotice(
    context,
    title == null ? text : '$title: $text',
    error: !success,
  );
}
