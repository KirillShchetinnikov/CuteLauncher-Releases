import 'package:flutter/material.dart';

import '../../app_fonts.dart';
import '../../l10n/app_localizations.dart';
import 'settings_value_stepper.dart';

class LanguageFontChoice extends StatelessWidget {
  final String title, value;
  final bool panel;
  final ValueChanged<String> onChanged;
  const LanguageFontChoice({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.panel = false,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final options = AppFonts.available(locale, panel: panel);
    return SettingsValueStepper(
      title: title,
      value: AppFonts.effective(value, locale),
      options: options,
      inlineChoices: true,
      enabled: options.length > 1,
      label: (id) => switch (id) {
        'system' => l.interfaceSystemFont,
        'sans-serif' => l.fontSans,
        'serif' => l.fontSerif,
        'monospace' => l.fontMono,
        'sans-serif-condensed' => l.fontCondensed,
        _ => AppFonts.families[id]!,
      },
      onChanged: (value) => onChanged(value as String),
    );
  }
}
