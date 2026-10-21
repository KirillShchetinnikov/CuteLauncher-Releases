import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flauncher/cloud_account.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/automatic_backup_service.dart';
import 'package:flauncher/providers/backup_automation_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/backup_storage.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/providers/drive_backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class _Account implements CloudAccountRepository {
  @override
  Future<CloudAccountInfo> info() async => const CloudAccountInfo(
    configured: true,
    url: 'https://example.test/',
    user: 'test',
  );
  @override
  Future<CloudAuthorization> authorization() async =>
      CloudAuthorization(Uri.parse('https://example.test/'), 'Basic dummy');
  @override
  Future<void> save(String url, String user, String password) async {}
  @override
  Future<void> disconnect() async {}
}

class _Drive extends DriveBackupService {
  @override
  Future<void> refreshAccount() async {}
}

class _Storage extends BackupStorage {
  final Map<String, List<int>> files;
  bool failUpload = false;
  _Storage(this.files, super.webdav, super.drive) : super(google: false);
  @override
  Future<List<RemoteBackupFile>> list() async => [
    for (final name in files.keys) RemoteBackupFile(name, name),
  ];
  @override
  Future<void> upload(File file, String name) async {
    if (failUpload) throw const CloudBackupException('network');
    files[name] = await file.readAsBytes();
  }

  @override
  Future<File> download(RemoteBackupFile file, Directory target) async =>
      File('${target.path}/${file.name}').writeAsBytes(files[file.id]!);
  @override
  Future<void> delete(RemoteBackupFile file) async {
    files.remove(file.id);
  }
}

class _TV {
  late SharedPreferences prefs;
  late FLauncherDatabase db;
  late SettingsService settings;
  late BackupService backup;
  late AutomaticBackupService local;
  late CloudBackupService webdav;
  late _Drive drive;
  late _Storage storage;
  late BackupAutomationService automation;
  late Directory root;
  DateTime clock = DateTime(2026, 10, 9, 12);
  int applies = 0;
  Future<void> start(
    Directory parent,
    Map<String, List<int>> files, {
    bool legacy = false,
  }) async {
    root = await parent.createTemp('tv-');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    db = FLauncherDatabase.inMemory();
    await db.insertCategory(CategoriesCompanion.insert(name: 'Apps', order: 0));
    settings = SettingsService(prefs);
    backup = BackupService(db, prefs);
    local = AutomaticBackupService(
      backup,
      settings,
      prefs,
      directory: () async => root,
      now: () => clock,
    );
    await local.initialized;
    if (legacy) await local.createNow();
    webdav = CloudBackupService(accounts: _Account());
    drive = _Drive();
    storage = _Storage(files, webdav.accounts, drive);
    automation = BackupAutomationService(
      prefs,
      backup,
      settings,
      local,
      webdav,
      drive,
      sources: [settings],
      directory: () async => root,
      now: () => clock,
      storageFactory: (_) => storage,
      apply: (file) async {
        await backup.replaceBackup(file, settings);
        applies++;
      },
    );
    await automation.initialized;
    await automation.configure(
      destination: BackupDestination.webdav,
      mode: BackupMode.synchronization,
      shared: true,
    );
  }

