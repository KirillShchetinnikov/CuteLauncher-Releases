import 'settings_page_layout.dart';

/*
 * FLauncher
 * Copyright (C) 2024 LeanBitLab
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

import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'focusable_settings_tile.dart';

import 'brightness_page.dart';
import 'night_mode_page.dart';

class DisplaySettingsPage extends StatelessWidget {
  static const String routeName = "display_settings_panel";

  const DisplaySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return SettingsPageLayout(
      title: Text(
        localizations.displayAndScreensaver,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.nightlight),
              title: Text(localizations.nightModeTitle),
              onPressed: () =>
                  Navigator.of(context).pushNamed(NightModePage.routeName),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.brightness_6),
              title: Text(localizations.scheduledBrightness),
              onPressed: () =>
                  Navigator.of(context).pushNamed(BrightnessPage.routeName),
            ),
          ],
        ),
      ),
    );
  }
}
