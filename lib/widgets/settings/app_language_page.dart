import 'settings_page_layout.dart';
/*
 * FLauncher
 * Copyright (C) 2026 LeanBitLab
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/language_names.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppLanguagePage extends StatelessWidget {
  static const String routeName = "app_language_panel";

  const AppLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
      builder: (context, service, _) {
        return SettingsPageLayout(
          title: Text(
            localizations.appLanguage,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          child: ListView(
            children: [
              _radioTile(
                context,
                service,
                localizations.systemDefault,
                "",
                autofocus: true,
              ),
              for (final language in languageNames.entries)
                if (AppLocalizations.supportedLocales.any(
                  (locale) => locale.languageCode == language.key,
                ))
                _radioTile(context, service, language.value, language.key),
            ],
          ),
        );
      },
    );
  }

  Widget _radioTile(
    BuildContext context,
    SettingsService service,
    String label,
    String value, {
    bool autofocus = false,
  }) {
    final isSelected = service.appLanguage == value;
    return FocusableSettingsTile(
      autofocus: autofocus && isSelected,
      trailing: isSelected ? const Icon(Icons.check) : const SizedBox.shrink(),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      onPressed: () => service.setAppLanguage(value),
    );
  }
}
