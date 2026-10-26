import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../providers/sleep_timer_service.dart';
import '../sleep_timer_configuration.dart';

String sleepTimerPresetLabel(AppLocalizations l, int seconds) {
  if (seconds == 30) return l.sleepTimerThirtySeconds;
  if (seconds == 5400) return l.sleepTimerHourAndHalf;
  if (seconds % 3600 == 0) return l.sleepTimerHours(seconds ~/ 3600);
  if (seconds % 60 == 0) return l.sleepTimerMinutes(seconds ~/ 60);
  return formatTimerDuration(seconds);
}

String sleepTimerActiveLabel(
  BuildContext context,
  SleepTimerService timer,
  SleepTimerConfiguration configuration,
) {
  final remaining = formatTimerDuration(
    timer.remainingSeconds,
    showSeconds: configuration.showSeconds,
  );
  final end = timer.endTime;
  final material = MaterialLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final use24 = MediaQuery.alwaysUse24HourFormatOf(context);
  final formatter = configuration.showSeconds
      ? (use24 ? DateFormat.Hms(locale) : DateFormat.jms(locale))
      : (use24 ? DateFormat.Hm(locale) : DateFormat.jm(locale));
  var time = formatter.format(end);
  final now = DateTime.now();
  if (!DateUtils.isSameDay(end, now)) {
    time = '${material.formatShortDate(end)} $time';
  }
  return switch (configuration.display) {
    'end' => time,
    'both' => '$remaining · $time',
    _ => remaining,
  };
}
