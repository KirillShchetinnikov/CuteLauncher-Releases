import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/network_service.dart';
import '../../providers/settings_service.dart';
import 'adb_permission_tile.dart';
import 'data_usage_period_page.dart';
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
          FocusableSettingsTile(
            title: Text(l.dataUsagePeriod),
            trailing: Text(trafficPeriodLabel(l, settings.dataUsagePeriod)),
            onPressed: () =>
                Navigator.pushNamed(context, DataUsagePeriodPage.routeName),
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
