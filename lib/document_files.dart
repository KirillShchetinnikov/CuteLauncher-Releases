import 'package:flauncher/bridge_result.dart';

import 'dart:io';
import 'dart:convert';

import 'package:flutter/widgets.dart';

import 'widgets/file_selection.dart';
import 'providers/settings_service.dart';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'image_limits.dart';
import 'drive_client_configuration.dart';

typedef DocumentExporter = Future<String?> Function(
  File file, {
  required String name,
});

class _PickedImage extends XFile {
  final String selectionKey;
  final String? sourceFolder;
  _PickedImage(super.path, this.selectionKey, this.sourceFolder);
}

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

  static Future<XFile?> pickImage({
    BuildContext? context,
    String? selectionKey,
  }) async {
    if (context == null && !Platform.isAndroid) {
      return ImagePicker().pickImage(source: ImageSource.gallery);
    }
    String? sourceFolder;
    final path = await (context != null
        ? FileSelection.select<String>(
            context,
            'pickImageDocument',
            selectionKey: selectionKey,
            onSelectedFolder: (value) => sourceFolder = value,
          )
        : _channel.invokeMethod<String>('pickImageDocument'));
    return path == null
        ? null
        : selectionKey == null
        ? XFile(path)
        : _PickedImage(path, selectionKey, sourceFolder);
  }

  static Future<XFile?> pickWallpaper({
    BuildContext? context,
    String? selectionKey,
  }) async {
    if (context == null && !Platform.isAndroid) {
      return ImagePicker().pickMedia();
    }
    String? sourceFolder;
    final path = await (context != null
        ? FileSelection.select<String>(
            context,
            'pickWallpaperDocument',
            selectionKey: selectionKey,
            onSelectedFolder: (value) => sourceFolder = value,
          )
        : _channel.invokeMethod<String>('pickWallpaperDocument'));
    return path == null
        ? null
        : selectionKey == null
        ? XFile(path)
        : _PickedImage(path, selectionKey, sourceFolder);
  }

  /// Commit the source only after the consumer has validated and applied the image.
  static Future<void> rememberImageSelection(
    XFile file,
    SettingsService settings,
  ) async {
    if (file is! _PickedImage) return;
    try {
      await settings.rememberFileBrowserLocation(
        'selected:${file.selectionKey}',
        file.sourceFolder,
      );
    } catch (_) {
      /* Navigation history must not fail a successfully applied image. */
    }
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

  static Future<String?> pickWeatherTokenText(BuildContext context) =>
      _pickWeatherText(context, 'pickWeatherTokenDocument');

  static Future<String?> pickWeatherServerText(BuildContext context) =>
      _pickWeatherText(context, 'pickWeatherServerDocument');

  static Future<String?> _pickWeatherText(
    BuildContext context,
    String operation,
  ) async {
    final bytes = await FileSelection.select<Uint8List>(context, operation);
    if (bytes == null) return null;
    try {
      return utf8.decode(bytes);
    } finally {
      try {
        bytes.fillRange(0, bytes.length, 0);
      } on UnsupportedError {
        // Engine messages may own an unmodifiable buffer. Clearing is best effort
        // and must not turn a decoded document into an import error.
      }
    }
  }

  static Future<String?> pickDriveClientText({BuildContext? context}) async {
    final path = await (context != null
        ? FileSelection.select<String>(context, 'pickDriveClientDocument')
        : _channel.invokeMethod<String>('pickDriveClientDocument'));
    if (path == null) return null;
    final file = File(path);
    try {
      final bytes = <int>[];
      await for (final chunk in file.openRead()) {
        if (bytes.length + chunk.length >
            DriveClientConfiguration.maximumBytes) {
          throw const FormatException('Google Drive client document too large');
        }
        bytes.addAll(chunk);
      }
      return utf8.decode(bytes);
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
