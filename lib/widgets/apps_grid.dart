/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/section_names.dart';
import 'dart:math';

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

import '../models/app.dart';
import '../models/category.dart';
import '../providers/settings_service.dart';
import 'category_container_common.dart';
import 'category_surface.dart';
import '../providers/appearance_service.dart';
import '../tile_appearance.dart';
import 'category_focus.dart';

class AppsGrid extends StatelessWidget
{
  final Category category;
  final List<App> applications;

  final bool isFirstSection;

  const AppsGrid({
    super.key,
    required this.category,
    required this.applications,
    this.isFirstSection = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = context.watch<AppearanceService?>();
    final appearance = service?.tilesFor(category.id) ?? const TileAppearance();
    final balanced = service?.category(category.id).layout == 'rows';
    final maxRows = context.watch<AppearanceService?>()?.category(category.id).maxRows ?? 0;
    Widget categoryContent;
    if (applications.isEmpty) {
      categoryContent = categoryContainerEmptyState(context);
    }
    else if (balanced) {
      categoryContent = _balancedRows(context, appearance,
          service!.category(category.id).rows);
    } else {
      categoryContent = LayoutBuilder(builder: (context, constraints) {
        final columns = _columns(context, appearance, constraints.maxWidth);
        final delegate = _buildSliverGridDelegate(context, appearance, constraints.maxWidth);
        final grid = GridView.custom(
        physics: maxRows > 0 ? const NeverScrollableScrollPhysics() : null,
        clipBehavior: Clip.none,
        primary: false,
        shrinkWrap: true,
        gridDelegate: _buildSliverGridDelegate(context, appearance, constraints.maxWidth),
        padding: EdgeInsets.all(16),
        childrenDelegate: SliverChildBuilderDelegate(
          childCount: applications.length,
          findChildIndexCallback: _findChildIndex,
          (context, index) {
            final isFirstInRow = index % columns == 0;
            final isLastInRow = index % columns == columns - 1 || index == applications.length - 1;

            return AppCard(
              key: Key(applications[index].packageName),
              index: index,
              category: category,
              application: applications[index],
              autofocus: index == 0,
              handleUpNavigationToSettings: isFirstSection && index < columns,
              isFirstInRow: isFirstInRow,
              isLastInRow: isLastInRow,
              onMove: (direction) => _onMove(context, direction, applications[index], columns),
              onMoveEnd: () => _saveOrder(context),
              onMoveCancel: () => _cancelOrder(context),
            );
          }
        )
      );
        if (maxRows == 0) return grid;
        final height = delegate.mainAxisExtent!;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: 32 + maxRows * height + (maxRows - 1) * appearance.verticalGap),
          child: SingleChildScrollView(child: grid),
        );
      });
    }

