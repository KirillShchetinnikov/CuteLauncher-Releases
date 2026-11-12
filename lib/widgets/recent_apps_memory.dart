import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../l10n/app_localizations.dart';

String recentMemoryBytes(BuildContext context, int bytes) {
  final l = AppLocalizations.of(context)!;
  final gib = bytes >= 1024 * 1024 * 1024;
  final number = NumberFormat.decimalPattern(l.localeName)
    ..minimumFractionDigits = gib ? 2 : 0
    ..maximumFractionDigits = gib ? 2 : 0;
  final value = number.format(bytes / (gib ? 1073741824 : 1048576));
  return gib ? l.recentRamGiB(value) : l.recentRamMiB(value);
}

class RecentAppsMemory extends StatelessWidget {
  final int? total, available;
  final bool loading;
  const RecentAppsMemory({
    super.key,
    required this.total,
    required this.available,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final total = this.total, available = this.available;
    final valid =
        total != null &&
        available != null &&
        total > 0 &&
        available >= 0 &&
        available <= total;
    final fraction = valid ? (total - available) / total : null;
    final value = valid
        ? l.recentRamUsed(
            recentMemoryBytes(context, total - available),
            recentMemoryBytes(context, total),
            NumberFormat.decimalPattern(l.localeName)
                .format((fraction! * 100).round()),
          )
        : loading
        ? l.loading
        : l.recentRamUnavailable;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 4,
            children: [
              Text(
                l.recentRamTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(value),
            ],
          ),
          if (fraction != null) ...[
            const SizedBox(height: 6),
            ExcludeSemantics(child: LinearProgressIndicator(value: fraction)),
            const SizedBox(height: 4),
            Text(
              l.recentRamAvailable(recentMemoryBytes(context, available!)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
