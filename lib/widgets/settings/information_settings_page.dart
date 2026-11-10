import 'settings_section.dart';
import '../../information_placement.dart';
import '../../information_formats.dart';
import '../../panel_clock_style.dart';
import '../../theme/launcher_style.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/settings_service.dart';
import '../launcher_dialog.dart';
import '../action_notice.dart';
import '../rounded_switch_list_tile.dart';
import 'color_palette_dialog.dart';
import 'date_time_format_page.dart';
import 'background_information_order_page.dart';
import 'focusable_settings_tile.dart';
import 'panel_clock_style_page.dart';
import 'settings_page_layout.dart';
import 'settings_route.dart';
import 'weather_page.dart';
import 'settings_choice_tile.dart';
import 'settings_color_swatch.dart';
import 'settings_slider_tile.dart';
import 'settings_help.dart';
import 'reset_style_tile.dart';
import 'information_weather_format_tile.dart';
import 'weather_appearance_options.dart';
import 'background_information_layout_control.dart';

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
    return SettingsSection(
      title: l.informationGroup,
      children: [
        _informationPage(
          context,
          l.settings,
          const InformationSettingsPage(),
          InformationSettingsPage.routeName,
          icon: Icons.settings_outlined,
        ),
      ],
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
              wideValue: true,
              valueStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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
  String name, {
  IconData? icon,
}) => FocusableSettingsTile(
  title: Text(title),
  leading: icon == null ? null : Icon(icon),
  onPressed: () => Navigator.of(context).push(
    SettingsRoute(
      settings: RouteSettings(name: name),
      builder: (_) => child,
    ),
  ),
);

