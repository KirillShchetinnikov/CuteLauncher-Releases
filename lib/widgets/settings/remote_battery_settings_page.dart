import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/remote_battery_service.dart';
import '../../providers/settings_service.dart';
import '../../remote_battery_preferences.dart';
import '../remote_battery_widget.dart';
import '../rounded_switch_list_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';
import 'widget_placement_page.dart';

class RemoteBatterySettingsPage extends StatelessWidget {
  static const routeName = 'remote_battery_settings';
  const RemoteBatterySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.remoteBatteryTitle),
      child: ListView(
        children: [
          WidgetPlacementLink(id: 'remoteBattery', title: l.remoteBatteryTitle),
          const RemoteBatteryDeviceButton(),
          RoundedSwitchListTile(
            title: Text(l.remoteBatteryShowPercent),
            value: settings.showRemoteBatteryPercent,
            onChanged: settings.setShowRemoteBatteryPercent,
          ),
          RoundedSwitchListTile(
            title: Text(l.remoteBatteryColorLowCharge),
            value: settings.remoteBatteryLowColorEnabled,
            onChanged: settings.setRemoteBatteryLowColorEnabled,
          ),
          SettingsValueStepper(
            title: l.remoteBatteryLowThreshold,
            options: List<int>.generate(
              remoteBatteryMaxLowThreshold,
              (index) => index + 1,
            ),
            enabled: settings.remoteBatteryLowColorEnabled,
            value: settings.remoteBatteryLowThreshold,
            label: (value) => '$value%',
            onChanged: (value) =>
                settings.setRemoteBatteryLowThreshold(value as int),
          ),
          const _RemoteBatteryPermission(),
        ],
      ),
    );
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
