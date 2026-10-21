// Benchmark and network diagnostic tests intentionally print their measurements.
// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/models/category.dart';

void main() {
  test('Benchmark _findTargetCategoryForNewApp optimization', () {
    int numCategories = 100;
    Map<int, Category> categoriesById = {};

    for (int i = 0; i < numCategories; i++) {
      categoriesById[i] = Category(
        id: i,
        name: i == numCategories - 2 ? "TV Apps" : (i == numCategories - 1 ? "Non-TV Apps" : "Cat $i"),
        type: CategoryType.grid,
        sort: CategorySort.manual,
        columnsCount: 4,
        rowHeight: 100,
        order: i,
      );
    }

    Map<String, Category>? categoriesByNameCache;
    Category? fallbackCategoryCache;


    Category? findTargetCategoryForNewAppOptimized(bool isSideloaded) {
      if (categoriesById.isEmpty) return null;

      if (categoriesByNameCache == null) {
        categoriesByNameCache = {};
        for (var c in categoriesById.values) {
          categoriesByNameCache!.putIfAbsent(c.name.toLowerCase(), () => c);
        }

        try {
          fallbackCategoryCache = categoriesById.values.firstWhere(
            (c) => c.name.toLowerCase() != 'favorites',
            orElse: () => categoriesById.values.first,
          );
        } catch (_) {
          fallbackCategoryCache = null;
        }
      }

      final targetName = isSideloaded ? "non-tv apps" : "tv apps";
      return categoriesByNameCache![targetName] ?? fallbackCategoryCache;
    }

    // Measure Optimized
    Stopwatch sw = Stopwatch()..start();
    for (int i = 0; i < 100000; i++) {
      findTargetCategoryForNewAppOptimized(false);
      findTargetCategoryForNewAppOptimized(true);
    }
    sw.stop();
    print("Optimized time: ${sw.elapsedMilliseconds} ms");
  });
}