  Future<void> close() async {
    automation.dispose();
    local.dispose();
    webdav.dispose();
    drive.dispose();
    settings.dispose();
    await db.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late Map<String, List<int>> files;
  late _TV a, b;
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cute-backup-integration-');
    files = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => root.path,
        );
    a = _TV();
    b = _TV();
    await a.start(root, files);
    await b.start(root, files);
  });
  tearDown(() async {
    await a.close();
    await b.close();
    await root.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
  });
  test(
    'old local points remain intact and appear in managed local storage',
    () async {
      final tv = _TV();
      await tv.start(root, {}, legacy: true);
      try {
        final original = tv.local.entries.single;
        await tv.automation.configure(
          destination: BackupDestination.local,
          mode: BackupMode.backup,
        );
        final copies = await tv.automation.availableCopies();
        expect(copies, hasLength(1));
        expect(await original.file.exists(), true);
        expect(
          BackupAutomationService.createdAt(copies.single),
          original.createdAt,
        );
        expect(tv.automation.lastSuccess, tv.local.lastSuccess);
        expect(tv.local.enabled, false);
      } finally {
        await tv.close();
      }
    },
  );
  for (final mode in BackupMode.values) {
    test(
      'missed $mode catches up after sleep and retries failed transmission',
      () async {
        await a.automation.configure(mode: mode, enabled: true);
        expect(await a.automation.checkDue(), true);
        final success = a.automation.lastSuccess;
        a.automation.didChangeAppLifecycleState(AppLifecycleState.paused);
        a.clock = a.clock.add(const Duration(days: 3));
        await a.settings.setAppLanguage('ru');
        expect(await a.automation.checkDue(), false);
        expect(a.automation.lastSuccess, success);
        a.storage.failUpload = true;
        final failure = Completer<void>();
        void failed() {
          if (!a.automation.busy &&
              a.automation.failed &&
              !failure.isCompleted) {
            failure.complete();
          }
        }

        a.automation.addListener(failed);
        a.automation.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await failure.future.timeout(const Duration(seconds: 10));
        a.automation.removeListener(failed);
        expect(a.automation.lastSuccess, success);
        a.storage.failUpload = false;
        a.automation.didChangeAppLifecycleState(AppLifecycleState.paused);
        final completed = Completer<void>();
        void saved() {
          if (!a.automation.busy &&
              a.automation.lastSuccess == a.clock &&
              !completed.isCompleted) {
            completed.complete();
          }
        }

        a.automation.addListener(saved);
        a.automation.didChangeAppLifecycleState(AppLifecycleState.resumed);
        await completed.future.timeout(const Duration(seconds: 10));
        a.automation.removeListener(saved);
        final count = files.length;
        expect(await a.automation.checkDue(), false);
        expect(files.length, count);
        await a.automation.configure(enabled: false);
      },
    );
  }
  test(
    'selected local tree synchronizes two TVs and exposes one current copy',
    () async {
      const native = MethodChannel('me.efesser.flauncher/method');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(native, (call) async {
        if (call.method != 'backupFolderOperation') return null;
        final args = call.arguments as Map;
        final name = args['name'] as String?;
        switch (args['operation']) {
          case 'list':
            return [
              for (final name in files.keys) {'name': name, 'id': name},
            ];
          case 'upload':
            files[name!] = await File(args['path'] as String).readAsBytes();
            return true;
          case 'download':
            await File(args['path'] as String).writeAsBytes(files[name!]!);
            return true;
          case 'delete':
            files.remove(name);
            return true;
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(native, null));
      for (final tv in [a, b]) {
        await tv.automation.setLocalFolder('content://test/tree/backups');
        await tv.automation.configure(
          destination: BackupDestination.local,
          shared: true,
        );
      }
      await a.settings.setAppLanguage('en');
      expect(await a.automation.run(manual: true), true);
      expect(await b.automation.run(manual: true), true);
      expect(b.settings.appLanguage, 'en');
      final copies = await b.automation.availableCopies();
      expect(copies, hasLength(1));
      expect(files.length, 2);
      await b.automation.deleteCopy(copies.single);
      expect(files.length, 1);
      await expectLater(
        b.automation.deleteCopy(copies.single),
        throwsStateError,
      );
    },
  );
  test(
    'local backups can be restored and deleted without touching cloud storage',
    () async {
      await a.automation.configure(
        destination: BackupDestination.local,
        mode: BackupMode.backup,
      );
      await a.settings.setAppLanguage('en');
      expect(await a.automation.run(manual: true), true);
      final copies = await a.automation.availableCopies();
      expect(copies, hasLength(1));
      expect(files, isEmpty);
      await a.settings.setAppLanguage('ru');
      await a.automation.importLatest(selected: copies.single);
      expect(a.settings.appLanguage, 'en');
      await a.automation.deleteCopy(copies.single);
      expect(await a.automation.availableCopies(), isEmpty);
    },
  );
  test('two TVs download, merge by modification time and converge without questions', () async {
    a.clock = DateTime(2026, 10, 9, 12);
    await a.settings.setAppLanguage('en');
    expect(await a.automation.run(manual: true), true);
    b.clock = DateTime(2026, 10, 9, 13);
    await b.settings.setAppLanguage('ru');
    await b.settings.setShowCategoryTitles(false);
    expect(await b.automation.run(manual: true), true);
    a.clock = DateTime(2026, 10, 9, 14);
    expect(await a.automation.run(manual: true), true);
    expect(a.settings.appLanguage, 'ru');
    expect(a.settings.showCategoryTitles, false);
    expect(await b.automation.run(manual: true), true);
    expect(b.settings.appLanguage, 'ru');
    expect(b.settings.showCategoryTitles, false);
    expect(a.local.entries, isNotEmpty);
    expect(a.applies, 1);
    expect(files.length, 2);
  });
  test('later synchronization does not change timestamps of already applied server values', () async {
    await a.settings.setAppLanguage('en');
    expect(await a.automation.run(manual: true), true);
    expect(await b.automation.run(manual: true), true);
    b.clock = DateTime(2026, 10, 9, 16);
    await b.settings.setShowCategoryTitles(false);
    expect(await b.automation.run(manual: true), true);
    a.clock = DateTime(2026, 10, 9, 15);
    await a.settings.setAppLanguage('ru');
    expect(await a.automation.run(manual: true), true);
    expect(a.settings.appLanguage, 'ru');
    expect(a.settings.showCategoryTitles, false);
  });
  test(
    'failed upload preserves server copies and last successful status',
    () async {
      expect(await a.automation.run(manual: true, exportOnly: true), true);
      final names = files.keys.toSet(), success = a.automation.lastSuccess;
      a.storage.failUpload = true;
      a.clock = a.clock.add(const Duration(days: 1));
      expect(await a.automation.run(manual: true, exportOnly: true), false);
      expect(files.keys.toSet(), names);
      expect(a.automation.lastSuccess, success);
      expect(a.automation.failed, true);
    },
  );
  test('retention deletes only the current TV own snapshots', () async {
    await a.local.setKeepCount(1);
    await b.local.setKeepCount(1);
    expect(await b.automation.run(manual: true, exportOnly: true), true);
    expect(await a.automation.run(manual: true, exportOnly: true), true);
    a.clock = a.clock.add(const Duration(days: 1));
    expect(await a.automation.run(manual: true, exportOnly: true), true);
    expect(files.length, 2);
    expect(
      files.keys.where((n) => n.contains(b.automation.device)),
      hasLength(1),
    );
  });
  test('full import removes missing portable settings and preserves device credentials', () async {
    await a.settings.setAppLanguage('en');
    expect(await a.automation.run(manual: true, exportOnly: true), true);
    await b.prefs.setString('some_old_setting', 'delete');
    await b.prefs.setString('cloud_secret', 'keep');
    await b.automation.importLatest();
    expect(b.prefs.containsKey('some_old_setting'), false);
    expect(b.prefs.getString('cloud_secret'), 'keep');
    expect(b.settings.appLanguage, 'en');
    expect(b.local.entries, isNotEmpty);
  });
  test('background does not start any transfer', () async {
    a.automation.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(await a.automation.run(manual: true), false);
    expect(files, isEmpty);
  });
  test('full import removes absent wallpaper and keeps the previous image in a restore point', () async {
    expect(await a.automation.run(manual: true, exportOnly: true), true);
    final image = File('${root.path}/wallpaper');
    await image.writeAsBytes(kTransparentImage);
    await b.automation.importLatest();
    expect(await image.exists(), false);
    final point =
        jsonDecode(await b.local.entries.first.file.readAsString()) as Map;
    expect(
      (point['resources'] as Map)['wallpaper'],
      base64Encode(kTransparentImage),
    );
  });
  test('all blocks may be local while the policy still synchronizes and restores safely', () async {
    a.clock = a.clock.add(const Duration(hours: 1));
    for (final group in BackupSyncGroup.values) {
      await a.automation.setSyncGroupEnabled(group, false);
    }
    await b.settings.setAppLanguage('en');
    await b.prefs.setInt('custom_local_setting', 42);
    await b.db.customStatement(
      "UPDATE categories SET name = 'Local sections';",
    );
    final image = File('${root.path}/wallpaper');
    await image.writeAsBytes(kTransparentImage);
    expect(await a.automation.run(manual: true), true);
    final source = files.keys.single;
    final packet = jsonDecode(utf8.decode(files[source]!)) as Map;
    expect(
      (packet['backup'] as Map).keys,
      unorderedEquals(['version', 'settings']),
    );
    expect((packet['backup']['settings'] as Map).keys, [backupSyncGroupsKey]);
    expect(await b.automation.run(manual: true), true);
    expect(
      BackupSyncGroup.values.every(
        (group) => !b.automation.syncGroupEnabled(group),
      ),
      true,
    );
    await b.automation.importLatest(selected: RemoteBackupFile(source, source));
    expect(b.prefs.getString('app_language'), 'en');
    expect(b.prefs.getInt('custom_local_setting'), 42);
    expect(
      (await b.db.select(b.db.categories).get()).any(
        (row) => row.name == 'Local sections',
      ),
      true,
    );
    expect(await image.readAsBytes(), kTransparentImage);
  });
  test(
    'persistent sync history stores metadata rather than an archive or images',
    () async {
      expect(await a.automation.run(manual: true), true);
      final state = jsonDecode(
        await File('${a.root.path}/backup_sync_state.json').readAsString(),
      ) as Map;
      expect(state['stateVersion'], 1);
      expect(state.containsKey('backup'), false);
      expect(state['revisions'], isNotEmpty);
    },
  );
  test('group choice synchronizes while disabled settings remain different on each TV', () async {
    expect(await a.automation.run(manual: true), true);
    expect(await b.automation.run(manual: true), true);
    a.clock = a.clock.add(const Duration(hours: 1));
    b.clock = b.clock.add(const Duration(hours: 2));
    await a.settings.setAccentColor('FFFFFF');
    await b.settings.setAccentColor('000000');
    await a.settings.setAppLanguage('ru');
    await b.settings.setAppLanguage('en');
    await a.automation.setSyncGroupEnabled(BackupSyncGroup.accent, false);
    await a.automation.setSyncGroupEnabled(BackupSyncGroup.language, false);
    expect(await a.automation.run(manual: true), true);
    final copy = files.keys.firstWhere(
      (name) =>
          name.startsWith('cute-sync-') && name.contains(a.automation.device),
    );
    final packet = jsonDecode(utf8.decode(files[copy]!)) as Map;
    final values = packet['backup']['settings'] as Map;
    expect(values.containsKey('accent_color'), false);
    expect(values.containsKey('app_language'), false);
    expect(values[backupSyncGroupsKey], ['accent', 'language']);
    expect(await b.automation.run(manual: true), true);
    expect(b.automation.syncGroupEnabled(BackupSyncGroup.accent), false);
    expect(b.prefs.getString('accent_color'), '000000');
    expect(b.prefs.getString('app_language'), 'en');
    expect(await a.automation.run(manual: true), true);
    expect(a.prefs.getString('accent_color'), 'FFFFFF');
    expect(a.prefs.getString('app_language'), 'ru');
    final currentCopy = files.keys.firstWhere(
      (name) =>
          name.startsWith('cute-sync-') && name.contains(a.automation.device),
    );
    final selected = RemoteBackupFile(currentCopy, currentCopy);
    await b.automation.importLatest(selected: selected);
    expect(b.prefs.getString('accent_color'), '000000');
    expect(b.prefs.getString('app_language'), 'en');
    expect(b.prefs.getStringList(backupSyncGroupsKey), ['accent', 'language']);
    expect(await a.automation.run(manual: true, exportOnly: true), true);
    final complete = files.entries.firstWhere(
      (e) => e.key.startsWith('cute-backup-'),
    );
    final full = jsonDecode(utf8.decode(complete.value)) as Map;
    expect(full['settings']['accent_color'], 'FFFFFF');
    expect(full['settings']['app_language'], 'ru');
    expect(full.containsKey('resources'), true);
    b.clock = b.clock.add(const Duration(hours: 1));
    await b.automation.setSyncGroupEnabled(BackupSyncGroup.accent, true);
    expect(await b.automation.run(manual: true), true);
    expect(await a.automation.run(manual: true), true);
    expect(a.automation.syncGroupEnabled(BackupSyncGroup.accent), true);
    expect(
      a.prefs.getString('accent_color'),
      b.prefs.getString('accent_color'),
    );
    expect(a.prefs.getString('app_language'), 'ru');
  });
  test(
    'editing one child preserves the other legacy-disabled children',
    () async {
      await a.prefs.setStringList(backupSyncGroupsKey, [
        'appearance',
        'weather',
      ]);
      expect(a.automation.syncGroupEnabled(BackupSyncGroup.accent), false);
      expect(a.automation.syncGroupEnabled(BackupSyncGroup.background), false);
      expect(
        a.automation.syncGroupEnabled(BackupSyncGroup.weatherSource),
        false,
      );
      await a.automation.setSyncGroupEnabled(BackupSyncGroup.accent, true);
      expect(a.automation.syncGroupEnabled(BackupSyncGroup.accent), true);
      expect(a.automation.syncGroupEnabled(BackupSyncGroup.background), false);
      expect(
        a.automation.syncGroupEnabled(BackupSyncGroup.weatherDisplay),
        false,
      );
      expect(a.prefs.getStringList(backupSyncGroupsKey), [
        'background',
        'tiles',
        'animations',
        'menuLayout',
        'weatherSource',
        'weatherDisplay',
      ]);
    },
  );
}
