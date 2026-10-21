import '../../providers/remote_panel_service.dart';
import '../rounded_switch_list_tile.dart';
import 'appearance_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/network_service.dart';
import '../../providers/notifications_service.dart';
import '../../providers/tv_inputs_service.dart';
import '../../providers/weather_service.dart';
import 'settings_page_layout.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';
import 'panel_order_page.dart';
import 'notifications_settings_page.dart';
import 'inputs_settings_page.dart';
import 'weather_page.dart';

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
    final weather = context.watch<WeatherService>();
    bool available(String id) => switch (id) {
      'traffic' => network.hasUsageStatsPermission,
      'notifications' => notifications.hasPermission,
      'inputs' => inputs.hasInputs,
      'weather' => weather.hasWeather,
      _ => true,
    };
    final labels = {
      'settings': l.settings,
      'systemSettings': l.androidTvSettings,
      'inputs': l.inputs,
      'notifications': l.notificationBell,
      'sleepTimer': l.sleepTimer,
      'nightMode': l.nightModeTitle,
      'network': l.showNetwork,
      'traffic': l.showTraffic,
      'weather': l.weather,
      'date': l.showDate,
      'time': l.showTime,
    };
    return SettingsPageLayout(
      title: Text(l.topPanelObjects),
      child: ListView(
        children: [
          for (final id in [
            'time',
            'date',
            ...panel.order.where((id) => id != 'time' && id != 'date'),
          ])
            RoundedSwitchListTile(
              key: ValueKey(id),
              autofocus: id == 'time',
              title: Text(labels[id]!),
              enabled: available(id),
              value: available(id) && panel.visible(id),
              onChanged: (value) => panel.show(id, value),
            ),
          if (!network.hasUsageStatsPermission)
            FocusableSettingsTile(
              title: Text(l.grantUsagePermission),
              leading: const Icon(Icons.lock_open),
              onPressed: network.requestPermission,
            ),
          if (!notifications.hasPermission)
            FocusableSettingsTile(
              title: Text(l.notificationAccess),
              leading: const Icon(Icons.notifications_outlined),
              onPressed: () => Navigator.of(context).push(
                SettingsRoute(
                  builder: (_) => const NotificationsSettingsPage(),
                ),
              ),
            ),
          if (!inputs.hasInputs)
            FocusableSettingsTile(
              title: Text(l.inputs),
              leading: const Icon(Icons.tv_outlined),
              onPressed: () => Navigator.of(
                context,
              ).push(SettingsRoute(builder: (_) => const InputsSettingsPage())),
            ),
          if (!weather.hasWeather)
            FocusableSettingsTile(
              title: Text(l.weatherSettings),
              leading: const Icon(Icons.cloud_outlined),
              onPressed: () =>
                  Navigator.of(context)
                      .push(SettingsRoute(builder: (_) => const WeatherPage())),
            ),
        ],
      ),
    );
  }
}
