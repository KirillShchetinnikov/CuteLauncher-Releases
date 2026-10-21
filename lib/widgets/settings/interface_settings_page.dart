import 'section_style_page.dart';
import 'wallpaper_panel_page.dart';
import 'appearance_page.dart';
import 'misc_panel_page.dart';
import 'settings_route.dart';
import 'settings_choice_tile.dart';
import 'back_button_actions.dart';
import 'card_focus_dialog.dart';
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
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import '../../providers/settings_service.dart';
import '../../providers/screensaver_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'launcher_sections_panel_page.dart';

class HomeParametersPage extends StatelessWidget {
  const HomeParametersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final canStartScreensaver =
        context.watch<ScreensaverService?>()?.capabilities.canStart == true;
    return SettingsPageLayout(
      title: Text(
        l.homeParameters,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          Consumer<SettingsService>(
            builder: (context, s, _) => SettingsChoiceTile<String>(
              title: l.backButtonAction,
              value:
                  s.backButtonAction == BACK_BUTTON_ACTION_SCREENSAVER &&
                      !canStartScreensaver
                  ? BACK_BUTTON_ACTION_NOTHING
                  : s.backButtonAction,
              options: [
                BACK_BUTTON_ACTION_NOTHING,
                BACK_BUTTON_ACTION_CLOCK,
                if (canStartScreensaver) BACK_BUTTON_ACTION_SCREENSAVER,
              ],
              label: (value) => switch (value) {
                BACK_BUTTON_ACTION_CLOCK =>
                  l.dialogOptionBackButtonActionShowClock,
                BACK_BUTTON_ACTION_SCREENSAVER when canStartScreensaver =>
                  l.dialogOptionBackButtonActionShowScreensaver,
                _ => l.dialogOptionBackButtonActionDoNothing,
              },
              onChanged: s.setBackButtonAction,
            ),
          ),
          Consumer<SettingsService>(
            builder: (context, s, _) => SettingsChoiceTile<CardFocusMode>(
              title: l.cardFocusMode,
              value: s.cardFocusMode,
              options: CardFocusMode.values,
              label: (mode) => cardFocusLabel(mode, l),
              onChanged: s.setCardFocusMode,
            ),
          ),
          Consumer<SettingsService>(
            builder: (context, s, _) => RoundedSwitchListTile(
              value: s.hideLauncherTile,
              onChanged: s.setHideLauncherTile,
              title: Text(l.hideLauncherTile),
            ),
          ),
          Consumer<SettingsService>(
            builder: (context, s, _) => RoundedSwitchListTile(
              value: s.hideAndroidSettingsTile,
              onChanged: s.setHideAndroidSettingsTile,
              title: Text(l.hideAndroidSettingsTile),
            ),
          ),
          Consumer<SettingsService>(
            builder: (context, s, _) => RoundedSwitchListTile(
              value: s.appKeyClickEnabled,
              onChanged: s.setAppKeyClickEnabled,
              title: Text(l.appKeyClick),
            ),
          ),
        ],
      ),
    );
  }
}

class InterfaceSettingsPage extends StatelessWidget {
  static const routeName = 'interface_settings_panel';
  const InterfaceSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.homeScreen),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.category),
            title: Text(l.sectionsAndOrder),
            onPressed: () =>
                Navigator.of(context)
                    .pushNamed(LauncherSectionsPanelPage.routeName),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.palette_outlined),
            title: Text(l.appearanceSettings),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute<void>(builder: (_) => const HomeAppearancePage()),
            ),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.tune),
            title: Text(l.homeParameters),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute<void>(builder: (_) => const HomeParametersPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeAppearancePage extends StatelessWidget {
  const HomeAppearancePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.appearanceSettings),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.wallpaper),
            title: Text(l.background),
            onPressed: () =>
                Navigator.of(context).pushNamed(WallpaperPanelPage.routeName),
          ),

          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.view_agenda_outlined),
            title: Text(l.launcherSections),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute<void>(builder: (_) => const SectionStylePage()),
            ),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.grid_view),
            title: Text(l.tilesAndLabels),
            onPressed: () => Navigator.of(
              context,
            ).push(SettingsRoute<void>(builder: (_) => const AppearancePage())),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.animation),
            title: Text(l.highlightAndAnimation),
            onPressed: () => Navigator.of(
              context,
            ).push(SettingsRoute<void>(builder: (_) => const MiscPanelPage())),
          ),
        ],
      ),
    );
  }
}
