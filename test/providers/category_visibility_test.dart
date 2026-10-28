import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' hide isNull;
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FLauncherDatabase db;
  late AppsService service;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = FLauncherDatabase.inMemory();
    await db.insertCategory(CategoriesCompanion.insert(name: 'Renamed TV', order: 0, systemKey: const Value('tv_apps')));
    await db.insertCategory(CategoriesCompanion.insert(name: 'My category', order: 1));
    final channel = MockFLauncherChannel();
    when(channel.getApplications()).thenAnswer((_) async => []);
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    service = AppsService(channel, db);
    for (var i = 0; i < 100 && !service.initialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(service.initialized, isTrue);
  });
  tearDown(() async { service.dispose(); await db.close(); });

  for (final key in Category.systemKeys) {
    test('$key allows renaming while preserving its key', () async {
      final existing = service.categories.where((c) => c.systemKey == key);
      final id = existing.isNotEmpty ? existing.first.id
          : await service.addCategory('Original', systemKey: key);
      final category = service.categories.firstWhere((c) => c.id == id);
      const original = 'Changed';
      await service.renameCategory(category, 'Changed');
      expect(service.categories.firstWhere((c) => c.id == id).name, original);
      expect((await db.getCategories()).firstWhere((c) => c.id == id).name, original);
      await service.updateCategory(id, 'Changed', CategorySort.alphabetical,
          category.type, category.columnsCount, category.rowHeight);
      expect(service.categories.firstWhere((c) => c.id == id).name, original);
      expect(service.categories.firstWhere((c) => c.id == id).sort, CategorySort.alphabetical);
      expect((await db.getCategories()).firstWhere((c) => c.id == id).name, original);
    });
  }

  test('custom category can still be renamed', () async {
    final category = service.categories.last;
    await service.renameCategory(category, 'Changed');
    expect(service.categories.firstWhere((c) => c.id == category.id).name, 'Changed');
    expect((await db.getCategories()).firstWhere((c) => c.id == category.id).name, 'Changed');
  });

  test('renamed system category cannot be deleted; hidden category keeps data', () async {
    final system = service.categories.first;
    await service.renameCategory(system, 'Another name');
    await service.deleteSection(0);
    expect((await db.getCategories()).length, 2);
    expect(await service.setCategoryVisible(system.id, false), isTrue);
    expect(service.visibleLauncherSections.length, 1);
    expect((await db.getCategories()).first.systemKey, 'tv_apps');
    expect(await service.setCategoryVisible(service.categories.last.id, false), isFalse);
    expect(await service.setCategoryVisible(system.id, true), isTrue);
    expect(service.visibleLauncherSections.length, 2);
  });

  test('Favorites cannot be deleted but can be hidden', () async {
    final id = await service.addCategory('Favorites', systemKey: 'favorites');
    final favorite = service.categories.firstWhere((category) => category.id == id);
    expect(favorite.isSystem, isTrue);
    final index = service.launcherSections.indexWhere((section) => section.id == id);
    await service.deleteSection(index);
    expect((await db.getCategories()).any((category) => category.id == id), isTrue);
    expect(await service.setCategoryVisible(id, false), isTrue);
  });

  test('concurrent hides leave a visible category', () async {
    await Future.wait(service.categories.map((c) => service.setCategoryVisible(c.id, false)));
    expect((await db.getCategories()).where((c) => c.visible).length, 1);
    expect(service.visibleLauncherSections.length, 1);
  });

  test('import with all categories hidden is rejected before settings change', () async {
    final prefs = await SharedPreferences.getInstance();
    final dir = await Directory.systemTemp.createTemp('category_backup');
    final file = File('${dir.path}/invalid.json');
    await file.writeAsString(jsonEncode({
      'version': 1, 'settings': {'accent_color': 123}, 'apps': [], 'appsCategories': [], 'spacers': [],
      'categories': [{'id': 1, 'name': 'Hidden', 'order': 0, 'rowHeight': 110, 'columnsCount': 6, 'sort': 0, 'type': 0, 'visible': false}],
    }));
    try {
      await expectLater(BackupService(db, prefs).importBackup(file), throwsFormatException);
      expect((await db.getCategories()).length, 2);
      expect(prefs.getInt('accent_color'), isNull);
    } finally { await dir.delete(recursive: true); }
  });
}
