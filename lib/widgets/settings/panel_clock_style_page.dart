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
import 'settings_color_swatch.dart';
import 'settings_page_layout.dart';

import 'settings_value_stepper.dart';

enum InformationStyleSection { all, layout, typography, colors, effects }

class PanelClockStylePage extends StatelessWidget {
  static const routeName = 'panel_clock_style';
  final bool combined;
  final bool remotePanel;
  final bool background;
  final bool embedded;
  final InformationStyleSection section;
  const PanelClockStylePage({
    super.key,
    this.combined = false,
    this.remotePanel = false,
    this.background = false,
    this.embedded = false,
    this.section = InformationStyleSection.all,
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
    final composition = InformationPanelComposition(
      service.appearance,
      settings,
      remote: remote,
    );
    final hasClockAndText =
        composition.combined && composition.members.contains('time');
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

    final clockColor = clock.clockColor ?? textStyle.color!;
    final panelTypography = combined && !background;
    final showTypography = !panelTypography || !clock.inheritsPanelTypography;
    Widget color(String title, String key, Color? selected) =>
        FocusableSettingsTile(
          title: Text(title),
          trailing: SettingsColorSwatch(
            color: selected ?? clockColor,
            inherited: selected == null,
            tooltip: selected == null ? l.defaultOption : title,
          ),
          onPressed: () async {
            final chosen = await showLauncherDialog<(int?,)>(
              context: context,
              builder: (_) => ColorPaletteDialog(
                title: title,
                current: selected?.toARGB32(),
                allowDefault: true,
              ),
            );
            if (chosen != null && context.mounted) {
              if (chosen.$1 != null) {
                set(key, chosen.$1);
              } else {
                save({...clock.values}..remove(key));
              }
            }
          },
        );
    final fields = <Widget>[
      if (panelTypography &&
          (section == InformationStyleSection.all || section == InformationStyleSection.typography))
        RoundedSwitchListTile(
          title: Text(l.informationInheritPanelTypography),
          value: clock.inheritsPanelTypography,
          onChanged: (value) => set('inheritPanelTypography', value),
        ),
      if (showTypography && (section == InformationStyleSection.all || section == InformationStyleSection.typography)) ...[
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
      SettingsValueStepper(
        title: l.clockPreset,
        value: clock.preset,
        options: [...PanelClockStyle.fontStyles.keys],
        inlineChoices: true,
        label: (id) => id == 'italic' ? l.clockItalic : l.interfaceStandard,
        onChanged: (id) => save(clock.withFontStyle(id as String)),
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
      ],
      if (section == InformationStyleSection.all || section == InformationStyleSection.colors) ...[
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
          clock.hoursColor,
        ),
        color(
          l.clockMinutesColor,
          'minutesColor',
          clock.minutesColor,
        ),
      ] else
        color(l.clockTextColor, 'clockColor', clock.clockColor),
      ],
      if (section == InformationStyleSection.all || section == InformationStyleSection.effects) ...[
      RoundedSwitchListTile(
        title: Text(l.clockGlow),
        value: clock.values['glow'] == true,
        onChanged: (v) => set('glow', v),
      ),
      ],
      if ((section == InformationStyleSection.all || section == InformationStyleSection.layout) && combined && !background) ...[
        SettingsChoiceTile<bool>(
          title: l.informationPosition,
          enabled: hasClockAndText,
          value: clock.clockOnRight,
          options: const [false, true],
          label: (v) => v ? l.informationClockRight : l.informationClockLeft,
          onChanged: (v) => set('clockOnRight', v),
        ),
        SettingsValueStepper(
          title: l.informationSpacing,
          enabled: hasClockAndText,
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
      showObscuredInformationPreview: !background,
      child: ListView(children: fields),
    );
  }
}
