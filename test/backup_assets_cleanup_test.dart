import 'dart:io';

import 'package:flauncher/backup_assets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cute-asset-cleanup-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('cleanup preserves unknown directories, names and nested contents', () async {
    final managed = await Directory('${root.path}/backup-assets-known').create();
    final user = await Directory('${root.path}/user-images').create();
    final nested = await Directory('${managed.path}/nested').create();
    final keep = [
      File('${root.path}/custom_banner_root.app'),
      File('${user.path}/custom_banner_user.app'),
      File('${managed.path}/notes.txt'),
      File('${managed.path}/previous-wallpaper'),
      File('${nested.path}/custom_banner_nested.app'),
    ];
    for (final file in keep) {
      await file.writeAsString('keep');
    }
    final obsolete = await File('${managed.path}/custom_banner_old.app').writeAsString('old');
    await cleanupUnusedBackupAssets(root, []);
    expect(await obsolete.exists(), false);
    for (final file in keep) {
      expect(await file.readAsString(), 'keep');
    }
  });

  test('cleanup does not follow directory or file links and resolves live aliases', () async {
    final managed = await Directory('${root.path}/backup-assets-owned').create();
    final outside = await Directory.systemTemp.createTemp('cute-user-images-');
    addTearDown(() => outside.delete(recursive: true));
    final external = await File('${outside.path}/custom_banner_user.app').writeAsString('user');
    final live = await File('${managed.path}/custom_banner_live.app').writeAsString('live');
    final alias = Link('${root.path}/live-alias');
    final directoryLink = Link('${root.path}/backup-assets-linked');
    final fileLink = Link('${managed.path}/custom_banner_link.app');
    try {
      await directoryLink.create(outside.path);
      await fileLink.create(external.path);
      await alias.create(live.path);
    } on FileSystemException catch (error) {
      if (!Platform.isWindows || ![5, 1314].contains(error.osError?.errorCode)) rethrow;
      markTestSkipped('Windows account cannot create symbolic links');
      return;
    }
    await cleanupUnusedBackupAssets(root, [alias.path]);
    expect(await external.readAsString(), 'user');
    expect(await live.readAsString(), 'live');
    expect(await directoryLink.exists(), true);
    expect(await fileLink.exists(), true);
  });
}
