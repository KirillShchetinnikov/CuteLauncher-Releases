import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import 'settings_help.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

class NetworkSpeedSettingsPage extends StatelessWidget {
  static const routeName = 'network_speed_settings';
  const NetworkSpeedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.networkSpeedSettings),
      child: ListView(
        children: [
          SettingsValueStepper(
            autofocus: true,
            title: l.networkSpeedInterval,
            options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            value: settings.networkSpeedInterval,
            label: (value) => l.autoLaunchSeconds(value as int),
            onChanged: (value) =>
                settings.setNetworkSpeedInterval(value as int),
          ),
          SettingsHelp(title: l.networkSpeedTitle, text: l.networkSpeedHelp),
        ],
      ),
    );
  }
}
