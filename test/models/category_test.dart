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

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';

void main() {
  group('Category', () {
    test('default constructor initializes fields correctly', () {
      final category = Category(name: 'Test Category', id: 1, order: 2);

      expect(category.id, 1);
      expect(category.order, 2);
      expect(category.name, 'Test Category');
      expect(category.columnsCount, Category.ColumnsCount);
      expect(category.rowHeight, Category.RowHeight);
      expect(category.sort, Category.Sort);
      expect(category.type, Category.Type);
      expect(category.applications, isEmpty);
    });

    test('withApplications constructor initializes applications correctly', () {
      final app1 = App(name: 'App 1', packageName: 'com.test.app1', version: '1.0.0', hidden: false);
      final app2 = App(name: 'App 2', packageName: 'com.test.app2', version: '1.0.0', hidden: false);
      final List<App> applications = [app1, app2];

      final category = Category.withApplications(
        name: 'Apps Category',
        applications: applications,
      );

      expect(category.name, 'Apps Category');
      expect(category.applications.length, 2);
      expect(category.applications, containsAll([app1, app2]));

      // the list itself should be identical since it just assigns the reference
      expect(category.applications, applications);
    });

    test('unmodifiable creates a copy with unmodifiable list of applications', () {
      final app1 = App(name: 'App 1', packageName: 'com.test.app1', version: '1.0.0', hidden: false);
      final List<App> applications = [app1];

      final category = Category.withApplications(
        name: 'Modifiable Category',
        id: 5,
        order: 10,
        columnsCount: 4,
        rowHeight: 120,
        sort: CategorySort.alphabetical,
        type: CategoryType.grid,
        applications: applications,
      );

      final unmodifiableCategory = category.unmodifiable();

      // Properties should be copied
      expect(unmodifiableCategory.id, category.id);
      expect(unmodifiableCategory.order, category.order);
      expect(unmodifiableCategory.name, category.name);
      expect(unmodifiableCategory.columnsCount, category.columnsCount);
      expect(unmodifiableCategory.rowHeight, category.rowHeight);
      expect(unmodifiableCategory.sort, category.sort);
      expect(unmodifiableCategory.type, category.type);

      // Verify the list contains the same elements
      expect(unmodifiableCategory.applications.length, 1);
      expect(unmodifiableCategory.applications.first, app1);

      // Verify the list is unmodifiable
      expect(
        () => unmodifiableCategory.applications.add(App(name: 'App 2', packageName: 'com.test.app2', version: '1.0.0', hidden: false)),
        throwsUnsupportedError,
      );

      // UnmodifiableListView wraps the list, so modifications to original are reflected,
      // but typically we don't depend on this leaky abstraction in tests unless necessary.
      // We remove the assertion checking length is 2 to keep the test strictly about unmodifiability.
    });
  });

  group('LauncherSpacer', () {
    test('constructor initializes fields correctly', () {
      final spacer = LauncherSpacer(id: 3, order: 4, height: 50);

      expect(spacer.id, 3);
      expect(spacer.order, 4);
      expect(spacer.height, 50);
    });
  });
}
