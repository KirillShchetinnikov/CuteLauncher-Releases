import 'package:flauncher/bridge_result.dart';

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'image_limits.dart';

class DocumentFiles {
  static Future<String?> saveDiagnostics(File file, {required String name}) =>
      _channel.invokeMethod<String>('saveDiagnosticsDocument', {
        'path': file.path,
        'name': name,
      });
  static Future<String?> saveBackupDownloads(File file) =>
      _channel.invokeMethod<String>('saveBackupDownloads', {'path': file.path});
  static const _channel = BridgeChannel('me.efesser.flauncher/method');

  static Future<XFile?> pickImage() async {
    if (!Platform.isAndroid) {
      return ImagePicker().pickImage(source: ImageSource.gallery);
    }
    final path = await _channel.invokeMethod<String>('pickImageDocument');
    return path == null ? null : XFile(path);
  }

  static Future<XFile?> pickWallpaper() async {
    if (!Platform.isAndroid) return ImagePicker().pickMedia();
    final path = await _channel.invokeMethod<String>('pickWallpaperDocument');
    return path == null ? null : XFile(path);
  }

  static Future<File?> pickBackup() async {
    final path = await _channel.invokeMethod<String>('pickBackupDocument');
    return path == null ? null : File(path);
  }

  static Future<bool?> saveBackup(
    File file, {
    String name = 'cutelauncher_backup.json',
  }) => _channel.invokeMethod<bool>('saveBackupDocument', {
    'path': file.path,
    'name': name,
  });

  static Future<void> releaseImage(XFile file) async {
    if (Platform.isAndroid) await File(file.path).delete();
  }

  static Future<Uint8List> readImage(XFile file) async {
    try {
      final bytes = await readBoundedImage(file.openRead());
      await validateImageBytes(bytes);
      return bytes;
    } finally {
      await releaseImage(file);
    }
  }
}
