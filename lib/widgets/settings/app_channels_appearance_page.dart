import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/apps_service.dart';
import '../../section_names.dart';
import 'inherited_setting.dart';
import 'reset_style_tile.dart';
import 'section_style_page.dart';
import '../launcher_dialog.dart';
import 'color_palette_dialog.dart';
import 'focusable_settings_tile.dart';
import 'settings_page_layout.dart';
import 'settings_value_stepper.dart';

/// Content previews always use a single 16:9 tape with titles below the image.
class AppChannelsAppearancePage extends StatelessWidget {
  final int categoryId;
  const AppChannelsAppearancePage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final style = service.tilesFor(categoryId);
    final name = context
        .watch<AppsService?>()
        ?.categories
        .where((category) => category.id == categoryId)
        .firstOrNull
        ?.name;
    Widget value(
      String key,
      String title,
      num current,
      List<num> options, {
      bool autofocus = false,
    }) => InheritedSetting(
      categoryId: categoryId,
      field: key,
      child: SettingsValueStepper(
        autofocus: autofocus,
        title: title,
        value: current,
        options: options,
        label: (value) => '$value',
        onChanged: (value) => service.setCategoryTile(categoryId, key, value),
      ),
    );
    return SettingsPageLayout(
      title: Text(
        l.categoryAppearance +
            (name == null ? '' : ' · ${localizedSectionName(name, l)}'),
      ),
      child: ListView(
        children: [
          value('size', l.tileSize, style.tileSize, [
            for (var n = 64; n <= 256; n += 8) n,
          ], autofocus: true),
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
                if (selected != null) {
                  await service.setCategoryTile(
                    categoryId,
                    'labelColor',
                    selected.$1,
                  );
                }
              },
            ),
          ),
          ...SectionStylePage.controls(
            context,
            categoryId: categoryId,
            includeReset: false,
          ),
          ResetStyleTile(
            title: l.resetSectionToGlobal,
            hint: l.resetSectionToGlobalHint,
            onReset: () => service.resetFields(const [
              'size',
              'radius',
              'horizontalGap',
              'labelSize',
              'labelColor',
              'sectionTitles',
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
