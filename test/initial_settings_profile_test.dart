import 'dart:convert';
import 'dart:io';

import 'package:flauncher/database.dart';
import 'package:flauncher/category_appearance.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:flauncher/initial_settings_profile.dart';
import 'package:flauncher/initial_profile_restore.dart';
import 'package:flauncher/launcher_defaults.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/tile_appearance.dart';
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
      expect(settings.dateFormat, shortWeekdayDateFormat);
      expect(
        formatLauncherDate(settings.dateFormat, DateTime(2026, 11, 10), 'ru'),
        'Вт, 10 Нояб',
      );
      expect(settings.accentColorHex, 'FF6D00');
      expect(settings.settingsMenuOnRight, isFalse);
      expect(appearance.appearance.interfaceStyle, 'standard');
      expect(appearance.appearance.interfaceFont, 'medeo-sans');
      expect(appearance.appearance.panelFont, 'medeo-sans');
      expect(appearance.appearance.number('settingsColor'), 0xff393939);
      expect(appearance.appearance.number('settingsTextSize'), 16);
      expect(
        appearance.appearance.settingsScrollbarMode,
        SettingsScrollbarMode.onScroll,
      );
      expect(appearance.appearance.labels, 'none');
      expect(appearance.appearance.horizontalGap, 6);
      expect(appearance.appearance.verticalGap, 6);
      expect(appearance.appearance.focusScale, 0.2);
      expect(appearance.appearance.focusBorderStyle(), 'glow');
      expect(appearance.appearance.dynamicFocusColor, isTrue);
      expect(appearance.appearance.values['focusPulse'], isTrue);
      expect(appearance.appearance.sectionTitles, isTrue);
      expect(appearance.appearance.sectionIcons, isTrue);
      expect(appearance.appearance.sectionPosition, 0.2);
      expect(settings.landscape.motion, isTrue);
      expect(settings.landscape.precipitation, isTrue);
      expect(settings.landscape.fog, isTrue);
      expect(settings.landscape.starRotation, isTrue);
      expect(
        TileAppearance.validValues(LauncherDefaults.appearance),
        LauncherDefaults.appearance,
      );
      final categories = await database.getCategories();
      expect(categories.where((c) => c.visible).map((c) => c.systemKey), [
        'all_apps',
        'app_channels',
      ]);
      expect(appearance.category(categories.first.id).maxRows, 3);
      await appearance.set('labels', 'all');
      await initializeSettingsProfile(
        prefs,
        directory,
        () => throw StateError('must not reopen'),
      );
      expect(appearance.appearance.labels, 'all');
      expect(isDeviceLocalBackupKey(initialProfileStateKey), isTrue);
      expect(isDeviceLocalBackupKey(initialProfileSeedKey), isTrue);
    },
  );

  for (final marker in <String?>[null, 'legacy', 'complete']) {
    for (final hasProfile in [false, true]) {
      test(
        'upgrade preserves implicit and explicit choices: marker=$marker profile=$hasProfile',
        () async {
          const oldProfile =
              '{"settingsInterfaceStyle":"glass","settingsTextSize":18,"labels":"all","focusScale":0.05,"sectionPosition":0.1}';
          final saved = <String, Object>{
            initialProfileStateKey: ?marker,
            if (hasProfile) tileAppearanceKey: oldProfile,
            if (hasProfile)
              initialProfileSeedKey: jsonEncode({
                tileAppearanceKey: oldProfile,
              }),
            categoryAppearanceKey:
                '{"1":{"layout":"grid","columns":4,"maxRows":2}}',
            'unrelated_setting': 'preserved',
          };
          SharedPreferences.setMockInitialValues(saved);
          final prefs = await SharedPreferences.getInstance();
          final beforeSettings = SettingsService(prefs);
          final beforeAppearance = AppearanceService(prefs);
          addTearDown(beforeSettings.dispose);
          addTearDown(beforeAppearance.dispose);
          final oldSettings = beforeSettings.exportSettingsMap();
          final oldAppearance = beforeAppearance.appearance;
          expect(beforeSettings.accentColorHex, ACCENT_COLOR_PURPLE);
          expect(oldAppearance.horizontalGap, 16);
          expect(oldAppearance.verticalGap, 16);
          expect(oldAppearance.interfaceFont, hasProfile ? 'outfit' : 'system');
          expect(oldAppearance.panelFont, 'sans-serif');
          expect(oldAppearance.sectionIcons, isFalse);
          expect(oldAppearance.focusBorderStyle(), 'outline');
          await initializeSettingsProfile(
            prefs,
            directory,
            () => throw StateError(
              'an upgrade must not open or rewrite the database',
            ),
          );
          final afterSettings = SettingsService(prefs);
          final afterAppearance = AppearanceService(prefs);
          addTearDown(afterSettings.dispose);
          addTearDown(afterAppearance.dispose);
          expect(afterSettings.exportSettingsMap(), oldSettings);
          expect(afterAppearance.appearance.values, oldAppearance.values);
          expect(
            afterAppearance.appearance.interfaceFont,
            oldAppearance.interfaceFont,
          );
          expect(
            afterAppearance.appearance.horizontalGap,
            oldAppearance.horizontalGap,
          );
          expect(
            afterAppearance.appearance.focusScale,
            oldAppearance.focusScale,
          );
          for (final entry in saved.entries) {
            expect(prefs.get(entry.key), entry.value, reason: entry.key);
          }
          expect(
            prefs.getKeys().difference(saved.keys.toSet()),
            marker == null ? {initialProfileStateKey} : isEmpty,
          );
        },
      );
    }
  }

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
      expect(jsonDecode(prefs.getString('tile_appearance')!)['labels'], 'none');
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
    expect(jsonDecode(newCopy['tile_appearance'])['labels'], 'none');
  });
}
