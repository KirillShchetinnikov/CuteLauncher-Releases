// Benchmark and network diagnostic tests intentionally print their measurements.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';

import 'package:flauncher/database.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';

void main() {
  test('Benchmark apps categories grouping', () {
    int numApps = 2000;
    int numCategories = 10;

    List<AppCategory> appsCategories = [];
    Map<String, App> applications = {};
    Map<int, Category> categoriesById = {};

    for (int i = 0; i < numCategories; i++) {
      categoriesById[i] = Category(
        id: i,
        name: "Cat $i",
        type: CategoryType.grid,
        sort: CategorySort.manual,
        columnsCount: 4,
        rowHeight: 100,
        order: i,
      );
    }

    for (int i = 0; i < numApps; i++) {
      String pkg = "com.example.app$i";
      applications[pkg] = App(
        packageName: pkg,
        name: "App $i",
        version: "1.0",
        hidden: false,
      );
      appsCategories.add(AppCategory(
        categoryId: i % numCategories,
        appPackageName: pkg,
        order: i,
      ));
      appsCategories.add(AppCategory(
        categoryId: (i + 1) % numCategories,
        appPackageName: pkg,
        order: i,
      ));
    }

    // Original O(N*M)
    Stopwatch sw = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      for (App application in applications.values) {
        if (appsCategories.isNotEmpty && !application.hidden) {
          Iterable<AppCategory> currentApplicationCategories = appsCategories
              .where((appCategory) => appCategory.appPackageName == application.packageName);

          for (AppCategory appCategory in currentApplicationCategories) {
            if (categoriesById.containsKey(appCategory.categoryId)) {
              Category category = categoriesById[appCategory.categoryId]!;
              application.categoryOrders[category.id] = appCategory.order;
            }
          }
        }
      }
    }
    sw.stop();
    print("Original time: ${sw.elapsedMilliseconds} ms");

    // Optimized O(N+M)
    sw.reset();
    sw.start();
    for (int i = 0; i < 100; i++) {
      Map<String, List<AppCategory>> appsCategoriesByPackage = {};
      if (appsCategories.isNotEmpty) {
        for (AppCategory appCategory in appsCategories) {
          (appsCategoriesByPackage[appCategory.appPackageName] ??= []).add(appCategory);
        }
      }

      for (App application in applications.values) {
        if (appsCategories.isNotEmpty && !application.hidden) {
          List<AppCategory>? currentApplicationCategories = appsCategoriesByPackage[application.packageName];

          if (currentApplicationCategories != null) {
            for (AppCategory appCategory in currentApplicationCategories) {
              if (categoriesById.containsKey(appCategory.categoryId)) {
                Category category = categoriesById[appCategory.categoryId]!;
                application.categoryOrders[category.id] = appCategory.order;
              }
            }
          }
        }
      }
    }
    sw.stop();
    print("Optimized time: ${sw.elapsedMilliseconds} ms");
  });
}
