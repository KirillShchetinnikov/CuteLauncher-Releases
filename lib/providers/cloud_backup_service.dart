import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:xml/xml.dart';

import '../cloud_account.dart';
import '../backup_assets.dart';
import '../image_limits.dart';

class _Transfer {
  final HttpClient client;
  Timer? deadline;
  bool cancelled = false, expired = false, finished = false;
  _Transfer(this.client);
}

/// Explicit WebDAV transfers. No polling, redirects or background upload.
class CloudBackupService extends ChangeNotifier with WidgetsBindingObserver {
  final CloudAccountRepository accounts;
  final HttpClient Function() _clientFactory;
  final Duration budget;
  _Transfer? _current;
  bool busy = false;
  bool _foreground = true, _disposed = false;
  CloudAccountInfo account = const CloudAccountInfo();
  CloudBackupService({
    CloudAccountRepository? accounts,
    HttpClient Function()? clientFactory,
    this.budget = const Duration(seconds: 90),
  }) : accounts = accounts ?? NativeCloudAccountRepository(),
       _clientFactory = clientFactory ?? HttpClient.new {
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _foreground = lifecycle == null || lifecycle == AppLifecycleState.resumed;
    WidgetsBinding.instance.addObserver(this);
  }
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _foreground = true;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _foreground = false;
      cancel();
    }
  }

  void cancel() {
    final operation = _current;
    if (operation == null) return;
    operation.cancelled = true;
    operation.client.close(force: true);
  }

  void _check(_Transfer operation) {
    if (operation.expired) throw const CloudBackupException('timeout');
    if (operation.cancelled ||
        operation.finished ||
        !_foreground ||
        _disposed) {
      throw const CloudBackupException('cancelled');
    }
  }

  Future<T> _work<T>(Future<T> Function(_Transfer) action) async {
    if (busy) throw const CloudBackupException('busy');
    if (!_foreground || _disposed) {
      throw const CloudBackupException('cancelled');
    }
    final operation = _Transfer(
      _clientFactory()
        ..connectionTimeout = const Duration(seconds: 8)
        ..autoUncompress = false,
    );
    _current = operation;
    busy = true;
    _notify();
    try {
      operation.deadline = Timer(budget, () {
        operation.expired = true;
        operation.client.close(force: true);
      });
      _check(operation);
      return await action(operation).timeout(budget);
    } on CloudBackupException {
      rethrow;
    } on TimeoutException {
      operation.expired = true;
      throw const CloudBackupException('timeout');
    } on FileSystemException {
      _check(operation);
      throw const CloudBackupException('file');
    } catch (_) {
      _check(operation);
      throw const CloudBackupException('network');
    } finally {
      operation.finished = true;
      operation.deadline?.cancel();
      operation.client.close(force: true);
      if (identical(_current, operation)) _current = null;
      busy = false;
      _notify();
    }
  }

  Future<void> refreshAccount() => _work((operation) async {
    final current = await accounts.info();
    _check(operation);
    account = current;
  });
  Future<HttpClientRequest> _request(
    CloudAuthorization auth,
    String method,
    Uri target,
    _Transfer operation,
  ) async {
    _check(operation);
    if (target.origin != auth.directory.origin ||
        !target.path.startsWith(auth.directory.path)) {
      throw const CloudBackupException('configuration');
    }
    final request = await operation.client.openUrl(method, target);
    request.followRedirects = false;
    request.headers.set(HttpHeaders.authorizationHeader, auth.header);
    request.headers.set(HttpHeaders.acceptEncodingHeader, 'identity');
    request.headers.set(HttpHeaders.userAgentHeader, 'CuteLauncher WebDAV');
    _check(operation);
    return request;
  }

  void _status(
    HttpClientResponse response,
    Set<int> expected,
    _Transfer operation,
  ) {
    _check(operation);
    if (expected.contains(response.statusCode)) return;
    throw CloudBackupException(switch (response.statusCode) {
      401 || 403 => 'authorization',
      404 => 'missing',
      405 || 501 => 'unsupported',
      412 => 'conflict',
      507 => 'quota',
      >= 300 && < 400 => 'redirect',
      _ => 'server',
    });
  }

  Future<List<int>> _metadata(Stream<List<int>> response) async {
    try {
      return await readBoundedImage(response, limit: 64 * 1024);
    } on ImageInputException {
      throw const CloudBackupException('server');
    }
  }

  Future<void> _verify(CloudAuthorization auth, _Transfer operation) async {
    final request = await _request(auth, 'PROPFIND', auth.directory, operation);
    request.headers.set('Depth', '0');
    request.headers.contentType = ContentType(
      'application',
      'xml',
      charset: 'utf-8',
    );
    request.write(
      '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:resourcetype/></d:prop></d:propfind>',
    );
    final response = await request.close();
    _status(response, {207}, operation);
    final bytes = await _metadata(response);
    try {
      final document = XmlDocument.parse(utf8.decode(bytes));
      if (document.children.any((node) => node is XmlDoctype)) {
        throw const CloudBackupException('unsupported');
      }
      final roots = document.findElements('multistatus', namespaceUri: 'DAV:');
      if (roots.length != 1) throw const CloudBackupException('unsupported');
      final responses = roots.single.findElements(
        'response',
        namespaceUri: 'DAV:',
      );
      if (responses.length != 1) {
        throw const CloudBackupException('unsupported');
      }
      final entry = responses.single;
      final hrefs = entry.findElements('href', namespaceUri: 'DAV:');
      if (hrefs.length != 1) throw const CloudBackupException('unsupported');
      final target = auth.directory.resolve(hrefs.single.innerText);
      if (target.origin != auth.directory.origin ||
          target.userInfo.isNotEmpty ||
          target.hasQuery ||
          target.hasFragment ||
          cloudDirectory(target.toString()) != auth.directory) {
        throw const CloudBackupException('unsupported');
      }
      final collection = entry.findElements('propstat', namespaceUri: 'DAV:').any((
        stat,
      ) {
        final statuses = stat.findElements('status', namespaceUri: 'DAV:');
        return statuses.length == 1 &&
            RegExp(r'^HTTP/[0-9.]+ 200(?: |$)')
                .hasMatch(statuses.single.innerText.trim()) &&
            stat
                .findElements('prop', namespaceUri: 'DAV:')
                .any(
                  (prop) => prop
                      .findElements('resourcetype', namespaceUri: 'DAV:')
                      .any(
                        (type) => type
                            .findElements('collection', namespaceUri: 'DAV:')
                            .isNotEmpty,
                      ),
                );
      });
      if (!collection) throw const CloudBackupException('unsupported');
    } on CloudBackupException {
      rethrow;
    } catch (_) {
      throw const CloudBackupException('unsupported');
    }
    _check(operation);
  }

  Future<void> signIn(String url, String user, String password) {
    final directory = cloudDirectory(url);
    final header = cloudBasicAuthorization(user, password);
    return _work((operation) async {
      await _verify(CloudAuthorization(directory, header), operation);
      _check(operation);
      await accounts.save(directory.toString(), user, password);
      final current = await accounts.info();
      _check(operation);
      account = current;
    });
  }

  Future<void> checkAccount() => _work((operation) async {
    await _verify(await accounts.authorization(), operation);
  });
  Future<void> disconnect() => _work((operation) async {
    await accounts.disconnect();
    _check(operation);
    account = const CloudAccountInfo();
  });
  Future<void> upload(File file) => _work((operation) async {
    final size = await file.length();
    if (size <= 0 || size > maximumBackupBytes) {
      throw const CloudBackupException('size');
    }
    final auth = await accounts.authorization();
    final random = Random.secure();
    final suffix = List.generate(
      12,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
    final temporary = auth.directory.resolve(
      'cutelauncher_backup_$suffix.partial',
    );
    final destination = auth.directory.resolve('cutelauncher_backup.json');
    var published = false;
    try {
      final request = await _request(auth, 'PUT', temporary, operation);
      request.headers.contentType = ContentType.json;
      request.contentLength = size;
      await request.addStream(file.openRead());
      final response = await request.close();
      _status(response, {200, 201, 204}, operation);
      await _metadata(response);
      final move = await _request(auth, 'MOVE', temporary, operation);
      move.headers.set('Destination', destination.toString());
      move.headers.set('Overwrite', 'T');
      final moved = await move.close();
      _status(moved, {201, 204}, operation);
      await _metadata(moved);
      published = true;
    } finally {
      if (!published &&
          !operation.cancelled &&
          !operation.expired &&
          !operation.finished) {
        try {
          final request = await _request(auth, 'DELETE', temporary, operation);
          await _metadata(await request.close());
        } catch (_) {
          /* A disconnected provider may retain the unique temporary object. */
        }
      }
    }
  });
  Future<File> download(Directory directory) => _work((operation) async {
    final auth = await accounts.authorization();
    final request = await _request(
      auth,
      'GET',
      auth.directory.resolve('cutelauncher_backup.json'),
      operation,
    );
    final response = await request.close();
    _status(response, {200}, operation);
    if (response.contentLength > maximumBackupBytes ||
        response.contentLength == 0) {
      throw const CloudBackupException('size');
    }
    final partial = File('${directory.path}/cloud_backup.json.partial');
    final destination = File('${directory.path}/cloud_backup.json');
    if (await partial.exists() || await destination.exists()) {
      throw const CloudBackupException('file');
    }
    RandomAccessFile? writer;
    try {
      writer = await partial.open(mode: FileMode.write);
      var size = 0;
      await for (final chunk in response) {
        _check(operation);
        size += chunk.length;
        if (size > maximumBackupBytes) throw const CloudBackupException('size');
        await writer.writeFrom(chunk);
      }
      if (size == 0 ||
          response.contentLength >= 0 && response.contentLength != size) {
        throw const CloudBackupException('file');
      }
      _check(operation);
      await writer.flush();
      await writer.close();
      writer = null;
      _check(operation);
      return await partial.rename(destination.path);
    } finally {
      await writer?.close();
      if (await partial.exists()) await partial.delete();
    }
  });
  @override
  void dispose() {
    _disposed = true;
    cancel();
    _current?.deadline?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
