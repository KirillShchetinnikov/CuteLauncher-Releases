import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_value_stepper.dart';

import 'package:flauncher/widgets/action_notice.dart';

import 'adb_permission_tile.dart';
import 'watch_next_limits_page.dart';
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
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';

import 'continue_watching_apps_page.dart';
import 'continue_watching_card_size_page.dart';
import 'continue_watching_max_items_page.dart';
import 'focusable_settings_tile.dart';

class ContinueWatchingSettingsPage extends StatefulWidget {
  static const String routeName = "continue_watching_settings_panel";

  const ContinueWatchingSettingsPage({super.key});

  @override
  State<ContinueWatchingSettingsPage> createState() =>
      _ContinueWatchingSettingsPageState();
}

class _ContinueWatchingSettingsPageState
    extends State<ContinueWatchingSettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<WatchNextService>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settingsService = context.watch<SettingsService>();
    final watchNextService = context.watch<WatchNextService>();

    final rawSize = settingsService.continueWatchingCardSize;
    final height =
        int.tryParse(rawSize) ??
        (rawSize == 'compact'
            ? 112
            : rawSize == 'large'
            ? 157
            : 135);
    final blockedCount = settingsService.hiddenWatchNextPackages.length;
    final hiddenProgramsCount =
        settingsService.hiddenWatchNextProgramIds.length;

    return SettingsPageLayout(
      title: Text(
        localizations.continueWatching,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Watch Next Permission
          FocusableSettingsTile(
            autofocus: true,
            leading: const Icon(Icons.security),
            title: Text(
              localizations.watchNextAccess,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Text(
              watchNextService.hasPermission
                  ? localizations.granted
                  : localizations.permissionRequired,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: watchNextService.hasPermission
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onPressed: () async {
              final has = await watchNextService.checkPermission();
              if (!has && context.mounted) {
                final granted = await watchNextService.requestPermission();
                if (!granted && context.mounted) {
                  _showWatchNextPermissionGuide(context);
                }
              }
            },
          ),
          AdbPermissionTile(
            title: localizations.watchNextAccessAdb,
            action: 'watchNext',
            permissionMethod: 'checkWatchNextPermission',
            onRefresh: watchNextService.refresh,
          ),
          if (settingsService.showContinueWatching) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Divider(),
            ),
            // App Management (Apps & Blocked Content)
            FocusableSettingsTile(
              leading: const Icon(Icons.apps_outlined),
              title: Text(
                AppLocalizations.of(context)!.appsWithContinueWatching,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: Text(
                blockedCount > 0
                    ? localizations.blockedCount(blockedCount)
                    : localizations.manage,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: blockedCount > 0
                      ? Theme.of(context).colorScheme.tertiary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(ContinueWatchingAppsPage.routeName),
            ),
            FocusableSettingsTile(
              leading: const Icon(Icons.apps_outlined),
              title: Text(localizations.watchNextAppLimits),
              onPressed: () =>
                  Navigator.of(context)
                      .pushNamed(WatchNextLimitsPage.routeName),
            ),
            SettingsValueStepper(
              title: localizations.maximumItems,
              options: ContinueWatchingMaxItemsPage.maxItemsPresets,
              value: settingsService.continueWatchingMaxItems,
              label: (v) => v == 0
                  ? localizations.unlimitedItems
                  : localizations.itemsCount(v as int),
              onChanged: (v) =>
                  settingsService.setContinueWatchingMaxItems(v as int),
            ),
            SettingsValueStepper(
              title: localizations.cardSize,
              value: height,
              options: ContinueWatchingCardSizePage.cardSizePresets(
                localizations,
              ).map((preset) => preset.$1).toList(),
              label: (v) => '$v dp',
              onChanged: (v) =>
                  settingsService.setContinueWatchingCardSize('$v'),
            ),
            // Show progress bar
            RoundedSwitchListTile(
              value: settingsService.continueWatchingShowProgress,
              onChanged: (v) =>
                  settingsService.setContinueWatchingShowProgress(v),
              title: Text(
                AppLocalizations.of(context)!.playbackProgressBar,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Show percentage badge
            RoundedSwitchListTile(
              value: settingsService.continueWatchingShowPercentage,
              onChanged: (v) =>
                  settingsService.setContinueWatchingShowPercentage(v),
              title: Text(
                AppLocalizations.of(context)!.playbackPercentage,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Show description
            RoundedSwitchListTile(
              value: settingsService.continueWatchingShowDescription,
              onChanged: (v) =>
                  settingsService.setContinueWatchingShowDescription(v),
              title: Text(
                AppLocalizations.of(context)!.episodeVideoDetails,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            // Hidden individual programs
            if (hiddenProgramsCount > 0)
              FocusableSettingsTile(
                leading: Icon(
                  Icons.restore,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                title: Text(
                  AppLocalizations.of(context)!.restoreHiddenPrograms,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
                trailing: Text(
                  localizations.hiddenCount(hiddenProgramsCount),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.tertiary),
                ),
                onPressed: () async {
                  await settingsService.clearHiddenWatchNextPrograms();
                  await watchNextService.refresh();
                  if (context.mounted) {
                    showActionNotice(
                      context,
                      AppLocalizations.of(context)!.allHiddenProgramsRestored,
                    );
                  }
                },
              ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Divider(),
          ),
        ],
      ),
    );
  }

  Future<void> _showWatchNextPermissionGuide(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final packageName = packageInfo.packageName;
    if (!context.mounted) return;

    showLauncherDialog(
      context: context,
      builder: (dialogContext) => LauncherAlertDialog(
        title: Text(AppLocalizations.of(context)!.watchNextAccessAdb),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.watchNextPermissionGuide,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .08),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: SelectableText(
                'adb shell pm grant $packageName com.android.providers.tv.permission.READ_WRITE_WATCH_NEXT_PROGRAMS',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          LauncherDialogButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.ok),
          ),
        ],
      ),
    );
  }
}
