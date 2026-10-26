import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/backup_assets.dart';

void main() {
  test('video is excluded from image backups; replacement can restore it on rollback', () async {
    final root = await Directory.systemTemp.createTemp('backup-video-');
    final video = await File('${root.path}/wallpaper_video')
        .writeAsBytes([1, 2, 3]);
    try {
      expect(await exportBackupAssets(root, {}), isEmpty);
      final staged = await BackupAssets.prepare(root, {}, {});
      await staged.installWallpapers(replace: true);
      expect(await video.exists(), false);
      await staged.rollback();
      expect(await video.readAsBytes(), [1, 2, 3]);
      final replacement = await BackupAssets.prepare(root, {}, {});
      await replacement.installWallpapers(replace: true);
      await replacement.finish();
      expect(await video.exists(), false);
    } finally {
      await root.delete(recursive: true);
    }
  });
}
