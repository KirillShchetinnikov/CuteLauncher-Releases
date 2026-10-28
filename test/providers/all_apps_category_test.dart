import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('reopening preserves renamed standard sections and their data', () async {
    final dir = await Directory.systemTemp.createTemp('standard-names');
    final file = File('${dir.path}/db');
    FLauncherDatabase open() => FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    var db = open();
    try {
      await db.persistApps([AppsCompanion.insert(packageName: 'sample', name: 'Sample', version: '1')]);
      final ids = <String, int>{};
      for (final key in Category.systemKeys) {
        ids[key] = await db.insertCategory(CategoriesCompanion.insert(
          name: 'Телеканалы $key', systemKey: Value(key), order: ids.length,
          visible: const Value(false), columnsCount: const Value(8)));
      }
      final customId = await db.insertCategory(CategoriesCompanion.insert(name: 'Телеканалы', order: 4));
      await db.insertAppsCategories([AppsCategoriesCompanion.insert(
        categoryId: ids['favorites']!, appPackageName: 'sample', order: 7)]);
      await db.close();
      db = open();
      final categories = await db.getCategories();
      for (final key in Category.systemKeys) {
        final category = categories.firstWhere((c) => c.id == ids[key]);
        expect(category.name, 'Телеканалы $key');
        expect(category.order, Category.systemKeys.toList().indexOf(key));
        expect(category.visible, isFalse);
        expect(category.columnsCount, 8);
      }
      expect(categories.firstWhere((c) => c.id == customId).name, 'Телеканалы');
      final link = (await db.getAppsCategories()).single;
      expect(link.categoryId, ids['favorites']);
      expect(link.order, 7);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
      'existing database adds all apps once and preserves section order and membership',
      () async {
    final dir = await Directory.systemTemp.createTemp('all-apps-migration');
    final file = File('${dir.path}/db');
    FLauncherDatabase open() =>
        FLauncherDatabase(DatabaseConnection(NativeDatabase(file)));
    var db = open();
    try {
      await db.persistApps(
          [AppsCompanion.insert(packageName: 'a', name: 'A', version: '1')]);
      final id = await db.insertCategory(CategoriesCompanion.insert(
          name: 'Favorites', order: 0, systemKey: const Value('favorites')));
      await db
          .insertSpacer(LauncherSpacersCompanion.insert(height: 20, order: 1));
      await db
          .insertCategory(CategoriesCompanion.insert(name: 'Custom', order: 2));
      await db.insertAppsCategories([
        AppsCategoriesCompanion.insert(
            categoryId: id, appPackageName: 'a', order: 0)
      ]);
      await db.close();
      db = open();
      expect((await db.getCategories()).map((c) => c.name),
          ['All Apps', 'Favorites', 'Custom', 'TV Apps', 'Non-TV Apps']);
      expect((await db.getCategories()).map((c) => c.order), [0, 1, 3, 4, 5]);
      expect((await db.getLauncherSpacers()).single.order, 2);
      expect((await db.getAppsCategories()).single.categoryId, id);
      await db.ensureAllAppsCategory();
      expect((await db.getCategories()).length, 5);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });

  test(
      'fresh install combines app types, excludes hidden and includes self, tracks app events',
      () async {
    final db = FLauncherDatabase.inMemory();
    final channel = MockFLauncherChannel();
    final events = StreamController<Map<String, dynamic>>.broadcast();
    final apps = [
      {
        'packageName': 'tv',
        'name': 'Zulu',
        'version': '1',
        'sideloaded': false
      },
      {
        'packageName': 'other',
        'name': 'Alpha',
        'version': '1',
        'sideloaded': true
      },
      {
        'packageName': 'self',
        'name': 'Self',
        'system': true,
        'version': '1',
        'sideloaded': false
      },
    ];
    when(channel.getApplications()).thenAnswer((_) async => apps);
    when(channel.addAppsChangedListener(any)).thenAnswer(
        (call) => events.stream.listen(call.positionalArguments[0]));
    final service = AppsService(channel, db, ownPackageName: 'self');
    try {
      for (var i = 0; i < 200 && !service.initialized; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(service.initialized, isTrue);
      final all =
          service.categories.firstWhere((c) => c.systemKey == 'all_apps');
      expect(all.order, 0);
      expect(all.applications.map((a) => a.packageName), ['other', 'self', 'tv']);
      expect(service.getApp('self')!.isSystem, isTrue);
      expect(service.getApp('other')!.isSystem, isFalse);
      final other = service.getApp('other')!;
      await service.addCategory('Custom');
      final custom = service.categories.firstWhere((c) => c.name == 'Custom');
      await service.addToCategory(other, custom);
      await service.toggleFavorite(other);
      final membership = await db.getAppsCategories();
      var changes = 0;
      void changed() => changes++;
      service.addListener(changed);
      await service.addToCategory(other, all);
      await service.removeFromCategory(other, all);
      service.removeListener(changed);
      expect(changes, 0, reason: 'All Apps membership cannot be edited');
      expect(service.categories.first.applications.map((a) => a.packageName),
          ['other', 'self', 'tv']);
      expect(await db.getAppsCategories(), membership);
      await service.hideApplication(other);
      expect(service.categories.where((category) => category.isAutomatic).every((category) =>
          category.applications.every((app) => app.packageName != 'other')), isTrue);
      expect(service.categories.firstWhere((category) => category.id == custom.id)
          .applications.map((app) => app.packageName), contains('other'));
      expect(service.isAppInFavorites(other), isTrue);
      expect(await db.getAppsCategories(), membership,
          reason: 'Global hiding must preserve saved category membership');
      await service.showApplication(other);
      expect(service.categories.firstWhere((c) => c.id == custom.id)
          .applications.map((a) => a.packageName), contains('other'));
      expect(service.isAppInFavorites(other), isTrue);
      await service.hideApplication(other);
      expect(service.categories.first.applications.map((a) => a.packageName),
          ['self', 'tv']);
      events.add({'action': 'PACKAGE_REMOVED', 'packageName': 'tv'});
      for (var i = 0; i < 100 && service.getApp('tv') != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(service.categories.first.applications.map((a) => a.packageName), ['self']);
    } finally {
      service.dispose();
      await events.close();
      await db.close();
    }
  });
}
