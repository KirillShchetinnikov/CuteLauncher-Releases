import 'top_panel_item.dart';

import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DailyDataUsageWidget extends StatelessWidget {
  const DailyDataUsageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkService, SettingsService>(
      builder: (context, networkService, settingsService, _) {
        if (!networkService.hasUsageStatsPermission) {
          return const SizedBox.shrink();
        }

        final period = settingsService.dataUsagePeriod;
        String label;
        switch (period) {
          case 'weekly':
            label = AppLocalizations.of(context)!.weeklyUsage;
            break;
          case 'monthly':
            label = AppLocalizations.of(context)!.monthlyUsage;
            break;
          case 'daily':
          default:
            label = AppLocalizations.of(context)!.dailyUsage;
            break;
        }

        return FutureBuilder<int>(
          key: ValueKey(period),
          future: networkService.getDataUsageForPeriod(period),
          builder: (context, snapshot) {
            final usage = snapshot.hasError
                ? null
                : snapshot.data ??
                    (period == 'daily' && snapshot.connectionState == ConnectionState.waiting
                        ? networkService.dailyDataUsage
                        : null);
            final usageString = usage == null || usage < 0 ? '—' : _formatBytes(usage);

            return RichText(
              text: TextSpan(
                style: topPanelAppearance(context).panelTextStyleFor(Localizations.localeOf(context)),
                children: [
                  TextSpan(text: label),
                  TextSpan(text: usageString),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = 0;
    double d = bytes.toDouble();
    while (d >= 1024 && i < suffixes.length - 1) {
      d /= 1024;
      i++;
    }
    return "${d.toStringAsFixed(2)} ${suffixes[i]}";
  }
}
