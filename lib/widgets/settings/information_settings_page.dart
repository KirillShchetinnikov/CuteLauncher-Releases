import '../../information_placement.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'date_time_format_page.dart';
import 'background_information_order_page.dart';
import 'focusable_settings_tile.dart';
import 'panel_clock_style_page.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'weather_page.dart';
import 'settings_choice_tile.dart';
import 'settings_value_stepper.dart';
import 'settings_help.dart';

/// Object visibility is panel-specific; block settings are shared.
class InformationObjectsSection extends StatelessWidget {
  final bool remotePanel;
  const InformationObjectsSection({super.key, this.remotePanel = false});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    if (remotePanel) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InformationVisibility(remotePanel: true),
          InformationGroupingControl(remotePanel: true),
        ],
      );
    }
    final placement = InformationPlacement(
      context.watch<AppearanceService>().appearance,
      context.watch<SettingsService>(),
    );
    final summary = [
      for (final id in InformationPlacement.ids)
        '${switch (id) {
          'time' => l.informationTime,
          'date' => l.informationDate,
          _ => l.weather,
        }}: ${switch (placement.values[id]) {
          'panel' => l.topPanel,
          'background' => l.informationOnBackground,
          _ => l.disabled,
        }}',
    ].join(' · ');
    return FocusableSettingsTile(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.informationGroup),
          Text(summary, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      leading: const Icon(Icons.schedule),
      onPressed: () => Navigator.of(context).push(
        SettingsRoute(
          settings: const RouteSettings(
            name: InformationSettingsPage.routeName,
          ),
          builder: (_) => const InformationSettingsPage(),
        ),
      ),
    );
  }
}

class InformationVisibility extends StatelessWidget {
  final bool remotePanel;
  const InformationVisibility({super.key, this.remotePanel = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final remote = remotePanel ? context.watch<RemotePanelService>() : null;
    final appearanceService = context.watch<AppearanceService>();
    final placement = InformationPlacement(
      appearanceService.appearance,
      settings,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final id in InformationPlacement.ids)
          if (remote != null)
            RoundedSwitchListTile(
              key: ValueKey(id),
              title: Text(switch (id) {
                'time' => l.showTime,
                'date' => l.showDate,
                _ => l.showWeather,
              }),
              value: remote.visible(id),
              onChanged: (value) => remote.show(id, value),
            )
          else
            SettingsChoiceTile<String>(
              key: ValueKey(id),
              title: switch (id) {
                'time' => l.informationTime,
                'date' => l.informationDate,
                _ => l.weather,
              },
              value: placement.values[id]!,
              options: InformationPlacement.destinations,
              label: (value) => switch (value) {
                'panel' => l.topPanel,
                'background' => l.informationOnBackground,
                _ => l.disabled,
              },
              onChanged: (value) => appearanceService.set(
                'panelInformationPlacements',
                {...placement.values, id: value},
              ),
            ),
      ],
    );
  }
}

Widget _informationPage(
  BuildContext context,
  String title,
  Widget child,
  String name,
) => FocusableSettingsTile(
  title: Text(title),
  leading: const Icon(Icons.tune),
  onPressed: () => Navigator.of(context).push(
    SettingsRoute(
      settings: RouteSettings(name: name),
      builder: (_) => child,
    ),
  ),
);

class InformationSettingsPage extends StatelessWidget {
  static const routeName = 'information_settings';
  final bool remotePanel;
  const InformationSettingsPage({super.key, this.remotePanel = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final placement = InformationPlacement(
      context.watch<AppearanceService>().appearance,
      context.watch<SettingsService>(),
    );
    return SettingsPageLayout(
      title: Text(l.informationGroup),
      child: ListView(
        children: [
          const InformationVisibility(),
          _informationPage(
            context,
            l.informationPanelAppearance,
            const PanelInformationSettingsPage(),
            PanelInformationSettingsPage.routeName,
          ),
          if (placement.hasBackground)
            _informationPage(
              context,
              l.backgroundInformationAppearance,
              const BackgroundInformationSettingsPage(),
              BackgroundInformationSettingsPage.routeName,
            ),
          _informationPage(
            context,
            l.informationData,
            const InformationDataSettingsPage(),
            InformationDataSettingsPage.routeName,
          ),
        ],
      ),
    );
  }
}

class InformationGroupingControl extends StatelessWidget {
  final bool remotePanel;
  const InformationGroupingControl({super.key, this.remotePanel = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final remote = remotePanel ? context.watch<RemotePanelService>() : null;
    final composition = InformationPanelComposition(
      service.appearance,
      context.watch<SettingsService>(),
      remote: remote,
    );
    return RoundedSwitchListTile(
      key: const ValueKey('information_grouping'),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.combinedInformation),
          if (!composition.canCombine)
            Text(
              l.informationGroupingMinimum,
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
      value: composition.combined,
      enabled: composition.canCombine,
      onChanged: (value) => remote != null
          ? remote.set('combinedInformation', value)
          : service.set('panelCombinedInformation', value),
    );
  }
}

class PanelInformationSettingsPage extends StatelessWidget {
  static const routeName = 'panel_information_settings';
  const PanelInformationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.informationPanelAppearance),
      child: ListView(
        children: const [
          InformationGroupingControl(),
          PanelClockStylePage(combined: true, embedded: true),
        ],
      ),
    );
  }
}

class InformationDataSettingsPage extends StatelessWidget {
  static const routeName = 'information_data_settings';
  const InformationDataSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(l.informationData),
      child: ListView(
        children: [
          const TimeFormatSettingsTile(),
          const DateFormatSettingsTile(),
          _informationPage(
            context,
            l.weatherSettings,
            const WeatherPage(),
            WeatherPage.routeName,
          ),
        ],
      ),
    );
  }
}

class BackgroundInformationSettingsPage extends StatelessWidget {
  static const routeName = 'background_information_settings';
  const BackgroundInformationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    return SettingsPageLayout(
      title: Text(l.backgroundInformationAppearance),
      child: ListView(
        children: [
          SettingsHelp(text: l.informationBackgroundHelp),
          _informationPage(
            context,
            l.panelObjectOrder,
            const BackgroundInformationOrderPage(),
            BackgroundInformationOrderPage.routeName,
          ),
          SettingsChoiceTile<String>(
            title: l.informationBackgroundAlignment,
            value: appearance.backgroundInformationAlignment,
            options: const ['left', 'center', 'right'],
            label: (value) => switch (value) {
              'left' => l.settingsMenuLeft,
              'right' => l.settingsMenuRight,
              _ => l.selectionCenter,
            },
            onChanged: (value) =>
                service.set('panelBackgroundInformationAlignment', value),
          ),
          SettingsValueStepper(
            title: l.informationSize,
            value: appearance.backgroundInformationSize,
            options: [for (var size = 48; size <= 144; size += 4) size],
            label: (value) => '${(value as num).round()}',
            onChanged: (value) =>
                service.set('panelBackgroundInformationSize', value),
          ),
          const PanelClockStylePage(
            combined: true,
            background: true,
            embedded: true,
          ),
        ],
      ),
    );
  }
}
