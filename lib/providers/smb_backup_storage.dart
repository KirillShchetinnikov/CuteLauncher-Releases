import 'dart:io';

import '../backup_assets.dart';
import '../cloud_account.dart';
import 'backup_storage.dart';
import 'smb_backup_service.dart';

/// Each native operation verifies the original account identity before I/O.
class SmbBackupStorage extends BackupStorage {
  final SmbBackupCalls calls;
  Future<String?>? _identity;
  bool _cancelled = false;
  SmbBackupStorage(super.webdav, super.drive, {required String profile})
    : calls = SmbBackupCalls(profile),
      super(google: false);

  void _check() {
    if (_cancelled) throw const CloudBackupException('cancelled');
  }

  Future<T?> _call<T>(
    String method, [
    Map<String, Object?> fields = const {},
  ]) async {
    _check();
    final identity = await (_identity ??= calls.call<String>('identity'));
    _check();
    if (identity == null || identity.isEmpty) {
      throw const CloudBackupException('configuration');
    }
    final result = await calls.call<T>(method, {
      ...fields,
      'identity': identity,
    });
    _check();
    return result;
  }

  @override
  void cancel() {
    _cancelled = true;
    calls.cancel();
  }

  Future<List<RemoteBackupFile>> _list(bool temporary) async {
    final data = await _call<List>(temporary ? 'listTemporary' : 'list');
    if (data == null || data.length > 4096) {
      throw const CloudBackupException('response');
    }
    return [
      for (final item in data)
        if (item is Map &&
            item['name'] is String &&
            item['id'] == item['name'] &&
            (temporary
                ? BackupStorage.temporaryName(item['name'])
                : BackupStorage.validName.hasMatch(item['name'])))
          RemoteBackupFile(item['name'], item['id']),
    ];
  }

  @override
  Future<List<RemoteBackupFile>> list() => _list(false);
  @override
  Future<List<RemoteBackupFile>> temporaryFiles() => _list(true);

  void _name(RemoteBackupFile file, {bool temporary = false}) {
    if (file.id != file.name ||
        !(temporary
            ? BackupStorage.temporaryName(file.name)
            : BackupStorage.validName.hasMatch(file.name))) {
      throw const CloudBackupException('configuration');
    }
  }

  @override
  Future<void> upload(File file, String name) async {
    _name(RemoteBackupFile(name, name));
    final size = await file.length();
    if (size == 0 || size > maximumBackupBytes) {
      throw const CloudBackupException('size');
    }
    if (await _call<bool>('upload', {'name': name, 'path': file.path}) != true) {
      throw const CloudBackupException('file');
    }
  }

  @override
  Future<File> download(RemoteBackupFile file, Directory target) async {
    _name(file);
    final pending = File('${target.path}/${file.name}.partial');
    try {
      if (await _call<bool>('download', {
            'name': file.name,
            'path': pending.path,
          }) !=
          true) {
        throw const CloudBackupException('file');
      }
      final size = await pending.length();
      if (size == 0 || size > maximumBackupBytes) {
        throw const CloudBackupException('size');
      }
      _check();
      return await pending.rename('${target.path}/${file.name}');
    } catch (_) {
      if (await pending.exists()) await pending.delete();
      rethrow;
    }
  }

  @override
  Future<void> delete(RemoteBackupFile file) async {
    _name(file);
    if (await _call<bool>('delete', {'name': file.name}) != true) {
      throw const CloudBackupException('file');
    }
  }

  @override
  Future<void> deleteTemporary(RemoteBackupFile file) async {
    _name(file, temporary: true);
    if (await _call<bool>('deleteTemporary', {'name': file.name}) != true) {
      throw const CloudBackupException('file');
    }
  }
}
