import 'package:flauncher/file_browser_options.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/settings_sync.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'options persist, validate imports and synchronize without local history',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      addTearDown(settings.dispose);
      expect(settings.fileBrowserOptions, const FileBrowserOptions());
      const options = FileBrowserOptions(
        start: FileBrowserStart.downloads,
        sort: FileBrowserSort.size,
        descending: true,
        foldersFirst: false,
        showHidden: true,
        showDetails: false,
      );
      await settings.setFileBrowserOptions(options);
      var notified = 0;
      settings.addListener(() => notified++);
      await settings.rememberFileBrowserLocation(
        'selected:wallpaper:day',
        '/storage/USB/Pictures',
      );
      expect(notified, 0);
      final reloaded = SettingsService(prefs);
      addTearDown(reloaded.dispose);
      expect(reloaded.fileBrowserOptions, options);
      expect(
        reloaded.fileBrowserLocation('selected:wallpaper:day'),
        '/storage/USB/Pictures',
      );
      final backup = settings.exportSettingsMap();
      expect(backup.containsKey(fileBrowserLocationsKey), isFalse);
      expect(isDeviceLocalBackupKey(fileBrowserLocationsKey), isTrue);
      final sync = SettingsSyncState(
        'A',
        {},
      ).capture({...backup, fileBrowserLocationsKey: 'private paths'});
      expect(sync.entries.containsKey(fileBrowserOptionsKey), isTrue);
      expect(sync.entries.containsKey(fileBrowserLocationsKey), isFalse);
      await settings.setFileBrowserOptions(const FileBrowserOptions());
      await settings.importSettingsMap(backup);
      expect(settings.fileBrowserOptions, options);
      for (final raw in [
        'no-json',
        '[]',
        '{"sort":"unknown"}',
        '{"showHidden":1}',
        '{"start":false}',
      ]) {
        await settings.importSettingsMap({
          fileBrowserOptionsKey: raw,
          fileBrowserLocationsKey: '{"injected":"path"}',
        });
        expect(settings.fileBrowserOptions, options);
        expect(settings.fileBrowserLocation('injected'), isNull);
      }
      for (var i = 0; i < 110; i++) {
        await settings.rememberFileBrowserLocation('last:$i', '/storage/$i');
      }
      expect(settings.fileBrowserLocation('last:0'), isNull);
      expect(settings.fileBrowserLocation('last:109'), '/storage/109');
    },
  );

  final listing = <Object?, Object?>{
    'folders': [
      {'name': 'Z folder', 'path': '/storage/Z', 'modified': 30},
      {'name': '.hidden folder', 'path': '/storage/.hidden', 'modified': 40},
    ],
    'files': [
      {'name': 'b.json', 'path': '/storage/b', 'size': 20, 'modified': 10},
      {'name': 'A.json', 'path': '/storage/a', 'size': 5, 'modified': 20},
      {
        'name': '.hidden.json',
        'path': '/storage/.file',
        'size': 0,
        'modified': 50,
      },
      {
        'name': 'unknown.json',
        'path': '/storage/unknown',
        'size': -1,
        'modified': 0,
      },
    ],
  };
  List<String> names(FileBrowserOptions options) =>
      options.entries(listing).map((e) => e['name'] as String).toList();

  test(
    'name sorting respects direction, hidden entries and folder grouping',
    () {
      expect(names(const FileBrowserOptions()), [
        'Z folder',
        'A.json',
        'b.json',
        'unknown.json',
      ]);
      expect(names(const FileBrowserOptions(descending: true)), [
        'Z folder',
        'unknown.json',
        'b.json',
        'A.json',
      ]);
      expect(names(const FileBrowserOptions(foldersFirst: false)), [
        'A.json',
        'b.json',
        'unknown.json',
        'Z folder',
      ]);
      expect(names(const FileBrowserOptions(showHidden: true)).take(2), [
        '.hidden folder',
        'Z folder',
      ]);
    },
  );
  test(
    'date and size sorting keep unknown values last in either direction',
    () {
      expect(
        names(
          const FileBrowserOptions(
            sort: FileBrowserSort.date,
            foldersFirst: false,
          ),
        ),
        ['b.json', 'A.json', 'Z folder', 'unknown.json'],
      );
      expect(
        names(
          const FileBrowserOptions(
            sort: FileBrowserSort.date,
            foldersFirst: false,
            descending: true,
          ),
        ),
        ['Z folder', 'A.json', 'b.json', 'unknown.json'],
      );
      expect(names(const FileBrowserOptions(sort: FileBrowserSort.size)), [
        'Z folder',
        'A.json',
        'b.json',
        'unknown.json',
      ]);
      expect(
        names(
          const FileBrowserOptions(
            sort: FileBrowserSort.size,
            descending: true,
          ),
        ),
        ['Z folder', 'b.json', 'A.json', 'unknown.json'],
      );
      final entries = const FileBrowserOptions(foldersFirst: false)
          .entries(listing);
      expect(entries.first['directory'], isFalse);
      expect(entries.last['directory'], isTrue);
    },
  );
}
