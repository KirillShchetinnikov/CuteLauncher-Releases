import '../../providers/appearance_service.dart';
import '../../providers/remote_panel_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
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
  ('EEEE d', 'Friday 17'),
  ('E d', 'Fri 17'),
  ('dd/MM/y', '17/01/2026'),
  ('MMM d, y', 'Jan 17, 2026'),
  ('d MMMM', '17 January'),
  ('M/d/y', '1/17/2026'),
];

// Time format presets (using 3:45 PM / 15:45 for clear 12h/24h distinction)
const List<(String format, String example)> timeFormatPresets = [
  ('H:mm', '3:45'),
  ('hh:mm', '03:45'),
  ('h:mm a', '3:45 PM'),
  ('hh:mm a', '03:45 PM'),
  ('HH:mm', '15:45'),
];

/// Date settings; the time format is edited together with the shared clock style.
class DateTimeFormatPage extends StatelessWidget {
  static const String routeName = 'date_time_format_panel';
  final bool remotePanel;
  const DateTimeFormatPage({super.key, this.remotePanel = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<SettingsService>();
    final appearance = context.watch<AppearanceService>();
    final panel = remotePanel ? context.watch<RemotePanelService>() : null;
    return SettingsPageLayout(
      title: Text(l.dateSettings),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            title: l.date,
            autofocus: true,
            value: service.dateFormat,
            options: dateFormatPresets.map((v) => v.$1).toList(),
            label: (v) => formatLauncherDate(
              v,
              v == compactDateFormat
                  ? DateTime(2026, 10, 2)
                  : DateTime(2026, 1, 17),
              Localizations.localeOf(context).toString(),
            ),
            onChanged: (v) => service.setDateTimeFormat(v, service.timeFormat),
          ),
          RoundedSwitchListTile(
            title: Text(l.dateCalendarEnabled),
            value: panel?.dateCalendar ?? appearance.appearance.dateCalendar,
            onChanged: (value) => panel != null
                ? panel.set('dateCalendar', value)
                : appearance.set('panelDateCalendar', value),
          ),
        ],
      ),
    );
  }
}

class TimeFormatSettingsTile extends StatelessWidget {
  const TimeFormatSettingsTile({super.key});
  @override
  Widget build(BuildContext context) {
    final service = context.watch<SettingsService>();
    return SettingsChoiceTile<String>(
      title: AppLocalizations.of(context)!.time,
      value: service.timeFormat,
      options: timeFormatPresets.map((v) => v.$1).toList(),
      label: (v) => DateFormat(
        v,
        Localizations.localeOf(context).toString(),
      ).format(DateTime(2026, 1, 17, 15, 45)),
      onChanged: (v) => service.setDateTimeFormat(service.dateFormat, v),
    );
  }
}
