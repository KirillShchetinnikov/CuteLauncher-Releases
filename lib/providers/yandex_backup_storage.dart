import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../backup_assets.dart';
import '../cloud_account.dart';
import 'backup_storage.dart';

/// The OAuth application folder is the only namespace this transport can access.
class YandexBackupStorage extends BackupStorage {
  YandexBackupStorage(super.webdav, super.drive, {super.clientFactory})
    : super(google: false);

  HttpClient? _client;
  bool _cancelled = false;
  Future<String>? _authorization;

  @override
  void cancel() {
    _cancelled = true;
    _client?.close(force: true);
  }

  void _check() {
    if (_cancelled) throw const CloudBackupException('cancelled');
  }

  Future<T> _use<T>(Future<T> Function(HttpClient, String) action) async {
    _check();
    final client = clientFactory()
      ..connectionTimeout = const Duration(seconds: 8)
      ..autoUncompress = false;
    _client = client;
    try {
      return await (() async {
        final header = await (_authorization ??= drive.authorization());
        _check();
        return action(client, header);
      })().timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          cancel();
          throw const CloudBackupException('timeout');
        },
      );
    } on CloudBackupException {
      rethrow;
    } on TimeoutException {
      throw const CloudBackupException('timeout');
    } catch (_) {
      _check();
      throw const CloudBackupException('network');
    } finally {
      client.close(force: true);
      if (identical(_client, client)) _client = null;
    }
  }

  void _status(HttpClientResponse response, Set<int> allowed) {
    if (allowed.contains(response.statusCode)) return;
    throw CloudBackupException(switch (response.statusCode) {
      401 || 403 => 'authorization',
      404 => 'missing',
      409 || 412 => 'conflict',
      >= 300 && < 400 => 'redirect',
      _ => 'server',
    }, httpStatus: response.statusCode);
  }

  Future<List<int>> _bytes(HttpClientResponse response, int limit) async {
    if (response.contentLength > limit) {
      throw const CloudBackupException('size');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      _check();
      if (bytes.length + chunk.length > limit) {
        throw const CloudBackupException('size');
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  Future<Map> _api(
    HttpClient client,
    String header,
    String method,
    String endpoint,
    Map<String, String> query, {
    Set<int> allowed = const {200},
  }) async {
    _check();
    final request = await client.openUrl(
      method,
      Uri.https('cloud-api.yandex.net', '/v1/disk/resources$endpoint', query),
    );
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, header);
    final response = await request.close();
    _status(response, allowed);
    final bytes = await _bytes(response, 1024 * 1024);
    if (bytes.isEmpty) {
      if (response.statusCode == 202) {
        throw const CloudBackupException('response');
      }
      return {};
    }
    final result = jsonDecode(utf8.decode(bytes)) as Map;
    if (response.statusCode == 202 && result['href'] is! String) {
      throw const CloudBackupException('response');
    }
    return result;
  }

  // Transfer URLs are signed capabilities. Never send account tokens to them.
  Uri _transferUrl(Map data, String method) {
    final url = data['href'] is String
        ? Uri.tryParse(data['href'] as String)
        : null;
    if (url == null ||
        url.scheme != 'https' ||
        url.userInfo.isNotEmpty ||
        url.port != 443 ||
        url.hasFragment ||
        data['method'] != method ||
        !(url.host.endsWith('.yandex.net') ||
            url.host.endsWith('.yandex.ru'))) {
      throw const CloudBackupException('response');
    }
    return url;
  }

  String _path(RemoteBackupFile file, {bool temporary = false}) {
    if (!(temporary
            ? BackupStorage.temporaryName(file.name)
            : BackupStorage.validName.hasMatch(file.name)) ||
        file.id != 'app:/${file.name}') {
      throw const CloudBackupException('configuration');
    }
    return file.id;
  }

  @override
  Future<List<RemoteBackupFile>> list() => _listing(false);
  @override
  Future<List<RemoteBackupFile>> temporaryFiles() => _listing(true);

  Future<List<RemoteBackupFile>> _listing(bool temporary) => _use((
    client,
    header,
  ) async {
    final result = <RemoteBackupFile>[];
    var offset = 0;
    while (true) {
      Map data;
      try {
        data = await _api(client, header, 'GET', '', {
          'path': 'app:/',
          'limit': '100',
          'offset': '$offset',
          'sort': 'name',
        });
      } on CloudBackupException catch (error) {
        if (error.code == 'missing' && offset == 0) return result;
        rethrow;
      }
      final embedded = data['_embedded'];
      if (embedded is! Map ||
          embedded['items'] is! List ||
          embedded['total'] is! int) {
        throw const CloudBackupException('response');
      }
      final items = embedded['items'] as List;
      final total = embedded['total'] as int;
      if (total > 4096 || offset + items.length > 4096) {
        throw const CloudBackupException('size');
      }
      for (final item in items) {
        if (item is! Map || item['type'] != 'file' || item['name'] is! String) {
          continue;
        }
        final name = item['name'] as String;
        if (temporary
            ? BackupStorage.temporaryName(name)
            : BackupStorage.validName.hasMatch(name)) {
          result.add(RemoteBackupFile(name, 'app:/$name'));
        }
      }
      offset += items.length;
      if (offset >= total) return result;
      if (items.isEmpty) throw const CloudBackupException('response');
    }
  });

  @override
  Future<void> upload(File file, String name) => _use((client, header) async {
    if (!BackupStorage.validName.hasMatch(name)) {
      throw const CloudBackupException('configuration');
    }
    final size = await file.length();
    if (size == 0 || size > maximumBackupBytes) {
      throw const CloudBackupException('size');
    }
    final link = await _api(client, header, 'GET', '/upload', {
      'path': 'app:/$name',
      'overwrite': 'false',
    });
    _check();
    final request = await client.openUrl('PUT', _transferUrl(link, 'PUT'));
    request.followRedirects = false;
    request.contentLength = size;
    await request.addStream(file.openRead());
    final response = await request.close();
    _status(response, {201});
    await _bytes(response, 65536);
  });

  @override
  Future<File> download(RemoteBackupFile file, Directory target) => _use((
    client,
    header,
  ) async {
    final link = await _api(client, header, 'GET', '/download', {
      'path': _path(file),
    });
    _check();
    final request = await client.openUrl('GET', _transferUrl(link, 'GET'));
    request.followRedirects = false;
    final response = await request.close();
    _status(response, {200});
    if (response.contentLength > maximumBackupBytes) {
      throw const CloudBackupException('size');
    }
    final pending = File('${target.path}/${file.name}.partial');
    final writer = await pending.open(mode: FileMode.write);
    var size = 0;
    try {
      await for (final chunk in response) {
        _check();
        size += chunk.length;
        if (size > maximumBackupBytes) throw const CloudBackupException('size');
        await writer.writeFrom(chunk);
      }
      if (size == 0 ||
          response.contentLength >= 0 && size != response.contentLength) {
        throw const CloudBackupException('file');
      }
      await writer.flush();
    } catch (_) {
      await writer.close();
      await pending.delete();
      rethrow;
    }
    await writer.close();
    _check();
    return pending.rename('${target.path}/${file.name}');
  });

  @override
  Future<void> delete(RemoteBackupFile file) => _delete(file, false);
  @override
  Future<void> deleteTemporary(RemoteBackupFile file) => _delete(file, true);
  Future<void> _delete(RemoteBackupFile file, bool temporary) => _use((
    client,
    header,
  ) async {
    final result = await _api(
      client,
      header,
      'DELETE',
      '',
      {'path': _path(file, temporary: temporary), 'permanently': 'true'},
      allowed: {202, 204, 404},
    );
    if (!result.containsKey('href')) return;
    final url = Uri.tryParse(result['href'] as String);
    if (url == null ||
        url.origin != 'https://cloud-api.yandex.net' ||
        url.userInfo.isNotEmpty ||
        url.hasFragment ||
        !url.path.startsWith('/v1/disk/operations/')) {
      throw const CloudBackupException('response');
    }
    while (true) {
      _check();
      final request = await client.openUrl('GET', url);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.authorizationHeader, header);
      final response = await request.close();
      _status(response, {200});
      final status = (jsonDecode(
        utf8.decode(await _bytes(response, 65536)),
      ) as Map)['status'];
      if (status == 'success') return;
      if (status != 'in-progress') throw const CloudBackupException('server');
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  });
}
