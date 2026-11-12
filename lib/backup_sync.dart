import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

import 'backup_validation.dart';
import 'backup_sync_groups.dart';
import 'settings_import.dart';

String backupFingerprint(Object? value) {
  Object? sorted(Object? v) => v is Map
      ? {
          for (final k in v.keys.cast<String>().toList()..sort())
            k: sorted(v[k]),
        }
      : v is List
      ? v.map(sorted).toList()
      : v;
  return sha256.convert(utf8.encode(jsonEncode(sorted(value)))).toString();
}

enum BackupSyncResumeChoice { local, remote, mergeLocal, mergeRemote }

/// Settings merge individually. Relational tables and image resources each
/// form a coherent block. Ties use device ID, so equal clocks converge.
class BackupSyncDocument {
  static const databaseKeys = [
    'apps',
    'categories',
    'appsCategories',
    'spacers',
  ];
  final Map<String, dynamic> backup;
  final Map<String, dynamic> revisions;
  BackupSyncDocument(this.backup, this.revisions);
  Map<String, Object?> toJson() {
    final settings = backup['settings'] as Map;
    final filtered = _withParts({
      for (final e in parts(backup).entries)
        if (backupSyncPartEnabled(e.key, settings)) e.key: e.value,
    });
    return {
      'syncVersion': 3,
      'backup': {
        for (final e in filtered.entries)
          if (e.key != 'settings' &&
              (!databaseKeys.contains(e.key) ||
                  backupSyncPartEnabled(
                    'database',
                    backup['settings'] as Map,
                  )) &&
              (e.key != 'resources' ||
                  backupSyncPartEnabled(
                    'resources',
                    backup['settings'] as Map,
                  )))
            e.key: e.value,
        'settings': {
          ...(filtered['settings'] as Map).cast<String, dynamic>(),
          backupSyncGroupsKey: settings[backupSyncGroupsKey] ?? <String>[],
        },
      },
      'revisions': {
        for (final e in revisions.entries)
          if (e.key != 'setting:$backupSyncGroupsKey' &&
              backupSyncPartEnabled(e.key, backup['settings'] as Map))
            e.key: e.value,
      },
    };
  }

  static Map<String, dynamic> parts(
    Map<String, dynamic> backup, {
    bool legacy = false,
  }) => {
    if (databaseKeys.every(backup.containsKey))
      'database': {for (final k in databaseKeys) k: backup[k]},
    if (backup.containsKey('resources')) 'resources': backup['resources'],
    for (final e in (backup['settings'] as Map).entries)
      if (!isDeviceLocalBackupKey(e.key as String) &&
          (legacy ||
              e.key != backupSyncGroupsKey && e.key != 'tile_appearance'))
        'setting:${e.key}': e.value,
    if (!legacy && (backup['settings'] as Map)['tile_appearance'] is String)
      for (final e in (jsonDecode(
        (backup['settings'] as Map)['tile_appearance'] as String,
      ) as Map).entries)
        'appearance:${e.key}': e.value,
  };

