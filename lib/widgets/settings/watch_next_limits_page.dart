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
    final settings = context.read<SettingsService>();
    final limits = context.select<SettingsService, Map<String, int>>(
      (service) => service.watchNextAppLimits,
    );
    final names = context.select<AppsService, Map<String, String>>(
      (service) => {for (final app in service.applications) app.packageName: app.name},
    );
    final sources = context.select<WatchNextService, Set<String>>(
      (service) => service.programs.map((program) => program.packageName).toSet(),
    );
    final priority = {
      ...limits.keys,
      ...sources,
    };
    final packages =
        {
          ...names.keys,
          ...limits.keys,
          ...sources,
        }.toList()..sort((a, b) {
          final group = (priority.contains(a) ? 0 : 1).compareTo(
            priority.contains(b) ? 0 : 1,
          );
          return group != 0
              ? group
              : (names[a] ?? a).toLowerCase().compareTo(
                  (names[b] ?? b).toLowerCase(),
                );
        });
    final indices = {
      for (var i = 0; i < packages.length; i++) packages[i]: i + 1,
    };
    return SettingsPageLayout(
      title: Text(l.watchNextAppLimits),
      child: ListView.builder(
        itemCount: packages.length + 1,
        findChildIndexCallback: (key) =>
            indices[(key as ValueKey<String>).value],
        itemBuilder: (context, index) {
          if (index == 0) {
            return SettingsHelp(
              title: l.watchNextAppLimits,
              text: l.watchNextAppLimitsHint,
            );
          }
          final package = packages[index - 1];
          return SettingsValueStepper(
            key: ValueKey(package),
            autofocus: package == packages.first,
            title: names[package] ?? package,
            options: const [0, 1, 3, 5, 10, 15, 20, 30, 50],
            value: limits[package] ?? 0,
            label: (v) => v == 0 ? l.unlimitedItems : l.itemsCount(v as int),
            onChanged: (v) => settings.setWatchNextAppLimit(package, v as int),
          );
        },
      ),
    );
  }
}
