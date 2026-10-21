import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:xml/xml.dart';

import '../backup_assets.dart';
import '../cloud_account.dart';
import 'drive_backup_service.dart';

class RemoteBackupFile {
  final String name, id;
  const RemoteBackupFile(this.name, this.id);
}

/// Only immutable, app-owned objects. Devices never overwrite another head.
class BackupStorage {
  final CloudAccountRepository webdav;
  final DriveBackupService drive;
  final bool google;
  final HttpClient Function() clientFactory;
  HttpClient? _active;
  BackupStorage(
    this.webdav,
    this.drive, {
    required this.google,
    HttpClient Function()? clientFactory,
  }) : clientFactory = clientFactory ?? HttpClient.new;
  void cancel() => _active?.close(force: true);
  Future<T> _use<T>(
    Future<T> Function(HttpClient client, CloudAuthorization auth) action,
  ) async {
    final client = clientFactory()
      ..connectionTimeout = const Duration(seconds: 8)
      ..autoUncompress = false;
    _active = client;
    try {
      return await (() async {
        final auth = google
            ? CloudAuthorization(
                Uri.https('www.googleapis.com', '/'),
                await drive.authorization(),
              )
            : await webdav.authorization();
        return action(client, auth);
      })().timeout(const Duration(seconds: 90));
    } on CloudBackupException {
      rethrow;
    } on TimeoutException {
      throw const CloudBackupException('timeout');
    } catch (_) {
      throw const CloudBackupException('network');
    } finally {
      client.close(force: true);
      if (identical(_active, client)) _active = null;
    }
  }

