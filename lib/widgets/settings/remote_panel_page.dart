import 'settings_help.dart';
import 'volume_widget_settings_page.dart';
import '../../providers/remote_panel_service.dart';
import '../rounded_switch_list_tile.dart';
import '../storage_status_watch.dart';
import 'appearance_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/network_service.dart';
import '../../providers/notifications_service.dart';
import '../../providers/storage_status_service.dart';
import '../../providers/tv_inputs_service.dart';
import 'settings_page_layout.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';
import 'panel_order_page.dart';
import 'remote_buttons_page.dart';

class RemotePanelPage extends StatelessWidget {
  static const routeName = 'remote_panel_settings';
  const RemotePanelPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.remotePanel),
      child: ListView(
        children: [
          FocusableSettingsTile(
            autofocus: true,
            title: Text(l.appearanceSettings),
            leading: const Icon(Icons.palette_outlined),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                settings: const RouteSettings(
                  name: AppearancePage.remotePanelRouteName,
                ),
                builder: (_) =>
                    const AppearancePage(section: 'panel', remotePanel: true),
              ),
            ),
          ),
          FocusableSettingsTile(
            title: Text(l.topPanelObjects),
            leading: const Icon(Icons.widgets_outlined),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                settings: const RouteSettings(
                  name: RemotePanelObjectsPage.routeName,
                ),
                builder: (_) => const RemotePanelObjectsPage(),
              ),
            ),
          ),
          FocusableSettingsTile(
            title: Text(l.panelObjectOrder),
            leading: const Icon(Icons.swap_vert),
            onPressed: () => Navigator.of(context).push(
              SettingsRoute(
                builder: (_) => const PanelOrderPage(remotePanel: true),
              ),
            ),
          ),
          SettingsHelp(title: l.remotePanel, text: l.remotePanelDescription),
          FocusableSettingsTile(
            title: Text(l.remoteButtonsTitle),
            leading: const Icon(Icons.settings_remote_outlined),
            onPressed: () =>
                Navigator.of(context).pushNamed(RemoteButtonsPage.routeName),
          ),
        ],
      ),
    );
  }
}

class RemotePanelObjectsPage extends StatelessWidget {
  static const routeName = 'remote_panel_objects';
  const RemotePanelObjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final panel = context.watch<RemotePanelService>();
    final network = context.watch<NetworkService>();
    final notifications = context.watch<NotificationsService>();
    final inputs = context.watch<TvInputsService>();
    final nasSupported = context.select<StorageStatusService?, bool>(
      (storage) => storage?.state.nasSupported == true,
    );
    bool available(String id) => switch (id) {
      'traffic' => network.hasUsageStatsPermission,
      'notifications' => notifications.hasPermission,
      'inputs' => inputs.hasInputs,
      'nas' => nasSupported,
      _ => true,
    };
    final labels = {
      'settings': l.settings,
      'systemSettings': l.androidTvSettings,
      'inputs': l.inputs,
      'notifications': l.notificationBell,
      'sleepTimer': l.sleepTimer,
      'nightMode': l.nightModeTitle,
      'nas': l.networkStorageTitle,
      'usb': l.usbStorageTitle,
      'network': l.showNetwork,
      'vpn': l.vpnTitle,
      'traffic': l.showTraffic,
      'networkSpeed': l.networkSpeedTitle,
      'weather': l.weather,
      'system': l.system,
      'audio': l.showVolume,
      'date': l.showDate,
      'time': l.showTime,
    };
    final page = SettingsPageLayout(
      title: Text(l.topPanelObjects),
      child: ListView(
        children: [
          for (final id in panel.order.where((id) => !const ['network', 'vpn', 'networkSpeed', 'traffic'].contains(id))) ...[
            RoundedSwitchListTile(
              key: ValueKey(id),
              title: Text(labels[id]!),
              enabled: available(id),
              value: available(id) && panel.visible(id),
              onChanged: (value) => panel.show(id, value),
            ),
            if (id == 'audio')
              FocusableSettingsTile(
                title: Text(l.volumeWidgetSettings),
                leading: const Icon(Icons.volume_up_outlined),
                onPressed: () => Navigator.of(context).pushNamed(VolumeWidgetSettingsPage.routeName),
              ),
          ],
          Padding(padding: const EdgeInsets.all(12), child: Text(l.networkSummary,
            style: Theme.of(context).textTheme.titleSmall)),
          for (final id in const ['network', 'vpn', 'networkSpeed', 'traffic'])
            RoundedSwitchListTile(key: ValueKey(id), title: Text(labels[id]!),
              enabled: available(id), value: available(id) && panel.visible(id),
              onChanged: (value) => panel.show(id, value)),
        ],
      ),
    );
    return StorageStatusWatch(
      visible: ModalRoute.isCurrentOf(context) != false,
      child: page,
    );
  }
}
