import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

import 'category_appearance.dart';
import 'database.dart';
import 'launcher_defaults.dart';
import 'models/category.dart';

const initialProfileStateKey = 'initial_profile_state_v1';
const initialProfileSeedKey = 'initial_profile_seed_values_v1';

/// The marker is local to this installation, never a synced user preference.
/// A pending write is completed before any settings consumers are constructed.
Future<void> initializeSettingsProfile(
  SharedPreferences preferences,
  Directory documents,
  FLauncherDatabase Function() database, {
  bool primaryEngine = true,
}) async {
  if (preferences.getString(initialProfileStateKey) == 'complete' ||
      preferences.getString(initialProfileStateKey) == 'legacy') {
    return;
  }
  await documents.create(recursive: true);
  final lock = await File('${documents.path}/.initial-profile.lock')
      .open(mode: FileMode.append);
  await lock.lock(FileLock.blockingExclusive);
  try {
    await preferences.reload();
    final state = preferences.getString(initialProfileStateKey);
    if (state == 'complete' || state == 'legacy') return;
    if (!primaryEngine) {
      if (state == 'pending') {
        throw StateError('Initial settings are not ready');
      }
      return;
    }
    if (state != 'pending') {
      final hasFiles = await documents.list().any((entry) {
        final name = path.basename(entry.path);
        // Android's Flutter engine extracts these before invoking Dart main.
        // Every other file, including database journals and backups, is user data.
        return name != '.initial-profile.lock' &&
            !(entry is Directory && name == 'flutter_assets') &&
            !(entry is File && RegExp(r'^res_timestamp-\d+-\d+$').hasMatch(name));
      });
      if (preferences.getKeys().isNotEmpty || hasFiles) {
        // Failure to remember this classification must not block an old install.
        await preferences.setString(initialProfileStateKey, 'legacy');
        return;
      }
      // Written before opening the DB: interruption must never look like an old install.
      await _write(preferences, initialProfileStateKey, 'pending');
    }
    final db = database();
    await db.transaction(() async {
      await db.ensureStandardCategories();
      final layouts = <String, dynamic>{};
      for (final category in await db.getCategories()) {
        final visible =
            category.systemKey == 'all_apps' ||
            category.systemKey == 'app_channels';
        await db.updateCategory(
          category.id,
          CategoriesCompanion(
            visible: Value(visible),
            type: Value(
              category.systemKey == 'all_apps'
                  ? CategoryType.grid
                  : category.type,
            ),
          ),
        );
        if (category.systemKey == 'all_apps') {
          layouts['${category.id}'] = {
            'layout': 'grid',
            'columns': 6,
            'maxRows': 3,
          };
        }
      }
      for (final entry in LauncherDefaults.preferences.entries) {
        await _write(preferences, entry.key, entry.value);
      }
      await _write(preferences, categoryAppearanceKey, jsonEncode(layouts));
      await _write(
        preferences,
        initialProfileSeedKey,
        jsonEncode({
          ...LauncherDefaults.preferences,
          categoryAppearanceKey: jsonEncode(layouts),
        }),
      );
    });
    // Last: rendering and services only start after both stores are ready.
    await _write(preferences, initialProfileStateKey, 'complete');
  } finally {
    await lock.unlock();
    await lock.close();
  }
}

Future<void> _write(
  SharedPreferences preferences,
  String key,
  Object value,
) async {
  final saved = switch (value) {
    String v => await preferences.setString(key, v),
    bool v => await preferences.setBool(key, v),
    int v => await preferences.setInt(key, v),
    double v => await preferences.setDouble(key, v),
    _ => throw ArgumentError.value(value),
  };
  if (!saved) throw StateError('Could not write initial settings');
}