    return CategorySurface(categoryId: category.id, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Selector<SettingsService, bool>(
          selector: (context, service) => service.showCategoryTitles,
          builder: (context, showCategoriesTitle, _) {
            if (showCategoriesTitle) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    Text(localizedSectionName(category.name, AppLocalizations.of(context)!),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge!
                          .copyWith(fontSize: 22, fontWeight: FontWeight.w500, shadows: [const Shadow(color: Colors.black38, offset: Offset(0, 1), blurRadius: 4)])
                    ),
                    const SizedBox(width: 8),
                    Text('•  ${applications.length}',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium!
                          .copyWith(color: Colors.white54)
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }
        ),
        categoryContent
      ],
    ));
  }


  int? _findChildIndex(Key key) {
    final valueKey = key as ValueKey<String>;
    final index = applications.indexWhere((app) => app.packageName == valueKey.value);
    return index >= 0 ? index : null;
  }

  void _onMove(BuildContext context, AxisDirection direction, App movingApp, int columns) {
    final index = applications.indexOf(movingApp);
    if (index == -1) return;

    final currentRow = (index / columns).floor();
    final totalRows = ((applications.length - 1) / columns).floor();

    int? newIndex;
    switch (direction) {
      case AxisDirection.up:
        if (currentRow > 0) {
          newIndex = index - columns;
        }
        // At top boundary - do nothing
        break;
      case AxisDirection.right:
        if (index < applications.length - 1) {
          newIndex = index + 1;
        }
        break;
      case AxisDirection.down:
        if (currentRow < totalRows) {
          newIndex = min(index + columns, applications.length - 1);
        }
        // At bottom boundary - do nothing
        break;
      case AxisDirection.left:
        if (index > 0) {
          newIndex = index - 1;
        }
        break;
    }
    if (newIndex != null) {
      final appsService = context.read<AppsService>();
      appsService.setPendingReorderFocus(movingApp.packageName, category.id, newIndex);
      appsService.reorderApplication(category, index, newIndex);
    }
  }

  void _saveOrder(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.saveApplicationOrderInCategory(category);
  }

  void _cancelOrder(BuildContext context) {
    final appsService = context.read<AppsService>();
    appsService.cancelReorderApplication(category);
  }

  int _columns(BuildContext context, TileAppearance appearance, double width) {
    final layout = context.read<AppearanceService?>()?.category(category.id).values['layout'];
    if (layout == 'columns') return category.columnsCount;
    final sizing = layout == 'auto'
        ? TileAppearance({...appearance.values, 'size': appearance.tileSize}) : appearance;
    return sizing.columns(category.columnsCount, width: width);
  }

  SliverGridDelegateWithFixedCrossAxisCount _buildSliverGridDelegate(BuildContext context, TileAppearance appearance, double width) {
    final columns = _columns(context, appearance, width);
    final available = (width - 32 - appearance.horizontalGap * (columns - 1)) / columns;
    final layout = context.read<AppearanceService?>()?.category(category.id).values['layout'];
    final exactSize = layout != 'columns'
        && (layout == 'auto' || appearance.number('size') != null);
    final cellWidth = exactSize ? min(available, appearance.tileSize * appearance.aspectRatio) : available;
    final showLabel = context.watch<SettingsService>().showAppNamesBelowIcons && appearance.labelPosition == 'below';
    return _TileGridDelegate(
        tileWidth: cellWidth,
        crossAxisCount: columns,
        childAspectRatio: appearance.aspectRatio,
        mainAxisExtent: cellWidth / appearance.aspectRatio + ((appearance.active || layout != null) && showLabel ? appearance.labelSize * MediaQuery.textScalerOf(context).scale(1) * 1.4 + 8 : 0),
        mainAxisSpacing: appearance.verticalGap,
        crossAxisSpacing: appearance.horizontalGap,
      );
  }

  Widget _balancedRows(BuildContext context, TileAppearance appearance, int requested) =>
      _BalancedTileRows(category: category, applications: applications,
        appearance: appearance, rows: requested, isFirstSection: isFirstSection,
        onMoveEnd: () => _saveOrder(context), onMoveCancel: () => _cancelOrder(context));

}

List<int> balancedRowCounts(int count, int rows) => count == 0 ? [] : [
  for (var row = 0; row < min(rows, count); row++)
    count ~/ min(rows, count) + (row < count % min(rows, count) ? 1 : 0),
];

class _TileGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  final double tileWidth;
  const _TileGridDelegate({required this.tileWidth, required super.crossAxisCount,
    required super.mainAxisExtent, required super.mainAxisSpacing,
    required super.crossAxisSpacing, required super.childAspectRatio});
  @override
  SliverGridLayout getLayout(SliverConstraints constraints) => SliverGridRegularTileLayout(
    crossAxisCount: crossAxisCount,
    mainAxisStride: mainAxisExtent! + mainAxisSpacing,
    crossAxisStride: tileWidth + crossAxisSpacing,
    childMainAxisExtent: mainAxisExtent!, childCrossAxisExtent: tileWidth,
    reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
  );
  @override
  bool shouldRelayout(covariant _TileGridDelegate oldDelegate) =>
      tileWidth != oldDelegate.tileWidth || super.shouldRelayout(oldDelegate);
}


