import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/remote_battery_service.dart';
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
import 'settings_information.dart';
import 'settings_read_only_value.dart';

/// Both entry points edit the existing visibility preferences.
class WidgetPlacementPage extends StatelessWidget {
  static const routeName = 'widget_placement';
  final String id;
  final String title;
  const WidgetPlacementPage({super.key, required this.id, required this.title});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final remote = context.watch<RemotePanelService>();
    final storageIndicator = id == 'usb' || id == 'nas';
    final connected = storageIndicator
        ? context.select<StorageStatusService?, bool?>(
            (s) => id == 'usb' ? s?.state.usb : s?.state.nas,
          )
        : null;
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
      'remoteBattery' => (
        settings.showRemoteBatteryInStatusBar,
        settings.setShowRemoteBatteryInStatusBar,
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
          if (id == 'network') const _NetworkStatus(),
          if (storageIndicator)
            Text(connected == null ? '—' : connected ? l.inputConnected : l.inputDisconnected),
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
          if (id == 'remoteBattery') const _RemoteBatteryPermission(),
        ],
      ),
    );
    return storageIndicator
        ? StorageStatusWatch(
            visible: ModalRoute.isCurrentOf(context) != false,
            child: page,
          )
        : page;
  }
}

class _RemoteBatteryPermission extends StatefulWidget {
  const _RemoteBatteryPermission();

  @override
  State<_RemoteBatteryPermission> createState() =>
      _RemoteBatteryPermissionState();
}

class _RemoteBatteryPermissionState extends State<_RemoteBatteryPermission> {
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    context.read<RemoteBatteryService?>()?.refreshBluetoothPermission();
  }

  Future<void> _request(RemoteBatteryService service) async {
    setState(() => _requesting = true);
    try {
      await service.requestBluetoothPermission();
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = context.read<RemoteBatteryService?>();
    final permission = context.select<RemoteBatteryService?, bool?>(
      (s) => s?.bluetoothPermission,
    );
    if (service == null || permission == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    return FocusableSettingsTile(
      title: Text(l.remoteBatteryBluetoothPermission),
      leading: const Icon(Icons.bluetooth),
      trailing: Text(permission ? l.granted : l.requestPermission),
      busy: _requesting,
      onPressed: () => _request(service),
    );
  }
}

class _NetworkStatus extends StatelessWidget {
  const _NetworkStatus();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final state = context.select<NetworkService?, (NetworkType, bool)?>(
      (network) => network == null ? null : (network.networkType, network.hasInternetAccess),
    );
    final type = state?.$1;
    final connection = switch (type) {
      NetworkType.Cellular => l.networkMobile,
      NetworkType.Wifi => 'Wi-Fi',
      NetworkType.Vpn => 'VPN',
      NetworkType.Wired => 'Ethernet',
      NetworkType.Unknown => state?.$2 == true ? l.networkUnavailable : l.networkDisconnected,
      NetworkType.Pending || null => '—',
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsReadOnlyValue(label: l.networkConnection, value: connection, wrapLines: true),
        if (state != null && type != NetworkType.Pending)
          SettingsMessage(text: state.$2 ? l.networkConnected : l.networkOffline),
      ],
    );
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
        settings: const RouteSettings(name: WidgetPlacementPage.routeName),
        builder: (_) => WidgetPlacementPage(id: id, title: title),
      ),
    ),
  );
}
