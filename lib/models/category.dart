// Historical constants and enum names are preserved for upstream and serialized data compatibility.
// ignore_for_file: constant_identifier_names

/*
 * FLauncher
 * Copyright (C) 2024 Oscar Rojas
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

import 'dart:collection';

import 'app.dart';

enum LauncherSectionType
{
  Category,
  Spacer
}

enum CategorySort
{
  manual,
  alphabetical,
  lastUsed,
  mostUsed,
}

enum CategoryType
{
  row,
  grid,
}

class LauncherSection
{
  final int id;

  int order;

  LauncherSection({
    this.id = 0,
    this.order = 0
  });
}

class Category extends LauncherSection
{
  static const standardNames = {
    'all_apps': 'All Apps', 'tv_apps': 'TV Apps',
    'other_apps': 'Non-TV Apps', 'favorites': 'Favorites',
  };

  // Section identity follows systemKey; display names remain user-editable.
  static String normalizeName(String name, String? systemKey) =>
      name;

  static const systemKeys = {'all_apps', 'tv_apps', 'other_apps', 'favorites'};
  String? systemKey;
  bool visible;
  bool get isSystem => systemKey != null;
  bool get isAutomatic => const {'all_apps', 'tv_apps', 'other_apps'}.contains(systemKey);
  static const int          ColumnsCount  = 6;
  static const int          RowHeight     = 110;
  static const CategorySort Sort          = CategorySort.manual;
  static const CategoryType Type          = CategoryType.row;

  int columnsCount;

  int rowHeight;

  String name;

  CategorySort sort;

  CategoryType type;

  final List<App> applications;

  Category({
    this.systemKey,
    this.visible = true,
    required this.name,
    super.id,
    super.order,
    this.columnsCount = Category.ColumnsCount,
    this.rowHeight = Category.RowHeight,
    this.sort = Category.Sort,
    this.type = Category.Type
  }):   applications = [];

  Category.withApplications({
    this.systemKey,
    this.visible = true,
    required this.name,
    required this.applications,
    super.id,
    super.order,
    this.columnsCount = Category.ColumnsCount,
    this.rowHeight = Category.RowHeight,
    this.sort = Category.Sort,
    this.type = Category.Type
  });

  Category unmodifiable() {
    return Category.withApplications(
      systemKey: systemKey,
      visible: visible,
      name: name,
      id: id,
      order: order,
      columnsCount: columnsCount,
      rowHeight: rowHeight,
      sort: sort,
      type: type,
      applications: UnmodifiableListView(applications));
  }
}

class LauncherSpacer extends LauncherSection
{
  int height;

  LauncherSpacer({
    super.id,
    super.order,
    this.height = 0
  });
}

class ContinueWatchingSection extends LauncherSection
{
  static const int sectionId = -999;

  ContinueWatchingSection({
    super.order,
  }): super(id: sectionId);
}
