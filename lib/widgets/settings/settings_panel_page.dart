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
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';

import 'settings_destinations.dart';
import 'settings_section.dart';

import 'package:flauncher/widgets/settings/interface_settings_page.dart';

import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

import 'focusable_settings_tile.dart';
import 'updates_page.dart';
import '../android_settings_icon.dart';

class SettingsPanelPage extends StatefulWidget {
  static const String routeName = "settings_panel";

  const SettingsPanelPage({super.key});

  @override
  State<SettingsPanelPage> createState() => _SettingsPanelPageState();
}

class _SettingsPanelPageState extends State<SettingsPanelPage> {
  final _homeFocus = FocusNode();

  @override
  void dispose() {
    _homeFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final updateVersion = context.select<UpdateService?, String?>(
      (service) =>
          service?.fromPlay == false ? service?.release?.version : null,
    );

    return SettingsPageLayout(
      title: SizedBox(
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 68),
              child: Text(l.settings),
            ),
            PositionedDirectional(
              end: 0,
              top: 0,
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/about-icon.png',
                    width: 56,
                    height: 56,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsetsDirectional.only(end: 68),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: updateVersion == null
              ? Text(
                  'CuteLauncher',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                )
              : TextButton(
                  key: const ValueKey('available-update-shortcut'),
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.bodySmall,
                    backgroundColor: theme.colorScheme.primary.withValues(
                      alpha: .12,
                    ),
                  ),
                  onPressed: () =>
                      Navigator.of(context).pushNamed(UpdatesPage.routeName),
                  child: Text(
                    '${l.updateAvailable} · ${displayAppVersion(updateVersion)}',
                  ),
                ),
        ),
      ),
      initialFocus: _homeFocus,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSection(
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  focusNode: _homeFocus,
                  leading: const Icon(Icons.home_outlined),
                  title: Text(l.homeScreen),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(InterfaceSettingsPage.routeName),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.widgets_outlined),
                  title: Text(l.widgetsAndPanels),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(WidgetsAndPanelsPage.routeName),
                ),
              ],
            ),
            SettingsSection(
              children: [
                FocusableSettingsTile(
                  autofocus: false,
                  leading: const Icon(Icons.handyman_outlined),
                  title: Text(l.launcherFunctions),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(LauncherFunctionsPage.routeName),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.terminal_outlined),
                  title: Text(l.launcherDefaultAndAdb),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(LauncherAccessPage.routeName),
                ),
                FocusableSettingsTile(
                  autofocus: false,
                  leading: const Icon(Icons.apps),
                  title: Text(l.applications),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(ApplicationsPanelPage.routeName),
                ),
              ],
            ),
            SettingsSection(
              children: [
                FocusableSettingsTile(
                  autofocus: false,
                  leading: const Icon(Icons.settings_outlined),
                  title: Text(l.launcherSettings),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(GeneralSettingsPage.routeName),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.monitor_heart_outlined),
                  title: Text(l.diagnosticsHubTitle),
                  onPressed: () =>
                      Navigator.of(context)
                          .pushNamed(LauncherDiagnosticsPage.routeName),
                ),
              ],
            ),
            const Divider(),
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
