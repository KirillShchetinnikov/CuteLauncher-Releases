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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/watch_next_service.dart';
import '../application_list_icon.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';

class ContinueWatchingAppsPage extends StatelessWidget {
  static const routeName = 'continue_watching_apps_panel';
  const ContinueWatchingAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.read<SettingsService>();
    final source = context.read<WatchNextService>();
    final names = context.select<AppsService, Map<String, String>>(
      (service) => {for (final app in service.applications) app.packageName: app.name},
    );
    final blocked = context
        .select<SettingsService, List<String>>(
          (service) => service.hiddenWatchNextPackages,
        )
        .toSet();
    final counts = <String, int>{};
    for (final program in context.select<WatchNextService, List<String>>(
      (service) =>
          service.programs.map((program) => program.packageName).toList(),
    )) {
      counts.update(program, (count) => count + 1, ifAbsent: () => 1);
    }
    // Switching a source never moves its row or duplicates it in another group.
    final packages = {...names.keys, ...blocked, ...counts.keys}.toList()
      ..sort(
        (a, b) => (names[a] ?? a).toLowerCase().compareTo(
          (names[b] ?? b).toLowerCase(),
        ),
      );
    final indices = {
      for (var i = 0; i < packages.length; i++) packages[i]: i + 1,
    };
    return SettingsPageLayout(
      title: Text(l.continueWatchingApps),
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
                  title: l.continueWatchingApps,
                  text: l.blockWatchNextHint,
                ),
                Text(l.blockedWatchNextCount(blocked.length)),
                if (blocked.isEmpty) Text(l.allAppsCanContinueWatching),
                if (counts.isEmpty) Text(l.noWatchNextApps),
                if (blocked.isNotEmpty)
                  FocusableSettingsTile(
                    leading: const Icon(Icons.clear_all),
                    title: Text(l.unblockAllApps),
                    onPressed: () async {
                      await settings.unhideAllWatchNextPackages();
                      await source.refresh();
                    },
                  ),
              ],
            );
          }
          final package = packages[index - 1];
          return RoundedSwitchListTile(
            key: ValueKey(package),
            value: !blocked.contains(package),
            onChanged: (allowed) async {
              if (allowed) {
                await settings.unhideWatchNextPackage(package);
              } else {
                await settings.hideWatchNextPackage(package);
              }
              await source.refresh();
            },
            secondary: names.containsKey(package)
                ? ApplicationListIcon(packageName: package)
                : const Icon(Icons.android),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(names[package] ?? package),
                Text(
                  blocked.contains(package)
                      ? l.blockedContinueWatching
                      : counts.containsKey(package)
                      ? l.activeItemsCount(counts[package]!)
                      : l.enabled,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
