import 'package:flauncher/widgets/launcher_dialog.dart';
import 'memory_page.dart';
import 'diagnostics_page.dart';
import 'settings_page_layout.dart';

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
import 'backup_restore_page.dart';

import 'flauncher_about_dialog.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:flauncher/language_names.dart';

class GeneralSettingsPage extends StatelessWidget {
  static const routeName = 'general_settings_panel';
  const GeneralSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final language = context.watch<SettingsService>().appLanguage;
    final languageName = languageNames[language] ?? l.systemDefault;
    return SettingsPageLayout(
      title: Text(
        l.generalSettings,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.language),
            title: Text(l.appLanguage),
            trailing: Text(languageName),
            onPressed: () =>
                Navigator.of(context).pushNamed(AppLanguagePage.routeName),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.system_update_alt),
            title: Text(l.appUpdates),
            onPressed: () =>
                Navigator.of(context).pushNamed(UpdatesPage.routeName),
          ),
          FocusableSettingsTile(
            autofocus: false,
            leading: const Icon(Icons.settings_backup_restore),
            title: Text(l.backupAndRestore),
            onPressed: () =>
                Navigator.of(context).pushNamed(BackupRestorePage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.memory),
            title: Text(l.memoryTitle),
            onPressed: () => Navigator.of(context).pushNamed(MemoryPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: Text(l.diagnosticsHubTitle),
            onPressed: () => Navigator.of(context).pushNamed(DiagnosticsPage.routeName),
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
        ],
      ),
    );
  }
}
