import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

class SystemWidgetSettingsPage extends StatelessWidget {
  static const routeName = 'system_widget_settings';
  const SystemWidgetSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
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