  Future<HttpClientRequest> _request(
    HttpClient client,
    CloudAuthorization auth,
    String method,
    Uri url,
  ) async {
    if (url.origin != auth.directory.origin ||
        (!google && !url.path.startsWith(auth.directory.path))) {
      throw const CloudBackupException('configuration');
    }
    final request = await client.openUrl(method, url);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, auth.header);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    return request;
  }

  void _status(HttpClientResponse response, Set<int> allowed) {
    if (!allowed.contains(response.statusCode)) {
      throw CloudBackupException(switch (response.statusCode) {
        401 || 403 => 'authorization',
        404 => 'missing',
        412 => 'conflict',
        >= 300 && < 400 => 'redirect',
        _ => 'server',
      });
    }
  }

  Future<List<int>> _bytes(HttpClientResponse response, int maximum) async {
    if (response.contentLength > maximum) {
      throw const CloudBackupException('size');
    }
    final bytes = <int>[];
    await for (final chunk in response) {
      if (bytes.length + chunk.length > maximum) {
        throw const CloudBackupException('size');
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  static final validName = RegExp(
    r'^cute-(backup|sync)-(shared|[a-f0-9]{32})-[a-f0-9]{32}-[0-9]+-[a-f0-9]{16}\.json$',
  );
  // Private markers distinguish our files from user files with similar names.
  static const _driveBackupQuery =
      "trashed = false and appProperties has { key='cutelauncher' and value='backup' }";

  Future<String> _driveFolder(
    HttpClient client,
    CloudAuthorization auth,
  ) async {
    final lookup = await _request(
      client,
      auth,
      'GET',
      Uri.https('www.googleapis.com', '/drive/v3/files', {
        'spaces': 'drive',
        'q': "trashed = false and mimeType = 'application/vnd.google-apps.folder' and appProperties has { key='cutelauncher' and value='backup-folder' }",
        'fields': 'files(id)',
        'pageSize': '1',
        'orderBy': 'createdTime',
      }),
    );
    final found = await lookup.close();
    _status(found, {200});
    final entries =
        (jsonDecode(utf8.decode(await _bytes(found, 65536))) as Map)['files']
            as List;
    if (entries.isNotEmpty) return entries.first['id'] as String;
    final create = await _request(
      client,
      auth,
      'POST',
      Uri.https('www.googleapis.com', '/drive/v3/files', {'fields': 'id'}),
    );
    create.headers.contentType = ContentType.json;
    create.write(
      jsonEncode({
        'name': 'CuteLauncher',
        'mimeType': 'application/vnd.google-apps.folder',
        'appProperties': {'cutelauncher': 'backup-folder'},
      }),
    );
    final created = await create.close();
    _status(created, {200, 201});
    return (jsonDecode(utf8.decode(await _bytes(created, 65536))) as Map)['id']
        as String;
  }

  Future<List<RemoteBackupFile>> list() => _use((client, auth) async {
    final result = <RemoteBackupFile>[];
    if (google) {
      String? page;
      do {
        final request = await _request(
          client,
          auth,
          'GET',
          Uri.https('www.googleapis.com', '/drive/v3/files', {
            'spaces': 'drive',
            'q': _driveBackupQuery,
            'fields': 'nextPageToken,files(id,name)',
            'pageSize': '1000',
            'pageToken': ?page,
          }),
        );
        final response = await request.close();
        _status(response, {200});
        final data =
            jsonDecode(utf8.decode(await _bytes(response, 1024 * 1024))) as Map;
        for (final file in data['files'] as List) {
          if (validName.hasMatch(file['name'] as String)) {
            result.add(
              RemoteBackupFile(file['name'] as String, file['id'] as String),
            );
          }
        }
        page = data['nextPageToken'] as String?;
        if (result.length > 4096) throw const CloudBackupException('size');
      } while (page != null);
    } else {
      final request = await _request(client, auth, 'PROPFIND', auth.directory);
      request.headers.set('Depth', '1');
      request.headers.contentType = ContentType('application', 'xml');
      request.write(
        '<d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>',
      );
      final response = await request.close();
      _status(response, {207});
      final source = utf8.decode(await _bytes(response, 1024 * 1024));
      if (source.toUpperCase().contains('<!DOCTYPE')) {
        throw const CloudBackupException('unsupported');
      }
      final document = XmlDocument.parse(source);
      if (document.findElements('multistatus', namespaceUri: 'DAV:').length !=
          1) {
        throw const CloudBackupException('unsupported');
      }
      for (final entry in document.findAllElements(
        'response',
        namespaceUri: 'DAV:',
      )) {
        final href = entry
            .findElements('href', namespaceUri: 'DAV:')
            .singleOrNull
            ?.innerText;
        if (href == null) continue;
        final url = auth.directory.resolve(href);
        if (url.origin != auth.directory.origin ||
            !url.path.startsWith(auth.directory.path) ||
            url.hasQuery ||
            url.hasFragment) {
          continue;
        }
        final name = url.pathSegments.last;
        if (validName.hasMatch(name) &&
            url.path == auth.directory.resolve(name).path) {
          result.add(RemoteBackupFile(name, url.toString()));
        }
      }
    }
    return result;
  });
  Future<void> upload(File file, String name) => _use((client, auth) async {
    if (!validName.hasMatch(name) || await file.length() > maximumBackupBytes) {
      throw const CloudBackupException('size');
    }
    if (google) {
      final folder = await _driveFolder(client, auth);
      final boundary = 'cute_${DateTime.now().microsecondsSinceEpoch}';
      final request = await _request(
        client,
        auth,
        'POST',
        Uri.https('www.googleapis.com', '/upload/drive/v3/files', {
          'uploadType': 'multipart',
          'fields': 'id',
        }),
      );
      request.headers.set(
        HttpHeaders.contentTypeHeader,
        'multipart/related; boundary=$boundary',
      );
      request.write(
        '--$boundary\r\nContent-Type: application/json; charset=UTF-8\r\n\r\n${jsonEncode({
          'name': name,
          'parents': [folder],
          'appProperties': {'cutelauncher': 'backup'},
        })}\r\n--$boundary\r\nContent-Type: application/json\r\n\r\n',
      );
      await request.addStream(file.openRead());
      request.write('\r\n--$boundary--\r\n');
      final response = await request.close();
      _status(response, {200, 201});
      await _bytes(response, 65536);
    } else {
      final temporary = auth.directory.resolve('$name.partial');
      var published = false;
      try {
        final request = await _request(client, auth, 'PUT', temporary);
        request.headers.contentType = ContentType.json;
        request.contentLength = await file.length();
        await request.addStream(file.openRead());
        final response = await request.close();
        _status(response, {200, 201, 204});
        await _bytes(response, 65536);
        final move = await _request(client, auth, 'MOVE', temporary);
        move.headers.set(
          'Destination',
          auth.directory.resolve(name).toString(),
        );
        move.headers.set('Overwrite', 'F');
        final moved = await move.close();
        _status(moved, {201, 204});
        await _bytes(moved, 65536);
        published = true;
      } finally {
        if (!published) {
          try {
            final deletion = await _request(client, auth, 'DELETE', temporary);
            await _bytes(await deletion.close(), 65536);
          } catch (_) {}
        }
      }
    }
  });
  Future<File> download(RemoteBackupFile file, Directory target) => _use((
    client,
    auth,
  ) async {
    if (!validName.hasMatch(file.name)) {
      throw const CloudBackupException('configuration');
    }
    final uri = google
        ? Uri.https(
            'www.googleapis.com',
            '/drive/v3/files/${Uri.encodeComponent(file.id)}',
            {'alt': 'media'},
          )
        : Uri.parse(file.id);
    final request = await _request(client, auth, 'GET', uri);
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
    return pending.rename('${target.path}/${file.name}');
  });
  Future<void> delete(RemoteBackupFile file) => _use((client, auth) async {
    if (!validName.hasMatch(file.name)) {
      throw const CloudBackupException('configuration');
    }
    final request = await _request(
      client,
      auth,
      'DELETE',
      google
          ? Uri.https(
              'www.googleapis.com',
              '/drive/v3/files/${Uri.encodeComponent(file.id)}',
            )
          : Uri.parse(file.id),
    );
    final response = await request.close();
    _status(response, {200, 204, 404});
    await _bytes(response, 65536);
  });
}
