import 'settings_help.dart';
import 'settings_page_layout.dart';
import '../application_list_icon.dart';
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
import 'package:flauncher/models/app.dart';
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
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Consumer2<NotificationsService, AppsService>(
      builder: (context, notificationsService, appsService, _) {
        final blockedPackages = notificationsService.blockedPackages;
        final allApps = List<App>.from(
          appsService.applications,
        )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

        final blockedApps = allApps
            .where((a) => blockedPackages.contains(a.packageName))
            .toList();
        final knownBlockedPkg = blockedApps.map((a) => a.packageName).toSet();
        final unknownBlockedPkg = blockedPackages
            .where((p) => !knownBlockedPkg.contains(p))
            .toList();

        return SettingsPageLayout(
          title: Text(
            localizations.blockedNotificationApps,
            style: theme.textTheme.titleLarge,
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              SettingsHelp(
                key: const ValueKey('notification-apps-hint'),
                text: localizations.notificationAppsHint,
              ),
              // --- SECTION 1: BLOCKED APPS ---
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text(
                  "${localizations.blockedAppsGroup} (${blockedPackages.length})",
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (blockedPackages.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.green,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                localizations.noBlockedApps,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              SettingsHelp(text: localizations.noBlockedAppsDesc),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                ...blockedApps.map(
                  (app) => FocusableSettingsTile(
                    leading: FutureBuilder<dynamic>(
                      future: appsService.getAppIcon(app.packageName),
                      builder: (_, snapshot) => snapshot.hasData
                          ? Image.memory(
                              snapshot.data,
                              width: 32,
                              height: 32,
                              cacheWidth: 64,
                            )
                          : const Icon(Icons.android),
                    ),
                    title: Text(app.name),
                    trailing: Text(localizations.unblockApp),
                    valueIcon: Icons.lock_open,
                    onPressed: () =>
                        notificationsService.unblockPackage(app.packageName),
                  ),
                ),
                ...unknownBlockedPkg.map(
                  (pkg) => FocusableSettingsTile(
                    leading: ApplicationListIcon(packageName: pkg),
                    title: Text(pkg),
                    trailing: Text(localizations.unblockApp),
                    valueIcon: Icons.lock_open,
                    onPressed: () => notificationsService.unblockPackage(pkg),
                  ),
                ),
                FocusableSettingsTile(
                  leading: const Icon(Icons.clear_all, color: Colors.orange),
                  title: Text(
                    localizations.unblockAll,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.orange,
                    ),
                  ),
                  onPressed: () => notificationsService.unblockAllPackages(),
                ),
              ],

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(),
              ),

              // --- SECTION 2: ALL APPLICATIONS ---
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.applications,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    SettingsHelp(text: localizations.noBlockedAppsDesc),
                  ],
                ),
              ),
              ...allApps.map((app) {
                final isBlocked = blockedPackages.contains(app.packageName);

                return RoundedSwitchListTile(
                  key: ValueKey(app.packageName),
                  value: !isBlocked,
                  onChanged: (allowed) {
                    if (allowed) {
                      notificationsService.unblockPackage(app.packageName);
                    } else {
                      notificationsService.blockPackage(app.packageName);
                    }
                  },
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(app.name, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 2),
                      if (!isBlocked)
                        Text(
                          isBlocked
                              ? localizations.notificationsBlocked
                              : localizations.notificationsAllowed,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isBlocked
                                ? Colors.redAccent
                                : Colors.white54,
                          ),
                        ),
                    ],
                  ),
                  secondary: FutureBuilder<dynamic>(
                    future: appsService.getAppIcon(app.packageName),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.memory(
                            snapshot.data,
                            cacheWidth:
                                (64 * MediaQuery.devicePixelRatioOf(context))
                                    .ceil()
                                    .clamp(1, 512),
                            width: 32,
                            height: 32,
                          ),
                        );
                      }
                      return const Icon(Icons.android, size: 32);
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
