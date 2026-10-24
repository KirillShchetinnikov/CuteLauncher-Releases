import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../l10n/app_localizations.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';
import 'settings_choice_tile.dart';
import 'home_style_setting.dart';
import 'reset_style_tile.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import '../launcher_dialog.dart';

class SectionStylePage extends StatelessWidget {
  final int? categoryId;
  const SectionStylePage({super.key, this.categoryId});
  static List<Widget> controls(
    BuildContext context, {
    int? categoryId,
    bool includeReset = true,
  }) {
    final l = AppLocalizations.of(context)!;
    final s = context.watch<AppearanceService>();
    final a = categoryId == null ? s.appearance : s.tilesFor(categoryId);
    void set(String k, dynamic v) {
      if (categoryId == null) {
        s.set(k, v);
      } else {
        s.setCategoryTile(categoryId, k, v);
      }
    }

    Widget inherited(String k, Widget Function(bool) builder) =>
        HomeStyleSetting(categoryId: categoryId, field: k, builder: builder);
    Widget toggle(String k, String title, bool value) => inherited(
      k,
      (enabled) => RoundedSwitchListTile(
        enabled: enabled,
        title: Text(title),
        value: value,
        onChanged: (v) => set(k, v),
      ),
    );
    Widget number(String k, String title, num value, List<num> options) =>
        inherited(
          k,
          (enabled) => SettingsValueStepper(
            enabled: enabled,
            title: title,
            value: value,
            options: options,
            label: (v) => '$v',
            onChanged: (v) => set(k, v),
          ),
        );
    return [
      if (categoryId == null) ...[
        SettingsChoiceTile<String>(
          title: l.homeScrollMode,
          value: a.anchored ? 'anchored' : 'free',
          options: const ['free', 'anchored'],
          label: (v) => v == 'free' ? l.homeFree : l.homeAnchored,
          onChanged: (v) => set('sectionScroll', v),
        ),
        if (a.anchored)
          SettingsValueStepper(
            title: l.homeSectionPosition,
            value: a.sectionPosition,
            options: [for (var n = 0; n <= 14; n++) n / 20],
            label: (v) => '${((v as num) * 100).round()}%',
            onChanged: (v) => set('sectionPosition', v),
          ),
      ],
      toggle('sectionTitles', l.showSectionTitles, a.sectionTitles),
      toggle('sectionIcons', l.homeSectionIcons, a.sectionIcons),
      if (categoryId != null)
        SettingsValueStepper(
          title: l.categoryPadding,
          value: a.number('sectionPadding') ?? 0,
          options: [for (var n = 0; n <= 64; n += 4) n],
          label: (v) => '$v',
          onChanged: (v) => set('sectionPadding', v),
        ),
      if (categoryId == null)
        number(
          'inactiveOpacity',
          l.homeInactiveOpacity,
          a.number('inactiveOpacity') ?? 1,
          [for (var n = 0; n <= 10; n++) n / 10],
        ),
      inherited(
        'sectionBackground',
        (enabled) => FocusableSettingsTile(
          enabled: enabled,
          title: Text(l.categoryBackground),
          trailing: (a.values['sectionBackground'] as int? ?? 0) == 0
              ? Text(l.categoryTransparent)
              : Container(
                  width: 36,
                  height: 24,
                  color: Color(a.values['sectionBackground'] as int),
                ),
          onPressed: () async {
            final selected = await showLauncherDialog<(int?,)>(
              context: context,
              builder: (_) => ColorPaletteDialog(
                title: l.categoryBackground,
                current: a.values['sectionBackground'] as int?,
                allowDefault: true,
                defaultLabel: l.categoryTransparent,
              ),
            );
            if (selected != null) {
              set('sectionBackground', selected.$1 ?? 0);
            }
          },
        ),
      ),
      if (categoryId == null)
        number('sectionGap', l.homeSectionGap, a.sectionGap, [
          for (var n = 0; n <= 96; n += 4) n,
        ]),
      if (includeReset)
        ResetStyleTile(
          title: categoryId == null ? null : l.resetSectionToGlobal,
          hint: categoryId == null ? null : l.resetSectionToGlobalHint,
          onReset: () => s.resetFields([
            'sectionTitles',
            'sectionIcons',
            if (categoryId != null) 'sectionPadding',
            'sectionBackground',
            if (categoryId == null) 'inactiveOpacity',
            if (categoryId == null) ...[
              'sectionGap',
              'sectionScroll',
              'sectionPosition',
            ],
          ], categoryId: categoryId),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return SettingsPageLayout(
      title: Text(categoryId == null ? l.launcherSections : l.homeSectionStyle),
      child: ListView(children: controls(context, categoryId: categoryId)),
    );
  }
}
