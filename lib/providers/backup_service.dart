import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'dart:convert';
import '../backup_validation.dart';
import '../settings_import.dart';
import '../backup_assets.dart';
import '../image_limits.dart';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupService {
  final FLauncherDatabase _database;
  final SharedPreferences _sharedPreferences;

  BackupService(this._database, this._sharedPreferences);

  /// Gets the path to the backup file.
  /// Tries Downloads folder first, falls back to external files directory.
  Future<File> getBackupFile() async {
    Directory? dir;
    try {
      dir = await getDownloadsDirectory();
    } catch (_) {
      // Ignored, fallback below
    }
    if (dir == null) {
      try {
        dir = await getExternalStorageDirectory();
      } catch (_) {
        // Ignored, fallback below
      }
    }
    if (dir == null) {
      try {
        dir = await getApplicationDocumentsDirectory();
      } catch (_) {
        // Ignored
      }
    }
    if (dir == null) {
      throw const FileSystemException("Could not find any suitable directory for backup");
    }
    return File(path.join(dir.path, 'cutelauncher_backup.json'));
  }

  Future<Directory> getBackupDirectory() async {
    final file = await getBackupFile();
    return file.parent;
  }

  /// Discovers all possible directories where backup files may reside:
  /// - App private and external storage
  /// - Standard Android /sdcard/Download directories
  /// - Mounted USB drives (/storage/*)
  Future<List<Directory>> getSearchDirectories() async {
    final Set<String> paths = {};
    final List<Directory> dirs = [];

    void addDir(Directory? dir) {
      if (dir != null && paths.add(dir.path)) {
        dirs.add(dir);
      }
    }

    try {
      addDir(await getDownloadsDirectory());
    } catch (_) {}
    try {
      addDir(await getExternalStorageDirectory());
    } catch (_) {}
    try {
      addDir(await getApplicationDocumentsDirectory());
    } catch (_) {}

    final standardPaths = [
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Downloads',
      '/sdcard/Download',
      '/sdcard/Downloads',
      '/storage/emulated/0',
      '/sdcard',
    ];

    for (final p in standardPaths) {
      final d = Directory(p);
      if (d.existsSync()) {
        addDir(d);
      }
    }

    // Scan mounted USB drives and external volumes in /storage
    try {
      final storageDir = Directory('/storage');
      if (storageDir.existsSync()) {
        for (final entity in storageDir.listSync()) {
          if (entity is Directory) {
            final name = path.basename(entity.path);
            if (name != 'self' && name != 'emulated' && name != 'knox-emulated') {
              addDir(entity);
              final usbDownload = Directory(path.join(entity.path, 'Download'));
              if (usbDownload.existsSync()) {
                addDir(usbDownload);
              }
            }
          }
        }
      }
    } catch (_) {}

    return dirs;
  }

  /// Gets the list of available backup files across all search locations.
  Future<List<BackupFileEntry>> getBackupFiles() async {
    final List<Directory> searchDirs = await getSearchDirectories();
    final List<BackupFileEntry> entries = [];
    final Set<String> seenPaths = {};

    for (final dir in searchDirs) {
      if (!await dir.exists()) continue;
      try {
        await for (final entity in dir.list()) {
          if (entity is File && seenPaths.add(entity.path)) {
            final name = path.basename(entity.path);
            if ((name.startsWith('cutelauncher_backup') || name.startsWith('ltv_backup') || name.startsWith('flauncher_backup')) && name.endsWith('.json')) {
              try {
                final lastModified = await entity.lastModified();
                final size = await entity.length();
                entries.add(BackupFileEntry(
                  file: entity,
                  name: name,
                  lastModified: lastModified,
                  size: size,
                ));
              } catch (_) {}
            }
          }
        }
      } catch (_) {}
    }

    // Sort by modification date (newest first)
    entries.sort((a, b) => b.lastModified.compareTo(a.lastModified));
    return entries;
  }

  /// Exports categories, apps, spacers, and settings to a JSON file.
  Future<String> exportBackup([SettingsService? settingsService]) async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final now = DateTime.now();
    final timestamp = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_"
        "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    final filename = 'cutelauncher_backup_$timestamp.json';
    final File file = File(path.join(dir.path, filename));

    await writeBackupTo(file, settingsService: settingsService);
    return file.path;
  }

  Future<void> _operation = Future<void>.value();
  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final previous = _operation;
    final done = Completer<void>();
    _operation = done.future;
    await previous;
    try { return await action(); } finally { done.complete(); }
  }

  /// Write a portable archive to an explicitly chosen staging file.
  Future<void> writeBackupTo(File file, {SettingsService? settingsService,
      bool validateStructure = false}) => _exclusive(() => _writeBackupTo(file,
        settingsService: settingsService, validateStructure: validateStructure));

  Future<void> _writeBackupTo(File file, {SettingsService? settingsService,
      bool validateStructure = false}) async {
    // 1. Fetch complete settings
    final Map<String, dynamic> settingsMap = {};
    if (settingsService != null) {
      settingsMap.addAll(settingsService.exportSettingsMap());
    }
    final Set<String> keys = _sharedPreferences.getKeys();
    for (final key in keys) {
      if (isDeviceLocalBackupKey(key)) continue;
      final value = _sharedPreferences.get(key);
      if (value != null) {
        settingsMap[key] = value;
      }
    }

    // 2. Fetch database tables
    final (categories, apps, appsCategories, spacers) = await _database.transaction(() async => (
      await _database.getCategories(), await _database.getApplications(),
      await _database.getAppsCategories(), await _database.getLauncherSpacers(),
    ));

    final resources = await exportBackupAssets(await getApplicationDocumentsDirectory(), settingsMap);
    // 3. Serialize everything
    final Map<String, dynamic> backupData = {
      "version": 3,
      "resources": resources,
      "settings": settingsMap,
      "apps": apps.map((a) => {
        "packageName": a.packageName,
        "name": a.name,
        "version": a.version,
        "hidden": a.hidden,
        "lastLaunchedAt": a.lastLaunchedAt?.millisecondsSinceEpoch,
      }).toList(),
      "categories": categories.map((c) => {
        "id": c.id,
        "name": c.name,
        "systemKey": c.systemKey,
        "visible": c.visible,
        "sort": c.sort.index,
        "type": c.type.index,
        "rowHeight": c.rowHeight,
        "columnsCount": c.columnsCount,
        "order": c.order,
      }).toList(),
      "appsCategories": appsCategories.map((ac) => {
        "categoryId": ac.categoryId,
        "appPackageName": ac.appPackageName,
        "order": ac.order,
      }).toList(),
      "spacers": spacers.map((s) => {
        "id": s.id,
        "height": s.height,
        "order": s.order,
      }).toList(),
    };

    if (validateStructure) validateBackup(backupData);
    final bytes = await compute(_encodeBackup, backupData);
    await file.writeAsBytes(bytes, flush: true);
  }

  /// Imports categories, apps, spacers, and settings from the JSON file.
  /// If [file] is not provided, tries to import the latest backup file.
  Future<void> importBackup([File? file, SettingsService? settingsService]) =>
      _exclusive(() => _importBackup(file, settingsService));
  Future<void> replaceBackup(File file, SettingsService settings) =>
      _exclusive(() => _importBackup(file, settings, replaceSettings: true));

  Future<void> _importBackup(File? file, SettingsService? settingsService, {bool replaceSettings = false}) async {
    File? backupFile = file;
    if (backupFile == null) {
      final List<BackupFileEntry> backups = await getBackupFiles();
      if (backups.isEmpty) {
        throw FileNotFoundException("No backup files found");
      }
      backupFile = backups.first.file;
    }
    if (!await backupFile.exists()) {
      throw FileNotFoundException("Backup file not found at ${backupFile.path}");
    }

    if (await backupFile.length() > maximumBackupBytes) throw const FormatException('Backup exceeds 64 MiB');
    final String jsonStr = utf8.decode(await readBoundedImage(backupFile.openRead(), limit: maximumBackupBytes));
    final Map<String, dynamic> backupData = json.decode(jsonStr) as Map<String, dynamic>;

    if (![1, 2, 3].contains(backupData["version"])) {
      throw FormatException("Invalid backup file version");
    }

    final settingsSchema = SettingsService(_sharedPreferences);
    final expected = {
      for (final key in _sharedPreferences.getKeys()) key: _sharedPreferences.get(key),
      ...settingsSchema.exportSettingsMap(),
    };
    settingsSchema.dispose();
    if (replaceSettings) {
      expected['tile_appearance'] = '{}';
      expected['category_appearance'] = '{}';
    }
    validateBackup(backupData);
    final settingsMap = compatibleSettings(backupData['settings'], expected);
    final assets = await BackupAssets.prepare(await getApplicationDocumentsDirectory(), backupData['version'] == 3 ? backupData['resources'] : null, settingsMap);
    final previous = {for (final key in _sharedPreferences.getKeys()) key: _sharedPreferences.get(key)};
    try {
    // 2. Restore database tables in a single transaction
    await _database.transaction(() async {
      // Clear existing records
      await _database.customStatement('DELETE FROM apps_categories;');
      await _database.customStatement('DELETE FROM launcher_spacers;');
      await _database.customStatement('DELETE FROM categories;');
      await _database.customStatement('DELETE FROM apps;');

      // Insert Apps
      final List<dynamic> appsJson = backupData["apps"] as List;
      final List<AppsCompanion> appsCompanions = appsJson.map((a) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(a as Map);
        final int? lla = map["lastLaunchedAt"] as int?;
        return AppsCompanion(
          packageName: Value(map["packageName"] as String),
          name: Value(map["name"] as String),
          version: Value(map["version"] as String),
          hidden: Value(map["hidden"] as bool),
          lastLaunchedAt: Value(lla != null ? DateTime.fromMillisecondsSinceEpoch(lla) : null),
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.apps, appsCompanions);
      });

      // Insert Categories
      final List<dynamic> categoriesJson = backupData["categories"] as List;
      final List<CategoriesCompanion> categoriesCompanions = categoriesJson.map((c) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(c as Map);
        return CategoriesCompanion(
          systemKey: Value(map['systemKey'] as String?),
          visible: Value(map['visible'] as bool? ?? true),
          id: Value(map["id"] as int),
          name: Value(map["name"] as String),
          sort: Value(CategorySort.values[map["sort"] as int]),
          type: Value(CategoryType.values[map["type"] as int]),
          rowHeight: Value(map["rowHeight"] as int),
          columnsCount: Value(map["columnsCount"] as int),
          order: Value(map["order"] as int),
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.categories, categoriesCompanions);
      });
      if (backupData['version'] == 1) await _database.assignLegacySystemKeys();
      await _database.ensureAllAppsCategory();

      // Insert AppsCategories
      final List<dynamic> appsCategoriesJson = backupData["appsCategories"] as List;
      final List<AppsCategoriesCompanion> appsCategoriesCompanions = appsCategoriesJson.map((ac) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(ac as Map);
        return AppsCategoriesCompanion(
          categoryId: Value(map["categoryId"] as int),
          appPackageName: Value(map["appPackageName"] as String),
          order: Value(map["order"] as int),
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.appsCategories, appsCategoriesCompanions);
      });

      // Insert Spacers
      final List<dynamic> spacersJson = backupData["spacers"] as List;
      final List<LauncherSpacersCompanion> spacersCompanions = spacersJson.map((s) {
        final Map<String, dynamic> map = Map<String, dynamic>.from(s as Map);
        return LauncherSpacersCompanion(
          id: Value(map["id"] as int),
          height: Value(map["height"] as int),
          order: Value(map["order"] as int),
        );
      }).toList();
      await _database.batch((batch) {
        batch.insertAll(_database.launcherSpacers, spacersCompanions);
      });
      await _database.ensureStandardCategories();
      if (replaceSettings) {
        for (final key in _sharedPreferences.getKeys()) {
          if (!isDeviceLocalBackupKey(key) && !settingsMap.containsKey(key)) {
            if (!await _sharedPreferences.remove(key)) throw StateError('Could not reset setting');
          }
        }
      }
      await _writeSettings(settingsMap);
      await assets.installWallpapers(replace: replaceSettings);
    });
    } catch (_) {
      try {
        await assets.rollback();
      } finally {
      for (final key in settingsMap.keys) {
        if (!previous.containsKey(key)) await _sharedPreferences.remove(key);
      }
      await _writeSettings(previous);
      settingsService?.reload();
      }
      rethrow;
    }
    // Cleanup cannot turn a committed, successful restore into an apparent failure.
    try { await assets.finish(); } on FileSystemException { /* Retryable leftover staging files. */ }
    settingsService?.reload();
  }

  Future<void> _writeSettings(Map<String, dynamic> settings) async {
    for (final entry in settings.entries) {
      final value = entry.value;
      final bool saved;
      if (value is bool) {
        saved = await _sharedPreferences.setBool(entry.key, value);
      } else if (value is int) {
        saved = await _sharedPreferences.setInt(entry.key, value);
      } else if (value is double) {
        saved = await _sharedPreferences.setDouble(entry.key, value);
      } else if (value is String) {
        saved = await _sharedPreferences.setString(entry.key, value);
      } else {
        saved = await _sharedPreferences.setStringList(entry.key, (value as List).cast<String>());
      }
      if (!saved) throw StateError('Could not save setting ${entry.key}');
    }
  }

}

class BackupFileEntry {
  final File file;
  final String name;
  final DateTime lastModified;
  final int size;

  BackupFileEntry({
    required this.file,
    required this.name,
    required this.lastModified,
    required this.size,
  });
}

class FileNotFoundException implements Exception {
  final String message;
  FileNotFoundException(this.message);
  @override
  String toString() => message;
}

List<int> _encodeBackup(Map<String, dynamic> data) {
  final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(data));
  if (bytes.length > maximumBackupBytes) throw const FormatException('Backup exceeds 64 MiB');
  return bytes;
}
