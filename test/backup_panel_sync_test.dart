import 'dart:convert';

import 'package:flauncher/backup_sync.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flutter_test/flutter_test.dart';

import 'backup_sync_test.dart' show archive;

void main() {
  test('a local appearance edit during v2 upgrade gets a new revision', () {
    final before = archive({
      'tile_appearance': jsonEncode({'panelTextSize': 16}),
    });
    final old = BackupSyncDocument({}, {
      'setting:tile_appearance': {
        'time': 100,
        'device': 'A',
        'hash': backupFingerprint(before['settings']['tile_appearance']),
      },
    });
    final after = BackupSyncDocument.capture(
      archive({
        'tile_appearance': jsonEncode({'panelTextSize': 22}),
      }),
      old,
      'B',
      DateTime.fromMillisecondsSinceEpoch(200),
    );
    expect(after.revisions['appearance:panelTextSize']['time'], 200);
    expect(after.revisions['appearance:panelTextSize']['device'], 'B');
  });
  test(
    'v2 clocks and remote panel use their original block classification',
    () {
      final backup = archive({
        backupSyncGroupsKey: ['topPanel'],
        'information_clock_behavior': '{}',
        'remote_panel_configuration': '{}',
        'tile_appearance': jsonEncode({'panelTextSize': 22}),
      });
      final revisions = {
        for (final e in BackupSyncDocument.parts(backup, legacy: true).entries)
          e.key: {'time': 1, 'device': 'A', 'hash': backupFingerprint(e.value)},
      };
      final parsed = BackupSyncDocument.parse({
        'syncVersion': 2,
        'backup': backup,
        'revisions': revisions,
      });
      expect(parsed.revisions['appearance:panelTextSize']['time'], 1);
      expect(parsed.revisions.containsKey('setting:tile_appearance'), false);
    },
  );

  test('a later local edit beats an already observed faster device clock', () {
    final remote = BackupSyncDocument.capture(
      archive({'app_language': 'ru'}),
      null,
      'A',
      DateTime(2030),
    );
    final local = BackupSyncDocument.capture(
      archive({'app_language': 'en'}),
      remote,
      'B',
      DateTime(2020),
    );
    expect(local.merge(remote).backup['settings']['app_language'], 'en');
  });
  final zero = DateTime.fromMillisecondsSinceEpoch(0);
  BackupSyncDocument capture(
    Map<String, dynamic> fields, {
    BackupSyncDocument? previous,
    String device = 'A',
    int time = 0,
    List<String> disabled = const [],
  }) => BackupSyncDocument.capture(
    archive({
      'tile_appearance': jsonEncode(fields),
      backupSyncGroupsKey: disabled,
    }),
    previous,
    device,
    zero.add(Duration(seconds: time)),
  );
  Map appearance(BackupSyncDocument doc) => jsonDecode(
    (doc.backup['settings'] as Map)['tile_appearance'] as String? ?? '{}',
  ) as Map;

  test(
    'top panel travels with tiles disabled; local subscription is retained',
    () {
      final a = capture(
        {
          'panelTextSize': 22,
          'panelButtonsOrder': ['network', 'settings'],
          'panelCombinedInformation': true,
          'radius': 25,
        },
        disabled: ['tiles'],
        time: 2,
      );
      final b = capture(
        {'panelTextSize': 14, 'radius': 8},
        disabled: ['tiles'],
        device: 'B',
      );
      final packet = BackupSyncDocument.parse(a.toJson());
      expect(appearance(packet).containsKey('radius'), false);
      final merged = b.merge(packet).preserveLocalGroups(b);
      expect(appearance(merged)['panelTextSize'], 22);
      expect(appearance(merged)['panelCombinedInformation'], true);
      expect(appearance(merged)['radius'], 8);
      expect((merged.backup['settings'] as Map)[backupSyncGroupsKey], [
        'tiles',
      ]);
    },
  );

  test(
    'independent panel and tile edits survive and resets do not resurrect',
    () {
      final base = capture({'panelTextSize': 16, 'radius': 8});
      final a = capture(
        {'panelTextSize': 22, 'radius': 8},
        previous: base,
        time: 1,
      );
      final b = capture(
        {'panelTextSize': 16, 'radius': 18},
        previous: base,
        device: 'B',
        time: 2,
      );
      final merged = a.merge(BackupSyncDocument.parse(b.toJson()));
      expect(appearance(merged), {'panelTextSize': 22, 'radius': 18});
      final reset = capture({'radius': 18}, previous: merged, time: 3);
      expect(appearance(reset.merge(a)).containsKey('panelTextSize'), false);
      expect(appearance(a.merge(reset)), appearance(reset.merge(a)));
    },
  );

  test(
    'remote subscription cannot disable local panel or enable local tiles',
    () {
      final local = capture(
        {'panelTextSize': 22, 'radius': 8},
        disabled: ['tiles'],
      );
      final remote = capture(
        {'panelTextSize': 10, 'radius': 40},
        device: 'B',
        time: 1,
        disabled: ['topPanel'],
      );
      final result = local
          .merge(BackupSyncDocument.parse(remote.toJson()))
          .preserveLocalGroups(local);
      expect(appearance(result), {'panelTextSize': 22, 'radius': 8});
      expect((result.backup['settings'] as Map)[backupSyncGroupsKey], [
        'tiles',
      ]);
    },
  );
}
