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
import 'settings_information.dart';
import 'settings_read_only_value.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import '../application_list_icon.dart';


import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlockedNotificationsPage extends StatelessWidget {
  static const String routeName = "blocked_notifications_panel";

  const BlockedNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    final notificationsService = context.read<NotificationsService>();
    final blockedPackages = context.select<NotificationsService, Set<String>>(
      (service) => service.blockedPackages,
    );
    final allApps =
        context
            .select<AppsService, List<(String, String)>>(
              (service) => [
                for (final app in service.applications)
                  (app.packageName, app.name),
              ],
            )
            .toList()
          ..sort((a, b) => a.$2.toLowerCase().compareTo(b.$2.toLowerCase()));

    final known = allApps.map((app) => app.$1).toSet();
    final missing =
        blockedPackages.where((package) => !known.contains(package)).toList()
          ..sort();
    final packages = [...allApps.map((app) => app.$1), ...missing];
    final names = {for (final app in allApps) app.$1: app.$2};
    final indices = {
      for (var i = 0; i < packages.length; i++) packages[i]: i + 1,
    };
    return SettingsPageLayout(
      title: Text(localizations.blockedNotificationApps),
      child: ListView.builder(
        itemCount: packages.length + 1,
        findChildIndexCallback: (key) =>
            indices[(key as ValueKey<String>).value],
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsHelp(
                  key: const ValueKey('notification-apps-hint'),
                  title: localizations.blockedAppsGroup,
                  text: localizations.notificationAppsHint,
                ),
                SettingsReadOnlyValue(
                  label: localizations.blockedAppsGroup,
                  value: '${blockedPackages.length}',
                  wrapLines: true,
                ),
                if (blockedPackages.isEmpty)
                  SettingsEmptyState(
                    text: localizations.noBlockedApps,
                    icon: Icons.notifications_none_rounded,
                  ),
                if (blockedPackages.isNotEmpty)
                  FocusableSettingsTile(
                    leading: const Icon(Icons.clear_all),
                    title: Text(localizations.unblockAll),
                    onPressed: notificationsService.unblockAllPackages,
                  ),
              ],
            );
          }
          final package = packages[index - 1];
          return RoundedSwitchListTile(
            key: ValueKey(package),
            value: blockedPackages.contains(package),
            onChanged: (blocked) => blocked
                ? notificationsService.blockPackage(package)
                : notificationsService.unblockPackage(package),
            title: Text(names[package] ?? package),
            secondary: names.containsKey(package)
                ? ApplicationListIcon(packageName: package)
                : const Icon(Icons.android),
          );
        },
      ),
    );
  }
}
