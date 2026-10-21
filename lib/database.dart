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

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';

part 'database.drift.dart';

@UseRowClass(App)
class Apps extends Table
{
  TextColumn get packageName => text()();

  TextColumn get name => text()();

  TextColumn get version => text()();

  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  IntColumn get launchCount => integer().withDefault(const Constant(0))();

  DateTimeColumn get lastLaunchedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {packageName};
}

@UseRowClass(Category)
class Categories extends Table
{
  TextColumn get systemKey => text().nullable().unique()();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  IntColumn get sort => intEnum<CategorySort>().withDefault(const Constant(0))();

  IntColumn get type => intEnum<CategoryType>().withDefault(const Constant(0))();

  IntColumn get rowHeight => integer().withDefault(const Constant(110))();

  IntColumn get columnsCount => integer().withDefault(const Constant(6))();

  IntColumn get order => integer()();
}

@UseRowClass(LauncherSpacer)
class LauncherSpacers extends Table
{
  IntColumn get id => integer().autoIncrement()();

  IntColumn get height => integer()();

  IntColumn get order => integer()();
}

@DataClassName("AppCategory")
class AppsCategories extends Table
{
  IntColumn get categoryId => integer().customConstraint("REFERENCES categories(id) ON DELETE CASCADE")();

  TextColumn get appPackageName => text().customConstraint("REFERENCES apps(package_name) ON DELETE CASCADE")();

  IntColumn get order => integer()();

  @override
  Set<Column> get primaryKey => {categoryId, appPackageName};
}

@DriftDatabase(tables: [Apps, Categories, AppsCategories, LauncherSpacers])
class FLauncherDatabase extends _$FLauncherDatabase
{
  late final bool wasCreated;

  FLauncherDatabase(DatabaseConnection super.databaseConnection);

