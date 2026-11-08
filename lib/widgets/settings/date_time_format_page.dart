import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
import 'custom_date_format_dialog.dart';
import '../launcher_dialog.dart';
import 'settings_panel_presentation.dart';
import '../../information_formats.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Oscar Rojas
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flauncher/l10n/app_localizations.dart';

// Date format presets
const List<(String format, String example)> dateFormatPresets = [
  (compactDateFormat, 'ПТН 2 Окт'),
  (shortWeekdayDateFormat, 'Вс, 1 Нояб'),
  ('EEEE d', 'Friday 17'),
  ('E d', 'Fri 17'),
  ('dd/MM/y', '17/01/2026'),
  ('MMM d, y', 'Jan 17, 2026'),
  ('d MMMM', '17 January'),
  ('M/d/y', '1/17/2026'),
];

// Morning and afternoon examples distinguish zero padding in 24-hour formats.
const List<(String format, String example)> timeFormatPresets = [
  ('H:mm', '3:45 / 15:45'),
  ('hh:mm', '03:45'),
  ('h:mm a', '3:45 PM'),
  ('hh:mm a', '03:45 PM'),
  ('HH:mm', '03:45 / 15:45'),
];

/// Date settings; the time format is edited together with the shared clock style.
class DateTimeFormatPage extends StatelessWidget {
  static const String routeName = 'date_time_format_panel';
  final bool remotePanel;
  final bool showCalendar;
  const DateTimeFormatPage({
    super.key,
    this.remotePanel = false,
    this.showCalendar = true,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.dateSettings),
      child: ListView(
        children: [
          const DateFormatSettingsTile(),
        ],
      ),
    );
  }
}

class TimeFormatSettingsTile extends StatelessWidget {
  final bool background;
  const TimeFormatSettingsTile({super.key, this.background = false});
  @override
  Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    final formats = service.informationDateTime(background: background);
    return SettingsChoiceTile<String>(
      title: AppLocalizations.of(context)!.informationTimeFormat,
      value: formats.time,
      options: timeFormatPresets.map((v) => v.$1).toList(),
      label: (v) {
        final formatter = DateFormat(v, Localizations.localeOf(context).toString());
        final afternoon = formatter.format(DateTime(2026, 1, 17, 15, 45));
        if (v == 'H:mm' || v == 'HH:mm') {
          return '${formatter.format(DateTime(2026, 1, 17, 3, 45))} / $afternoon';
        }
        return afternoon;
      },
      onChanged: (v) => service.setInformationDateTime(
        InformationDateTimeFormat(date: formats.date, time: v), background: background),
    );
  }
}

class DateFormatSettingsTile extends StatelessWidget {
  final bool background;
  const DateFormatSettingsTile({super.key, this.background = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<SettingsService>();
    final formats = service.informationDateTime(background: background);
    const custom = 'custom';
    final isCustom = !dateFormatPresets.any((v) => v.$1 == formats.date);
    return SettingsChoiceTile<String>(
      title: l.informationDateFormat,
      autofocus: true,
      value: isCustom ? custom : formats.date,
      valueLabel: isCustom ? formatLauncherDate(formats.date,
          DateTime.now(), Localizations.localeOf(context).toString()) : null,
      options: [custom, ...dateFormatPresets.map((v) => v.$1)],
      label: (v) => v == custom ? l.customDateFormat : formatLauncherDate(
        v,
        v == shortWeekdayDateFormat ? DateTime(2026, 11, 1) : DateTime(2026, 10, 2),
        Localizations.localeOf(context).toString(),
      ),
      onChanged: (v) async {
        if (v == custom) {
          final pattern = switch (formats.date) {
            compactDateFormat => 'E d MMM',
            shortWeekdayDateFormat => 'E, d MMM',
            _ => formats.date,
          };
          final result = await SettingsPanelPresentation.runHidden(
            context,
            () => showLauncherDialog<String>(
              context: context,
              parentPanelHidden: true,
              parentPanelWidth: 0,
              builder: (_) => CustomDateFormatDialog(
                pattern: pattern,
              ),
            ),
          );
          if (result != null && context.mounted) {
            await service.setInformationDateTime(InformationDateTimeFormat(date: result, time: formats.time), background: background);
          }
        } else {
          await service.setInformationDateTime(InformationDateTimeFormat(date: v, time: formats.time), background: background);
        }
      },
    );
  }
}
