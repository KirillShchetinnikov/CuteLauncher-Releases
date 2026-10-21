import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

String adbActionEffect(AppLocalizations l, String action) => switch (action) {
  'home' => l.adbEffectHome,
  'restore' => l.adbEffectRestore,
  'disableSystem' => l.adbEffectDisable,
  'enableSystem' => l.adbEffectEnable,
  'accessibility' => l.adbEffectAccessibility,
  'disableAccessibility' => l.adbEffectAccessibilityDisable,
  'restoreAccessibility' => l.adbEffectAccessibilityRestore,
  'overlay' => l.adbEffectOverlay,
  'notifications' => l.adbEffectNotifications,
  'watchNext' => l.adbEffectWatchNext,
  'usage' => l.adbEffectUsage,
  'writeSettings' => l.adbEffectWriteSettings,
  _ => l.adbChanged,
};

Future<bool> confirmAdbAction(
  BuildContext context,
  String title,
  String action,
  List<String> commands,
) async {
  final l = AppLocalizations.of(context)!;
  final recoveryChanged = commands.any(
    (command) => command.contains(
      'com.google.android.tungsten.setupwraith',
    ),
  );
  return await showLauncherDialog<bool>(
        context: context,
        builder: (ctx) => LauncherAlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(adbActionEffect(l, action)),
                if (recoveryChanged)
                  Text(
                    action == 'disableSystem'
                        ? l.adbRecoveryHomeDisable
                        : l.adbRecoveryHomeRestore,
                  ),
                if (commands.isNotEmpty)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(l.dialogCommandDetails),
                    children: [
                      for (final command in commands)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: SelectableText(
                            'adb shell $command',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            LauncherDialogButton(
              autofocus: true,
              onPressed: () => Navigator.pop(ctx, false),
              isCancel: true,
              child: Text(l.cancel),
            ),
            LauncherDialogButton(
              primary: true,
              danger: action == 'disableSystem',
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(action == 'home' ? l.dialogAssign : l.dialogApply),
            ),
          ],
        ),
      ) ==
      true;
}
