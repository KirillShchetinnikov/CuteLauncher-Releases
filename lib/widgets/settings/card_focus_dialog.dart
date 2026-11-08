import 'settings_choice_dialog.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';

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
      return SettingsChoiceDialog<CardFocusMode>(
        title: Text(l.cardFocusMode),
        width: 360,
        value: settings.cardFocusMode,
        options: CardFocusMode.values,
        optionBuilder: (mode) => Text(cardFocusLabel(mode, l)),
        onSelected: (mode) async {
          await settings.setCardFocusMode(mode);
          if (context.mounted) Navigator.of(context).pop();
        },
      );
    },
  );
}
