import 'settings_help.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/appearance_service.dart';
import '../../providers/apps_service.dart';
import '../../models/category.dart';
import '../../home_layout.dart';
import '../../l10n/app_localizations.dart';
import 'settings_page_layout.dart';
import 'settings_choice_tile.dart';
import 'settings_value_stepper.dart';
import 'focusable_settings_tile.dart';
import 'settings_route.dart';
import 'appearance_page.dart';
import 'section_style_page.dart';

class CategoryAppearancePage extends StatelessWidget {
  final int categoryId;
  const CategoryAppearancePage({super.key, required this.categoryId});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<AppearanceService>();
    final style = service.category(categoryId);
    final category = context
        .watch<AppsService?>()
        ?.categories
        .where((c) => c.id == categoryId)
        .firstOrNull;
    final mode = style.resolvedLayout(
      category == null || category.type == CategoryType.row,
    );
    final columns = style.resolvedColumns(
      legacyRow: category == null || category.type == CategoryType.row,
      legacyColumns: category?.columnsCount ?? 6,
    );
    final tiles = service.tilesFor(categoryId);
    final geometry = HomeLayout(
      mode: mode,
      count: category?.applications.length ?? 1,
      availableWidth:
          MediaQuery.sizeOf(context).width -
          48 -
          2 * (tiles.number('sectionPadding') ?? style.padding),
      style: tiles,
      requestedRows: style.rows,
      requestedColumns: columns,
      labelHeight: tiles.labels == 'all' && tiles.labelPosition == 'below'
          ? MediaQuery.textScalerOf(context).scale(tiles.labelSize) * 1.4 + 8
          : 0,
    );
    final autoCount = HomeLayout(
      mode: mode,
      count: geometry.count,
      availableWidth:
          MediaQuery.sizeOf(context).width -
          48 -
          2 * (tiles.number('sectionPadding') ?? style.padding),
      style: tiles,
    ).columns;
    Widget page(String title, Widget child) => FocusableSettingsTile(
      title: Text(title),
      onPressed: () =>
          Navigator.of(context)
              .push(SettingsRoute<void>(builder: (_) => child)),
    );
    return SettingsPageLayout(
      title: Text(l.categoryAppearance),
      child: ListView(
        children: [
          SettingsChoiceTile<String>(
            autofocus: true,
            title: l.layout,
            value: mode == 'grid' ? 'grid' : 'row',
            options: const ['row', 'grid'],
            label: (v) => {
              'row': l.homeLayoutRow,
              'grid': l.homeLayoutGrid,
            }[v]!,
            onChanged: (v) => service.setCategory(categoryId, 'layout',
                v == 'row' && mode == 'rows' ? 'rows' : v),
          ),
          SettingsValueStepper(
            useSlider: false,
            title: l.homeCardCount,
            value: columns,
            options: [for (var n = 0; n <= 12; n++) n],
            label: (v) => v == 0 ? '${l.homeAuto} — $autoCount' : '$v',
            onChanged: (v) => service.setCategory(categoryId, 'columns', (v as num).toInt()),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              '${columns > 0 ? l.homeCalculatedSize : l.tileSize}: ${geometry.width.round()} × ${geometry.height.round()}',
            ),
          ),
          if (geometry.gapX < tiles.horizontalGap)
            SettingsHelp(text: l.homeGapLimited(geometry.gapX.round())),
          if (mode != 'grid')
            SettingsValueStepper(
              title: l.tileRowCount,
              value: mode == 'row' ? 1 : style.rows.clamp(1, 6),
              options: const [1, 2, 3, 4, 5, 6],
              label: (v) => '$v',
              onChanged: (v) => service.setTapeRows(categoryId, (v as num).toInt()),
            ),
          if (mode == 'grid')
            SettingsValueStepper(
              title: l.categoryMaxRows,
              value: style.maxRows.clamp(0, 6),
              options: const [0, 1, 2, 3, 4, 5, 6],
              label: (v) => v == 0 ? l.categoryAllRows : '$v',
              onChanged: (v) => service.setCategory(categoryId, 'maxRows', v),
            ),
          if (mode == 'grid' && style.maxRows > 0)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                l.homeVisibleRows(
                  geometry.visibleRows(
                    style.maxRows,
                    MediaQuery.sizeOf(context).height - 180,
                  ),
                ),
              ),
            ),
          page(l.tilesAndLabels, AppearancePage(categoryId: categoryId)),
          page(l.homeSectionStyle, SectionStylePage(categoryId: categoryId)),
          FocusableSettingsTile(
            title: Text(l.homeResetLayout),
            leading: const Icon(Icons.restore),
            onPressed: () =>
                service.resetCategoryLayout(categoryId, grid: mode == 'grid'),
          ),
          FocusableSettingsTile(
            title: Text(l.homeResetSection),
            leading: const Icon(Icons.restore),
            onPressed: () => service.resetCategoryStyle(categoryId),
          ),
        ],
      ),
    );
  }
}
