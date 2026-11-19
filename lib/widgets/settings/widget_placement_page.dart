import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/storage_status_service.dart';
import '../../providers/tv_inputs_service.dart';
import '../../providers/network_service.dart';
import '../../providers/notifications_service.dart';
import '../rounded_switch_list_tile.dart';
import '../storage_status_watch.dart';
import 'settings_page_layout.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';

/// Both entry points edit the existing visibility preferences.
class WidgetPlacementPage extends StatelessWidget {
  final String id;
  final String title;
  const WidgetPlacementPage({super.key, required this.id, required this.title});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final remote = context.watch<RemotePanelService>();
    final available =
        id != 'nas' ||
        context.watch<StorageStatusService?>()?.state.nasSupported == true;
    final (value, change) = switch (id) {
      'network' => (
        settings.showNetworkIndicatorInStatusBar,
        settings.setShowNetworkIndicatorInStatusBar,
      ),
      'usb' => (settings.showUsbInStatusBar, settings.setShowUsbInStatusBar),
      'nas' => (settings.showNasInStatusBar, settings.setShowNasInStatusBar),
      'vpn' => (settings.showVpnInStatusBar, settings.setShowVpnInStatusBar),
      'networkSpeed' => (
        settings.showNetworkSpeedInStatusBar,
        settings.setShowNetworkSpeedInStatusBar,
      ),
      'traffic' => (
        settings.showDataWidgetInStatusBar,
        settings.setShowDataWidgetInStatusBar,
      ),
      'audio' => (
        settings.showVolumeInStatusBar,
        settings.setShowVolumeInStatusBar,
      ),
      'inputs' => (
        settings.showInputsWidgetInStatusBar,
        settings.setShowInputsWidgetInStatusBar,
      ),
      'system' => (
        settings.showSystemInStatusBar,
        settings.setShowSystemInStatusBar,
      ),
      'notifications' => (
        settings.showNotificationsWidgetInStatusBar,
        settings.setShowNotificationsWidgetInStatusBar,
      ),
      'sleepTimer' => (
        settings.showSleepTimerInStatusBar,
        settings.setShowSleepTimerInStatusBar,
      ),
      _ => throw ArgumentError.value(id, 'id'),
    };
    final page = SettingsPageLayout(
      title: Text(title),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            title: Text(l.topPanel),
            value: available && value,
            enabled:
                available &&
                (id != 'inputs' ||
                    context.watch<TvInputsService?>()?.hasInputs == true),
            onChanged: change,
          ),
          RoundedSwitchListTile(
            title: Text(l.remotePanel),
            value: available && remote.visible(id),
            enabled:
                available &&
                switch (id) {
                  'inputs' =>
                    context.watch<TvInputsService?>()?.hasInputs == true,
                  'traffic' =>
                    context.watch<NetworkService?>()?.hasUsageStatsPermission ==
                        true,
                  'notifications' =>
                    context.watch<NotificationsService?>()?.hasPermission ==
                        true,
                  _ => true,
                },
            onChanged: (value) => remote.show(id, value),
          ),
        ],
      ),
    );
    return id == 'nas'
        ? StorageStatusWatch(
            visible: ModalRoute.isCurrentOf(context) != false,
            child: page,
          )
        : page;
  }
}

class WidgetPlacementLink extends StatelessWidget {
  final String id;
  final String title;
  const WidgetPlacementLink({super.key, required this.id, required this.title});
  @override
  Widget build(BuildContext context) => FocusableSettingsTile(
    title: Text(AppLocalizations.of(context)!.informationObjectPlacement),
    leading: const Icon(Icons.dashboard_outlined),
    onPressed: () => Navigator.of(context).push(
      SettingsRoute(
        builder: (_) => WidgetPlacementPage(id: id, title: title),
      ),
    ),
  );
}

class IndicatorSettingsPage extends StatelessWidget {
  final String id;
  final String title;
  const IndicatorSettingsPage({
    super.key,
    required this.id,
    required this.title,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final connected = switch (id) {
      'network' => context.watch<NetworkService?>()?.hasInternetAccess,
      'usb' => context.select<StorageStatusService?, bool?>(
        (s) => s?.state.usb,
      ),
      _ => context.select<StorageStatusService?, bool?>((s) => s?.state.nas),
    };
    final page = SettingsPageLayout(
      title: Text(title),
      child: ListView(
        children: [
          WidgetPlacementLink(id: id, title: title),
          Text(
            connected == null
                ? '—'
                : connected
                ? l.inputConnected
                : l.inputDisconnected,
          ),
        ],
      ),
    );
    return id != 'network'
        ? StorageStatusWatch(
            visible: ModalRoute.isCurrentOf(context) != false,
            child: page,
          )
        : page;
  }
}
