import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealHttp extends HttpOverrides {}

class _Account implements CloudAccountRepository {
  final Uri root;
  _Account(this.root);
  @override
  Future<CloudAuthorization> authorization() async =>
      CloudAuthorization(root, 'Basic dummy');
  @override
  Future<CloudAccountInfo> info() async =>
      CloudAccountInfo(configured: true, url: root.toString(), user: 'test');
  @override
  Future<void> save(String url, String user, String password) async {}
  @override
  Future<void> disconnect() async {}
}

class _RoutedClient implements HttpClient {
  final HttpClient inner;
  final Uri root;
  _RoutedClient(this.inner, this.root);
  Uri _route(Uri url) => root.replace(path: url.path, query: url.query);
  @override
  Future<HttpClientRequest> postUrl(Uri url) => inner.postUrl(_route(url));
  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) =>
      inner.openUrl(method, _route(url));
  @override
  set connectionTimeout(Duration? value) {
    inner.connectionTimeout = value;
  }

  @override
  set autoUncompress(bool value) {
    inner.autoUncompress = value;
  }

  @override
  void close({bool force = false}) => inner.close(force: force);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late HttpServer server;
  late Uri root;
  late Directory temp;
  late DriveBackupService drive;
  late BackupStorage storage;
  final files = <String, List<int>>{};
  String? listing;
  bool rejectMove = false;
  bool google = false;
  Map? stored;
  late Future<void> Function(HttpRequest) handler;
  final original = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _RealHttp());
  tearDownAll(() => HttpOverrides.global = original);
  HttpClient client() => HttpClient(
    context: SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificates('test/fixtures/cloud/test_certificate.txt'),
  );
  setUp(() async {
    files.clear();
    listing = null;
    rejectMove = false;
    google = false;
    stored = null;
    final tls = SecurityContext()
      ..useCertificateChain('test/fixtures/cloud/test_certificate.txt')
      ..usePrivateKey('test/fixtures/cloud/test_key.txt');
    server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls);
    root = Uri.parse('https://127.0.0.1:${server.port}/dav/');
    temp = await Directory.systemTemp.createTemp('cute-storage-');
    handler = (request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        google ? 'Bearer dummy-access' : 'Basic dummy',
      );
      switch (request.method) {
        case 'PROPFIND':
          expect(request.headers.value('Depth'), '1');
          await request.drain<void>();
          request.response.statusCode = 207;
          request.response.write(
            listing ??
                '<d:multistatus xmlns:d="DAV:">${files.keys.map((name) => '<d:response><d:href>${root.path}$name</d:href></d:response>').join()}</d:multistatus>',
          );
        case 'PUT':
          files[request.uri.path.split('/').last] = await request
              .fold<List<int>>([], (all, c) => all..addAll(c));
          request.response.statusCode = 201;
        case 'MOVE':
          expect(request.headers.value('Overwrite'), 'F');
          request.response.statusCode = rejectMove ? 500 : 201;
          if (!rejectMove) {
            files[Uri.parse(request.headers.value('Destination')!)
                .pathSegments
                .last] = files.remove(
              request.uri.pathSegments.last,
            )!;
          }
        case 'GET':
          final data = files[request.uri.pathSegments.last];
          request.response.statusCode = data == null ? 404 : 200;
          if (data != null) {
            request.response.contentLength = data.length;
            request.response.add(data);
          }
        case 'DELETE':
          files.remove(request.uri.pathSegments.last);
          request.response.statusCode = 204;
        default:
          request.response.statusCode = 405;
      }
      await request.response.close();
    };
    server.listen((request) async {
      await handler(request);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/drive_account'),
          (call) async {
            if (call.method == 'read') return stored;
            if (call.method == 'save') {
              stored = Map.from(call.arguments as Map);
              return true;
            }
            if (call.method == 'disconnect') {
              stored = null;
              return true;
            }
            return null;
          },
        );
    drive = DriveBackupService(
      clientFactory: () => _RoutedClient(client(), root),
    );
    storage = BackupStorage(
      _Account(root),
      drive,
      google: false,
      clientFactory: client,
    );
  });
  tearDown(() async {
    drive.dispose();
    await server.close(force: true);
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/drive_account'),
          null,
        );
  });
  final name = 'cute-backup-shared-${'a' * 32}-100-${'b' * 16}.json';
  test('Google device flow requests only drive.file, displays code and saves tokens after consent', () async {
    final connected = Completer<void>();
    drive.addListener(() {
      if (drive.configured && !connected.isCompleted) connected.complete();
    });
    handler = (request) async {
      final fields = Uri.splitQueryString(
        await utf8.decoder.bind(request).join(),
      );
      if (request.uri.path == '/device/code') {
        expect(fields['scope'], 'https://www.googleapis.com/auth/drive.file');
        request.response.write(
          jsonEncode({
            'device_code': 'dummy-device',
            'user_code': 'TV-CODE',
            'verification_url': 'https://www.google.com/device',
            'expires_in': 30,
            'interval': 5,
          }),
        );
      } else {
        expect(fields['client_secret'], 'dummy-secret');
        expect(fields['device_code'], 'dummy-device');
        request.response.write(
          jsonEncode({
            'access_token': 'dummy-access',
            'refresh_token': 'dummy-refresh',
            'expires_in': 3600,
          }),
        );
      }
      await request.response.close();
    };
    await drive.connect('dummy-id', 'dummy-secret');
    expect(drive.code, 'TV-CODE');
    expect(drive.verificationUrl, 'https://www.google.com/device');
    expect(stored, isNull);
    await connected.future.timeout(const Duration(seconds: 15));
    expect(
      (jsonDecode(stored!['payload'] as String) as Map)['refreshToken'],
      'dummy-refresh',
    );
    expect(drive.code, isEmpty);
    expect(drive.busy, false);
  });
  test(
    'cancelled Google code request cannot start polling or save a late account',
    () async {
      final started = Completer<void>(), release = Completer<void>();
      var calls = 0;
      handler = (request) async {
        calls++;
        await request.drain<void>();
        started.complete();
        await release.future;
        try {
          request.response.write(
            jsonEncode({
              'device_code': 'late',
              'user_code': 'LATE',
              'verification_url': 'https://www.google.com/device',
              'expires_in': 30,
              'interval': 5,
            }),
          );
          await request.response.close();
        } on SocketException {
          // Cancellation may close the fixture socket before its late response.
        } on HttpException {
          // Cancellation may close the fixture response before publication.
        }
      };
      final connecting = drive.connect('dummy-id', 'dummy-secret');
      await started.future;
      drive.cancel();
      release.complete();
      try {
        await connecting;
      } catch (_) {}
      expect(drive.busy, false);
      expect(drive.code, isEmpty);
      expect(stored, isNull);
      expect(calls, 1);
    },
  );
  test(
    'old hidden account requires new consent without deleting credentials',
    () async {
      stored = {
        'clientId': 'old-id',
        'payload': jsonEncode({
          'clientSecret': 'old-secret',
          'refreshToken': 'old-token',
        }),
      };
      await drive.refreshAccount();
      expect(drive.configured, false);
      expect(drive.clientId, 'old-id');
      expect(drive.clientSecret, 'old-secret');
      await expectLater(
        drive.authorization(),
        throwsA(isA<CloudBackupException>()),
      );
      expect(stored, isNotNull);
    },
  );
  test(
    'Drive creates missing folder, reuses renamed folder and lists moved files',
    () async {
      stored = {
        'clientId': 'dummy-id',
        'payload': jsonEncode({
          'clientSecret': 'dummy-secret',
          'refreshToken': 'dummy-refresh',
          'scope': DriveBackupService.scope,
        }),
      };
      var folderExists = false, creations = 0, uploads = 0;
      handler = (request) async {
        final query = request.uri.queryParameters;
        if (request.uri.path == '/token') {
          await request.drain<void>();
          request.response.write('{"access_token":"dummy-access"}');
        } else if (request.uri.path == '/upload/drive/v3/files') {
          final body = await utf8.decoder.bind(request).join();
          expect(body, contains('"parents":["folder2"]'));
          uploads++;
          request.response.write('{"id":"uploaded"}');
        } else if (request.method == 'POST') {
          final metadata =
              jsonDecode(await utf8.decoder.bind(request).join()) as Map;
          expect(metadata['name'], 'CuteLauncher');
          expect(metadata['mimeType'], 'application/vnd.google-apps.folder');
          expect(metadata['appProperties'], {'cutelauncher': 'backup-folder'});
          creations++;
          folderExists = true;
          request.response.write('{"id":"folder2"}');
        } else if (query['q']!.contains('backup-folder')) {
          expect(query['q'], isNot(contains('name =')));
          request.response.write(
            folderExists ? '{"files":[{"id":"folder2"}]}' : '{"files":[]}',
          );
        } else {
          expect(query['q'], contains('trashed = false'));
          expect(query['q'], isNot(contains('parents')));
          if (query['pageToken'] == null) {
            request.response.write(
              jsonEncode({
                'files': [
                  {'id': 'moved', 'name': name},
                  {'id': 'unrelated', 'name': 'notes.txt'},
                ],
                'nextPageToken': 'next',
              }),
            );
          } else {
            expect(query['pageToken'], 'next');
            request.response.write('{"files":[]}');
          }
        }
        await request.response.close();
      };
      final googleStorage = BackupStorage(
        _Account(root),
        drive,
        google: true,
        clientFactory: () => _RoutedClient(client(), root),
      );
      final file = await File('${temp.path}/visible.json').writeAsString('{}');
      await googleStorage.upload(file, name);
      await googleStorage.upload(file, name);
      expect(creations, 1);
      folderExists = false;
      await googleStorage.upload(file, name);
      expect(creations, 2);
      expect(uploads, 3);
      expect((await googleStorage.list()).single.id, 'moved');
    },
  );
  test('WebDAV publishes immutable archive, lists and downloads it', () async {
    final file = await File('${temp.path}/archive.json')
        .writeAsString('{"version":3}');
    await storage.upload(file, name);
    final listing = await storage.list();
    expect(listing.single.name, name);
    final downloaded = await storage.download(listing.single, temp);
    expect(await downloaded.readAsString(), '{"version":3}');
    await storage.delete(listing.single);
    expect(files, isEmpty);
  });
  test(
    'failed MOVE preserves published snapshots and removes temporary upload',
    () async {
      files[name] = utf8.encode('old');
      rejectMove = true;
      final file = await File('${temp.path}/archive.json').writeAsString('new');
      await expectLater(
        storage.upload(file, name.replaceFirst('-100-', '-101-')),
        throwsA(isA<CloudBackupException>()),
      );
      expect(files.keys, [name]);
      expect(utf8.decode(files[name]!), 'old');
    },
  );
  test('external hrefs and unrelated files are never imported or deleted', () async {
    listing =
        '<d:multistatus xmlns:d="DAV:"><d:response><d:href>https://evil.test/$name</d:href></d:response><d:response><d:href>/elsewhere/$name</d:href></d:response><d:response><d:href>/dav/private.txt</d:href></d:response></d:multistatus>';
    expect(await storage.list(), isEmpty);
    await expectLater(
      storage.delete(
        const RemoteBackupFile('private.txt', 'https://evil.test/private.txt'),
      ),
      throwsA(isA<CloudBackupException>()),
    );
  });
  test('DTD is rejected rather than resolving external entities', () async {
    listing = '<!DOCTYPE x [<!ENTITY secret SYSTEM "file:///etc/passwd">]><x/>';
    await expectLater(storage.list(), throwsA(isA<CloudBackupException>()));
  });
  test(
    'Google refresh uses isolated encrypted account and visible marked files',
    () async {
      stored = {
        'clientId': 'dummy-id',
        'payload': jsonEncode({
          'clientSecret': 'dummy-secret',
          'refreshToken': 'dummy-refresh',
          'scope': DriveBackupService.scope,
        }),
      };
      google = true;
      handler = (request) async {
        if (request.uri.path == '/token') {
          final body = await utf8.decoder.bind(request).join();
          expect(body, contains('refresh_token=dummy-refresh'));
          request.response.write(
            jsonEncode({'access_token': 'dummy-access', 'expires_in': 3600}),
          );
        } else if (request.uri.path == '/upload/drive/v3/files') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer dummy-access',
          );
          final body = await utf8.decoder.bind(request).join();
          expect(body, contains('"parents":["folder1"]'));
          expect(body, contains('"cutelauncher":"backup"'));
          expect(body, isNot(contains('appDataFolder')));
          expect(body, contains(name));
          request.response.write('{"id":"file1"}');
        } else if (request.uri.path == '/drive/v3/files' &&
            request.uri.queryParameters['q']!.contains('backup-folder')) {
          request.response.write('{"files":[{"id":"folder1"}]}');
        } else if (request.uri.path == '/drive/v3/files') {
          expect(request.uri.queryParameters['spaces'], 'drive');
          expect(
            request.uri.queryParameters['q'],
            contains("key='cutelauncher' and value='backup'"),
          );
          request.response.write(
            jsonEncode({
              'files': [
                {'id': 'file1', 'name': name},
              ],
            }),
          );
        } else {
          request.response.write('{"version":3}');
        }
        await request.response.close();
      };
      final storage = BackupStorage(
        _Account(root),
        drive,
        google: true,
        clientFactory: () => _RoutedClient(client(), root),
      );
      await storage.upload(
        await File('${temp.path}/google.json').writeAsString('{"version":3}'),
        name,
      );
      final list = await storage.list();
      expect(list.single.id, 'file1');
      final downloaded = await storage.download(list.single, temp);
      expect(await downloaded.readAsString(), '{"version":3}');
      await drive.disconnect();
      expect(stored, isNull);
      expect(drive.configured, false);
    },
  );
}
