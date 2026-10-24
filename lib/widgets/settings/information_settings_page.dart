import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/weather_service.dart';
import '../rounded_switch_list_tile.dart';
import 'date_time_format_page.dart';
import 'focusable_settings_tile.dart';
import 'panel_clock_style_page.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'weather_page.dart';

/// The same group in both panels; visibility and calendar remain panel-specific.
class InformationObjectsSection extends StatelessWidget {
  final bool remotePanel;
  const InformationObjectsSection({super.key, this.remotePanel = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final remote = remotePanel ? context.watch<RemotePanelService>() : null;
    final weatherAvailable =
        !remotePanel || context.watch<WeatherService?>()?.hasWeather == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            l.informationGroup,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final id in ['time', 'date', 'weather'])
          RoundedSwitchListTile(
            key: ValueKey(id),
            enabled: id != 'weather' || weatherAvailable,
            title: Text(switch (id) {
              'time' => l.showTime,
              'date' => l.showDate,
              _ => l.showWeather,
            }),
            value: remote != null
                ? (id != 'weather' || weatherAvailable) && remote.visible(id)
                : switch (id) {
                    'time' => settings.showTimeInStatusBar,
                    'date' => settings.showDateInStatusBar,
                    _ => settings.showWeatherInStatusBar,
                  },
            onChanged: (value) {
              if (remote != null) {
                remote.show(id, value);
              } else {
                switch (id) {
                  case 'time':
                    settings.setShowTimeInStatusBar(value);
                  case 'date':
                    settings.setShowDateInStatusBar(value);
                  default:
                    settings.setShowWeatherInStatusBar(value);
                }
              }
            },
          ),
        FocusableSettingsTile(
          title: Text(l.informationSettings),
          leading: const Icon(Icons.tune),
          onPressed: () => Navigator.of(context).push(
            SettingsRoute(
              settings: const RouteSettings(
                name: InformationSettingsPage.routeName,
              ),
              builder: (_) => InformationSettingsPage(remotePanel: remotePanel),
            ),
          ),
        ),
      ],
    );
  }
}

class InformationSettingsPage extends StatelessWidget {
  static const routeName = 'information_settings';
  final bool remotePanel;
  const InformationSettingsPage({super.key, this.remotePanel = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    final panel = remotePanel ? context.watch<RemotePanelService>() : null;
    final combined = appearance.combinedInformation;
    Widget page(String title, Widget child, String name) =>
        FocusableSettingsTile(
          title: Text(title),
          leading: const Icon(Icons.tune),
          onPressed: () => Navigator.of(context).push(
            SettingsRoute(
              settings: RouteSettings(name: name),
              builder: (_) => child,
            ),
          ),
        );
    return SettingsPageLayout(
      title: Text(l.informationGroup),
      child: ListView(
        children: [
          RoundedSwitchListTile(
            autofocus: true,
            title: Text(l.combinedInformation),
            value: combined,
            onChanged: (v) => service.set('panelCombinedInformation', v),
          ),
          if (combined)
            page(
              l.informationAppearance,
              PanelClockStylePage(combined: true, remotePanel: remotePanel),
              PanelClockStylePage.routeName,
            )
          else ...[
            page(
              l.panelClockStyle,
              const PanelClockStylePage(),
              PanelClockStylePage.routeName,
            ),
            page(
              l.dateSettings,
              DateTimeFormatPage(remotePanel: remotePanel, showCalendar: false),
              DateTimeFormatPage.routeName,
            ),
          ],
          page(l.weatherSettings, const WeatherPage(), WeatherPage.routeName),
          if (combined)
            RoundedSwitchListTile(
              title: Text(l.clockAnimate),
              value: appearance.informationStyle.animate,
              onChanged: (v) => service.set('panelInformationStyle', {
                ...appearance.informationStyle.values,
                'animate': v,
              }),
            ),
          RoundedSwitchListTile(
            title: Text(l.dateCalendarEnabled),
            value: panel?.dateCalendar ?? appearance.dateCalendar,
            onChanged: (v) => panel != null
                ? panel.set('dateCalendar', v)
                : service.set('panelDateCalendar', v),
          ),
        ],
      ),
    );
  }
}
