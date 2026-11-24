import 'settings_section.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_value_stepper.dart';
import 'memory_settings_page.dart';

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
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';

import 'continue_watching_apps_page.dart';
import 'app_channels_appearance_page.dart';
import 'continue_watching_max_items_page.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';

class ContinueWatchingSettingsPage extends StatefulWidget {
  static const String routeName = "continue_watching_settings_panel";

  const ContinueWatchingSettingsPage({super.key});

  @override
  State<ContinueWatchingSettingsPage> createState() =>
      _ContinueWatchingSettingsPageState();
}

class _ContinueWatchingSettingsPageState
    extends State<ContinueWatchingSettingsPage> {
  WatchNextService? _source;
  @override
  void initState() {
    super.initState();
    _source = context.read<WatchNextService>();
    _source!.setCatalogVisible(this, true);
  }

  @override
  void dispose() {
    _source?.setCatalogVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final settingsService = context.watch<SettingsService>();
    final watchNextService = context.watch<WatchNextService>();

    final blockedCount = settingsService.hiddenWatchNextPackages.length;
    return SettingsPageLayout(
      title: Text(
        localizations.continueWatching,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          RoundedSwitchListTile(
            value: settingsService.showContinueWatching,
            onChanged: settingsService.setShowContinueWatching,
            title: Text(localizations.categoryVisible),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.apps_outlined),
            title: Text(localizations.appsWithContinueWatching),
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
            onPressed: () => Navigator.of(context)
                .pushNamed(ContinueWatchingAppsPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.format_list_numbered),
            title: Text(localizations.watchNextAppLimits),
            onPressed: () =>
                Navigator.of(context).pushNamed(WatchNextLimitsPage.routeName),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.tune),
            title: Text(localizations.appChannelsSectionSettings),
            onPressed: () => Navigator.of(context).push(SettingsRoute<void>(
              builder: (_) => const ContinueWatchingSectionSettingsPage(),
            )),
          ),
          FocusableSettingsTile(
            title: Text(localizations.categoryAppearance),
            leading: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.of(context).push(SettingsRoute<void>(
              builder: (_) => const AppChannelsAppearancePage(
                categoryId: ContinueWatchingSection.sectionId,
              ),
            )),
          ),
          SettingsSection(
            title: localizations.settingsGroupAccess,
            children: [
              FocusableSettingsTile(
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
            ],
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

class ContinueWatchingSectionSettingsPage extends StatelessWidget {
  const ContinueWatchingSectionSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final hiddenProgramsCount = settings.hiddenWatchNextProgramIds.length;
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SettingsPageLayout(
      title: Text(l.appChannelsSectionSettings),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SettingsSection(
            children: [
              SettingsValueStepper(
                autofocus: true,
                title: l.maximumItems,
                options: ContinueWatchingMaxItemsPage.maxItemsPresets,
                value: settings.continueWatchingMaxItems,
                label: (v) => v == 0 ? l.unlimitedItems : l.itemsCount(v as int),
                onChanged: (v) => settings.setContinueWatchingMaxItems(v as int),
              ),
              const PosterMemoryLink(PosterCacheSection.watchNext, fromSection: true),
            ],
          ),
          SettingsSection(
            title: l.settingsGroupCards,
            children: [
              RoundedSwitchListTile(
                value: settings.continueWatchingShowProgress,
                onChanged: settings.setContinueWatchingShowProgress,
                title: Text(l.playbackProgressBar),
              ),
              RoundedSwitchListTile(
                value: settings.continueWatchingShowDescription,
                onChanged: settings.setContinueWatchingShowDescription,
                title: Text(l.episodeVideoDetails),
              ),
              if (hiddenProgramsCount > 0)
                FocusableSettingsTile(
                  leading: Icon(Icons.restore, color: colors.tertiary),
                  title: Text(
                    l.restoreHiddenPrograms,
                    style: textTheme.bodyMedium?.copyWith(color: colors.tertiary),
                  ),
                  trailing: Text(
                    l.hiddenCount(hiddenProgramsCount),
                    style: textTheme.bodySmall?.copyWith(color: colors.tertiary),
                  ),
                  onPressed: () async {
                    final source = context.read<WatchNextService>();
                    await settings.clearHiddenWatchNextPrograms();
                    await source.refresh();
                    if (context.mounted) {
                      showActionNotice(context, l.allHiddenProgramsRestored);
                    }
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
