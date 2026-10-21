import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flauncher/backup_assets.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealHttp extends HttpOverrides {}

class _Accounts implements CloudAccountRepository {
  CloudAccountInfo value = const CloudAccountInfo();
  CloudAuthorization? auth;
  int saves = 0;
  Future<CloudAccountInfo> Function()? read;
  @override
  Future<CloudAccountInfo> info() async => read == null ? value : await read!();
  @override
  Future<CloudAuthorization> authorization() async => auth!;
  @override
  Future<void> save(String url, String user, String password) async {
    saves++;
    value = CloudAccountInfo(configured: true, url: url, user: user);
    auth = CloudAuthorization(
      cloudDirectory(url),
      cloudBasicAuthorization(user, password),
    );
  }

  @override
  Future<void> disconnect() async {
    value = const CloudAccountInfo();
    auth = null;
  }
}

class _Dav {
  late HttpServer server;
  late Uri directory;
  final files = <String, List<int>>{};
  final methods = <String>[];
  int status = 207, moveStatus = 204;
  String? xml, location;
  Future<void> Function(HttpRequest)? override;
  final expectedAuth = cloudBasicAuthorization('test-user', 'dummy-password');
  Future<void> start() async {
    final tls = SecurityContext()
      ..useCertificateChain('test/fixtures/cloud/test_certificate.txt')
      ..usePrivateKey('test/fixtures/cloud/test_key.txt');
    server = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, tls);
    directory = Uri.parse(
      'https://127.0.0.1:${server.port}/dav/u%20ser/backup/',
    );
    server.listen((request) async {
      try {
        methods.add(request.method);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          expectedAuth,
        );
        if (override != null) {
          await override!(request);
          return;
        }
        switch (request.method) {
          case 'PROPFIND':
            expect(request.headers.value('Depth'), '0');
            await request.drain<void>();
            request.response.statusCode = status;
            if (location != null) {
              request.response.headers.set('Location', location!);
            }
            request.response.write(
              xml ??
                  '<d:multistatus xmlns:d="DAV:"><d:response><d:href>${directory.path}</d:href><d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>',
            );
          case 'PUT':
            files[request.uri.path] = await request.fold<List<int>>(
              [],
              (all, part) => all..addAll(part),
            );
            request.response.statusCode = 201;
          case 'MOVE':
            request.response.statusCode = moveStatus;
            if (moveStatus == 204) {
              expect(request.headers.value('Overwrite'), 'T');
              final target = Uri.parse(request.headers.value('Destination')!);
              expect(target.origin, directory.origin);
              files[target.path] = files.remove(request.uri.path)!;
            }
          case 'GET':
            final data = files[request.uri.path];
            request.response.statusCode = data == null ? 404 : 200;
            if (data != null) {
              request.response.contentLength = data.length;
              request.response.add(data);
            }
          case 'DELETE':
            files.remove(request.uri.path);
            request.response.statusCode = 204;
          default:
            request.response.statusCode = 405;
        }
        await request.response.close();
      } on SocketException {
        /* Expected when the client cancels. */
      } on HttpException {
        /* Expected when the client cancels. */
      }
    });
  }

  HttpClient client() => HttpClient(
    context: SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificates('test/fixtures/cloud/test_certificate.txt'),
  );
  Future<void> close() => server.close(force: true);
}