  factory BackupSyncDocument.parse(Object? source) {
    if (source is! Map ||
        ![1, 2, 3].contains(source['syncVersion']) ||
        source['backup'] is! Map ||
        source['revisions'] is! Map) {
      throw const FormatException('Invalid sync archive');
    }
    final backup = Map<String, dynamic>.from(source['backup'] as Map);
    if (backup['version'] != 3 || backup['settings'] is! Map) {
      throw const FormatException('Invalid backup');
    }
    disabledBackupSyncGroups((backup['settings'] as Map)[backupSyncGroupsKey]);
    final legacy = source['syncVersion'] != 3;
    if (source['syncVersion'] != 1 &&
        !(backup['settings'] as Map).containsKey(backupSyncGroupsKey)) {
      throw const FormatException('Missing sync policy');
    }
    final tables = databaseKeys.where(backup.containsKey).length;
    if (tables != 0 && tables != databaseKeys.length ||
        source['syncVersion'] == 1 && tables == 0) {
      throw const FormatException('Incomplete sync database');
    }
    if (tables != 0) validateBackup(backup);
    if (backup.containsKey('resources') && backup['resources'] is! Map) {
      throw const FormatException('Invalid sync resources');
    }
    final revisions = readRevisions(source['revisions']);
    // Older broad policies may carry fields now assigned to a finer block.
    if (source['syncVersion'] != 1 &&
        (!legacy ||
            !hasLegacyBackupSyncGroups(
              (backup['settings'] as Map)[backupSyncGroupsKey],
            ))) {
      final settings = backup['settings'] as Map;
      bool enabled(String key) {
        if (legacy && key == 'setting:information_clock_behavior') {
          return backupSyncPartEnabled('setting:tile_appearance', settings);
        }
        if (legacy && key == 'setting:remote_panel_configuration') {
          return backupSyncPartEnabled('setting:legacy_other', settings);
        }
        return backupSyncPartEnabled(key, settings);
      }

      if ((tables != 0) != backupSyncPartEnabled('database', settings) ||
          backup.containsKey('resources') !=
              backupSyncPartEnabled('resources', settings) ||
          parts(backup, legacy: legacy).keys.any((key) => !enabled(key)) ||
          revisions.keys.any((key) => !enabled(key))) {
        throw const FormatException('Inconsistent sync blocks');
      }
    }
    for (final e in parts(backup, legacy: legacy).entries) {
      if (revisions[e.key]?['hash'] != backupFingerprint(e.value)) {
        throw const FormatException('Invalid fingerprint');
      }
    }
    if (legacy) {
      final appearance = revisions.remove('setting:tile_appearance');
      revisions.remove('setting:$backupSyncGroupsKey');
      if (appearance != null) {
        for (final e in parts(
          backup,
        ).entries.where((e) => e.key.startsWith('appearance:'))) {
          revisions[e.key] = {
            ...appearance as Map,
            'hash': backupFingerprint(e.value),
          };
        }
      }
    }
    return BackupSyncDocument(backup, revisions);
  }

