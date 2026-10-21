import 'package:flauncher/backup_sync.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> archive(
  Map<String, dynamic> settings, {
  String name = 'Apps',
}) => {
  'version': 3,
  'settings': settings,
  'resources': <String, dynamic>{},
  'apps': <Object>[],
  'appsCategories': <Object>[],
  'spacers': <Object>[],
  'categories': [
    {
      'id': 1,
      'name': name,
      'order': 0,
      'rowHeight': 100,
      'columnsCount': 5,
      'sort': 0,
      'type': 0,
    },
  ],
};
void main() {
  final zero = DateTime.fromMillisecondsSinceEpoch(0);
  test('independent changes merge and later conflicting setting wins', () {
    final a = BackupSyncDocument.capture(
      archive({'language': 'ru', 'color': 'blue'}),
      null,
      'A',
      zero,
    );
    final b = BackupSyncDocument.capture(a.backup, null, 'B', zero);
    final a1 = BackupSyncDocument.capture(
      archive({'language': 'en', 'color': 'blue'}),
      a,
      'A',
      DateTime(2026, 10, 9, 12),
    );
    final b1 = BackupSyncDocument.capture(
      archive({'language': 'de', 'color': 'red'}),
      b,
      'B',
      DateTime(2026, 10, 9, 13),
    );
    final merged = a1.merge(b1);
    expect(merged.backup['settings'], {
      'language': 'de',
      'color': 'red',
      backupSyncGroupsKey: [],
    });
    expect(
      backupFingerprint(merged.toJson()),
      backupFingerprint(b1.merge(a1).toJson()),
    );
    expect(
      BackupSyncDocument.parse(merged.toJson()).backup['settings'],
      merged.backup['settings'],
    );
  });
  test('first startup defaults do not override an existing server copy', () {
    final fresh = BackupSyncDocument.capture(
      archive({'language': 'ru'}),
      null,
      'new',
      zero,
    );
    final remote = BackupSyncDocument.capture(
      archive({'language': 'en'}),
      null,
      'old',
      DateTime(2026, 10, 8),
    );
    expect((fresh.merge(remote).backup['settings'] as Map)['language'], 'en');
  });
  test('resets travel as tombstones and stale data cannot resurrect them', () {
    final original = BackupSyncDocument.capture(
      archive({'extra': true}),
      null,
      'A',
      zero,
    );
    final reset = BackupSyncDocument.capture(
      archive({}),
      original,
      'A',
      DateTime(2026, 10, 9),
    );
    final merged = original.merge(reset);
    expect(merged.backup['settings'], {backupSyncGroupsKey: []});
    expect(BackupSyncDocument.parse(merged.toJson()).backup['settings'], {
      backupSyncGroupsKey: [],
    });
  });
  test('database rows merge as a single coherent block', () {
    final a = BackupSyncDocument.capture(
      archive({}, name: 'Old'),
      null,
      'A',
      zero,
    );
    final b = BackupSyncDocument.capture(
      archive({}, name: 'New'),
      a,
      'B',
      DateTime(2026, 10, 9),
    );
    expect((a.merge(b).backup['categories'] as List).single['name'], 'New');
  });
  test('corrupt data or revision hash is rejected before apply', () {
    final a = BackupSyncDocument.capture(
      archive({'language': 'ru'}),
      null,
      'A',
      zero,
    );
    final data = a.toJson();
    (data['revisions'] as Map)['setting:language'] = {
      'time': 0,
      'device': 'A',
      'hash': 'wrong',
    };
    expect(() => BackupSyncDocument.parse(data), throwsFormatException);
  });
  test('legacy full sync copies respect the current local block selection', () {
    final old = BackupSyncDocument.capture(
      archive({'accent_color': 'FFFFFF', 'app_language': 'en'}),
      null,
      'B',
      zero,
    ).toJson();
    old['syncVersion'] = 1;
    ((old['backup'] as Map)['settings'] as Map).remove(backupSyncGroupsKey);
    (old['revisions'] as Map).remove('setting:$backupSyncGroupsKey');
    final legacy = BackupSyncDocument.parse(old);
    final local = BackupSyncDocument.capture(
      archive({
        'accent_color': '000000',
        backupSyncGroupsKey: ['appearance'],
      }),
      null,
      'A',
      zero,
    );
    final restored = legacy.restoreOver(local);
    expect((restored['settings'] as Map)['accent_color'], '000000');
    expect((restored['settings'] as Map)['app_language'], 'en');
    expect((restored['settings'] as Map)[backupSyncGroupsKey], ['appearance']);
  });
  test('clock ties converge regardless of merge direction', () {
    final a = BackupSyncDocument.capture(
      archive({'language': 'ru'}),
      null,
      'A',
      zero,
    );
    final b = BackupSyncDocument.capture(
      archive({'language': 'en'}),
      null,
      'B',
      zero,
    );
    expect(
      backupFingerprint(a.merge(b).toJson()),
      backupFingerprint(b.merge(a).toJson()),
    );
  });

  test('disabled blocks and clocks never enter the sync packet, policy always does', () {
    final full = archive({
      'accent_color': 'FFFFFF',
      'app_language': 'ru',
      backupSyncGroupsKey: [
        for (final group in BackupSyncGroup.values) group.name,
      ],
    });
    full['resources'] = {'wallpaper': 'local-image'};
    final document = BackupSyncDocument.capture(full, null, 'A', zero);
    final wire = document.toJson();
    final data = wire['backup'] as Map;
    expect(data.keys, unorderedEquals(['version', 'settings']));
    expect((data['settings'] as Map).keys, [backupSyncGroupsKey]);
    expect((wire['revisions'] as Map).keys, ['setting:$backupSyncGroupsKey']);
    expect(BackupSyncDocument.parse(wire).backup, data);
    expect(document.backup['resources'], full['resources']);
    expect((document.backup['settings'] as Map)['accent_color'], 'FFFFFF');
  });

  test('winning policy preserves local values, local absences, database and images', () {
    final localData = archive({
      'accent_color': '000000',
      'app_language': 'ru',
    }, name: 'Local');
    localData['resources'] = {'wallpaper': 'local-image'};
    final local = BackupSyncDocument.capture(localData, null, 'A', zero);
    final oldRemote = BackupSyncDocument.capture(
      archive({
        'accent_color': 'FFFFFF',
        'gradient_uuid': 'remote-only',
        'app_language': 'en',
      }, name: 'Remote'),
      null,
      'B',
      DateTime(2026, 10, 8),
    );
    final policy = BackupSyncDocument.capture(
      archive({
        backupSyncGroupsKey: ['home', 'appearance'],
        'app_language': 'de',
      }),
      null,
      'C',
      DateTime(2026, 10, 9),
    );
    final remotePolicy = BackupSyncDocument.parse(policy.toJson());
    final first = local
        .merge(oldRemote)
        .merge(remotePolicy)
        .preserveLocalGroups(local);
    final second = local
        .merge(remotePolicy)
        .merge(oldRemote)
        .preserveLocalGroups(local);
    expect(backupFingerprint(first.backup), backupFingerprint(second.backup));
    final values = first.backup['settings'] as Map;
    expect(values['accent_color'], '000000');
    expect(values.containsKey('gradient_uuid'), false);
    expect(values['app_language'], 'de');
    expect(values[backupSyncGroupsKey], ['home', 'appearance']);
    expect((first.backup['categories'] as List).single['name'], 'Local');
    expect(first.backup['resources'], localData['resources']);
    final restored = remotePolicy.restoreOver(local);
    expect((restored['settings'] as Map)['accent_color'], '000000');
    expect(restored['categories'], localData['categories']);
    expect(restored['resources'], localData['resources']);
    expect((restored['settings'] as Map)['app_language'], 'de');
  });

  test(
    'reenabling a block exchanges it again with its original change clocks',
    () {
      final local = BackupSyncDocument.capture(
        archive({
          'accent_color': '000000',
          backupSyncGroupsKey: ['appearance'],
        }),
        null,
        'A',
        DateTime(2026, 10, 8),
      );
      final remote = BackupSyncDocument.capture(
        archive({'accent_color': 'FFFFFF', backupSyncGroupsKey: []}),
        null,
        'B',
        DateTime(2026, 10, 9),
      );
      final merged = local
          .merge(BackupSyncDocument.parse(remote.toJson()))
          .preserveLocalGroups(local);
      expect((merged.backup['settings'] as Map)['accent_color'], 'FFFFFF');
      expect((merged.toJson()['backup'] as Map)['resources'], isNotNull);
    },
  );

  test(
    'group policy is portable but malformed policies cannot be imported',
    () {
      expect(isDeviceLocalBackupKey(backupSyncGroupsKey), false);
      expect(
        compatibleSettings({
          backupSyncGroupsKey: ['weather'],
        }, {})[backupSyncGroupsKey],
        ['weather'],
      );
      expect(
        compatibleSettings({
          backupSyncGroupsKey: ['unknown'],
        }, {}),
        isEmpty,
      );
      expect(compatibleSettings({backupSyncGroupsKey: true}, {}), isEmpty);
      expect(
        backupSyncPartGroup('setting:weather_api_key'),
        BackupSyncGroup.weatherDisplay,
      );
    },
  );
  test(
    'partial sync packets require coherent blocks and a validated policy',
    () {
      final document = BackupSyncDocument.capture(archive({}), null, 'A', zero);
      final missingTables = document.toJson();
      (missingTables['backup'] as Map).remove('apps');
      expect(
        () => BackupSyncDocument.parse(missingTables),
        throwsFormatException,
      );
      final missingPolicy = document.toJson();
      (missingPolicy['backup'] as Map)['settings'] = {};
      expect(
        () => BackupSyncDocument.parse(missingPolicy),
        throwsFormatException,
      );
      final invalidPolicy = document.toJson();
      (invalidPolicy['backup'] as Map)['settings'] = {
        backupSyncGroupsKey: ['unknown'],
      };
      expect(
        () => BackupSyncDocument.parse(invalidPolicy),
        throwsFormatException,
      );
      final leaking = document.toJson();
      (leaking['backup'] as Map)['settings'] = {
        backupSyncGroupsKey: ['appearance'],
      };
      expect(() => BackupSyncDocument.parse(leaking), throwsFormatException);
    },
  );
  test(
    'fine blocks classify independently and each selectable group appears once',
    () {
      expect(
        backupSyncSections.values.expand((groups) => groups),
        unorderedEquals(BackupSyncGroup.values),
      );
      expect(BackupSyncGroup.values, hasLength(20));
      final settings = {
        backupSyncGroupsKey: ['accent', 'weatherDisplay', 'continueWatching'],
      };
      expect(backupSyncPartEnabled('setting:accent_color', settings), false);
      expect(backupSyncPartEnabled('setting:tile_appearance', settings), true);
      expect(backupSyncPartEnabled('resources', settings), true);
      expect(
        backupSyncPartEnabled('setting:weather_configuration', settings),
        true,
      );
      expect(
        backupSyncPartEnabled('setting:temperature_unit', settings),
        false,
      );
      expect(backupSyncPartEnabled('database', settings), true);
      expect(
        backupSyncPartEnabled('setting:show_continue_watching', settings),
        false,
      );
      expect(
        backupSyncPartGroup('setting:night_mode_configuration'),
        BackupSyncGroup.nightMode,
      );
      expect(
        backupSyncPartGroup('setting:brightness_solar'),
        BackupSyncGroup.brightness,
      );
      expect(
        backupSyncPartGroup('setting:app_language'),
        BackupSyncGroup.language,
      );
      expect(
        backupSyncPartGroup('setting:show_update_notifications'),
        BackupSyncGroup.updates,
      );
    },
  );
  test(
    'old broad selections expand but new packets still reject disabled data',
    () {
      expect(disabledBackupSyncGroups(['appearance']), {
        BackupSyncGroup.background,
        BackupSyncGroup.tiles,
        BackupSyncGroup.accent,
        BackupSyncGroup.animations,
        BackupSyncGroup.menuLayout,
      });
      final old = BackupSyncDocument.capture(
        archive({
          backupSyncGroupsKey: ['general'],
          'show_update_notifications': true,
        }),
        null,
        'A',
        zero,
      );
      expect(
        BackupSyncDocument.parse({
          'syncVersion': 2,
          'backup': old.backup,
          'revisions': old.revisions,
        }).backup,
        old.backup,
      );
      final current = BackupSyncDocument.capture(
        archive({
          backupSyncGroupsKey: ['accent'],
          'accent_color': 'FFFFFF',
        }),
        null,
        'A',
        zero,
      );
      expect(
        () => BackupSyncDocument.parse({
          'syncVersion': 2,
          'backup': current.backup,
          'revisions': current.revisions,
        }),
        throwsFormatException,
      );
    },
  );
}
