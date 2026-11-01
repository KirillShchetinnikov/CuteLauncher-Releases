import 'dart:convert';
import 'dart:io';

import 'package:flauncher/database.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:flauncher/initial_settings_profile.dart';
import 'package:flauncher/initial_profile_restore.dart';
import 'package:flauncher/launcher_defaults.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late FLauncherDatabase database;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cute-profile-');
    database = FLauncherDatabase.inMemory();
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'clean install has explicit profile and subsequent openings preserve edits',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await initializeSettingsProfile(prefs, directory, () => database);
      final settings = SettingsService(prefs),
          appearance = AppearanceService(prefs);
      addTearDown(settings.dispose);
      addTearDown(appearance.dispose);
      expect(settings.backgroundSource, 'landscape');
      expect(settings.dateFormat, compactDateFormat);
      expect(appearance.appearance.interfaceStyle, 'glass');
      expect(appearance.appearance.labels, 'all');
      expect(appearance.appearance.focusScale, 0.05);
      expect(appearance.appearance.sectionPosition, 0.1);
      final categories = await database.getCategories();
      expect(categories.where((c) => c.visible).map((c) => c.systemKey), [
        'all_apps',
        'app_channels',
      ]);
      expect(appearance.category(categories.first.id).maxRows, 3);
      await appearance.set('labels', 'none');
      await initializeSettingsProfile(
        prefs,
        directory,
        () => throw StateError('must not reopen'),
      );
      expect(appearance.appearance.labels, 'none');
      expect(isDeviceLocalBackupKey(initialProfileStateKey), isTrue);
      expect(isDeviceLocalBackupKey(initialProfileSeedKey), isTrue);
    },
  );

  test('sparse old settings keep legacy effective defaults', () async {
    SharedPreferences.setMockInitialValues({
      'tile_appearance': '{"radius":32}',
    });
    final prefs = await SharedPreferences.getInstance();
    await initializeSettingsProfile(
      prefs,
      directory,
      () => throw StateError('must not open'),
    );
    expect(prefs.getString('tile_appearance'), '{"radius":32}');
    final appearance = AppearanceService(prefs);
    addTearDown(appearance.dispose);
    expect(appearance.appearance.interfaceStyle, 'standard');
    expect(appearance.appearance.labels, 'none');
  });

  test(
    'existing database or wallpaper with empty prefs is not a new install',
    () async {
      await File('${directory.path}/wallpaper.png').writeAsString('existing');
      final prefs = await SharedPreferences.getInstance();
      await initializeSettingsProfile(
        prefs,
        directory,
        () => throw StateError('must not open'),
      );
      expect(prefs.getString('background_source'), isNull);
      expect(prefs.getString(initialProfileStateKey), 'legacy');
    },
  );

  test(
    'interrupted profile resumes before consumers and remote never seeds',
    () async {
      final prefs = await SharedPreferences.getInstance();
      await initializeSettingsProfile(
        prefs,
        directory,
        () => database,
        primaryEngine: false,
      );
      expect(prefs.getKeys(), isEmpty);
      await prefs.setString(initialProfileStateKey, 'pending');
      await prefs.setString('tile_appearance', '{}');
      await initializeSettingsProfile(prefs, directory, () => database);
      expect(prefs.getString(initialProfileStateKey), 'complete');
      expect(jsonDecode(prefs.getString('tile_appearance')!)['labels'], 'all');
    },
  );

  test(
    'engine-created assets are not evidence of an existing install',
    () async {
      await Directory('${directory.path}/flutter_assets').create();
      await File('${directory.path}/res_timestamp-131-1793395804813').create();
      final prefs = await SharedPreferences.getInstance();
      await initializeSettingsProfile(prefs, directory, () => database);
      expect(prefs.getString(initialProfileStateKey), 'complete');
      expect(prefs.getString('background_source'), 'landscape');
    },
  );

  test('old sparse backup strips seeds but preserves actual user edits', () {
    final seeds = LauncherDefaults.preferences;
    final current = <String, dynamic>{
      ...seeds,
      initialProfileSeedKey: jsonEncode(seeds),
      'tile_appearance': jsonEncode({
        ...LauncherDefaults.appearance,
        'radius': 32,
      }),
    };
    final restored = initialProfileRestoreBaseline(current, {
      'tile_appearance': '{"opacity":0.5}',
    });
    expect(jsonDecode(restored['tile_appearance']), {'radius': 32});
    expect(restored.containsKey('background_source'), isFalse);
    final newCopy = initialProfileRestoreBaseline(current, seeds);
    expect(newCopy['background_source'], 'landscape');
    expect(jsonDecode(newCopy['tile_appearance'])['labels'], 'all');
  });
}
