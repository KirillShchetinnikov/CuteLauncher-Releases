import 'settings_page_layout.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';

import 'appearance_settings_page.dart';
import 'status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/display_settings_page.dart';

import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'focusable_settings_tile.dart';
import '../android_settings_icon.dart';

class SettingsPanelPage extends StatelessWidget {
  static const String routeName = "settings_panel";

  const SettingsPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return SettingsPageLayout(
      title: Text(l.settings),
      subtitle: Text(
        'CuteLauncher',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FocusableSettingsTile(
              autofocus: true,
              leading: const Icon(Icons.home_outlined),
              title: Text(l.homeScreen),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(InterfaceSettingsPage.routeName),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.dashboard), title: Text(l.topPanel),
              onPressed: () => Navigator.of(context).pushNamed(StatusBarPanelPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: false,
              leading: const Icon(Icons.palette_outlined),
              title: Text(l.appearanceSettings),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(AppearanceSettingsPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: false,
              leading: const Icon(Icons.apps),
              title: Text(l.applications),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(ApplicationsPanelPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: false,
              leading: const Icon(Icons.tv),
              title: Text(l.displayAndScreensaver),
              onPressed: () =>
                  Navigator.of(context).pushNamed(DisplaySettingsPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: false,
              leading: const Icon(Icons.settings_remote),
              title: Text(l.controlAndStartup),
              onPressed: () =>
                  Navigator.of(context).pushNamed(AccessibilityPage.routeName),
            ),
            FocusableSettingsTile(
              autofocus: false,
              leading: const Icon(Icons.settings_suggest_outlined),
              title: Text(l.generalSettings),
              onPressed: () =>
                  Navigator.of(context).pushNamed(GeneralSettingsPage.routeName),
            ),
            const SizedBox(height: 16),
            FocusableSettingsTile(
              leading: const AndroidSettingsIcon(),
              title: Text(l.androidTvSettings),
              onPressed: () => context.read<AppsService>().openSettings(),
            ),
          ],
        ),
      ),
    );
  }
}
