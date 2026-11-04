import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

class VolumeWidgetSettingsPage extends StatelessWidget {
  static const routeName = 'volume_widget_settings';
  const VolumeWidgetSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.volumeWidgetSettings),
      child: ListView(
        children: [
          SettingsValueStepper(
            autofocus: true,
            title: l.volumeUpdateInterval,
            options: const [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
            value: settings.volumeUpdateInterval,
            label: (value) => l.autoLaunchSeconds(value as int),
            onChanged: (value) =>
                settings.setVolumeUpdateInterval(value as int),
          ),
        ],
      ),
    );
  }
}
