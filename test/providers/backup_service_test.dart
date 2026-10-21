import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:transparent_image/transparent_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FLauncherDatabase database;
  late SharedPreferences sharedPreferences;
  late BackupService backupService;
  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
    sharedPreferences = await SharedPreferences.getInstance();
    database = FLauncherDatabase.inMemory();
    backupService = BackupService(database, sharedPreferences);

    tempDir = await Directory.systemTemp.createTemp('ltv_backup_test');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return tempDir.path;
      },
    );
  });

  tearDown(() async {
    await database.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      null,
    );
  });

  test('update notice delivery state stays local during export and import', () async {
    await database.insertCategory(CategoriesCompanion.insert(name: 'Apps', order: 0));
    await sharedPreferences.setString('update_pending_notification', 'v1.0.0+3');
    await sharedPreferences.setString('update_shown_notification', 'v1.0.0+2');
    final archive = File(await backupService.exportBackup());
    final data = jsonDecode(await archive.readAsString()) as Map<String, dynamic>;
    final settings = data['settings'] as Map;
    expect(settings.containsKey('update_pending_notification'), isFalse);
    expect(settings.containsKey('update_shown_notification'), isFalse);
    settings['update_pending_notification'] = 'v1.0.0+9';
    settings['update_shown_notification'] = 'v1.0.0+8';
    await archive.writeAsString(jsonEncode(data));
    await backupService.importBackup(archive);
    expect(sharedPreferences.getString('update_pending_notification'), 'v1.0.0+3');
    expect(sharedPreferences.getString('update_shown_notification'), 'v1.0.0+2');
  });

  test('portable backup restores wallpaper and banner without source paths', () async {
    await database.insertCategory(CategoriesCompanion.insert(name: 'TV Apps', order: 0, systemKey: const Value('tv_apps')));
    final wallpaper = File('${tempDir.path}/wallpaper');
    final originalBanner = File('${tempDir.path}/source-banner.png');
    await wallpaper.writeAsBytes(kTransparentImage);
    await originalBanner.writeAsBytes(kTransparentImage);
    await sharedPreferences.setString('custom_banner_sample.app', originalBanner.path);
    final archive = File(await backupService.exportBackup());
    final data = jsonDecode(await archive.readAsString()) as Map<String, dynamic>;
    expect((data['settings'] as Map).containsKey('custom_banner_sample.app'), isFalse);
    expect((data['resources'] as Map).keys, containsAll(['wallpaper', 'custom_banner_sample.app']));
    await wallpaper.delete();
    await originalBanner.delete();
    await sharedPreferences.remove('custom_banner_sample.app');
    await backupService.importBackup(archive);
    final restoredPath = sharedPreferences.getString('custom_banner_sample.app')!;
    expect(restoredPath, isNot(originalBanner.path));
    expect(await File(restoredPath).readAsBytes(), kTransparentImage);
    expect(await wallpaper.readAsBytes(), kTransparentImage);
    expect((await database.getCategories()).map((c) => c.systemKey), ['all_apps', 'tv_apps', 'other_apps', 'favorites']);
  });

  test('invalid resource is rejected before preferences, files and DB change', () async {
    await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final wallpaper = File('${tempDir.path}/wallpaper');
    await wallpaper.writeAsBytes(kTransparentImage);
    final data = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    data['resources'] = {'wallpaper': base64Encode([1, 2, 3])};
    data['settings'] = {'new_setting': true};
    final archive = File('${tempDir.path}/invalid-image.json');
    await archive.writeAsString(jsonEncode(data));
    await expectLater(backupService.importBackup(archive), throwsA(anything));
    expect(sharedPreferences.containsKey('new_setting'), isFalse);
    expect(await wallpaper.readAsBytes(), kTransparentImage);
    expect((await database.getCategories()).single.name, 'Original');
    expect(tempDir.listSync().whereType<Directory>(), isEmpty);
  });

  test('failed wallpaper installation rolls back files, preferences and DB', () async {
    await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final wallpaper = File('${tempDir.path}/wallpaper');
    await wallpaper.writeAsBytes(kTransparentImage);
    final data = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    data['resources'] = {'wallpaper': base64Encode(kTransparentImage), 'wallpaper_day': base64Encode(kTransparentImage)};
    data['settings'] = {'new_setting': true};
    (data['categories'] as List).first['name'] = 'Changed';
    await Directory('${tempDir.path}/wallpaper_day').create();
    final archive = File('${tempDir.path}/failed-install.json');
    await archive.writeAsString(jsonEncode(data));
    await expectLater(backupService.importBackup(archive), throwsA(anything));
    expect(sharedPreferences.containsKey('new_setting'), isFalse);
    expect(await wallpaper.readAsBytes(), kTransparentImage);
    expect((await database.getCategories()).single.name, 'Original');
    expect(tempDir.listSync().whereType<Directory>().length, 1);
  });

  test('legacy backup skips foreign banner paths and preserves local settings', () async {
    await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final data = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    data['version'] = 1;
    data.remove('resources');
    data['settings'] = {'custom_banner_sample.app': '/storage/another-tv/banner.png', 'new_setting': true};
    final archive = File('${tempDir.path}/legacy.json');
    await archive.writeAsString(jsonEncode(data));
    await backupService.importBackup(archive);
    expect(sharedPreferences.containsKey('custom_banner_sample.app'), isFalse);
    expect(sharedPreferences.getBool('new_setting'), isTrue);
  });

  test('corruption in database sections preserves existing data', () async {
    await sharedPreferences.setString('themes', 'classic');
    final id = await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final original = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    for (final section in ['apps', 'categories', 'appsCategories', 'spacers']) {
      final data = {...original, 'settings': {'themes': 'premium'}, section: 'invalid'};
      final file = File('${tempDir.path}/invalid.json');
      await file.writeAsString(jsonEncode(data));
      await expectLater(backupService.importBackup(file), throwsFormatException);
      expect(sharedPreferences.getString('themes'), 'classic');
      expect((await database.getCategories()).single.id, id);
    }
    final invalidCategory = Map<String, dynamic>.from((original['categories'] as List).single as Map)..['sort'] = 999;
    for (final data in [
      {...original, 'categories': [invalidCategory]},
      {...original, 'appsCategories': [{'categoryId': id, 'appPackageName': 'missing', 'order': 0}]},
    ]) {
      final file = File('${tempDir.path}/invalid.json');
      await file.writeAsString(jsonEncode(data));
      await expectLater(backupService.importBackup(file), throwsFormatException);
      expect(sharedPreferences.getString('themes'), 'classic');
      expect((await database.getCategories()).single.id, id);
    }
  });

  test('compatible settings import skips bad values and preserves missing current values', () async {
    await sharedPreferences.setBool('show_system_settings_in_status_bar', false);
    await sharedPreferences.setString('app_banner_shape', 'premium');
    await sharedPreferences.setString('accent_color', '123456');
    await sharedPreferences.setStringList('hidden_watch_next_program_ids', ['7']);
    final id = await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final data = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    data['settings'] = {
      'app_banner_shape': 'future-theme',
      'accent_color': 'not-a-color',
      'show_time_in_status_bar': false,
      'hidden_watch_next_program_ids': ['8', 9],
      'future_setting': ['round', 'trip'],
      'broken_future_setting': {'object': true},
    };
    (data['categories'] as List).single['name'] = 'Imported';
    final file = File('${tempDir.path}/compatible.json');
    await file.writeAsString(jsonEncode(data));
    await backupService.importBackup(file);
    expect(sharedPreferences.getBool('show_system_settings_in_status_bar'), isFalse);
    expect(sharedPreferences.getString('app_banner_shape'), 'premium');
    expect(sharedPreferences.getString('accent_color'), '123456');
    expect(sharedPreferences.getStringList('hidden_watch_next_program_ids'), ['7']);
    expect(sharedPreferences.getBool('show_time_in_status_bar'), isFalse);
    expect(sharedPreferences.getStringList('future_setting'), ['round', 'trip']);
    expect(sharedPreferences.containsKey('broken_future_setting'), isFalse);
    expect((await database.getCategories()).firstWhere((category) => category.id == id).id, id);
    expect((await database.getCategories()).firstWhere((category) => category.id == id).name, 'Imported');
    for (final settings in [null, 'broken section']) {
      data['settings'] = settings;
      await file.writeAsString(jsonEncode(data));
      await backupService.importBackup(file);
      expect(sharedPreferences.getString('app_banner_shape'), 'premium');
    }
    data.remove('settings');
    await file.writeAsString(jsonEncode(data));
    await backupService.importBackup(file);
    expect(sharedPreferences.getBool('show_system_settings_in_status_bar'), isFalse);
  });

  test('preference write failure rolls back database and newly introduced keys', () async {
    SharedPreferencesStorePlatform.instance = _FailingPreferencesStore();
    await sharedPreferences.setString('themes', 'classic');
    final id = await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final data = jsonDecode(await File(await backupService.exportBackup()).readAsString()) as Map<String, dynamic>;
    data['settings'] = {'themes': 'premium', 'new_setting': 'new', 'test_error': 'reject'};
    (data['categories'] as List).single['name'] = 'Replacement';
    final file = File('${tempDir.path}/failed-write.json');
    await file.writeAsString(jsonEncode(data));
    await expectLater(backupService.importBackup(file), throwsStateError);
    await sharedPreferences.reload();
    expect(sharedPreferences.getString('themes'), 'classic');
    expect(sharedPreferences.containsKey('new_setting'), isFalse);
    expect(sharedPreferences.containsKey('test_error'), isFalse);
    final category = (await database.getCategories()).single;
    expect(category.id, id);
    expect(category.name, 'Original');
  });

  test("Export and Import Backup preserves database and SharedPreferences settings", () async {
    // 1. Populate database and SharedPreferences
    await sharedPreferences.setBool("app_highlight_animation_enabled", false);
    await sharedPreferences.setString("themes", "modern");
    await sharedPreferences.setInt("test_int_key", 42);

    await database.persistApps([
      AppsCompanion.insert(
        packageName: "com.test.app1",
        name: "Test App 1",
        version: "1.0.0",
        hidden: const Value(false),
      ),
      AppsCompanion.insert(
        packageName: "com.test.app2",
        name: "Test App 2",
        version: "2.0.0",
        hidden: const Value(true),
      ),
    ]);

    final categoryId = await database.insertCategory(CategoriesCompanion.insert(
      name: "Custom Category",
      order: 1,
    ));

    await database.into(database.appsCategories).insert(AppsCategoriesCompanion.insert(
      categoryId: categoryId,
      appPackageName: "com.test.app1",
      order: 0,
    ));

    await database.into(database.launcherSpacers).insert(LauncherSpacersCompanion.insert(
      height: 100,
      order: 2,
    ));

    // 2. Export Backup
    final backupPath = await backupService.exportBackup();
    final backupFile = File(backupPath);
    expect(await backupFile.exists(), isTrue);

    // Verify backup JSON content
    final jsonContent = await backupFile.readAsString();
    final Map<String, dynamic> decoded = json.decode(jsonContent);
    expect(decoded["version"], 3);
    expect(decoded["settings"]["app_highlight_animation_enabled"], false);
    expect(decoded["settings"]["themes"], "modern");
    expect(decoded["settings"]["test_int_key"], 42);
    expect((decoded["apps"] as List).length, 2);
    expect((decoded["categories"] as List).length, 1);
    expect((decoded["appsCategories"] as List).length, 1);
    expect((decoded["spacers"] as List).length, 1);

    // 3. Clear database and SharedPreferences
    await sharedPreferences.clear();
    await database.transaction(() async {
      await database.customStatement('DELETE FROM apps_categories;');
      await database.customStatement('DELETE FROM launcher_spacers;');
      await database.customStatement('DELETE FROM categories;');
      await database.customStatement('DELETE FROM apps;');
    });

    expect(sharedPreferences.getKeys(), isEmpty);
    expect(await database.getApplications(), isEmpty);
    expect(await database.getCategories(), isEmpty);

    // 4. Import Backup
    await backupService.importBackup();

    // 5. Verify SharedPreferences and database restored
    expect(sharedPreferences.getBool("app_highlight_animation_enabled"), false);
    expect(sharedPreferences.getString("themes"), "modern");
    expect(sharedPreferences.getInt("test_int_key"), 42);

    final apps = await database.getApplications();
    expect(apps.length, 2);
    final app1 = apps.firstWhere((a) => a.packageName == "com.test.app1");
    expect(app1.name, "Test App 1");
    expect(app1.hidden, false);
    final app2 = apps.firstWhere((a) => a.packageName == "com.test.app2");
    expect(app2.name, "Test App 2");
    expect(app2.hidden, true);

    final categories = await database.getCategories();
    expect(categories.length, 5);
    expect(categories[0].systemKey, 'all_apps');
    expect(categories[1].name, "Custom Category");

    final appsCategories = await database.getAppsCategories();
    expect(appsCategories.length, 1);
    expect(appsCategories[0].appPackageName, "com.test.app1");
    expect(appsCategories[0].categoryId, categoryId);

    final spacers = await database.getLauncherSpacers();
    expect(spacers.length, 1);
    expect(spacers[0].height, 100);
  });
}

class _FailingPreferencesStore extends InMemorySharedPreferencesStore {
  _FailingPreferencesStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (value == 'reject') return false;
    return super.setValue(valueType, key, value);
  }
}
