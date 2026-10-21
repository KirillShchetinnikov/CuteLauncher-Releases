import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'image_limits.dart';

const maximumBackupBytes = 64 * 1024 * 1024;
const maximumBackupAssetBytes = 32 * 1024 * 1024;
const _wallpapers = {'wallpaper', 'wallpaper_day', 'wallpaper_night'};

bool _validAssetKey(String key) => _wallpapers.contains(key) ||
    RegExp(r'^custom_banner_[A-Za-z0-9._-]+$').hasMatch(key);

Future<Map<String, String>> exportBackupAssets(Directory root, Map<String, dynamic> settings) async {
  final files = <String, File>{for (final name in _wallpapers) name: File(path.join(root.path, name))};
  for (final entry in settings.entries.toList()) {
    if (entry.key.startsWith('custom_banner_')) {
      settings.remove(entry.key); // Never export device-specific absolute paths.
      if (_validAssetKey(entry.key) && entry.value is String) files[entry.key] = File(entry.value as String);
    }
  }
  var total = 0;
  final resources = <String, String>{};
  for (final entry in files.entries) {
    if (!await entry.value.exists()) continue;
    final bytes = await readBoundedImage(entry.value.openRead());
    await validateImageBytes(bytes);
    total += bytes.length;
    if (total > maximumBackupAssetBytes) throw const FormatException('Backup images exceed 32 MiB');
    resources[entry.key] = base64Encode(bytes);
  }
  return resources;
}

/// Validate every image in a staging directory before changing settings or DB.
class BackupAssets {
  final Directory root;
  final Directory stage;
  final Map<String, File> files;
  final Map<String, File?> _originalWallpapers = {};
  BackupAssets._(this.root, this.stage, this.files);

  static Future<BackupAssets> prepare(Directory root, dynamic resources, Map<String, dynamic> settings) async {
    if (resources != null && (resources is! Map || resources.length > 256)) throw const FormatException('Invalid backup images');
    await root.create(recursive: true);
    final stage = await root.createTemp('backup-assets-');
    final assets = BackupAssets._(root, stage, {});
    try {
      // Old archives may reference only resources already present in this app's
      // private documents directory; never install an unchecked foreign path.
      for (final entry in settings.entries.toList()) {
        if (!entry.key.startsWith('custom_banner_')) continue;
        if (entry.value is! String || !path.isWithin(root.path, entry.value as String) || !await File(entry.value as String).exists()) {
          settings.remove(entry.key);
        }
      }
      var total = 0;
      if (resources is Map) {
        for (final entry in resources.entries) {
        if (entry.key is! String || !_validAssetKey(entry.key as String) || entry.value is! String ||
            (entry.value as String).length > ((maximumImageInputBytes + 2) ~/ 3) * 4) {
          throw const FormatException('Invalid backup image');
        }
        final bytes = base64Decode(entry.value as String);
        total += bytes.length;
        if (total > maximumBackupAssetBytes) throw const FormatException('Backup images exceed 32 MiB');
        await validateImageBytes(bytes);
        final key = entry.key as String;
        final file = File(path.join(stage.path, key));
        await file.writeAsBytes(bytes, flush: true);
        assets.files[key] = file;
        if (key.startsWith('custom_banner_')) settings[key] = file.path;
      }
      }
      return assets;
    } catch (_) {
      await stage.delete(recursive: true);
      rethrow;
    }
  }

  Future<void> installWallpapers({bool replace = false}) async {
    for (final name in replace ? _wallpapers : files.keys.where(_wallpapers.contains)) {
      final target = File(path.join(root.path, name));
      File? previous;
      if (await target.exists()) previous = await target.copy(path.join(stage.path, 'previous-$name'));
      _originalWallpapers[name] = previous;
      if (files[name] != null) { await files[name]!.copy(target.path); }
      else if (await target.exists()) { await target.delete(); }
    }
  }

  Future<void> rollback() async {
    for (final entry in _originalWallpapers.entries) {
      final target = File(path.join(root.path, entry.key));
      if (entry.value != null) {
        await entry.value!.copy(target.path);
      } else if (await target.exists()) {
        await target.delete();
      }
    }
    if (await stage.exists()) await stage.delete(recursive: true);
  }

  Future<void> finish() async {
    for (final file in _originalWallpapers.values.whereType<File>()) {
      if (await file.exists()) await file.delete();
    }
    for (final entry in files.entries.where((e) => _wallpapers.contains(e.key))) {
      if (await entry.value.exists()) await entry.value.delete();
    }
    if (!files.keys.any((key) => key.startsWith('custom_banner_'))) await stage.delete(recursive: true);
  }
}
