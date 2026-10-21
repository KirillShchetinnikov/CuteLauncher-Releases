import 'dart:io';

import '../bridge_result.dart';
import '../backup_assets.dart';
import 'backup_storage.dart';

/// Selected SAF tree or private folder; the same immutable format as cloud.
class LocalBackupStorage extends BackupStorage {
  static const downloadsFolder = 'cutelauncher://downloads/CuteLauncher';
  static const channel = BridgeChannel('me.efesser.flauncher/method');
  final Future<Directory> Function() directory;
  final String? tree;
  bool _cancelled = false;
  LocalBackupStorage(
    super.webdav,
    super.drive, {
    required this.directory,
    this.tree,
  }) : super(google: false);

  @override
  void cancel() {
    _cancelled = true;
  }

  void _check() {
    if (_cancelled) throw StateError('Local operation cancelled');
  }

  Future<Directory> _root() async {
    _check();
    return Directory('${(await directory()).path}/backup_storage')
        .create(recursive: true);
  }

  Future<T?> _call<T>(String operation, {String? name, String? path}) async {
    _check();
    final value = await channel.invokeMethod<T>('backupFolderOperation', {
      'operation': operation,
      'uri': tree,
      'name': name,
      'path': path,
    });
    _check();
    if (value == null || value == false) {
      throw StateError('Folder operation unavailable');
    }
    return value;
  }

  @override
  Future<List<RemoteBackupFile>> list() async {
    if (tree != null) {
      final values = await _call<List<dynamic>>('list');
      return values!
          .map((v) => RemoteBackupFile(v['name'] as String, v['id'] as String))
          .where((v) => BackupStorage.validName.hasMatch(v.name))
          .toList();
    }
    final result = <RemoteBackupFile>[];
    var count = 0;
    await for (final entity in (await _root()).list(followLinks: false)) {
      _check();
      if (++count > 4096) throw StateError('Too many local files');
      final name = entity.uri.pathSegments.last;
      if (entity is File && BackupStorage.validName.hasMatch(name)) {
        result.add(RemoteBackupFile(name, name));
      }
    }
    return result;
  }

  void _name(String name) {
    _check();
    if (!BackupStorage.validName.hasMatch(name)) {
      throw ArgumentError('Invalid backup name');
    }
  }

  @override
  Future<void> upload(File file, String name) async {
    _name(name);
    if (await file.length() > maximumBackupBytes) {
      throw StateError('Backup too large');
    }
    if (tree != null) {
      await _call<bool>('upload', name: name, path: file.path);
      return;
    }
    final root = await _root(), target = File('${(await _root()).path}/$name');
    if (await target.exists()) throw StateError('Backup already exists');
    final pending = File('${root.path}/$name.partial');
    try {
      await file.copy(pending.path);
      _check();
      await pending.rename(target.path);
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  @override
  Future<File> download(RemoteBackupFile file, Directory target) async {
    _name(file.name);
    final output = File('${target.path}/${file.name}');
    if (tree != null) {
      await _call<bool>('download', name: file.name, path: output.path);
      return output;
    }
    final source = File('${(await _root()).path}/${file.name}');
    if (await source.length() > maximumBackupBytes) {
      throw StateError('Backup too large');
    }
    final result = await source.copy(output.path);
    _check();
    return result;
  }

  @override
  Future<void> delete(RemoteBackupFile file) async {
    _name(file.name);
    if (tree != null) {
      await _call<bool>('delete', name: file.name);
      return;
    }
    final target = File('${(await _root()).path}/${file.name}');
    if (await target.exists()) await target.delete();
  }
}