  FLauncherDatabase.inMemory() : super(LazyDatabase(() => NativeDatabase.memory()));

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from <= 1 && to >= 2) {
            // Drift requires TableMigration for these existing data-preserving upgrades.
            // ignore: experimental_member_use
            await migrator.alterTable(TableMigration(
              apps,
              newColumns: [
                apps.hidden,
                if (to >= 8) apps.lastLaunchedAt,
                if (to >= 10) apps.launchCount,
              ],
            ));
          }
          if (from <= 2 && from != 1 && to >= 3) {
            await migrator.addColumn(apps, apps.hidden);
          }
          if (from <= 3 && to >= 4) {
            await migrator.addColumn(categories, categories.sort);
            await migrator.addColumn(categories, categories.type);
            await migrator.addColumn(categories, categories.rowHeight);
            await migrator.addColumn(categories, categories.columnsCount);
            await (update(categories)..where((tbl) => tbl.name.equals("Applications")))
                .write(const CategoriesCompanion(type: Value(CategoryType.grid)));
          }
          if (from < 6 && to >= 6) {
            final columns = await customSelect("PRAGMA table_info(apps);").get();
            final hasBanner = columns.any((row) => row.read<String>('name') == 'banner');
            final hasIcon = columns.any((row) => row.read<String>('name') == 'icon');
            if (hasBanner) {
              await customStatement("ALTER TABLE apps DROP COLUMN banner;");
            }
            if (hasIcon) {
              await customStatement("ALTER TABLE apps DROP COLUMN icon;");
            }
          }
          if (from < 7 && to >= 7) {
            await migrator.createTable(launcherSpacers);
            final columns = await customSelect("PRAGMA table_info(apps);").get();
            final hasSideloaded = columns.any((row) => row.read<String>('name') == 'sideloaded');
            if (hasSideloaded) {
              await migrator.dropColumn(apps, "sideloaded");
            }
          }
          if (from < 8 && from != 1 && to >= 8) {
            await migrator.addColumn(apps, apps.lastLaunchedAt);
          }
          if (from < 9 && to >= 9) {
            // Drift requires TableMigration for these existing data-preserving upgrades.
            // ignore: experimental_member_use
            await migrator.alterTable(TableMigration(categories,
              newColumns: [categories.systemKey, categories.visible]));
            await assignLegacySystemKeys();
          }
          if (from < 10 && from != 1 && to >= 10) {
            await migrator.addColumn(apps, apps.launchCount);
          }
        },
        beforeOpen: (openingDetails) async {
          await customStatement('PRAGMA foreign_keys = ON;');
          await customStatement('PRAGMA journal_mode = WAL;');
          wasCreated = openingDetails.wasCreated;
          if (!openingDetails.wasCreated) await ensureStandardCategories();
        },
      );

  Future<void> persistApps(Iterable<AppsCompanion> applications) =>
      batch((batch) => batch.insertAllOnConflictUpdate(apps, applications));

  /// Add once, preserving the relative order and contents of existing sections.
  Future<void> ensureAllAppsCategory() => transaction(() async {
    if ((await (select(categories)..where((c) => c.systemKey.equals('all_apps'))).get()).isNotEmpty) return;
    await customStatement('UPDATE categories SET "order" = "order" + 1');
    await customStatement('UPDATE launcher_spacers SET "order" = "order" + 1');
    await insertCategory(CategoriesCompanion.insert(name: 'All Apps', order: 0,
      systemKey: const Value('all_apps'), type: const Value(CategoryType.grid),
      sort: const Value(CategorySort.alphabetical)));
  });

  /// Restore missing protected sections without reusing names or memberships.
  Future<void> ensureStandardCategories() => transaction(() async {
    await ensureAllAppsCategory();
    final existing = await getCategories();
    final keys = existing.map((category) => category.systemKey).toSet();
    for (final category in existing) {
      final name = Category.normalizeName(category.name, category.systemKey);
      if (name != category.name) {
        await updateCategory(category.id, CategoriesCompanion(name: Value(name)));
      }
    }
    final orders = [
      ...existing.map((category) => category.order),
      ...(await getLauncherSpacers()).map((spacer) => spacer.order),
    ];
    var order = orders.fold<int>(-1, (maximum, value) => value > maximum ? value : maximum) + 1;
    for (final entry in const {'tv_apps': 'TV Apps', 'other_apps': 'Non-TV Apps', 'favorites': 'Favorites'}.entries) {
      if (keys.contains(entry.key)) continue;
      await insertCategory(CategoriesCompanion.insert(
        name: entry.value, order: order++, systemKey: Value(entry.key),
        type: Value(entry.key == 'tv_apps' ? CategoryType.grid : Category.Type),
      ));
    }
  });

  Future<void> assignLegacySystemKeys() async {
    for (final entry in {'tv_apps': ['TV Apps', 'TV Applications'], 'other_apps': ['Non-TV Apps', 'Non-TV Applications'], 'favorites': ['Favorites']}.entries) {
      await customStatement('UPDATE categories SET system_key = ? WHERE id = (SELECT MIN(id) FROM categories WHERE name IN (${List.filled(entry.value.length, '?').join(',')}) AND system_key IS NULL) AND NOT EXISTS (SELECT 1 FROM categories WHERE system_key = ?)', [entry.key, ...entry.value, entry.key]);
    }
  }

  Future<void> updateApp(String packageName, AppsCompanion value) =>
      (update(apps)..where((tbl) => tbl.packageName.equals(packageName))).write(value);

  Future<void> deleteApps(List<String> packageNames) =>
      (delete(apps)..where((tbl) => tbl.packageName.isIn(packageNames))).go();

  Future<int> insertCategory(Insertable<Category> category) => into(categories).insert(category);

  Future<void> deleteCategory(int id) => (delete(categories)..where((tbl) => tbl.id.equals(id))).go();

  Future<void> updateCategories(List<CategoriesCompanion> values) => batch(
        (batch) {
          for (final value in values) {
            batch.update<$CategoriesTable, Category>(
              categories,
              value,
              where: (table) => (table.id.equals(value.id.value)),
            );
          }
        },
      );

  Future<void> updateCategory(int id, CategoriesCompanion value) =>
      (update(categories)..where((tbl) => tbl.id.equals(id))).write(value);

  Future<void> deleteAppCategory(int categoryId, String packageName) => (delete(appsCategories)
        ..where((tbl) => tbl.categoryId.equals(categoryId) & tbl.appPackageName.equals(packageName)))
      .go();

  Future<void> insertAppsCategories(List<AppsCategoriesCompanion> value) =>
      batch((batch) => batch.insertAll(appsCategories, value, mode: InsertMode.insertOrIgnore));

  Future<void> replaceAppsCategories(List<AppsCategoriesCompanion> value) =>
      batch((batch) => batch.replaceAll(appsCategories, value));

  Future<int> insertSpacer(Insertable<LauncherSpacer> spacer) => into(launcherSpacers).insert(spacer);

  Future<int> deleteSpacer(int spacerId) => (delete(launcherSpacers)..where(
          (spacer) => spacer.id.equals(spacerId))).go();

  Future<int> updateSpacer(int spacerId, Insertable<LauncherSpacer> insertable) => (update(launcherSpacers)..where(
          (spacer) => spacer.id.equals(spacerId))).write(insertable);

  Future<void> updateSpacers(Iterable<LauncherSpacersCompanion> values) => batch(
        (batch) {
          for (final value in values) {
            batch.update<$LauncherSpacersTable, LauncherSpacer>(
              launcherSpacers,
              value,
              where: (table) => (table.id.equals(value.id.value)),
            );
          }
        }
      );

  Future<List<Category>> getCategories()
  {
    final query = select(categories);
    query.orderBy([ (c) => OrderingTerm.asc(c.order) ]);

    return query.get();
  }

  Future<List<LauncherSpacer>> getLauncherSpacers()
  {
    final query = select(launcherSpacers);
    query.orderBy([ (s) => OrderingTerm.asc(s.order) ]);

    return query.get();
  }

  Future<List<AppCategory>> getAppsCategories() {
    final query = select(appsCategories);
    query.orderBy([ (c) => OrderingTerm.asc(c.appPackageName) ]);

    return query.get();
  }

  Future<List<App>> getApplications() {
    return select(apps).get();
  }

  Future<int?> nextAppCategoryOrder(int categoryId) async {
    final query = selectOnly(appsCategories);
    final maxExpression = coalesce([appsCategories.order.max(), const Constant(-1)]) + const Constant(1);
    query.addColumns([maxExpression]);
    query.where(appsCategories.categoryId.equals(categoryId));
    final result = await query.getSingle();
    return result.read(maxExpression);
  }
}

DatabaseConnection connect() => DatabaseConnection.delayed(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(path.join(dbFolder.path, 'db.sqlite'));
      return DatabaseConnection(NativeDatabase(file, logStatements: foundation.kDebugMode));
    }());