Matcher errorCode(String code) =>
    isA<CloudBackupException>().having((error) => error.code, 'code', code);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final previousOverrides = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _RealHttp());
  tearDownAll(() => HttpOverrides.global = previousOverrides);
  late _Dav dav;
  late _Accounts accounts;
  late CloudBackupService service;
  late Directory staging;
  setUp(() async {
    dav = _Dav();
    await dav.start();
    accounts = _Accounts();
    service = CloudBackupService(accounts: accounts, clientFactory: dav.client);
    staging = await Directory.systemTemp.createTemp('cloud-backup-test-');
  });
  tearDown(() async {
    service.dispose();
    await dav.close();
    await staging.delete(recursive: true);
  });
  Future<void> connect() =>
      service.signIn(dav.directory.toString(), 'test-user', 'dummy-password');
  test('validates HTTPS and preserves escaped directory components', () {
    expect(
      cloudDirectory('https://example.test/u%20ser/a%2Fb').toString(),
      'https://example.test/u%20ser/a%2Fb/',
    );
    expect(
      cloudDirectory('https://example.test').toString(),
      'https://example.test/',
    );
    for (final url in [
      'http://example.test/',
      'https://u:p@example.test/',
      'https://example.test/?a=1',
      'https://example.test/#x',
      ' https://example.test/',
      'https://example.test:0/',
    ]) {
      expect(() => cloudDirectory(url), throwsA(errorCode('configuration')));
    }
    expect(
      () => cloudBasicAuthorization('user:bad', 'dummy'),
      throwsA(errorCode('configuration')),
    );
    expect(
      () => cloudBasicAuthorization('user', 'dummy\r\n'),
      throwsA(errorCode('configuration')),
    );
  });
  test(
    'HTTPS authentication, atomic upload, download and disconnect',
    () async {
      await connect();
      expect(accounts.saves, 1);
      expect(service.account.configured, true);
      final source = await File('${staging.path}/source.json')
          .writeAsString('{"test":"safe dummy"}');
      await service.upload(source);
      expect(dav.methods, ['PROPFIND', 'PUT', 'MOVE']);
      expect(dav.files.length, 1);
      final received = await service.download(staging);
      expect(await received.readAsString(), await source.readAsString());
      await service.disconnect();
      expect(service.account.configured, false);
      expect(dav.files.length, 1);
    },
  );
  test(
    'failed authentication keeps the previously configured account',
    () async {
      await connect();
      final previous = service.account;
      dav.status = 401;
      await expectLater(connect(), throwsA(errorCode('authorization')));
      expect(accounts.saves, 1);
      expect(service.account, same(previous));
    },
  );
  for (final entry in {
    403: 'authorization',
    404: 'missing',
    405: 'unsupported',
    507: 'quota',
    500: 'server',
  }.entries) {
    test(
      'maps HTTP ${entry.key} without exposing response or credentials',
      () async {
        dav.status = entry.key;
        await expectLater(connect(), throwsA(errorCode(entry.value)));
        expect(accounts.saves, 0);
      },
    );
  }
  test(
    'does not follow redirect or forward authorization to another server',
    () async {
      final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => target.close(force: true));
      var requests = 0;
      target.listen((r) {
        requests++;
        r.response.close();
      });
      dav.status = 302;
      dav.location = 'http://127.0.0.1:${target.port}/';
      await expectLater(connect(), throwsA(errorCode('redirect')));
      expect(requests, 0);
      expect(accounts.saves, 0);
    },
  );
  for (final body in [
    '<html>login</html>',
    '<d:multistatus xmlns:d="DAV:">',
    '<multistatus><response/></multistatus>',
    '<d:multistatus xmlns:d="DAV:"><d:response><d:href>/wrong/</d:href></d:response></d:multistatus>',
    '<!DOCTYPE x><d:multistatus xmlns:d="DAV:"/>',
  ]) {
    test('rejects malformed or non-WebDAV metadata ${body.length}', () async {
      dav.xml = body;
      await expectLater(connect(), throwsA(errorCode('unsupported')));
      expect(accounts.saves, 0);
    });
  }
  test('failed MOVE preserves the previous backup and deletes only its temporary file', () async {
    await connect();
    final target = dav.directory.resolve('cutelauncher_backup.json').path;
    dav.files[target] = utf8.encode('previous');
    dav.moveStatus = 500;
    final source = await File('${staging.path}/source')
        .writeAsString('replacement');
    await expectLater(service.upload(source), throwsA(errorCode('server')));
    expect(dav.files, {target: utf8.encode('previous')});
    expect(dav.methods, ['PROPFIND', 'PUT', 'MOVE', 'DELETE']);
  });
  test(
    'rejects oversized advertised download before creating a file',
    () async {
      await connect();
      dav.override = (request) async {
        request.response.contentLength = maximumBackupBytes + 1;
        request.response.add([0]);
        await request.response.flush();
      };
      await expectLater(service.download(staging), throwsA(errorCode('size')));
      expect(await staging.list().toList(), isEmpty);
    },
  );
  test('missing backup does not create a partial file', () async {
    await connect();
    await expectLater(service.download(staging), throwsA(errorCode('missing')));
    expect(await staging.list().toList(), isEmpty);
  });
  test('download refuses to replace an existing local file', () async {
    await connect();
    dav.files[dav.directory.resolve('cutelauncher_backup.json').path] = [
      1,
      2,
      3,
    ];
    final existing = await File('${staging.path}/cloud_backup.json')
        .writeAsString('keep');
    await expectLater(service.download(staging), throwsA(errorCode('file')));
    expect(await existing.readAsString(), 'keep');
  });
  test(
    'timeout then late account response cannot overwrite a newer operation',
    () async {
      service.dispose();
      service = CloudBackupService(
        accounts: accounts,
        clientFactory: dav.client,
        budget: const Duration(milliseconds: 40),
      );
      final late = Completer<CloudAccountInfo>();
      accounts.read = () => late.future;
      await expectLater(
        service.refreshAccount(),
        throwsA(errorCode('timeout')),
      );
      accounts.read = null;
      accounts.value = const CloudAccountInfo(
        configured: true,
        url: 'https://example.test/new/',
        user: 'new',
      );
      await service.refreshAccount();
      late.complete(
        const CloudAccountInfo(
          configured: true,
          url: 'https://example.test/old/',
          user: 'old',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(service.account.user, 'new');
      expect(service.busy, false);
    },
  );
  test(
    'background cancels a pending request; resume allows a new operation',
    () async {
      await connect();
      final arrived = Completer<void>();
      dav.override = (request) async {
        arrived.complete();
        await Future<void>.delayed(const Duration(milliseconds: 150));
        await request.response.close();
      };
      final operation = service.checkAccount();
      final result = expectLater(operation, throwsA(errorCode('cancelled')));
      await arrived.future;
      service.didChangeAppLifecycleState(AppLifecycleState.paused);
      await result;
      await expectLater(
        service.checkAccount(),
        throwsA(errorCode('cancelled')),
      );
      service.didChangeAppLifecycleState(AppLifecycleState.resumed);
      dav.override = null;
      await service.checkAccount();
      expect(service.busy, false);
    },
  );
  test('default production trust rejects the dummy certificate', () async {
    service.dispose();
    service = CloudBackupService(accounts: accounts);
    await expectLater(connect(), throwsA(errorCode('network')));
    expect(accounts.saves, 0);
  });
  test('real v3 archive travels through HTTPS and restores validated data without account secrets', () async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const paths = MethodChannel('plugins.flutter.io/path_provider');
    messenger.setMockMethodCallHandler(paths, (_) async => staging.path);
    addTearDown(() => messenger.setMockMethodCallHandler(paths, null));
    SharedPreferences.setMockInitialValues({
      'show_time_in_status_bar': false,
      'cloud_password': 'device-only-dummy',
    });
    final preferences = await SharedPreferences.getInstance();
    final database = FLauncherDatabase.inMemory();
    addTearDown(database.close);
    final id = await database.insertCategory(
      CategoriesCompanion.insert(name: 'Original', order: 0),
    );
    final backup = BackupService(database, preferences);
    final file = File('${staging.path}/archive.json');
    await backup.writeBackupTo(file, validateStructure: true);
    expect(await file.readAsString(), isNot(contains('device-only-dummy')));
    await connect();
    await service.upload(file);
    await preferences.setBool('show_time_in_status_bar', true);
    final downloaded = await service.download(staging);
    await backup.importBackup(downloaded);
    expect(preferences.getBool('show_time_in_status_bar'), false);
    expect(preferences.getString('cloud_password'), 'device-only-dummy');
    expect(
      (await database.getCategories()).map((category) => category.id),
      contains(id),
    );
    await downloaded.delete();
    dav.files[dav.directory.resolve('cutelauncher_backup.json').path] = utf8
        .encode('{"version":999,"settings":{"show_time_in_status_bar":true}}');
    final invalid = await service.download(staging);
    await expectLater(backup.importBackup(invalid), throwsFormatException);
    expect(preferences.getBool('show_time_in_status_bar'), false);
    expect(
      (await database.getCategories()).map((category) => category.id),
      contains(id),
    );
  });
  test(
    'upload rejects empty and oversized files before contacting the server',
    () async {
      await connect();
      final file = await File('${staging.path}/large').create();
      await expectLater(service.upload(file), throwsA(errorCode('size')));
      final writer = await file.open(mode: FileMode.write);
      await writer.truncate(maximumBackupBytes + 1);
      await writer.close();
      await expectLater(service.upload(file), throwsA(errorCode('size')));
      expect(dav.methods, ['PROPFIND']);
    },
  );
  test(
    'late PUT after timeout cannot MOVE or interfere with the next operation',
    () async {
      await connect();
      service.dispose();
      service = CloudBackupService(
        accounts: accounts,
        clientFactory: dav.client,
        budget: const Duration(milliseconds: 100),
      );
      final arrived = Completer<void>(), release = Completer<void>();
      dav.override = (request) async {
        await request.drain<void>();
        arrived.complete();
        await release.future;
        request.response.statusCode = 201;
        await request.response.close();
      };
      final file = await File('${staging.path}/source').writeAsString('dummy');
      final failed = expectLater(
        service.upload(file),
        throwsA(errorCode('timeout')),
      );
      await arrived.future;
      await failed;
      dav.override = null;
      await service.checkAccount();
      release.complete();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(dav.methods, ['PROPFIND', 'PUT', 'PROPFIND']);
      expect(service.busy, false);
    },
  );
  test('cancelled streamed download removes its partial file', () async {
    await connect();
    final sent = Completer<void>(), release = Completer<void>();
    dav.override = (request) async {
      request.response.add(List.filled(1024, 1));
      await request.response.flush();
      sent.complete();
      await release.future;
      await request.response.close();
    };
    final failed = expectLater(
      service.download(staging),
      throwsA(errorCode('cancelled')),
    );
    await sent.future;
    for (
      var i = 0;
      i < 100 &&
          !await File('${staging.path}/cloud_backup.json.partial').exists();
      i++
    ) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(
      await File('${staging.path}/cloud_backup.json.partial').exists(),
      true,
    );
    service.cancel();
    await failed;
    release.complete();
    expect(await staging.list().toList(), isEmpty);
  });
  test(
    'chunked download enforces the size limit and removes partial data',
    () async {
      await connect();
      dav.override = (request) async {
        final chunk = List.filled(64 * 1024, 1);
        for (var i = 0; i <= maximumBackupBytes ~/ chunk.length; i++) {
          request.response.add(chunk);
          await request.response.flush();
        }
        await request.response.close();
      };
      await expectLater(service.download(staging), throwsA(errorCode('size')));
      expect(await staging.list().toList(), isEmpty);
    },
  );
  test(
    'bounded metadata rejects oversized responses without saving an account',
    () async {
      dav.xml = 'x' * (64 * 1024 + 1);
      await expectLater(connect(), throwsA(errorCode('server')));
      expect(accounts.saves, 0);
    },
  );
  test('Depth 0 must identify the selected collection with a successful property status', () async {
    for (final resource in [
      '<d:resourcetype/>',
      '<d:resourcetype><d:collection/></d:resourcetype>',
    ]) {
      dav.xml =
          '<d:multistatus xmlns:d="DAV:"><d:response><d:href>${dav.directory.path}</d:href><d:propstat><d:prop>$resource</d:prop><d:status>HTTP/1.1 404 Not Found</d:status></d:propstat></d:response></d:multistatus>';
      await expectLater(connect(), throwsA(errorCode('unsupported')));
    }
    expect(accounts.saves, 0);
  });
}
