import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/network_service.dart';
import '../../providers/settings_service.dart';
import 'adb_permission_tile.dart';
import 'settings_choice_tile.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';

String trafficPeriodLabel(AppLocalizations l, String period) =>
    switch (period) {
      'weekly' => l.usageWeekly,
      'monthly' => l.usageMonthly,
      _ => l.usageDaily,
    };

class TrafficSettingsPage extends StatelessWidget {
  static const routeName = 'traffic_settings';
  const TrafficSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final network = context.watch<NetworkService>();
    final settings = context.watch<SettingsService>();
    return SettingsPageLayout(
      title: Text(l.trafficSettings),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            title: l.dataUsagePeriod,
            value: settings.dataUsagePeriod,
            options: const [DATA_USAGE_DAILY, DATA_USAGE_WEEKLY, DATA_USAGE_MONTHLY],
            label: (value) => trafficPeriodLabel(l, value),
            onChanged: settings.setDataUsagePeriod,
          ),
          if (network.hasUsageStatsPermission)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(l.trafficPermissionGranted),
            )
          else ...[
            FocusableSettingsTile(
              title: Text(l.grantUsagePermission),
              leading: const Icon(Icons.lock_open),
              onPressed: network.requestPermission,
            ),
            AdbPermissionTile(
              title: '${l.grantUsagePermission} · ADB',
              action: 'usage',
              permissionMethod: 'checkUsageStatsPermission',
              onRefresh: network.refreshPermissionAndUsage,
            ),
          ],
        ],
      ),
    );
  }
}
