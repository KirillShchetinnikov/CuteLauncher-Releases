import 'package:flauncher/widgets/launcher_dialog.dart';

import 'adb_permission_tile.dart';
import 'settings_page_layout.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/notifications_service.dart';

import 'focusable_settings_tile.dart';
import 'blocked_notifications_page.dart';

class NotificationsSettingsPage extends StatefulWidget {
  static const String routeName = "notifications_settings_panel";

  const NotificationsSettingsPage({super.key});

  @override
  State<NotificationsSettingsPage> createState() =>
      _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final service = context.read<NotificationsService>();
        service.checkPermission();
        service.checkOverlayPermission();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final service = context.read<NotificationsService>();
      service.checkPermission();
      service.checkOverlayPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;

    return SettingsPageLayout(
      title: Text(
        localizations.notifications,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: SingleChildScrollView(
        child: Consumer<NotificationsService>(
          builder: (context, service, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FocusableSettingsTile(
                  autofocus: true,
                  leading: const Icon(Icons.notifications_active_outlined),
                  title: Text(
                    localizations.notificationAccess,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: Text(
                    service.hasPermission
                        ? localizations.granted
                        : localizations.permissionRequired,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: service.hasPermission
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    await service.checkPermission();
                    if (!service.hasPermission) {
                      final success = await service.requestPermission();
                      if (!success && context.mounted) {
                        _showNotificationPermissionGuide(context);
                      }
                    }
                  },
                ),
                AdbPermissionTile(
                  title: localizations.notificationAccessAdb,
                  action: 'notifications',
                  permissionMethod: 'checkNotificationListenerPermission',
                  onRefresh: service.checkPermission,
                ),
                if (service.hasPermission) ...[
                  FocusableSettingsTile(
                    leading: const Icon(Icons.block),
                    title: Text(
                      localizations.blockedNotificationApps,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      service.blockedPackages.isEmpty
                          ? '0'
                          : '${service.blockedPackages.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: service.blockedPackages.isNotEmpty
                            ? Theme.of(context).colorScheme.tertiary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onPressed: () =>
                        Navigator.of(context)
                            .pushNamed(BlockedNotificationsPage.routeName),
                  ),
                  RoundedSwitchListTile(
                    title: Text(localizations.hidePersistentNotifications),
                    value: service.hidePersistentNotifications,
                    onChanged: service.setHidePersistentNotifications,
                  ),
                  RoundedSwitchListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(localizations.systemWidePopupAlert),
                        if (!service.hasOverlayPermission)
                          Text(localizations.overlayPermissionRequired),
                      ],
                    ),
                    value:
                        service.hasOverlayPermission &&
                        service.systemPopupEnabled,
                    onChanged: (value) async {
                      await service.checkOverlayPermission();
                      if (!service.hasOverlayPermission) {
                        final success = await service
                            .requestOverlayPermission();
                        if (!success && context.mounted) {
                          _showOverlayPermissionGuide(context);
                        }
                      } else {
                        await service.setSystemPopupEnabled(value);
                      }
                    },
                  ),
                  AdbPermissionTile(
                    title: localizations.overlayAccessAdb,
                    action: 'overlay',
                    permissionMethod: 'checkOverlayPermission',
                    onRefresh: service.checkOverlayPermission,
                  ),
                ],
                Consumer<SettingsService>(
                  builder: (context, settings, _) => RoundedSwitchListTile(
                    value: settings.showNowPlaying,
                    onChanged: settings.setShowNowPlaying,
                    title: Text(localizations.showNowPlaying),
                  ),
                ),
                Consumer<SettingsService>(
                  builder: (context, settings, _) => RoundedSwitchListTile(
                    value: settings.autoHideNotificationsWidget,
                    onChanged: settings.setAutoHideNotificationsWidget,
                    title: Text(localizations.autoHideNotificationBell),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _showNotificationPermissionGuide(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;
    if (!context.mounted) return;

    showLauncherDialog(
      context: context,
      builder: (dialogContext) => LauncherAlertDialog(
        title: Text(AppLocalizations.of(context)!.notificationAccessAdb),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.notificationPermissionGuide),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                'adb shell cmd notification allow_listener $packageName/com.leanbitlab.ltvL.LauncherNotificationListenerService',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          LauncherDialogButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<NotificationsService>()
                  .openAppNotificationSettings();
            },
            child: Text(AppLocalizations.of(context)!.openAppInfo),
          ),
          LauncherDialogButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showOverlayPermissionGuide(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;
    if (!context.mounted) return;

    showLauncherDialog(
      context: context,
      builder: (context) => LauncherAlertDialog(
        title: Text(AppLocalizations.of(context)!.overlayPermission),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.overlayPermissionGuide),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .08),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                'adb shell appops set $packageName SYSTEM_ALERT_WINDOW allow',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          LauncherDialogButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
