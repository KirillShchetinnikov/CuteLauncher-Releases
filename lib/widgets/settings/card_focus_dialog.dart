import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import 'focusable_settings_tile.dart';

String cardFocusLabel(CardFocusMode mode, AppLocalizations l) => switch (mode) {
  CardFocusMode.remember => l.cardFocusRemember,
  CardFocusMode.first => l.cardFocusFirst,
  CardFocusMode.settings => l.cardFocusSettings,
};

Future<void> showCardFocusDialog(BuildContext context) {
  final settings = context.read<SettingsService>();
  return showLauncherDialog<void>(
    context: context,
    builder: (context) {
      final l = AppLocalizations.of(context)!;
      return LauncherAlertDialog(
        title: Text(l.cardFocusMode),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final mode in CardFocusMode.values)
                FocusableSettingsTile(
                  autofocus: mode == settings.cardFocusMode,
                  title: Text(cardFocusLabel(mode, l)),
                  trailing: mode == settings.cardFocusMode
                      ? const Icon(Icons.check)
                      : null,
                  onPressed: () async {
                    await settings.setCardFocusMode(mode);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}
