import 'package:flauncher/bridge_result.dart';

import 'dart:io';

import 'package:flutter/widgets.dart';

import 'widgets/file_selection.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'image_limits.dart';

typedef DocumentExporter = Future<String?> Function(
  File file, {
  required String name,
});

class DocumentFiles {
  static Future<String?> saveDiagnostics(
    File file, {
    required String name,
    BuildContext? context,
    ValueChanged<String>? onSaved,
  }) => context != null
      ? FileSelection.select<String>(
          context,
          'saveDiagnosticsDocument',
          onSaved: onSaved,
          arguments: {'path': file.path, 'name': name},
        )
      : _channel.invokeMethod<String>('saveDiagnosticsDocument', {
          'path': file.path,
          'name': name,
        });
  static Future<String?> saveBackupDownloads(File file) =>
      _channel.invokeMethod<String>('saveBackupDownloads', {'path': file.path});
  static const _channel = BridgeChannel('me.efesser.flauncher/method');

  static Future<XFile?> pickImage({BuildContext? context}) async {
    if (context == null && !Platform.isAndroid) {
      return ImagePicker().pickImage(source: ImageSource.gallery);
    }
    final path = await (context != null
        ? FileSelection.select<String>(context, 'pickImageDocument')
        : _channel.invokeMethod<String>('pickImageDocument'));
    return path == null ? null : XFile(path);
  }

  static Future<XFile?> pickWallpaper({BuildContext? context}) async {
    if (context == null && !Platform.isAndroid) {
      return ImagePicker().pickMedia();
    }
    final path = await (context != null
        ? FileSelection.select<String>(context, 'pickWallpaperDocument')
        : _channel.invokeMethod<String>('pickWallpaperDocument'));
    return path == null ? null : XFile(path);
  }

  static Future<String?> pickWebhookText({BuildContext? context}) async {
    final path = await (context != null
        ? FileSelection.select<String>(context, 'pickWebhookDocument')
        : _channel.invokeMethod<String>('pickWebhookDocument'));
    if (path == null) return null;
    final file = File(path);
    try {
      if (await file.length() > 64 * 1024) {
        throw const FormatException('Webhook document too large');
      }
      return await file.readAsString();
    } finally {
      await file.delete();
    }
  }

  static Future<File?> pickBackup({BuildContext? context}) async {
    final path = await (context != null
        ? FileSelection.select<String>(context, 'pickBackupDocument')
        : _channel.invokeMethod<String>('pickBackupDocument'));
    return path == null ? null : File(path);
  }

  static Future<bool?> saveBackup(
    File file, {
    String name = 'cutelauncher_backup.json',
    BuildContext? context,
    ValueChanged<String>? onSaved,
  }) => context != null
      ? FileSelection.select<bool>(
          context,
          'saveBackupDocument',
          onSaved: onSaved,
          arguments: {'path': file.path, 'name': name},
        )
      : _channel.invokeMethod<bool>('saveBackupDocument', {
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