  static Map<String, dynamic> readRevisions(Object? source) {
    if (source is! Map) throw const FormatException('Invalid revisions');
    final revisions = Map<String, dynamic>.from(source);
    if (revisions.length > 4096) {
      throw const FormatException('Too many revisions');
    }
    for (final entry in revisions.entries) {
      final r = entry.value;
      if (!(entry.key == 'database' ||
              entry.key == 'resources' ||
              entry.key.startsWith('setting:') ||
              entry.key.startsWith('appearance:')) ||
          r is! Map ||
          r['time'] is! int ||
          r['time'] < 0 ||
          r['time'] > 8640000000000000 ||
          r['device'] is! String ||
          (r['device'] as String).length > 64 ||
          r['hash'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(r['hash'] as String)) {
        throw const FormatException('Invalid revision');
      }
    }
    return revisions;
  }

  factory BackupSyncDocument.capture(
    Map<String, dynamic> backup,
    BackupSyncDocument? previous,
    String device,
    DateTime time, {
    Map<String, int> changedTimes = const {},
  }) {
    backup = {
      ...backup,
      'settings': {
        ...(backup['settings'] as Map).cast<String, dynamic>(),
        backupSyncGroupsKey:
            (backup['settings'] as Map)[backupSyncGroupsKey] ?? <String>[],
      },
    };
    final partsNow = parts(backup);
    final revisions = <String, dynamic>{...?previous?.revisions};
    final observedTime = revisions.values.fold<int>(
      -1,
      (time, revision) => max(time, revision['time'] as int),
    );
    final oldAppearance = revisions.remove('setting:tile_appearance');
    revisions.remove('setting:$backupSyncGroupsKey');
    if (oldAppearance != null) {
      final unchanged =
          oldAppearance['hash'] ==
          backupFingerprint((backup['settings'] as Map)['tile_appearance']);
      for (final e in partsNow.entries.where(
        (e) => e.key.startsWith('appearance:'),
      )) {
        revisions.putIfAbsent(
          e.key,
          () => {
            ...oldAppearance as Map,
            'hash': unchanged
                ? backupFingerprint(e.value)
                : oldAppearance['hash'],
          },
        );
      }
    }
    for (final key in {...partsNow.keys, ...revisions.keys}) {
      final hash = backupFingerprint(partsNow[key]);
      if (revisions[key]?['hash'] != hash) {
        final previousTime = revisions[key]?['time'] as int? ?? -1;
        revisions[key] = {
          'time': max(
            changedTimes[key] ?? time.millisecondsSinceEpoch,
            min(max(previousTime, observedTime) + 1, 8640000000000000),
          ),
          'device': device,
          'hash': hash,
        };
      }
    }
    return BackupSyncDocument(backup, revisions);
  }

  BackupSyncDocument merge(BackupSyncDocument remote, {bool partial = false}) {
    final localParts = parts(backup), remoteParts = parts(remote.backup);
    final merged = <String, dynamic>{}, clocks = <String, dynamic>{};
    for (final key in {...revisions.keys, ...remote.revisions.keys}) {
      final a = revisions[key] as Map?, b = remote.revisions[key] as Map?;
      final fromRemote = _newer(b, a);
      final source = fromRemote ? remoteParts : localParts;
      clocks[key] = fromRemote ? b : a;
      if (source.containsKey(key)) merged[key] = source[key];
    }
    final result = _withParts(merged);
    if (!partial) validateBackup(result);
    return BackupSyncDocument(result, clocks);
  }

  static bool _newer(Map? a, Map? b) =>
      a != null &&
      (b == null ||
          a['time'] > b['time'] ||
          a['time'] == b['time'] &&
              (a['device'] as String).compareTo(b['device'] as String) > 0);

  Map<String, dynamic> _withParts(Map<String, dynamic> merged) => {
    ...backup,
    ...?(merged['database'] as Map?)?.cast<String, dynamic>(),
    if (merged.containsKey('resources')) 'resources': merged['resources'],
    'settings': {
      backupSyncGroupsKey:
          (backup['settings'] as Map)[backupSyncGroupsKey] ?? <String>[],
      for (final e in merged.entries)
        if (e.key.startsWith('setting:')) e.key.substring(8): e.value,
      if (merged.keys.any((key) => key.startsWith('appearance:')))
        'tile_appearance': jsonEncode({
          for (final e in merged.entries)
            if (e.key.startsWith('appearance:')) e.key.substring(11): e.value,
        }),
    },
  };

  /// Resolve the resumed exchange against this TV's last published snapshot.
  /// An absent revision in a merge has no opinion. A tombstone has a revision.
  BackupSyncDocument resumeWith(
    BackupSyncDocument remote,
    Map<String, dynamic> common,
    BackupSyncResumeChoice choice,
    String device,
  ) {
    final localParts = parts(backup);
    final remoteParts = parts(remote.backup);
    final localSettings = backup['settings'] as Map;
    final remoteSettings = remote.backup['settings'] as Map;
    final keys = {...revisions.keys, ...remote.revisions.keys};
    final combined = Map<String, dynamic>.of(localParts);
    final clocks = Map<String, dynamic>.of(revisions);
    final merge =
        choice == BackupSyncResumeChoice.mergeLocal ||
        choice == BackupSyncResumeChoice.mergeRemote;
    final preferRemote =
        choice == BackupSyncResumeChoice.remote ||
        choice == BackupSyncResumeChoice.mergeRemote;
    final sections = keys
        .where((key) => backupSyncPartGroup(key) == BackupSyncGroup.sections)
        .toList();
    final background = keys
        .where((key) => backupSyncPartGroup(key) == BackupSyncGroup.background)
        .toList();
    const policy = 'setting:$backupSyncGroupsKey';

    for (final block in [
      sections,
      background,
      for (final key in keys)
        if (!sections.contains(key) && !background.contains(key)) [key],
    ]) {
      if (block.isEmpty) continue;
      final first = block.first;
      if (!backupSyncPartEnabled(first, localSettings)) continue;
      final available =
          backupSyncPartEnabled(first, remoteSettings) &&
          (!block.contains('database') ||
              remoteParts.containsKey('database')) &&
          (!block.contains('resources') ||
              remoteParts.containsKey('resources'));
      bool changed(Map<String, dynamic> source) => block.any(
        (key) =>
            (source[key]?['hash'] ?? _absentHash) !=
            (common[key]?['hash'] ?? _absentHash),
      );
      final localChanged = changed(revisions);
      final remoteChanged = changed(remote.revisions);
      final takeRemote =
          first != policy &&
          available &&
          (merge
              ? block.any(remote.revisions.containsKey) &&
                    (!block.any(revisions.containsKey) ||
                        (localChanged == remoteChanged
                            ? preferRemote
                            : remoteChanged))
              : preferRemote);
      final source = takeRemote ? remoteParts : localParts;
      for (final key in block) {
        if (source.containsKey(key)) {
          combined[key] = source[key];
        } else {
          combined.remove(key);
        }
        final a = revisions[key] as Map?;
        final b = remote.revisions[key] as Map?;
        final hash = source.containsKey(key)
            ? (takeRemote ? b : a)!['hash']
            : _absentHash;
        if ((a == null || a['hash'] == hash) &&
            (b == null || b['hash'] == hash)) {
          clocks[key] = _newer(b, a) ? b : a;
        } else {
          // Beat the clocks of both inputs, including TVs with faster clocks.
          final time = max(a?['time'] as int? ?? 0, b?['time'] as int? ?? 0);
          if (time >= 8640000000000000) {
            throw const FormatException('Sync revision overflow');
          }
          clocks[key] = {'time': time + 1, 'device': device, 'hash': hash};
        }
      }
    }
    final result = _withParts(combined);
    validateBackup(result);
    return BackupSyncDocument(result, clocks);
  }

  static final _absentHash = backupFingerprint(null);

  /// Apply the final policy after all heads were merged, so head order cannot
  /// temporarily overwrite a block that a later head makes local.
  BackupSyncDocument preserveLocalGroups(BackupSyncDocument local) {
    final localSettings = local.backup['settings'] as Map;
    final settings = localSettings;
    final combined = <String, dynamic>{
      for (final e in parts(backup).entries)
        if (backupSyncPartEnabled(e.key, settings)) e.key: e.value,
      for (final e in parts(local.backup).entries)
        if (!backupSyncPartEnabled(e.key, settings)) e.key: e.value,
    };
    final result = local._withParts(combined);
    final clocks = <String, dynamic>{
      for (final e in revisions.entries)
        if (backupSyncPartEnabled(e.key, settings)) e.key: e.value,
      for (final e in local.revisions.entries)
        if (!backupSyncPartEnabled(e.key, settings)) e.key: e.value,
    };
    validateBackup(result);
    return BackupSyncDocument(result, clocks);
  }

  /// A selected sync copy contains only portable blocks; missing local blocks
  /// are filled from this TV before the full backup importer runs.
  Map<String, dynamic> restoreOver(BackupSyncDocument local) =>
      local._withParts({
        for (final e in parts(local.backup).entries)
          if (!backupSyncPartEnabled(e.key, local.backup['settings'] as Map) ||
              !backupSyncPartEnabled(e.key, backup['settings'] as Map))
            e.key: e.value,
        for (final e in parts(backup).entries)
          if (backupSyncPartEnabled(e.key, local.backup['settings'] as Map) &&
              backupSyncPartEnabled(e.key, backup['settings'] as Map))
            e.key: e.value,
      });
}
