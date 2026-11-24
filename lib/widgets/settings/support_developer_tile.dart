import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../launcher_dialog.dart';
import 'donate_dialog.dart';
import 'focusable_settings_tile.dart';

Future<void> showSupportDeveloperDialog(BuildContext context) =>
    showLauncherDialog<void>(
      context: context,
      builder: (_) => const DonateDialog(),
    );

class SupportDeveloperTile extends StatelessWidget {
  const SupportDeveloperTile({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return FocusableSettingsTile(
      leading: const Icon(Icons.favorite_outline),
      title: Text(l.supportDeveloper),
      onPressed: () => showSupportDeveloperDialog(context),
    );
  }
}
