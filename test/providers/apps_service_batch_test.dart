import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:drift/drift.dart';

import '../mocks.mocks.dart';

void main() {
  late FLauncherDatabase database;
  late MockFLauncherChannel mockChannel;
  late AppsService appsService;

  setUp(() async {
    database = FLauncherDatabase.inMemory();
    mockChannel = MockFLauncherChannel();
    when(mockChannel.addAppsChangedListener(any)).thenReturn(null);

    // Minimal mock for getApplications to avoid crash in _refreshState
    when(mockChannel.getApplications()).thenAnswer((_) async => []);

    appsService = AppsService(mockChannel, database);
    // Wait for initialization
    while (!appsService.initialized) {
      await Future.delayed(Duration(milliseconds: 10));
    }
  });

  tearDown(() async {
    appsService.dispose();
    await database.close();
  });

  test('cannot delete the final category', () async {
    // Default categories are now protected independently of the last-category guard.
    final ids = appsService.categories.map((c) => c.id).toList();
    await appsService.deleteSection(0);
    expect(appsService.categories.map((c) => c.id), ids);
    expect((await database.getCategories()).map((c) => c.id), ids);
  });

  test('failed category deletion rolls back transfers and in-memory state', () async {
    final id = await appsService.addCategory('Temporary');
    final category = appsService.categories.firstWhere((c) => c.id == id);
    final app = App(packageName: 'rollback.app', name: 'Rollback', version: '1', hidden: false);
    await database.persistApps([AppsCompanion.insert(packageName: app.packageName, name: app.name, version: app.version)]);
    await appsService.addToCategory(app, category);
    await database.customStatement("CREATE TRIGGER reject_delete BEFORE DELETE ON categories BEGIN SELECT RAISE(ABORT, 'test'); END;");
    final index = appsService.launcherSections.indexWhere((s) => s is Category && s.id == id);
    await expectLater(appsService.deleteSection(index), throwsA(anything));
    expect(app.categoryOrders.keys, [id]);
    expect(appsService.categories.any((c) => c.id == id), isTrue);
    expect((await database.getAppsCategories()).where((r) => r.appPackageName == app.packageName).single.categoryId, id);
  });

  test('Test addAllToCategory functionality', () async {
    const int numApps = 10;
    int categoryId = await appsService.addCategory("Test Category",
        shouldNotifyListeners: false);
    Category category =
        appsService.categories.firstWhere((c) => c.id == categoryId);

    List<App> appsToAdd = List.generate(
        numApps,
        (i) => App(
              packageName: 'com.example.app$i',
              name: 'App $i',
              version: '1.0.0',
              hidden: false,
            ));

    await database.persistApps(appsToAdd.map((app) => AppsCompanion(
          packageName: Value(app.packageName),
          name: Value(app.name),
          version: Value(app.version),
        )));

    await appsService.addAllToCategory(appsToAdd, category);

    expect(category.applications.length, numApps);
    for (int i = 0; i < numApps; i++) {
      expect(appsToAdd[i].categoryOrders[category.id], i);
      expect(category.applications[i].packageName, appsToAdd[i].packageName);
    }

    final dbAppsCategories = await database.getAppsCategories();
    expect(dbAppsCategories.length, numApps);
  });

  test('refreshState repairs missing AppsCategories rows in database',
      () async {
    when(mockChannel.getApplications()).thenAnswer((_) async => [
          {
            'packageName': 'com.example.app0',
            'name': 'App 0',
            'version': '1.0.0',
            'sideloaded': false
          },
          {
            'packageName': 'com.example.app1',
            'name': 'App 1',
            'version': '1.0.0',
            'sideloaded': false
          },
        ]);
    when(mockChannel.getApplicationIcon(any))
        .thenAnswer((_) async => Uint8List(0));
    when(mockChannel.getApplicationBanner(any))
        .thenAnswer((_) async => Uint8List(0));

    await database.persistApps([
      const AppsCompanion(
        packageName: Value('com.example.app0'),
        name: Value('App 0'),
        version: Value('1.0.0'),
      ),
      const AppsCompanion(
        packageName: Value('com.example.app1'),
        name: Value('App 1'),
        version: Value('1.0.0'),
      ),
    ]);

    final tvCategoryId =
        appsService.categories.firstWhere((c) => c.name == 'TV Apps').id;
    await database.insertAppsCategories([
      AppsCategoriesCompanion.insert(
        categoryId: tvCategoryId,
        appPackageName: 'com.example.app0',
        order: 0,
      ),
      AppsCategoriesCompanion.insert(
        categoryId: tvCategoryId,
        appPackageName: 'com.example.app1',
        order: 1,
      ),
    ]);
    await appsService.refreshState();

    var tvApps = appsService.categories.firstWhere((c) => c.name == 'TV Apps');
    expect(tvApps.applications.length, 2);

    await database.deleteAppCategory(tvCategoryId, 'com.example.app1');
    await appsService.refreshState();

    final repairedCategories = await database.getAppsCategories();
    final repaired = repairedCategories
        .where((row) => row.appPackageName == 'com.example.app1')
        .toList();
    expect(repaired.length, 1);
    expect(repaired.first.order, 1);

    final refreshedTvApps =
        appsService.categories.firstWhere((c) => c.name == 'TV Apps');
    expect(refreshedTvApps.applications.length, 2);
    expect(refreshedTvApps.applications[0].packageName, 'com.example.app0');
    expect(refreshedTvApps.applications[1].packageName, 'com.example.app1');
  });

  test('Test addCategory sets correct order', () async {
    int catId1 =
        await appsService.addCategory("Cat 1", shouldNotifyListeners: false);
    int catId2 =
        await appsService.addCategory("Cat 2", shouldNotifyListeners: false);

    Category cat1 = appsService.categories.firstWhere((c) => c.id == catId1);
    Category cat2 = appsService.categories.firstWhere((c) => c.id == catId2);

    expect(cat1.order, 4);
    expect(cat2.order, 5);
  });

  test(
      'deleteSection removes manual membership without adding to other sections',
      () async {
    int customCatId = await appsService.addCategory("Custom Category",
        shouldNotifyListeners: false);
    Category customCategory =
        appsService.categories.firstWhere((c) => c.id == customCatId);

    final app = App(
      packageName: 'com.example.custom_app',
      name: 'Custom App',
      version: '1.0.0',
      hidden: false,
    );

    await database.persistApps([
      const AppsCompanion(
        packageName: Value('com.example.custom_app'),
        name: Value('Custom App'),
        version: Value('1.0.0'),
      ),
    ]);

    await appsService.addToCategory(app, customCategory,
        shouldNotifyListeners: false);

    expect(customCategory.applications.map((a) => a.packageName),
        contains('com.example.custom_app'));
    expect(app.categoryOrders.containsKey(customCatId), true);

    int sectionIndex = appsService.launcherSections
        .indexWhere((s) => s.id == customCatId && s is Category);
    expect(sectionIndex, isNot(-1));

    await appsService.deleteSection(sectionIndex);

    // Section deleted
    expect(appsService.categories.any((c) => c.id == customCatId), false);
    expect(app.categoryOrders.containsKey(customCatId), false);

    expect(appsService.categories.firstWhere((category) => category.systemKey == 'favorites').applications, isEmpty);
    expect(app.categoryOrders, isEmpty);
    expect((await database.getAppsCategories()).where((row) => row.appPackageName == app.packageName), isEmpty);

  });
}
