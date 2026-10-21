import 'dart:io';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/local_backup_storage.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late DriveBackupService drive;
  late LocalBackupStorage storage;
  final name = 'cute-backup-shared-${'a' * 32}-100-${'b' * 16}.json';
  setUp(() async {
    root = await Directory.systemTemp.createTemp('local-storage-');
    drive = DriveBackupService();
    storage = LocalBackupStorage(
      NativeCloudAccountRepository(),
      drive,
      directory: () async => root,
    );
  });
  tearDown(() async {
    drive.dispose();
    await root.delete(recursive: true);
  });
  test(
    'immutable local snapshots list, download, delete; unrelated files survive',
    () async {
      final source = await File('${root.path}/source.json')
          .writeAsString('{"v":3}');
      await storage.upload(source, name);
      final unrelated = await File('${root.path}/backup_storage/notes.txt')
          .writeAsString('keep');
      final files = await storage.list();
      expect(files.map((v) => v.name), [name]);
      final target = await root.createTemp('download-');
      expect(
        await (await storage.download(files.single, target)).readAsString(),
        '{"v":3}',
      );
      await expectLater(storage.upload(source, name), throwsStateError);
      await storage.delete(files.single);
      expect(await storage.list(), isEmpty);
      expect(await unrelated.readAsString(), 'keep');
    },
  );
  test('rejects traversal and cancelled operations', () async {
    await expectLater(
      storage.delete(const RemoteBackupFile('../notes', '../notes')),
      throwsArgumentError,
    );
    storage.cancel();
    await expectLater(storage.list(), throwsStateError);
  });
}
