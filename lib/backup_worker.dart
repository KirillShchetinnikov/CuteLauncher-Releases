import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'backup_assets.dart';
import 'backup_sync.dart';
import 'image_limits.dart';

// Top-level entry points deliberately capture only sendable document data,
// never service instances, channels, preferences, or database connections.
Future<Map<String, dynamic>> readBackupJson(String file) => Isolate.run(() async {
  final bytes = await readBoundedImage(File(file).openRead(), limit: maximumBackupBytes);
  return Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map);
});

Future<void> writeBackupJson(String file, Object? document) => Isolate.run(() async {
  await File(file).writeAsString(jsonEncode(document), flush: true);
});

Future<String> fingerprintBackup(Object? document) =>
    Isolate.run(() => backupFingerprint(document));

Future<BackupSyncDocument> captureBackup(Map<String, dynamic> data,
    BackupSyncDocument? baseline, String device, DateTime now, Map<String, int> times) =>
    Isolate.run(() => BackupSyncDocument.capture(data, baseline, device, now, changedTimes: times));

Future<BackupSyncDocument> mergeBackup(BackupSyncDocument local, Map<String, dynamic> remote) =>
    Isolate.run(() => local.merge(BackupSyncDocument.parse(remote)));

Future<BackupSyncDocument> preserveBackupGroups(BackupSyncDocument merged, BackupSyncDocument original) =>
    Isolate.run(() => merged.preserveLocalGroups(original));
