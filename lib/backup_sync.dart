import 'dart:convert';

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
  Map<String, Object?> toJson() => {
    'syncVersion': 2,
    'backup': {
      for (final e in backup.entries)
        if (e.key != 'settings' &&
            (!databaseKeys.contains(e.key) ||
                backupSyncPartEnabled('database', backup['settings'] as Map)) &&
            (e.key != 'resources' ||
                backupSyncPartEnabled('resources', backup['settings'] as Map)))
          e.key: e.value,
      'settings': {
        for (final e in (backup['settings'] as Map).entries)
          if (!isDeviceLocalBackupKey(e.key as String) &&
              backupSyncPartEnabled(
                'setting:${e.key}',
                backup['settings'] as Map,
              ))
            e.key: e.value,
      },
    },
    'revisions': {
      for (final e in revisions.entries)
        if (backupSyncPartEnabled(e.key, backup['settings'] as Map))
          e.key: e.value,
    },
  };
  static Map<String, dynamic> parts(Map<String, dynamic> backup) => {
    if (databaseKeys.every(backup.containsKey))
      'database': {for (final k in databaseKeys) k: backup[k]},
    if (backup.containsKey('resources')) 'resources': backup['resources'],
    for (final e in (backup['settings'] as Map).entries)
      if (!isDeviceLocalBackupKey(e.key as String)) 'setting:${e.key}': e.value,
  };

  factory BackupSyncDocument.parse(Object? source) {
    if (source is! Map ||
        ![1, 2].contains(source['syncVersion']) ||
        source['backup'] is! Map ||
        source['revisions'] is! Map) {
      throw const FormatException('Invalid sync archive');
    }
    final backup = Map<String, dynamic>.from(source['backup'] as Map);
    if (backup['version'] != 3 || backup['settings'] is! Map) {
      throw const FormatException('Invalid backup');
    }
    disabledBackupSyncGroups((backup['settings'] as Map)[backupSyncGroupsKey]);
    if (source['syncVersion'] == 2 &&
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
    if (source['syncVersion'] == 2 &&
        !hasLegacyBackupSyncGroups(
          (backup['settings'] as Map)[backupSyncGroupsKey],
        )) {
      final settings = backup['settings'] as Map;
      if ((tables != 0) != backupSyncPartEnabled('database', settings) ||
          backup.containsKey('resources') !=
              backupSyncPartEnabled('resources', settings) ||
          parts(backup).keys
              .any((key) => !backupSyncPartEnabled(key, settings)) ||
          revisions.keys.any((key) => !backupSyncPartEnabled(key, settings))) {
        throw const FormatException('Inconsistent sync blocks');
      }
    }
    for (final e in parts(backup).entries) {
      if (revisions[e.key]?['hash'] != backupFingerprint(e.value)) {
        throw const FormatException('Invalid fingerprint');
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
              entry.key.startsWith('setting:')) ||
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
    for (final key in {...partsNow.keys, ...revisions.keys}) {
      final hash = backupFingerprint(partsNow[key]);
      if (revisions[key]?['hash'] != hash) {
        revisions[key] = {
          'time': changedTimes[key] ?? time.millisecondsSinceEpoch,
          'device': device,
          'hash': hash,
        };
      }
    }
    return BackupSyncDocument(backup, revisions);
  }

  BackupSyncDocument merge(BackupSyncDocument remote) {
    final localParts = parts(backup), remoteParts = parts(remote.backup);
    final merged = <String, dynamic>{}, clocks = <String, dynamic>{};
    for (final key in {...revisions.keys, ...remote.revisions.keys}) {
      final a = revisions[key] as Map?, b = remote.revisions[key] as Map?;
      final fromRemote =
          b != null &&
          (a == null ||
              b['time'] > a['time'] ||
              b['time'] == a['time'] &&
                  (b['device'] as String).compareTo(a['device'] as String) > 0);
      final source = fromRemote ? remoteParts : localParts;
      clocks[key] = fromRemote ? b : a;
      if (source.containsKey(key)) merged[key] = source[key];
    }
    final result = <String, dynamic>{
      ...backup,
      ...?(merged['database'] as Map?)?.cast<String, dynamic>(),
      if (merged.containsKey('resources')) 'resources': merged['resources'],
      'settings': {
        for (final e in merged.entries)
          if (e.key.startsWith('setting:')) e.key.substring(8): e.value,
      },
    };
    validateBackup(result);
    return BackupSyncDocument(result, clocks);
  }

  /// Apply the final policy after all heads were merged, so head order cannot
  /// temporarily overwrite a block that a later head makes local.
  BackupSyncDocument preserveLocalGroups(BackupSyncDocument local) {
    final settings = backup['settings'] as Map;
    final localSettings = local.backup['settings'] as Map;
    final result = <String, dynamic>{
      ...backup,
      if (!backupSyncPartEnabled('database', settings))
        for (final key in databaseKeys) key: local.backup[key],
      if (!backupSyncPartEnabled('resources', settings))
        'resources': local.backup['resources'],
      'settings': {
        for (final e in settings.entries)
          if (backupSyncPartEnabled('setting:${e.key}', settings))
            e.key: e.value,
        for (final e in localSettings.entries)
          if (!backupSyncPartEnabled('setting:${e.key}', settings))
            e.key: e.value,
      },
    };
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
      BackupSyncDocument({
        ...local.backup,
        ...backup,
        'settings': {
          backupSyncGroupsKey:
              (local.backup['settings'] as Map)[backupSyncGroupsKey] ??
              <String>[],
          ...(backup['settings'] as Map).cast<String, dynamic>(),
        },
      }, revisions).preserveLocalGroups(local).backup;
}
