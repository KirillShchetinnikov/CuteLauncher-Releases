import 'settings_option_tile.dart';
import 'settings_page_layout.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DataUsagePeriodPage extends StatelessWidget {
  static const String routeName = "data_usage_period_panel";

  const DataUsagePeriodPage({super.key});

  @override
  Widget build(BuildContext context) {
    AppLocalizations localizations = AppLocalizations.of(context)!;
    return Consumer<SettingsService>(
        builder: (context, service, _) {
          return SettingsPageLayout(
            title: Text(
              localizations.dataUsagePeriod,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            child: ListView(
              children: [
                _radioTile(
                  context,
                  service,
                  localizations.usageDaily,
                  DATA_USAGE_DAILY,
                ),
                _radioTile(
                  context,
                  service,
                  localizations.usageWeekly,
                  DATA_USAGE_WEEKLY,
                ),
                _radioTile(
                  context,
                  service,
                  localizations.usageMonthly,
                  DATA_USAGE_MONTHLY,
                ),
              ],
            ),
          );
        }
    );
  }

  Widget _radioTile(BuildContext context, SettingsService service, String label, String value) {
    final isSelected = service.dataUsagePeriod == value;
    return SettingsOptionTile(
      autofocus: isSelected,
      selected: isSelected,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      onPressed: () => service.setDataUsagePeriod(value),
    );
  }
}
