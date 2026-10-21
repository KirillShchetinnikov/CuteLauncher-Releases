import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flauncher/providers/settings_sync_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/settings_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late SharedPreferences preferences;
  late SettingsSyncService service;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('settings-sync-test-');
    SharedPreferences.setMockInitialValues({
      'accent_color': '7C4DFF',
      'show_time_in_status_bar': true,
      'weather_api_key': 'secret',
      'start_on_boot': true,
      'slideshow_folder': '/local/folder',
      'category_appearance': '{"1":{"radius":10}}',
      'custom_banner_sample.app': '/local/banner',
    });
    preferences = await SharedPreferences.getInstance();
    service = SettingsSyncService(preferences, newId: () => 'A');
  });
  tearDown(() => directory.delete(recursive: true));
  File file(String name) => File('${directory.path}/$name.json');
  Future<File> remote(SettingsSyncState state) async =>
      file('remote').writeAsString(state.encode());
  Future<SettingsSyncState> export() async {
    await service.exportTo(file('export'));
    return SettingsSyncState.decode(await file('export').readAsString());
  }

  test(
    'export excludes credentials, paths, apps and local sync metadata',
    () async {
      final state = await export();
      expect(state.entries.keys.toSet(), {
        'accent_color',
        'show_time_in_status_bar',
      });
      expect(await file('export').readAsString(), isNot(contains('secret')));
      expect(isDeviceLocalBackupKey(syncStateKey), isTrue);
      expect(isDeviceLocalBackupKey('settings_sync_pending'), isTrue);
    },
  );
  test('preview/cancel preserves settings; apply keeps independent edits and local state', () async {
    final baseline = await export();
    await preferences.setString('accent_color', 'FF0000');
    final other = SettingsSyncState(
      'B',
      baseline.entries,
    ).capture({'accent_color': '7C4DFF', 'show_time_in_status_bar': false});
    final preview = await service.preview(await remote(other));
    expect(preferences.getBool('show_time_in_status_bar'), isTrue);
    expect(preview.plan.changes, ['show_time_in_status_bar']);
    await service.apply(preview, {});
    expect(preferences.getString('accent_color'), 'FF0000');
    expect(preferences.getBool('show_time_in_status_bar'), isFalse);
    expect(preferences.getString('weather_api_key'), 'secret');
    expect(preferences.getString('slideshow_folder'), '/local/folder');
    expect(preferences.getBool('start_on_boot'), isTrue);
    expect(preferences.getString('custom_banner_sample.app'), '/local/banner');
    final repeat = await service.preview(await remote(other));
    expect(repeat.plan.changes, isEmpty);
    expect(repeat.plan.conflicts, isEmpty);
    await service.apply(repeat, {});
    expect(preferences.get('settings_sync_pending'), isNull);
  });
  test('concurrent conflict requires explicit choice; stale preview never overwrites edits', () async {
    final baseline = await export();
    await preferences.setString('accent_color', 'FF0000');
    final other = SettingsSyncState(
      'B',
      baseline.entries,
    ).capture({'accent_color': '00FF00', 'show_time_in_status_bar': true});
    var preview = await service.preview(await remote(other));
    expect(preview.plan.conflicts, ['accent_color']);
    await expectLater(service.apply(preview, {}), throwsStateError);
    await preferences.setBool('show_time_in_status_bar', false);
    await expectLater(
      service.apply(preview, {'accent_color': true}),
      throwsStateError,
    );
    expect(preferences.getString('accent_color'), 'FF0000');
    preview = await service.preview(await remote(other));
    await service.apply(preview, {'accent_color': true});
    expect(preferences.getString('accent_color'), '00FF00');
    expect(preferences.getBool('show_time_in_status_bar'), isFalse);
  });
  test(
    'reset propagates as deletion, without removing local preferences',
    () async {
      final baseline = await export();
      final other = SettingsSyncState(
        'B',
        baseline.entries,
      ).capture({'show_time_in_status_bar': true});
      final preview = await service.preview(await remote(other));
      await service.apply(preview, {});
      expect(preferences.containsKey('accent_color'), isFalse);
      expect(preferences.getString('weather_api_key'), 'secret');
    },
  );
  test('one invalid entry rejects the entire file before changing metadata or preferences', () async {
    final before = {
      for (final key in preferences.getKeys()) key: preferences.get(key),
    };
    final invalid = SettingsSyncState('B', {
      'show_time_in_status_bar': SyncValue(false, {'B': 1}),
      'accent_color': SyncValue('invalid', {'B': 1}),
    });
    await expectLater(
      service.preview(await remote(invalid)),
      throwsFormatException,
    );
    expect({
      for (final key in preferences.getKeys()) key: preferences.get(key),
    }, before);
    final invalidStyle = SettingsSyncState('B', {
      'tile_appearance': SyncValue('{"privatePath":"secret"}', {'B': 1}),
    });
    await expectLater(
      service.preview(await remote(invalidStyle)),
      throwsFormatException,
    );
  });
  test('whole tile style is portable, canonical and has explicit concurrent conflicts', () async {
    await preferences.setString(
      'tile_appearance',
      '{"radius":10,"opacity":0.8}',
    );
    final baseline = await export();
    expect(
      baseline.entries['tile_appearance']!.value,
      '{"opacity":0.8,"radius":10}',
    );
    await preferences.setString(
      'tile_appearance',
      '{"radius":20,"opacity":0.8}',
    );
    final other = SettingsSyncState('B', baseline.entries).capture({
      'accent_color': '7C4DFF',
      'show_time_in_status_bar': true,
      'tile_appearance': '{"radius":10,"opacity":0.5}',
    });
    final preview = await service.preview(await remote(other));
    expect(preview.plan.conflicts, ['tile_appearance']);
    await service.apply(preview, {'tile_appearance': false});
    expect(jsonDecode(preferences.getString('tile_appearance')!), {
      'radius': 20,
      'opacity': 0.8,
    });
  });
  test('interrupted apply restores its before image and history on next service start', () async {
    final baseline = await export();
    await preferences.setString(
      'settings_sync_pending',
      jsonEncode({
        'before': {
          'accent_color': '7C4DFF',
          'show_time_in_status_bar': true,
          'tile_appearance': null,
        },
        'state': baseline.encode(),
      }),
    );
    await preferences.setString('accent_color', 'FF0000');
    await preferences.setBool('show_time_in_status_bar', false);
    await preferences.setString('tile_appearance', '{"radius":20}');
    await preferences.setString(
      syncStateKey,
      SettingsSyncState('A', {}).encode(),
    );
    await SettingsSyncService(preferences).recover();
    expect(preferences.getString('accent_color'), '7C4DFF');
    expect(preferences.getBool('show_time_in_status_bar'), isTrue);
    expect(preferences.get('tile_appearance'), isNull);
    expect(preferences.getString(syncStateKey), baseline.encode());
    expect(preferences.get('settings_sync_pending'), isNull);
    expect(preferences.getString('weather_api_key'), 'secret');
  });
  test(
    'files larger than the exchange budget are rejected before parsing',
    () async {
      final oversized = file('oversized');
      await oversized.writeAsString(' ' * (syncMaximumBytes + 1));
      await expectLater(service.preview(oversized), throwsA(isA<Exception>()));
      expect(preferences.get(syncStateKey), isNull);
    },
  );
  test(
    'write failure after the first preference restores values and history',
    () async {
      final baseline = await export();
      final other = SettingsSyncState(
        'B',
        baseline.entries,
      ).capture({'accent_color': 'FF0000', 'show_time_in_status_bar': false});
      final preview = await service.preview(await remote(other));
      SharedPreferencesStorePlatform.instance = _FailingStore({
        for (final key in preferences.getKeys())
          'flutter.$key': preferences.get(key)!,
      });
      await expectLater(
        service.apply(preview, {}),
        throwsA(isA<FileSystemException>()),
      );
      await preferences.reload();
      expect(preferences.getString('accent_color'), '7C4DFF');
      expect(preferences.getBool('show_time_in_status_bar'), isTrue);
      expect(preferences.getString(syncStateKey), baseline.encode());
      expect(preferences.get('settings_sync_pending'), isNull);
      expect(preferences.getString('weather_api_key'), 'secret');
    },
  );
}

class _FailingStore extends InMemorySharedPreferencesStore {
  _FailingStore(super.data) : super.withData();
  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    if (key == 'flutter.show_time_in_status_bar' && value == false) {
      return false;
    }
    return super.setValue(valueType, key, value);
  }
}
