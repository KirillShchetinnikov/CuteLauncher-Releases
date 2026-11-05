import '../../information_placement.dart';
import 'language_font_choice.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../panel_clock_style.dart';
import '../../providers/appearance_service.dart';
import '../../providers/remote_panel_service.dart';
import '../../providers/settings_service.dart';

import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';

import 'settings_value_stepper.dart';

class PanelClockStylePage extends StatelessWidget {
  static const routeName = 'panel_clock_style';
  final bool combined;
  final bool remotePanel;
  final bool background;
  final bool embedded;
  const PanelClockStylePage({
    super.key,
    this.combined = false,
    this.remotePanel = false,
    this.background = false,
    this.embedded = false,
  });
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final remote = remotePanel ? context.watch<RemotePanelService>() : null;
    final appearance = combined && remote != null
        ? remote.appearanceFor(service.appearance)
        : service.appearance;
    final settings = context.watch<SettingsService>();
    final quickPanel = context.watch<RemotePanelService?>();
    bool needsLayout(InformationPanelComposition value) =>
        value.combined && value.members.contains('time');
    final hasClockAndText =
        needsLayout(
          InformationPanelComposition(service.appearance, settings),
        ) ||
        (quickPanel != null &&
            needsLayout(
              InformationPanelComposition(
                service.appearance,
                settings,
                remote: quickPanel,
              ),
            ));
    final clock = background
        ? appearance.backgroundInformationStyle
        : combined
        ? appearance.informationStyle
        : appearance.clockStyle;
    Future<void> save(Map<String, dynamic> values) => service.set(
      background
          ? 'panelBackgroundInformationStyle'
          : combined
          ? 'panelInformationStyle'
          : 'panelClockStyle',
      values,
    );
    void set(String key, dynamic value) {
      save({...clock.values, key: value});
    }

    final textStyle = clock.textStyle(
      appearance.panelTextStyleFor(Localizations.localeOf(context)),
      locale: Localizations.localeOf(context),
    );

    Widget color(String title, String key, Color current) =>
        FocusableSettingsTile(
          title: Text(title),
          trailing: Container(width: 32, height: 24, color: current),
          onPressed: () async {
            final chosen = await showLauncherDialog<(int?,)>(
              context: context,
              builder: (_) => ColorPaletteDialog(
                title: title,
                current: current.toARGB32(),
                allowDefault: key == 'hoursColor' || key == 'minutesColor',
              ),
            );
            if (chosen != null) {
              if (chosen.$1 != null) {
                set(key, chosen.$1);
              } else {
                save({...clock.values}..remove(key));
              }
            }
          },
        );
    final fields = <Widget>[
      if (!background)
        SettingsValueStepper(
          title: combined ? l.informationSize : l.styleTextSize,
          value: clock.size(appearance.panelTextSize),
          options: [
            for (var size = 10; size <= (combined ? 24 : 40); size++) size,
          ],
          label: (v) => '${(v as num).round()}',
          onChanged: (v) => set('size', v),
        ),
      LanguageFontChoice(
        title: l.panelFont,
        value: clock.values['font'] as String? ?? appearance.panelFont,
        panel: true,
        onChanged: (v) => set('font', v),
      ),
      SettingsChoiceTile<String>(
        title: l.clockPreset,
        value: clock.preset,
        options: [...PanelClockStyle.fontStyles.keys],
        label: (id) => id == 'italic' ? l.clockItalic : l.interfaceStandard,
        onChanged: (id) => save(clock.withFontStyle(id)),
      ),
      SettingsValueStepper(
        title: l.clockWeight,
        value: textStyle.fontWeight!.value,
        options: clock.availableWeights(
          appearance.panelTextStyleFor(Localizations.localeOf(context)),
          locale: Localizations.localeOf(context),
        ),
        useSlider: false,
        label: (v) => '$v',
        onChanged: (v) => set('weight', v),
      ),
      SettingsChoiceTile<bool>(
        title: l.clockColorMode,
        value: clock.splitColors,
        options: const [false, true],
        label: (split) => split ? l.clockSplitColors : l.clockSingleColor,
        valueBelow: true,
        onChanged: (split) => set('splitColors', split),
      ),
      if (clock.splitColors) ...[
        color(
          l.clockHoursColor,
          'hoursColor',
          clock.hoursColor ?? textStyle.color!,
        ),
        color(
          l.clockMinutesColor,
          'minutesColor',
          clock.minutesColor ?? textStyle.color!,
        ),
      ] else
        color(l.styleTextColor, 'color', textStyle.color!),
      RoundedSwitchListTile(
        title: Text(l.clockShowColon),
        value: clock.showColon,
        onChanged: (v) => set('showColon', v),
      ),
      RoundedSwitchListTile(
        title: Text(l.clockGlow),
        value: clock.values['glow'] == true,
        onChanged: (v) => set('glow', v),
      ),
      RoundedSwitchListTile(
        title: Text(l.clockAnimate),
        value: clock.animate,
        onChanged: (v) => set('animate', v),
      ),
      if (combined && hasClockAndText && !background) ...[
        SettingsChoiceTile<bool>(
          title: l.informationPosition,
          value: clock.clockOnRight,
          options: const [false, true],
          label: (v) => v ? l.informationClockRight : l.informationClockLeft,
          onChanged: (v) => set('clockOnRight', v),
        ),
        SettingsValueStepper(
          title: l.informationSpacing,
          value: clock.spacing,
          options: [for (var gap = 0; gap <= 32; gap++) gap],
          label: (v) => '${(v as num).round()}',
          onChanged: (v) => set('spacing', v),
        ),
      ],
    ];
    if (embedded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: fields,
      );
    }
    return SettingsPageLayout(
      title: Text(
        background
            ? l.backgroundInformationAppearance
            : l.informationPanelAppearance,
      ),
      child: ListView(children: fields),
    );
  }
}
