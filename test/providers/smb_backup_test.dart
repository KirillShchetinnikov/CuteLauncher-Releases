import 'dart:async';
import 'dart:io';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/providers/backup_accounts.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/providers/smb_backup_service.dart';
import 'package:flauncher/providers/smb_backup_storage.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SmbBackupService service;
  late DriveBackupService drive;
  late SmbBackupStorage storage;
  late Directory temp;
  late Future<Object?> Function(MethodCall) handler;
  final methods = <String>[];
  final name = 'cute-backup-shared-${'a' * 32}-123-${'b' * 16}.json';
  setUp(() async {
    methods.clear();
    temp = await Directory.systemTemp.createTemp('cute-smb-test-');
    service = SmbBackupService(profile: 'c' * 32);
    drive = DriveBackupService();
    storage = SmbBackupStorage(
      service.accounts,
      drive,
      profile: service.profile,
    );
    handler = (call) async {
      switch (call.method) {
        case 'identity':
          return 'account-identity';
        case 'info':
          return {
            'configured': true,
            'url': 'smb://nas/share/backups',
            'user': r'DOMAIN\user',
          };
        case 'list':
          return [
            {'name': name, 'id': name},
            {'name': 'personal.txt', 'id': 'personal.txt'},
          ];
        case 'listTemporary':
          return [
            {'name': '$name.partial', 'id': '$name.partial'},
          ];
        case 'download':
          await File(call.arguments['path']).writeAsString('backup-content');
          return true;
        default:
          return true;
      }
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/smb_backup'),
          (call) async {
            methods.add(call.method);
            expect(
              call.arguments['operationId'],
              matches(RegExp(r'^[a-f0-9]{32}$')),
            );
            if (call.method != 'cancel') {
              expect(call.arguments['profile'], service.profile);
            }
            return handler(call);
          },
        );
  });
  tearDown(() async {
    service.dispose();
    drive.dispose();
    await temp.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('cutelauncher/smb_backup'),
          null,
        );
  });
  test(
    'account info contains no password and failed reconnect preserves account',
    () async {
      await service.refreshAccount();
      expect(service.account.configured, true);
      final old = service.account;
      handler = (call) async {
        expect(call.method, 'connect');
        expect(call.arguments['password'], 'test-password');
        throw PlatformException(code: 'authorization');
      };
      await expectLater(
        service.signIn('smb://other/share', 'user', 'test-password'),
        throwsA(
          isA<CloudBackupException>().having(
            (e) => e.code,
            'code',
            'authorization',
          ),
        ),
      );
      expect(service.account, same(old));
      expect(service.busy, false);
    },
  );
  test('check account uses SMB identity and check instead of WebDAV', () async {
    await service.checkAccount();
    expect(methods, ['identity', 'check']);
    expect(service.busy, false);
  });
  test(
    'lists owned files, freezes identity and streams through local paths',
    () async {
      expect((await storage.list()).map((f) => f.name), [name]);
      expect((await storage.temporaryFiles()).single.name, '$name.partial');
      final previous = handler;
      handler = (call) async {
        expect(call.arguments['identity'], 'account-identity');
        expect((call.arguments as Map).containsKey('password'), false);
        return previous(call);
      };
      final input = await File('${temp.path}/source')
          .writeAsString('backup-content');
      await storage.upload(input, name);
      final output = await storage.download(RemoteBackupFile(name, name), temp);
      expect(await output.readAsString(), 'backup-content');
      await storage.delete(RemoteBackupFile(name, name));
      expect(methods.where((v) => v == 'identity').length, 1);
    },
  );
  test(
    'rejects forged paths and unrelated files before invoking native I/O',
    () async {
      await expectLater(
        storage.delete(RemoteBackupFile(name, '../$name')),
        throwsA(isA<CloudBackupException>()),
      );
      await expectLater(
        storage.download(
          const RemoteBackupFile('personal.txt', 'personal.txt'),
          temp,
        ),
        throwsA(isA<CloudBackupException>()),
      );
      expect(methods, isEmpty);
    },
  );
  test('cancellation during identity cannot start transfer later', () async {
    final pending = Completer<Object?>();
    final started = Completer<void>();
    handler = (call) async {
      if (call.method == 'identity') {
        started.complete();
        return pending.future;
      }
      return true;
    };
    final result = storage.list();
    final assertion = expectLater(
      result,
      throwsA(
        isA<CloudBackupException>().having((e) => e.code, 'code', 'cancelled'),
      ),
    );
    await started.future;
    storage.cancel();
    pending.complete('identity');
    await assertion;
    expect(methods, contains('cancel'));
    expect(methods, isNot(contains('list')));
  });
  test('failed native download removes the private partial file', () async {
    final previous = handler;
    handler = (call) async {
      if (call.method == 'download') {
        await File(call.arguments['path']).writeAsString('incomplete');
        throw PlatformException(code: 'network');
      }
      return previous(call);
    };
    await expectLater(
      storage.download(RemoteBackupFile(name, name), temp),
      throwsA(isA<CloudBackupException>()),
    );
    expect(await File('${temp.path}/$name.partial').exists(), false);
    expect(await File('${temp.path}/$name').exists(), false);
  });
  test(
    'SMB account profiles are independent of other storage providers',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final cloud = CloudBackupService();
      final accounts = BackupAccounts(prefs, cloud, drive);
      addTearDown(() {
        accounts.dispose();
        cloud.dispose();
      });
      final id = await accounts.create(false, smb: true);
      expect(accounts.ids(false, smb: true), ['default', id]);
      expect(accounts.ids(false), ['default']);
      expect(accounts.ids(true), ['default']);
      expect(accounts.ids(false, yandex: true), ['default']);
      expect(accounts.smb(id).profile, id);
    },
  );
}
