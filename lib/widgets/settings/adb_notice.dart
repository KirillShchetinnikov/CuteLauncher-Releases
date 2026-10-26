import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';

void showAdbNotice(BuildContext context, String? status, {String? title}) {
  final l = AppLocalizations.of(context)!;
  if (status == 'wifiOwned') {
    unawaited(confirmAdbWifiRisk(context, title: title, allowOverride: false));
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

/// A one-operation acknowledgement; dismissing either window never grants it.
Future<bool> confirmAdbWifiRisk(
  BuildContext context, {
  String? title,
  bool allowOverride = true,
}) async {
  final l = AppLocalizations.of(context)!;
  final proceed = await showLauncherDialog<bool>(
    context: context,
    builder: (ctx) => LauncherAlertDialog(
      title: Text(title ?? l.adbWifiOwnedTitle),
      content: Text(l.adbWifiOwned),
      actions: [
        LauncherDialogButton(
          autofocus: true,
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l.ok),
        ),
        if (allowOverride)
          LauncherDialogButton(
            danger: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.adbWifiOverride),
          ),
      ],
    ),
  );
  if (proceed != true || !allowOverride || !context.mounted) return false;
  return await showLauncherDialog<bool>(
        context: context,
        builder: (ctx) => LauncherAlertDialog(
          title: Text(l.adbWifiRiskTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.adbWifiRiskEffect),
              const SizedBox(height: 12),
              Text(l.adbWifiRiskLoss),
              const SizedBox(height: 12),
              Text(
                l.adbWifiRiskRecovery,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(l.adbWifiRiskConsent),
            ],
          ),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              isCancel: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              danger: true,
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l.adbWifiDisable),
            ),
          ],
        ),
      ) ==
      true;
}
