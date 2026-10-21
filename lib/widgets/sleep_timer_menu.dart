import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../theme/launcher_style.dart';
import '../providers/sleep_timer_service.dart';
import 'notice_style.dart';
import 'launcher_dialog.dart';
import 'settings/focusable_settings_tile.dart';

class SleepTimerMenu extends StatelessWidget {
  final Rect anchor;
  const SleepTimerMenu({super.key, required this.anchor});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final timer = context.watch<SleepTimerService>();
    return LayoutBuilder(
      builder: (context, constraints) {
        final margin = math.max(12.0, LauncherStyle.of(context).panelMargin);
        final width = math.min(300.0, constraints.maxWidth - margin * 2);
        final top = math.min(anchor.bottom + 8, constraints.maxHeight - 100);
        return Stack(
          children: [
            const Positioned.fill(child: LauncherPanelBackdrop()),
            Positioned(
              left: (anchor.center.dx - width / 2).clamp(
                margin,
                math.max(margin, constraints.maxWidth - width - margin),
              ),
              top: top,
              width: width,
              child: NoticeSurface(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight - top - margin,
                  ),
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(l.sleepTimer),
                          ),
                          if (timer.busy)
                            const Padding(
                              padding: EdgeInsets.all(8),
                              child: LinearProgressIndicator(),
                            ),
                          if (timer.error.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                timer.error == 'exact'
                                    ? l.sleepTimerExactRequired
                                    : timer.error == 'access'
                                    ? l.sleepTimerAccessRequired
                                    : l.sleepTimerFailed,
                              ),
                            ),
                          if (!timer.exactAllowed || timer.error == 'exact')
                            FocusableSettingsTile(
                              title: Text(l.sleepTimerAllowExact),
                              onPressed: () async {
                                if (!await timer.requestExact() &&
                                    context.mounted) {
                                  ScaffoldMessenger.maybeOf(
                                    context,
                                  )?.showSnackBar(
                                    SnackBar(
                                      content: Text(l.sleepTimerExactRequired),
                                    ),
                                  );
                                }
                              },
                            ),
                          for (final duration in [
                            Duration.zero,
                            const Duration(seconds: 30),
                            ...SleepTimerService.durations.map(
                              (minutes) => Duration(minutes: minutes),
                            ),
                          ])
                            FocusableSettingsTile(
                              key: ValueKey(
                                duration.inSeconds == 30
                                    ? 'sleep_timer_30_seconds'
                                    : 'sleep_timer_${duration.inMinutes}',
                              ),
                              autofocus: duration == Duration.zero,
                              title: Text(
                                duration == Duration.zero
                                    ? l.cancel
                                    : duration.inSeconds == 30
                                    ? l.sleepTimerThirtySeconds
                                    : duration.inMinutes < 60
                                    ? l.sleepTimerMinutes(duration.inMinutes)
                                    : duration.inMinutes == 90
                                    ? l.sleepTimerHourAndHalf
                                    : l.sleepTimerHours(duration.inHours),
                              ),
                              onPressed: () async {
                                final success = duration.inSeconds == 30
                                    ? await timer.selectTestTimer()
                                    : await timer.select(duration.inMinutes);
                                if (success && context.mounted) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
