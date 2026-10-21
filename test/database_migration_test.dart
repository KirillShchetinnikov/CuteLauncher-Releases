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

import 'package:drift_dev/api/migrations_native.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated_migrations/schema.dart';
import 'generated_migrations/schema_v1.dart' as v1;
import 'generated_migrations/schema_v2.dart' as v2;
import 'generated_migrations/schema_v3.dart' as v3;
import 'generated_migrations/schema_v4.dart' as v4;
import 'generated_migrations/schema_v8.dart' as v8;
import 'generated_migrations/schema_v9.dart' as v9;

void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v9 migration adds empty local counters and preserves user data', () async {
    final schema = await verifier.schemaAt(9);
    final oldDb = v9.DatabaseAtV9(schema.newConnection().executor);
    await oldDb.customStatement("INSERT INTO apps (package_name,name,version,hidden,last_launched_at) VALUES ('sample','Sample','1',1,123456)");
    await oldDb.customStatement('INSERT INTO categories (id,name,"order",visible) VALUES (1,\'Personal\',0,1)');
    await oldDb.customStatement("INSERT INTO apps_categories (category_id,app_package_name,\"order\") VALUES (1,'sample',0)");
    await oldDb.customStatement('INSERT INTO launcher_spacers (id,height,"order") VALUES (1,175,1)');
    await oldDb.close();
    final db = FLauncherDatabase(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 10);
      final app = (await db.getApplications()).single;
      expect(app.launchCount, 0);
      expect(app.hidden, isTrue);
      expect(app.lastLaunchedAt, DateTime.fromMillisecondsSinceEpoch(123456000));
      expect((await db.getAppsCategories()).single.categoryId, 1);
      expect((await db.getLauncherSpacers()).single.height, 175);
    } finally { await db.close(); }
  });

  test('v8 migration preserves memberships and assigns unique stable keys', () async {
    final schema = await verifier.schemaAt(8);
    final oldDb = v8.DatabaseAtV8(schema.newConnection().executor);
    await oldDb.customStatement("INSERT INTO apps (package_name,name,version) VALUES ('sample','Sample','1')");
    await oldDb.customStatement('INSERT INTO categories (id,name,"order") VALUES (1,\'Favorites\',0),(2,\'Favorites\',1),(3,\'TV Apps\',2)');
    await oldDb.customStatement("INSERT INTO apps_categories (category_id,app_package_name,\"order\") VALUES (1,'sample',0)");
    await oldDb.close();
    final db = FLauncherDatabase(schema.newConnection());
    try {
      await verifier.migrateAndValidate(db, 10);
      final categories = await db.getCategories();
      expect(categories.map((c) => c.systemKey), ['all_apps', 'favorites', null, 'tv_apps', 'other_apps']);
      expect(categories.every((c) => c.visible), isTrue);
      expect((await db.getAppsCategories()).single.categoryId, 1);
    } finally { await db.close(); }
  });

  test("upgrade from v1 to v10", () async {
    final schema = await verifier.schemaAt(1);

    final oldDb = v1.DatabaseAtV1(schema.newConnection().executor);
    await oldDb.customStatement(
      "INSERT INTO apps (package_name, name, class_name, version) VALUES ('me.efesser.flauncher', 'FLauncher', '.MainActivity', '0.0.1');",
    );
    await oldDb.customStatement(
      "INSERT INTO categories (id, name, \"order\") VALUES (1, 'Applications', 0);",
    );
    await oldDb.customStatement(
      "INSERT INTO apps_categories (category_id, app_package_name, \"order\") VALUES (1, 'me.efesser.flauncher', 0);",
    );
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);

    final app = await db.select(db.apps).getSingle();
    final category = await (db.select(db.categories)..where((c) => c.id.equals(1))).getSingle();
    final appsCategory = await db.select(db.appsCategories).getSingle();
    expect(app.packageName, "me.efesser.flauncher");
    expect(app.name, "FLauncher");
    expect(app.version, "0.0.1");
    expect(app.hidden, false);
    expect(category.id, 1);
    expect(category.name, "Applications");
    expect(category.order, 1);
    expect(category.sort, CategorySort.manual);
    expect(category.type, CategoryType.grid);
    expect(category.columnsCount, 6);
    expect(category.rowHeight, 110);
    expect(appsCategory.appPackageName, "me.efesser.flauncher");
    expect(appsCategory.categoryId, 1);
    expect(appsCategory.order, 0);
    await db.close();
  });

  test("upgrade from v2 to v10", () async {
    final schema = await verifier.schemaAt(2);

    final oldDb = v2.DatabaseAtV2(schema.newConnection().executor);
    await oldDb.customStatement(
      "INSERT INTO apps (package_name, name, version) VALUES ('me.efesser.flauncher', 'FLauncher', '0.0.1');",
    );
    await oldDb.customStatement(
      "INSERT INTO categories (id, name, \"order\") VALUES (1, 'Applications', 0);",
    );
    await oldDb.customStatement(
      "INSERT INTO apps_categories (category_id, app_package_name, \"order\") VALUES (1, 'me.efesser.flauncher', 0);",
    );
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);

    final app = await db.select(db.apps).getSingle();
    final category = await (db.select(db.categories)..where((c) => c.id.equals(1))).getSingle();
    final appsCategory = await db.select(db.appsCategories).getSingle();
    expect(app.packageName, "me.efesser.flauncher");
    expect(app.name, "FLauncher");
    expect(app.version, "0.0.1");
    expect(app.hidden, false);
    expect(category.id, 1);
    expect(category.name, "Applications");
    expect(category.order, 1);
    expect(category.sort, CategorySort.manual);
    expect(category.type, CategoryType.grid);
    expect(category.columnsCount, 6);
    expect(category.rowHeight, 110);
    expect(appsCategory.appPackageName, "me.efesser.flauncher");
    expect(appsCategory.categoryId, 1);
    expect(appsCategory.order, 0);
    await db.close();
  });

  test("upgrade from v3 to v10", () async {
    final schema = await verifier.schemaAt(3);

    final oldDb = v3.DatabaseAtV3(schema.newConnection().executor);
    await oldDb.customStatement(
      "INSERT INTO apps (package_name, name, version) VALUES ('me.efesser.flauncher', 'FLauncher', '0.0.1');",
    );
    await oldDb.customStatement(
      "INSERT INTO categories (id, name, \"order\") VALUES (1, 'Applications', 0);",
    );
    await oldDb.customStatement(
      "INSERT INTO apps_categories (category_id, app_package_name, \"order\") VALUES (1, 'me.efesser.flauncher', 0);",
    );
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);

    final app = await db.select(db.apps).getSingle();
    final category = await (db.select(db.categories)..where((c) => c.id.equals(1))).getSingle();
    final appsCategory = await db.select(db.appsCategories).getSingle();
    expect(app.packageName, "me.efesser.flauncher");
    expect(app.name, "FLauncher");
    expect(app.version, "0.0.1");
    expect(app.hidden, false);
    expect(category.id, 1);
    expect(category.name, "Applications");
    expect(category.order, 1);
    expect(category.sort, CategorySort.manual);
    expect(category.type, CategoryType.grid);
    expect(category.columnsCount, 6);
    expect(category.rowHeight, 110);
    expect(appsCategory.appPackageName, "me.efesser.flauncher");
    expect(appsCategory.categoryId, 1);
    expect(appsCategory.order, 0);
    await db.close();
  });

  test("upgrade from v4 to v10", () async {
    final schema = await verifier.schemaAt(4);

    final oldDb = v4.DatabaseAtV4(schema.newConnection().executor);
    await oldDb.customStatement(
      "INSERT INTO apps (package_name, name, version) VALUES ('me.efesser.flauncher', 'FLauncher', '0.0.1');",
    );
    await oldDb.customStatement(
      "INSERT INTO categories (id, name, type, \"order\") VALUES (1, 'Applications', 1, 0);",
    );
    await oldDb.customStatement(
      "INSERT INTO apps_categories (category_id, app_package_name, \"order\") VALUES (1, 'me.efesser.flauncher', 0);",
    );
    await oldDb.close();

    final db = FLauncherDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 10);

    final app = await db.select(db.apps).getSingle();
    final category = await (db.select(db.categories)..where((c) => c.id.equals(1))).getSingle();
    final appsCategory = await db.select(db.appsCategories).getSingle();
    expect(app.packageName, "me.efesser.flauncher");
    expect(app.name, "FLauncher");
    expect(app.version, "0.0.1");
    expect(app.hidden, false);
    expect(category.id, 1);
    expect(category.name, "Applications");
    expect(category.order, 1);
    expect(category.sort, CategorySort.manual);
    expect(category.type, CategoryType.grid);
    expect(category.columnsCount, 6);
    expect(category.rowHeight, 110);
    expect(appsCategory.appPackageName, "me.efesser.flauncher");
    expect(appsCategory.categoryId, 1);
    expect(appsCategory.order, 0);
    await db.close();
  });
}

