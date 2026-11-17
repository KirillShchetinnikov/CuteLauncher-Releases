import 'top_panel_item.dart';

import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class DailyDataUsageWidget extends StatefulWidget {
  final bool showUnavailable;
  final bool visible;
  const DailyDataUsageWidget({super.key, this.showUnavailable = false, this.visible = true});

  @override
  State<DailyDataUsageWidget> createState() => _DailyDataUsageWidgetState();
}

class _DailyDataUsageWidgetState extends State<DailyDataUsageWidget> {
  late final NetworkService _network;
  String _period = 'daily';
  (String, bool, bool, int)? _snapshotKey;
  Future<int>? _snapshot;
  @override
  void initState() {
    super.initState();
    _network = context.read<NetworkService>()..setTrafficVisible(this, widget.visible, period: _period);
  }
  @override
  void didUpdateWidget(DailyDataUsageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _network.setTrafficVisible(this, widget.visible, period: _period);
  }
  @override
  void dispose() {
    _network.setTrafficVisible(this, false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<NetworkService, SettingsService>(
      builder: (context, networkService, settingsService, _) {
        final allowed = networkService.hasUsageStatsPermission;
        if (!allowed && !widget.showUnavailable) {
          return const SizedBox.shrink();
        }

        final period = settingsService.dataUsagePeriod;
        if (_period != period) {
          _period = period;
          _network.setTrafficVisible(this, widget.visible, period: period);
        }
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

        final snapshotKey = (period, allowed, widget.visible, networkService.trafficRevision);
        if (_snapshotKey != snapshotKey) {
          _snapshotKey = snapshotKey;
          _snapshot = allowed && widget.visible ? networkService.getDataUsageForPeriod(period) : null;
        }
        return FutureBuilder<int>(
          key: ValueKey(period),
          future: _snapshot,
          builder: (context, snapshot) {
            final usage = !allowed || snapshot.hasError
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
