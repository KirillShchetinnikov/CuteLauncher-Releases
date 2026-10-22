import 'language_font_choice.dart';
import 'date_time_format_page.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../panel_clock_style.dart';
import '../../providers/appearance_service.dart';
import '../../theme/launcher_style.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
import 'settings_percentage_slider.dart';
import 'settings_value_stepper.dart';

class PanelClockStylePage extends StatelessWidget {
  static const routeName = 'panel_clock_style';
  const PanelClockStylePage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final appearance = service.appearance;
    final clock = appearance.clockStyle;
    Future<void> save(Map<String, dynamic> values) =>
        service.set('panelClockStyle', values);
    void set(String key, dynamic value) {
      save({...clock.values, 'preset': 'custom', key: value});
    }

    final textStyle = clock.textStyle(appearance.panelTextStyleFor(Localizations.localeOf(context)), locale: Localizations.localeOf(context));
    final background = clock.background(appearance.panelItemBackground);
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
                allowDefault: key == 'backgroundColor',
                defaultLabel: l.clockDefaultBackground,
              ),
            );
            if (chosen != null) {
              if (chosen.$1 == null) {
                set(
                  'backgroundColor',
                  (appearance.color('panelTextBackgroundColor') ??
                          const Color(0xff242935))
                      .toARGB32(),
                );
              } else {
                set(key, chosen.$1);
              }
            }
          },
        );
    return SettingsPageLayout(
      title: Text(l.panelClockStyle),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            title: l.clockPreset,
            autofocus: true,
            value: clock.preset,
            options: [
              ...PanelClockStyle.presets.keys,
              if (clock.preset == 'custom') 'custom',
            ],
            label: (id) => switch (id) {
              'minimal' => l.clockMinimal,
              'elegant' => l.clockElegant,
              'digital' => l.clockDigital,
              'neon' => l.clockNeon,
              'custom' => l.clockCustom,
              _ => l.defaultOption,
            },
            onChanged: (id) {
              if (id != 'custom') {
                save(
                  id == 'default'
                      ? {}
                      : {
                          'preset': id,
                          ...PanelClockStyle.presets[id]!,
                          'inheritBackground': clock.inheritBackground,
                        },
                );
              }
            },
          ),
          const TimeFormatSettingsTile(),
          SettingsValueStepper(
            title: l.styleTextSize,
            value: clock.size(appearance.panelTextSize),
            options: [for (var size = 10; size <= 40; size++) size],
            label: (v) => '${(v as num).round()}',
            onChanged: (v) => set('size', v),
          ),
          LanguageFontChoice(
            title: l.panelFont,
            value: clock.values['font'] as String? ?? appearance.panelFont,
            panel: true,
            onChanged: (v) => set('font', v),
          ),
          SettingsChoiceTile<int>(
            title: l.clockWeight,
            value: clock.values['weight'] as int? ?? 400,
            options: const [300, 400, 700],
            label: (v) => '$v',
            onChanged: (v) => set('weight', v),
          ),
          color(l.styleTextColor, 'color', textStyle.color!),
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
          RoundedSwitchListTile(
            title: Text(l.clockSharedBackground),
            value: clock.inheritBackground,
            onChanged: (v) => set('inheritBackground', v),
          ),
          if (!clock.inheritBackground) ...[
            RoundedSwitchListTile(
              title: Text(l.clockBackground),
              value: clock.backgroundEnabled(appearance.panelItemBackground),
              onChanged: (v) => set('background', v),
            ),
            if (clock.backgroundEnabled(appearance.panelItemBackground)) ...[
              color(
                l.styleBackgroundColor,
                'backgroundColor',
                background.withAlpha(255),
              ),
              SettingsPercentageSlider(
                title: l.styleTransparency,
                value: 1 - background.a,
                onChanged: (v) => set('opacity', 1 - v),
              ),
              SettingsValueStepper(
                title: l.clockRadius,
                value: clock.radius(LauncherStyle.of(context).topButtonRadius),
                options: [for (var r = 0; r <= 26; r++) r],
                label: (v) => '${(v as num).round()}',
                onChanged: (v) => set('radius', v),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
