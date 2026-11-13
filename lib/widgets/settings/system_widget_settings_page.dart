import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../../providers/system_status_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

class SystemWidgetSettingsPage extends StatefulWidget {
  static const routeName = 'system_widget_settings';
  const SystemWidgetSettingsPage({super.key});

  @override
  State<SystemWidgetSettingsPage> createState() =>
      _SystemWidgetSettingsPageState();
}

class _SystemWidgetSettingsPageState extends State<SystemWidgetSettingsPage> {
  SystemStatusService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<SystemStatusService?>();
    if (_service != service) {
      _service?.setVisible(this, false);
      _service = service;
    }
    final visible = TickerMode.valuesOf(context).enabled;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _service == service) service?.setVisible(this, visible);
    });
  }

  @override
  void dispose() {
    _service?.setVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final temperatureAvailable = context.select<SystemStatusService?, bool>(
      (service) => service?.state.temperature != null,
    );
    return SettingsPageLayout(
      title: Text(l.systemWidgetSettings),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            autofocus: true,
            title: Text(l.systemShowCpu),
            value: settings.systemShowCpu,
            onChanged: settings.setSystemShowCpu,
          ),
          RoundedSwitchListTile(
            title: Text(l.systemShowTemperature),
            enabled: temperatureAvailable,
            value: temperatureAvailable && settings.systemShowTemperature,
            onChanged: settings.setSystemShowTemperature,
          ),
          RoundedSwitchListTile(
            title: Text(l.systemShowRam),
            value: settings.systemShowRam,
            onChanged: settings.setSystemShowRam,
          ),
          SettingsValueStepper(
            title: l.systemUpdateInterval,
            options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            value: settings.systemUpdateInterval,
            label: (value) => l.autoLaunchSeconds(value as int),
            onChanged: (value) => settings.setSystemUpdateInterval(value as int),
          ),
          SettingsHelp(title: l.systemWidgetSettings, text: l.systemWidgetHelp),
        ],
      ),
    );
  }
}
