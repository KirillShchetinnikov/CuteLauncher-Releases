import 'settings_help.dart';
import 'settings_value_stepper.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/apps_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/watch_next_service.dart';
import 'settings_page_layout.dart';

class WatchNextLimitsPage extends StatelessWidget {
  static const routeName = 'watch_next_limits';
  const WatchNextLimitsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final apps = context.watch<AppsService>().applications;
    final names = {for (final app in apps) app.packageName: app.name};
    final packages = {
      ...names.keys,
      ...settings.watchNextAppLimits.keys,
      ...context.watch<WatchNextService>().programs.map((p) => p.packageName),
    }.toList()..sort((a, b) => (names[a] ?? a).compareTo(names[b] ?? b));
    return SettingsPageLayout(
      title: Text(l.watchNextAppLimits),
      child: ListView(
        children: [
          SettingsHelp(text: l.watchNextAppLimitsHint),
          for (final package in packages)
            SettingsValueStepper(
              autofocus: package == packages.first,
              title: names[package] ?? package,
              options: const [0, 1, 3, 5, 10, 15, 20, 30, 50],
              value: settings.watchNextAppLimits[package] ?? 0,
              label: (v) => v == 0 ? l.unlimitedItems : l.itemsCount(v as int),
              onChanged: (v) =>
                  settings.setWatchNextAppLimit(package, v as int),
            ),
        ],
      ),
    );
  }
}
