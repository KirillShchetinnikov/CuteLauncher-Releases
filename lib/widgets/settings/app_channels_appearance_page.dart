import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/category.dart';
import '../../providers/appearance_service.dart';
import '../../providers/apps_service.dart';
import '../../section_names.dart';
import 'inherited_setting.dart';
import 'reset_style_tile.dart';
import 'section_style_page.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

/// Appearance for horizontal rows of content previews.
class AppChannelsAppearancePage extends StatelessWidget {
  final int categoryId;
  const AppChannelsAppearancePage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final style = service.tilesFor(categoryId);
    final ownLabels = style.contentAppTileStyle && !style.contentUseSourceLabels;
    final categories = context.watch<AppsService?>()?.categories ?? const <Category>[];
    final sources = <int, String>{
      -1: l.contentTileOwnAppearance,
      0: l.contentTileCommonAppearance,
      for (final category in categories)
        if (!category.isAppChannels && category.id != categoryId)
          category.id: localizedSectionName(category.name, l),
    };
    final sourceId = style.contentAppTileSectionId;
    final selected = sources.containsKey(sourceId)
        ? sourceId!
        : style.contentAppTileStyle ? 0 : -1;
    final name = categoryId == ContinueWatchingSection.sectionId
        ? l.continueWatching
        : categories
              .where((category) => category.id == categoryId)
              .map((category) => localizedSectionName(category.name, l))
              .firstOrNull;
    Widget value(String key, String title, num current, List<num> options) =>
        InheritedSetting(
          categoryId: categoryId,
          field: key,
          child: SettingsValueStepper(
            title: title,
            value: current,
            options: options,
            label: (value) => '$value',
            onChanged: (value) =>
                service.setCategoryTile(categoryId, key, value),
          ),
        );
    return SettingsPageLayout(
      title: Text(l.categoryAppearance + (name == null ? '' : ' · $name')),
      child: ListView(
        children: [
          SettingsChoiceTile<int>(
            title: l.contentAppTileStyle,
            value: selected,
            options: sources.keys.toList(),
            label: (value) => sources[value]!,
            valueBelow: true,
            autofocus: true,
            onChanged: (value) => service.setCategoryTile(
              categoryId,
              'contentAppTileStyle',
              value > 0 ? value : value == 0,
            ),
          ),
          if (style.contentAppTileStyle)
            RoundedSwitchListTile(
              title: Text(l.contentUseSourceLabels),
              value: style.contentUseSourceLabels,
              onChanged: (value) => service.setCategoryTile(
                categoryId, 'contentUseSourceLabels', value,
              ),
            ),
          if (!style.contentAppTileStyle) ...[
            value('size', l.tileSize, style.tileSize, [
              for (var n = 64; n <= 256; n += 8) n,
            ]),
            InheritedSetting(
              categoryId: categoryId,
              field: 'radius',
              child: SettingsValueStepper(
                title: l.tileCornerRadius,
                value: style.number('radius'),
                options: const [null, 0, 8, 16, 32, 100],
                label: (value) => value == null ? l.defaultOption : '$value',
                onChanged: (value) =>
                    service.setCategoryTile(categoryId, 'radius', value),
              ),
            ),
            value('horizontalGap', l.tileHorizontalGap, style.horizontalGap, [
              for (var n = 0; n <= 48; n += 2) n,
            ]),
          ],
          if (ownLabels) ...[
            SettingsChoiceTile<String>(
              title: l.labelsGroup,
              value: style.labels,
              options: const ['none', 'selected', 'all'],
              label: (value) => switch (value) {
                'none' => l.homeLabelNone,
                'selected' => l.contentLabelSelected,
                _ => l.contentLabelAll,
              },
              onChanged: (value) =>
                  service.setCategoryTile(categoryId, 'labels', value),
            ),
            if (style.labels == 'all')
              SettingsChoiceTile<String>(
                title: l.tileLabelPosition,
                value: style.labelPosition,
                options: const ['below', 'inside'],
                label: (value) =>
                    value == 'below' ? l.tileLabelBelow : l.tileLabelInside,
                onChanged: (value) =>
                    service.setCategoryTile(categoryId, 'labelPosition', value),
              ),
          ],
          if (!style.contentAppTileStyle || ownLabels && style.labels != 'none') ...[
            value('labelSize', l.tileLabelSize, style.labelSize, const [
              10,
              12,
              14,
              16,
              20,
            ]),
            InheritedSetting(
              categoryId: categoryId,
              field: 'labelColor',
              child: FocusableSettingsTile(
                title: Text(l.tileLabelColor),
                trailing: Container(
                  width: 36,
                  height: 24,
                  color: style.color('labelColor') ?? Colors.white,
                ),
                onPressed: () async {
                  final selected = await showLauncherDialog<(int?,)>(
                    context: context,
                    builder: (_) => ColorPaletteDialog(
                      title: l.tileLabelColor,
                      current: style.values['labelColor'] as int?,
                      allowDefault: true,
                    ),
                  );
                  if (selected == null) return;
                  if (selected.$1 == null) {
                    await service.inheritField(categoryId, 'labelColor');
                  } else {
                    await service.setCategoryTile(
                      categoryId,
                      'labelColor',
                      selected.$1,
                    );
                  }
                },
              ),
            ),
          ],
          RoundedSwitchListTile(
            title: Text(l.scrollContentLabels),
            value: service.appearance.scrollContentLabels,
            onChanged: (value) => service.set('scrollContentLabels', value),
          ),
          ...SectionStylePage.controls(
            context,
            categoryId: categoryId,
            includeReset: false,
            includeIcons: false,
          ),
          ResetStyleTile(
            title: l.resetSectionToGlobal,
            hint: l.resetSectionToGlobalHint,
            onReset: () => service.resetFields(const [
              'size',
              'contentAppTileStyle',
              'contentUseSourceLabels',
              'radius',
              'horizontalGap',
              'labels',
              'labelPosition',
              'labelSize',
              'labelColor',
              'sectionTitles',
              'sectionTitleSize',
              'sectionTitleAligned',
              'sectionIcons',
              'sectionPadding',
              'sectionBackground',
              'sectionOpacity',
              'sectionRadius',
            ], categoryId: categoryId),
          ),
        ],
      ),
    );
  }
}