/// Short navigation lists keep a 48dp target and leave space between groups.
Widget _informationNavigation(BuildContext context, Widget child) => Theme(
  data: Theme.of(context).copyWith(
    extensions: [
      ...Theme.of(context).extensions.values
          .where((value) => value is! LauncherStyle),
      LauncherStyle.of(context).copyWith(
        rowMinHeight: 48,
        rowPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    ],
  ),
  child: child,
);

class InformationSettingsPage extends StatelessWidget {
  static const routeName = 'information_settings';
  final bool remotePanel;
  const InformationSettingsPage({super.key, this.remotePanel = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _informationNavigation(
      context,
      SettingsPageLayout(
        title: Text(l.informationGroup),
        child: ListView(
          children: [
            SettingsSection(
              title: l.informationObjectPlacement,
              children: const [InformationVisibility()],
            ),
            SettingsSection(
              title: l.appearanceSettings,
              children: [
                _informationPage(
                  context,
                  l.informationComposition,
                  const InformationDataSettingsPage(),
                  InformationDataSettingsPage.routeName,
                  icon: Icons.tune,
                ),
                _informationPage(
                  context,
                  l.informationPanelAppearance,
                  const PanelInformationSettingsPage(),
                  PanelInformationSettingsPage.routeName,
                  icon: Icons.view_day_outlined,
                ),
                _informationPage(
                  context,
                  l.backgroundInformationAppearance,
                  const BackgroundInformationSettingsPage(),
                  BackgroundInformationSettingsPage.routeName,
                  icon: Icons.wallpaper_outlined,
                ),
              ],
            ),
            SettingsSection(
              title: l.weather,
              children: [
                _informationPage(
                  context,
                  l.weatherSettings,
                  const WeatherPage(),
                  WeatherPage.routeName,
                  icon: Icons.cloud_outlined,
                ),
              ],
            ),
          ],
        ),
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
  Widget build(BuildContext context) => const InformationAppearancePage();
}

class BackgroundInformationSettingsPage extends StatelessWidget {
  static const routeName = 'background_information_settings';
  const BackgroundInformationSettingsPage({super.key});
  @override
  Widget build(BuildContext context) =>
      const InformationAppearancePage(background: true);
}

class InformationAppearancePage extends StatelessWidget {
  final bool background;
  const InformationAppearancePage({super.key, this.background = false});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    Widget page(String label, String section) => _informationPage(
      context,
      label,
      InformationSectionPage(background: background, section: section),
      'information_${background ? 'background' : 'panel'}_$section',
    );
    return SettingsPageLayout(
      title: Text(
        background
            ? l.backgroundInformationAppearance
            : l.informationPanelAppearance,
      ),
      showObscuredInformationPreview: !background,
      child: ListView(
        children: [
          page(
            background ? l.informationPositionSize : l.informationLayout,
            'layout',
          ),
          page(l.informationTypography, 'typography'),
          page(l.informationColors, 'colors'),
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
    final appearance = context.watch<AppearanceService>();
    final clock = appearance.informationClockBehavior;
    return SettingsPageLayout(
      title: Text(l.informationComposition),
      showObscuredInformationPreview: false,
      child: ListView(
        children: [
          SettingsSection(
            key: const ValueKey('information-time-section'),
            title: l.informationTime,
            children: [
              const TimeFormatSettingsTile(),
              RoundedSwitchListTile(
                title: Text(l.clockShowColon),
                value: clock.showColon,
                onChanged: (value) => appearance.setInformationClockBehavior(
                  InformationClockBehavior(
                    showColon: value,
                    animate: appearance.informationClockBehavior.animate,
                  ),
                ),
              ),
              RoundedSwitchListTile(
                title: Text(l.clockAnimate),
                value: clock.animate,
                onChanged: (value) => appearance.setInformationClockBehavior(
                  InformationClockBehavior(
                    showColon: appearance.informationClockBehavior.showColon,
                    animate: value,
                  ),
                ),
              ),
            ],
          ),
          SettingsSection(
            key: const ValueKey('information-date-section'),
            title: l.informationDate,
            children: const [DateFormatSettingsTile()],
          ),
          SettingsSection(
            key: const ValueKey('information-weather-section'),
            title: l.weather,
            children: [
              SettingsChoiceTile<bool>(
                title: l.temperatureUnit,
                value: context.watch<SettingsService>().useFahrenheit,
                options: const [false, true],
                label: (value) => value ? l.fahrenheit : l.celsius,
                onChanged: (value) async {
                  final settings = context.read<SettingsService>();
                  final current = settings.informationWeather();
                  try {
                    await settings.setInformationWeather(WeatherDisplayOptions(
                      format: current.format, fahrenheit: value, warnings: current.warnings,
                    ));
                  } catch (_) {
                    if (context.mounted) {
                      showActionNotice(context, l.weatherTextSaveError, error: true);
                    }
                  }
                },
              ),
              const InformationWeatherFormatTile(),
            ],
          ),
        ],
      ),
    );
  }
}

class InformationSectionPage extends StatelessWidget {
  final bool background;
  final String section;
  const InformationSectionPage({
    super.key,
    required this.background,
    required this.section,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance.forInformation(
      background: background,
    );
    String horizontalLabel(String value) => switch (value) {
      'left' => l.settingsMenuLeft,
      'right' => l.settingsMenuRight,
      _ => l.selectionCenter,
    };
    const horizontalChoices = ['left', 'center', 'right'];
    final title = switch (section) {
      'layout' => background ? l.informationPositionSize : l.informationLayout,
      'typography' => l.informationTypography,
      _ => l.informationColors,
    };
    final page = SettingsPageLayout(
      title: Text(title),
      showObscuredInformationPreview: !background,
      child: ListView(
        children: [
          if (section == 'layout' && background) ...[
            SettingsSection(
              key: const ValueKey('settingsGroupBlockPosition'),
              title: l.settingsGroupBlockPosition,
              children: [
                SettingsChoiceTile<String>(
                  title: l.informationBackgroundPosition,
                  value: appearance.backgroundInformationPosition,
                  options: horizontalChoices,
                  label: horizontalLabel,
                  onChanged: (value) =>
                      service.set('panelBackgroundInformationAlignment', value),
                ),
                SettingsSliderTile(
                  title: l.informationBackgroundOffset,
                  value: appearance.backgroundInformationOffset,
                  options: [
                    for (var offset = -100; offset <= 100; offset += 5) offset,
                  ],
                  label: (value) => '${value > 0 ? '+' : ''}${value.round()}%',
                  sliderTextDirection: TextDirection.ltr,
                  onChanged: (value) =>
                      service.set('panelBackgroundInformationOffset', value),
                ),
                const BackgroundInformationLayoutControl.verticalOffset(),
              ],
            ),
            SettingsSection(
              key: const ValueKey('settingsGroupBlockContent'),
              title: l.settingsGroupBlockContent,
              children: [
                _informationPage(
                  context,
                  l.panelObjectOrder,
                  const BackgroundInformationOrderPage(),
                  BackgroundInformationOrderPage.routeName,
                ),
                SettingsChoiceTile<String>(
                  title: l.informationBackgroundContentAlignment,
                  value: appearance.backgroundInformationAlignment,
                  options: horizontalChoices,
                  label: horizontalLabel,
                  onChanged: (value) => service.set(
                    'panelBackgroundInformationContentAlignment',
                    value,
                  ),
                ),
                const BackgroundInformationLayoutControl.size(),
              ],
            ),
            SettingsSection(
              key: const ValueKey('settingsGroupLayers'),
              title: l.settingsGroupLayers,
              children: [
                RoundedSwitchListTile(
                  title: Text(l.informationAboveLandscape),
                  value: appearance.backgroundInformationAboveLandscape,
                  onChanged: (v) => service.set(
                    'panelBackgroundInformationAboveLandscape',
                    v,
                  ),
                ),
                RoundedSwitchListTile(
                  title: Text(l.informationAboveWeather),
                  value: appearance.backgroundInformationAboveWeather,
                  onChanged: (v) =>
                      service.set('panelBackgroundInformationAboveWeather', v),
                ),
                SettingsHelp(
                  text:
                      '${l.informationAvoidOverlapHelp}\n\n${l.informationBackgroundHelp}',
                ),
              ],
            ),
            ResetStyleTile(
              title: l.informationResetPositionSize,
              onReset: service.resetBackgroundInformationLayout,
            ),
          ],
          if (section == 'layout' && !background) ...[
            const InformationGroupingControl(),
            const PanelClockStylePage(
              combined: true,
              embedded: true,
              section: InformationStyleSection.layout,
            ),
            SettingsHelp(text: l.weatherCompactLayout),
          ],
          if (section == 'typography')
            PanelClockStylePage(
              combined: true,
              background: background,
              embedded: true,
              section: InformationStyleSection.typography,
            ),
          if (section == 'colors') ...[
            SettingsSection(
              key: const ValueKey('information-common-section'),
              title: l.informationCommonAppearance,
              children: [
                PanelClockStylePage(
                  combined: true,
                  background: background,
                  embedded: true,
                  section: InformationStyleSection.effects,
                ),
              ],
            ),
            SettingsSection(
              key: const ValueKey('information-time-section'),
              title: l.informationTime,
              children: [
                PanelClockStylePage(
                  combined: true,
                  background: background,
                  embedded: true,
                  section: InformationStyleSection.colors,
                ),
              ],
            ),
            SettingsSection(
              key: const ValueKey('information-date-section'),
              title: l.informationDate,
              children: [
                FocusableSettingsTile(
                  title: Text(l.informationDateColor),
                  trailing: SettingsColorSwatch(
                    inherited: appearance.dateTextColor == null,
                    tooltip: appearance.dateTextColor == null
                        ? l.defaultOption
                        : l.informationDateColor,
                    color:
                        appearance.dateTextColor ??
                        (background
                                ? appearance.backgroundInformationStyle
                                : appearance.informationStyle)
                            .textStyle(appearance.panelTextStyle)
                            .color ??
                        appearance.panelTextColor,
                  ),
                  onPressed: () async {
                    final picked = await showLauncherDialog<(int?,)>(
                      context: context,
                      builder: (_) => ColorPaletteDialog(
                        title: l.informationDateColor,
                        current: appearance.dateTextColor?.toARGB32(),
                        allowDefault: true,
                      ),
                    );
                    if (picked != null && context.mounted) {
                      await service.setInformationAppearance(
                        'dateTextColor',
                        picked.$1,
                        background: background,
                      );
                    }
                  },
                ),
              ],
            ),
            SettingsSection(
              key: const ValueKey('information-weather-section'),
              title: l.weather,
              children: [
                WeatherAppearanceOptions(
                  service: service,
                  appearance: appearance,
                  background: background,
                ),
              ],
            ),
            ResetStyleTile(
              title: l.informationResetPositionSize,
              onReset: () => service.resetInformationColors(background: background),
            ),
          ],
          if (!background && section == 'typography')
            ResetStyleTile(
              title: l.informationResetTypography,
              onReset: service.resetInformationTypography,
            ),
        ],
      ),
    );
    return background && section == 'layout'
        ? SliderTheme(
            data: SliderTheme.of(context).copyWith(
              tickMarkShape: SliderTickMarkShape.noTickMark,
            ),
            child: page,
          )
        : page;
  }
}
