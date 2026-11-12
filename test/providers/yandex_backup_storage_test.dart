import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/backup_accounts.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';

import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/yandex_backup_storage.dart';
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
  final original = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _RealHttp());
  tearDownAll(() => HttpOverrides.global = original);
  late HttpServer server;
  late Directory temp;
  late DriveBackupService service;
  late YandexBackupStorage storage;
  late Future<void> Function(HttpRequest) handler;
  Map? stored;
  final name = 'cute-backup-shared-${'a' * 32}-100-${'b' * 16}.json';
  setUp(() async {
    stored = null;
    temp = await Directory.systemTemp.createTemp('cute-yandex-test-');
    final tls = SecurityContext()
      ..useCertificateChain('test/fixtures/cloud/test_certificate.txt')
      ..usePrivateKey('test/fixtures/cloud/test_key.txt');
    server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls);
    final root = Uri.parse('https://127.0.0.1:${server.port}/');
    HttpClient client() => _RoutedClient(
      HttpClient(
        context: SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificates('test/fixtures/cloud/test_certificate.txt'),
      ),
      root,
    );
    handler = (request) async {
      request.response.statusCode = 500;
      await request.response.close();
    };
    server.listen((request) async {
      await handler(request);
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/yandex_account'),
          (call) async {
            if (call.method == 'read') return stored;
            if (call.method == 'save') stored = Map.from(call.arguments as Map);
            if (call.method == 'disconnect') stored = null;
            return true;
          },
        );
    service = DriveBackupService(yandex: true, clientFactory: client);
    storage = YandexBackupStorage(
      _Account(root),
      service,
      clientFactory: client,
    );
  });
  tearDown(() async {
    service.dispose();
    await server.close(force: true);
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/yandex_account'),
          null,
        );
  });
  Future<void> connected() async {
    stored = {
      'clientId': 'test-id',
      'payload': jsonEncode({
        'clientSecret': 'test-secret',
        'refreshToken': 'test-refresh',
        'scope': DriveBackupService.yandexScope,
        'connectionId': 'a' * 32,
      }),
    };
    await service.refreshAccount();
  }

  Future<bool> token(HttpRequest request) async {
    if (request.uri.path != '/token') return false;
    request.response.write(
      jsonEncode({
        'access_token': 'test-access',
        'refresh_token': 'rotated',
        'expires_in': 3600,
      }),
    );
    await request.response.close();
    return true;
  }

  test(
    'Yandex profiles do not share account slots with Google or WebDAV',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cloud = CloudBackupService();
      final google = DriveBackupService();
      final accounts = BackupAccounts(preferences, cloud, google);
      addTearDown(() {
        accounts.dispose();
        cloud.dispose();
        google.dispose();
      });
      final id = await accounts.create(false, yandex: true);
      expect(accounts.ids(false, yandex: true), ['default', id]);
      expect(accounts.ids(true), ['default']);
      expect(accounts.ids(false), ['default']);
      expect(accounts.yandex(id).yandex, true);
      expect(accounts.yandex(id).profile, id);
    },
  );
  test('device flow uses Yandex code exchange and app folder scope', () async {
    final done = Completer<void>();
    service.addListener(() {
      if (service.configured && !done.isCompleted) done.complete();
    });
    handler = (request) async {
      final fields = Uri.splitQueryString(
        await utf8.decoder.bind(request).join(),
      );
      if (request.uri.path == '/device/code') {
        expect(fields['scope'], DriveBackupService.yandexScope);
        request.response.write(
          jsonEncode({
            'device_code': 'device-test',
            'user_code': 'TVTEST',
            'verification_url': 'https://oauth.yandex.ru/device',
            'expires_in': 60,
            'interval': 5,
          }),
        );
      } else {
        expect(fields['grant_type'], 'device_code');
        expect(fields['code'], 'device-test');
        expect(fields.containsKey('device_code'), false);
        request.response.write(
          jsonEncode({
            'access_token': 'test-access',
            'refresh_token': 'test-refresh',
            'expires_in': 3600,
          }),
        );
      }
      await request.response.close();
    };
    await service.connect('test-id', 'test-secret');
    expect(stored, isNull);
    expect(service.code, 'TVTEST');
    await done.future.timeout(const Duration(seconds: 15));
    expect(await service.authorization(), 'OAuth test-access');
    expect(
      jsonDecode(stored!['payload'])['scope'],
      DriveBackupService.yandexScope,
    );
  });
  test('refresh persists rotated token and lists only valid app files with pagination', () async {
    await connected();
    handler = (request) async {
      if (await token(request)) return;
      expect(request.headers.value('authorization'), 'OAuth test-access');
      expect(request.uri.queryParameters['path'], 'app:/');
      final offset = int.parse(request.uri.queryParameters['offset']!);
      request.response.write(
        jsonEncode({
          '_embedded': {
            'total': 2,
            'items': offset == 0
                ? [
                    {'name': 'unrelated.txt', 'type': 'file'},
                  ]
                : [
                    {'name': name, 'type': 'file'},
                  ],
          },
        }),
      );
      await request.response.close();
    };
    expect((await storage.list()).map((f) => f.id), ['app:/$name']);
    expect(jsonDecode(stored!['payload'])['refreshToken'], 'rotated');
    expect(jsonDecode(stored!['payload'])['connectionId'], 'a' * 32);
  });
  test(
    'upload and download do not send token to signed transfer URL',
    () async {
      await connected();
      var uploaded = <int>[];
      handler = (request) async {
        if (await token(request)) return;
        if (request.uri.path.startsWith('/v1/')) {
          expect(request.headers.value('authorization'), 'OAuth test-access');
          expect(request.uri.queryParameters['path'], 'app:/$name');
          final upload = request.uri.path.endsWith('/upload');
          if (upload) expect(request.uri.queryParameters['overwrite'], 'false');
          request.response.write(
            jsonEncode({
              'href': 'https://transfer.disk.yandex.net/data',
              'method': upload ? 'PUT' : 'GET',
            }),
          );
        } else {
          expect(request.headers.value('authorization'), isNull);
          if (request.method == 'PUT') {
            uploaded = await request.fold<List<int>>(
              [],
              (a, b) => a..addAll(b),
            );
            request.response.statusCode = 201;
          } else {
            request.response.add(uploaded);
          }
        }
        await request.response.close();
      };
      final input = File('${temp.path}/input')
        ..writeAsStringSync('backup-test');
      await storage.upload(input, name);
      final output = await storage.download(
        RemoteBackupFile(name, 'app:/$name'),
        temp,
      );
      expect(await output.readAsString(), 'backup-test');
    },
  );
  test('rejects foreign transfer URL and forged deletion path', () async {
    await connected();
    var deletes = 0;
    handler = (request) async {
      if (await token(request)) return;
      if (request.method == 'DELETE') deletes++;
      request.response.write(
        jsonEncode({'href': 'https://evil.example/file', 'method': 'GET'}),
      );
      await request.response.close();
    };
    await expectLater(
      storage.download(RemoteBackupFile(name, 'app:/$name'), temp),
      throwsA(isA<CloudBackupException>()),
    );
    await expectLater(
      storage.delete(RemoteBackupFile(name, 'disk:/personal')),
      throwsA(isA<CloudBackupException>()),
    );
    expect(deletes, 0);
  });
  test('asynchronous deletion waits for confirmed success', () async {
    await connected();
    var polls = 0;
    handler = (request) async {
      if (await token(request)) return;
      expect(request.headers.value('authorization'), 'OAuth test-access');
      if (request.method == 'DELETE') {
        expect(request.uri.queryParameters['path'], 'app:/$name');
        request.response.statusCode = 202;
        request.response.write(
          jsonEncode({
            'href': 'https://cloud-api.yandex.net/v1/disk/operations/test',
            'method': 'GET',
          }),
        );
      } else {
        polls++;
        request.response.write(
          jsonEncode({'status': polls == 1 ? 'in-progress' : 'success'}),
        );
      }
      await request.response.close();
    };
    await storage.delete(RemoteBackupFile(name, 'app:/$name'));
    expect(polls, 2);
  });
  test(
    'unexpected device verification URL is rejected without saving',
    () async {
      handler = (request) async {
        request.response.write(
          jsonEncode({
            'device_code': 'test',
            'user_code': 'test',
            'verification_url': 'https://evil.example/device',
            'expires_in': 60,
          }),
        );
        await request.response.close();
      };
      await expectLater(
        service.connect('test-id', 'test-secret'),
        throwsA(isA<CloudBackupException>()),
      );
      expect(stored, isNull);
      expect(service.busy, false);
    },
  );
  test('cancel prevents all following requests', () async {
    storage.cancel();
    await expectLater(
      storage.list(),
      throwsA(
        isA<CloudBackupException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
  });
}
