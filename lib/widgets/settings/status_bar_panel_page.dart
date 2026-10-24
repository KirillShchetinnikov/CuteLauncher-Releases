import 'information_settings_page.dart';
import 'settings_route.dart';
import 'settings_help.dart';
import 'remote_panel_page.dart';
import 'inputs_settings_page.dart';
import 'adb_permission_tile.dart';
import '../../providers/network_service.dart';
import 'settings_page_layout.dart';
/*
 * FLauncher
 * Copyright (C) 2024 Oscar Rojas
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
import '../../providers/tv_inputs_service.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'data_usage_period_page.dart';
import 'panel_order_page.dart';
import 'notifications_settings_page.dart';

class StatusBarObjectsPage extends StatelessWidget {
  static const routeName = 'status_bar_objects';

  const StatusBarObjectsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<SettingsService>();
    final inputs = context.watch<TvInputsService?>();
    return SettingsPageLayout(
      title: Text(
        l.topPanelObjects,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        children: [
          const InformationObjectsSection(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.networkAndTrafficGroup,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          RoundedSwitchListTile(
            autofocus: false,
            value: s.showNetworkIndicatorInStatusBar,
            onChanged: s.setShowNetworkIndicatorInStatusBar,
            title: Text(l.showNetwork),
          ),
          RoundedSwitchListTile(
            autofocus: false,
            value: s.showDataWidgetInStatusBar,
            onChanged: s.setShowDataWidgetInStatusBar,
            title: Text(l.showTraffic),
          ),
          if (s.showDataWidgetInStatusBar)
            Consumer<NetworkService>(
              builder: (context, network, _) => network.hasUsageStatsPermission
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(l.trafficPermissionGranted),
                    )
                  : FocusableSettingsTile(
                      title: Text(l.grantUsagePermission),
                      leading: const Icon(Icons.lock_open),
                      onPressed: network.requestPermission,
                    ),
            ),
          if (s.showDataWidgetInStatusBar)
            Consumer<NetworkService>(builder: (context, network, _) =>
              AdbPermissionTile(title: '${l.grantUsagePermission} · ADB', action: 'usage',
                permissionMethod: 'checkUsageStatsPermission', onRefresh: network.refreshPermissionAndUsage)),
          FocusableSettingsTile(
            autofocus: false,
            title: Text(l.dataUsagePeriod),
            trailing: Text(
                  s.dataUsagePeriod == DATA_USAGE_WEEKLY
                      ? l.usageWeekly
                      : s.dataUsagePeriod == DATA_USAGE_MONTHLY
                      ? l.usageMonthly
                      : l.usageDaily,
            ),
            onPressed: () =>
                Navigator.of(context).pushNamed(DataUsagePeriodPage.routeName),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              l.buttonsGroup,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          RoundedSwitchListTile(
            autofocus: false,
            value: s.showSystemSettingsInStatusBar,
            onChanged: s.setShowSystemSettingsInStatusBar,
            title: Text(l.androidTvSettings),
          ),
          RoundedSwitchListTile(
            value: s.showSleepTimerInStatusBar,
            onChanged: s.setShowSleepTimerInStatusBar,
            title: Text(l.sleepTimer),
          ),
          RoundedSwitchListTile(
            value: s.showNightModeInStatusBar,
            onChanged: s.setShowNightModeInStatusBar,
            title: Text(l.nightModeTitle),
          ),
          Padding(padding: const EdgeInsets.all(12), child: Text(l.inputs,
            style: Theme.of(context).textTheme.titleSmall)),
          RoundedSwitchListTile(
            autofocus: false,
            value: s.showInputsWidgetInStatusBar,
            enabled: inputs?.hasInputs == true,
            onChanged: s.setShowInputsWidgetInStatusBar,
            title: Text(l.inputs),
          ),
          if (inputs?.initialized == true && !inputs!.hasInputs)
            SettingsHelp(text: l.inputsUnavailableHint),
          FocusableSettingsTile(title: Text(l.inputsSettings),
            onPressed: () => Navigator.of(context).pushNamed(InputsSettingsPage.routeName)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(l.notifications,
                style: Theme.of(context).textTheme.titleSmall),
          ),
          RoundedSwitchListTile(
            autofocus: false,
            value: s.showNotificationsWidgetInStatusBar,
            onChanged: s.setShowNotificationsWidgetInStatusBar,
            title: Text(l.notificationBell),
          ),
          FocusableSettingsTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: Text(l.notifications),
            onPressed: () => Navigator.of(context)
                .pushNamed(NotificationsSettingsPage.routeName),
          ),
        ],
      ),
    );
  }
}

class StatusBarPanelPage extends StatelessWidget {
  static const routeName = 'status_bar_panel';
  const StatusBarPanelPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.topPanel),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            title: Text(l.appearanceSettings),
            leading: const Icon(Icons.palette_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed('panel_appearance'),
          ),
          FocusableSettingsTile(
            title: Text(l.topPanelObjects),
            leading: const Icon(Icons.widgets_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(StatusBarObjectsPage.routeName),
          ),
          FocusableSettingsTile(
            title: Text(l.panelObjectOrder),
            leading: const Icon(Icons.swap_vert),
            onPressed: () =>
                Navigator.of(context).pushNamed(PanelOrderPage.routeName),
          ),
          FocusableSettingsTile(
            title: Text(l.remotePanel),
            leading: const Icon(Icons.web_asset),
            onPressed: () => Navigator.of(context).push(SettingsRoute(
              settings: const RouteSettings(name: RemotePanelPage.routeName),
              builder: (_) => const RemotePanelPage(),
            )),
          ),
        ],
      ),
    );
  }
}