class _BalancedTileRows extends StatefulWidget {
  final Category category;
  final List<App> applications;
  final TileAppearance appearance;
  final int rows;
  final bool isFirstSection;
  final VoidCallback onMoveEnd, onMoveCancel;
  const _BalancedTileRows({required this.category, required this.applications,
    required this.appearance, required this.rows, required this.isFirstSection,
    required this.onMoveEnd, required this.onMoveCancel});
  @override
  State<_BalancedTileRows> createState() => _BalancedTileRowsState();
}

class _BalancedTileRowsState extends State<_BalancedTileRows> {
  final _controllers = <CategoryFocusController>[];
  CategoryFocusController? _parent;
  @override
  void dispose() {
    _parent?.scrollDelegates.removeWhere((_, controller) => _controllers.contains(controller));
    for (final controller in _controllers) { controller.dispose(); }
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final apps = widget.applications;
    final appearance = widget.appearance;
    final counts = balancedRowCounts(apps.length, widget.rows);
    while (_controllers.length < counts.length) { _controllers.add(CategoryFocusController()); }
    _parent = CategoryFocus.maybeOf(context);
    _parent?.scrollDelegates.removeWhere((_, controller) => _controllers.contains(controller));
    final showLabel = context.watch<SettingsService>().showAppNamesBelowIcons && appearance.labelPosition == 'below';
    final height = appearance.tileSize + (showLabel ? appearance.labelSize * MediaQuery.textScalerOf(context).scale(1) * 1.4 + 8 : 0);
    final starts = <int>[];
    var start = 0;
    for (final count in counts) { starts.add(start); start += count; }
    return Column(children: [
      for (var row = 0; row < counts.length; row++) ...[
        if (row > 0) SizedBox(height: appearance.verticalGap),
        Builder(builder: (context) {
          final controller = _controllers[row]
            ..parent = _parent ..gap = appearance.horizontalGap
            ..configure(apps.skip(starts[row]).take(counts[row]).map((app) => app.packageName));
          for (final app in apps.skip(starts[row]).take(counts[row])) {
            _parent?.scrollDelegates[app.packageName] = controller;
          }
          return CategoryFocus(controller: controller, child: SizedBox(
            height: height + 32,
            child: ListView.custom(
              controller: controller.scrollController,
              scrollDirection: Axis.horizontal, clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.all(16),
              itemExtent: appearance.tileSize * appearance.aspectRatio + appearance.horizontalGap,
              scrollCacheExtent: ScrollCacheExtent.pixels(appearance.tileSize * appearance.aspectRatio + appearance.horizontalGap),
              childrenDelegate: SliverChildBuilderDelegate((context, column) {
                final index = starts[row] + column;
                final app = apps[index];
                return Padding(key: ValueKey(app.packageName),
                  padding: EdgeInsets.only(right: appearance.horizontalGap),
                  child: AppCard(
                    index: index, category: widget.category, application: app,
                    autofocus: index == 0,
                    handleUpNavigationToSettings: widget.isFirstSection && row == 0,
                    isFirstInRow: column == 0, isLastInRow: column == counts[row] - 1,
                    onMove: (direction) {
                      final nextRow = direction == AxisDirection.up ? row - 1 : row + 1;
                      final target = switch(direction) {
                        AxisDirection.left => column > 0 ? index - 1 : index,
                        AxisDirection.right => column < counts[row] - 1 ? index + 1 : index,
                        _ => nextRow >= 0 && nextRow < counts.length
                          ? starts[nextRow] + min(column, counts[nextRow] - 1) : index,
                      };
                      if (target != index) {
                        final service = context.read<AppsService>();
                        service.setPendingReorderFocus(app.packageName, widget.category.id, target.toInt());
                        service.reorderApplication(widget.category, index, target.toInt());
                      }
                    },
                    onMoveEnd: widget.onMoveEnd, onMoveCancel: widget.onMoveCancel,
                  ),
                );
              }, childCount: counts[row], findChildIndexCallback: (key) {
                final package = (key as ValueKey<String>).value;
                final index = apps.indexWhere((app) => app.packageName == package) - starts[row];
                return index >= 0 && index < counts[row] ? index : null;
              }),
            ),
          ));
        }),
      ],
    ]);
  }
}
