import 'appearance_settings_page.dart';
import 'accent_color_page.dart';
import 'settings_section.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_page_layout.dart';
import 'settings_choice_tile.dart';
import 'file_browser_settings_page.dart';
import 'reset_settings_tile.dart';
import 'backup_restore_page.dart';

import 'package:provider/provider.dart';

import '../../providers/settings_service.dart';
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
import 'app_language_page.dart';
import 'updates_page.dart';

import 'flauncher_about_dialog.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flauncher/language_names.dart';

class GeneralSettingsPage extends StatelessWidget {
  static const routeName = 'general_settings_panel';
  const GeneralSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final languageName = languageNames[settings.appLanguage] ?? l.systemDefault;
    return SettingsPageLayout(
      title: Text(l.launcherSettings),
      child: ListView(
        children: [
          SettingsSection(
            title: l.homeVisualGroup,
            children: [
              const InterfaceStyleChoice(),
              FocusableSettingsTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l.accentColor),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AccentColorPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.language),
                title: Text(l.appLanguage),
                trailing: Text(languageName),
                onPressed: () =>
                    Navigator.of(context).pushNamed(AppLanguagePage.routeName),
              ),
              ...appearanceSettingsTiles(context),
            ],
          ),
          SettingsSection(
            title: l.settingsMaintenanceGroup,
            children: [
              FocusableSettingsTile(
                leading: const Icon(Icons.system_update_alt),
                title: Text(l.appUpdates),
                onPressed: () =>
                    Navigator.of(context).pushNamed(UpdatesPage.routeName),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l.aboutFlauncher),
                onPressed: () => showLauncherDialog(
                  context: context,
                  builder: (_) => FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (c, snapshot) => snapshot.hasData
                        ? CuteLauncherAboutDialog(packageInfo: snapshot.data!)
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              FocusableSettingsTile(
                leading: const Icon(Icons.description_outlined),
                title: Text(
                  MaterialLocalizations.of(context).licensesPageTitle,
                ),
                onPressed: () => showLicensePage(
                  context: context,
                  applicationName: 'CuteLauncher',
                ),
              ),
            ],
          ),
          const SettingsManagementSection(),
          SettingsSection(
            title: l.filePickerBuiltIn,
            children: [
              Consumer<SettingsService>(
                builder: (context, settings, _) =>
                    SettingsChoiceTile<FileManagerPreference>(
                      title: l.fileManagerPreference,
                      value: settings.fileManagerPreference,
                      options: FileManagerPreference.values,
                      label: (value) => switch (value) {
                        FileManagerPreference.ask => l.fileManagerAsk,
                        FileManagerPreference.builtIn => l.fileManagerBuiltIn,
                        FileManagerPreference.external => l.fileManagerExternal,
                      },
                      onChanged: settings.setFileManagerPreference,
                    ),
              ),
              FocusableSettingsTile(
                title: Text(l.filePickerBuiltIn),
                leading: const Icon(Icons.folder_open_outlined),
                onPressed: () =>
                    Navigator.of(context)
                        .pushNamed(FileBrowserSettingsPage.routeName),
              ),
            ],
          ),
          SettingsSection(children: [const ResetSettingsTile()]),
        ],
      ),
    );
  }
}
