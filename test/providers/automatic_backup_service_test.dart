import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/automatic_backup_service.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:transparent_image/transparent_image.dart';

class _ControlledBackup extends BackupService {
  Completer<void>? gate;
  Completer<void>? started;
  int? size;
  _ControlledBackup(super.database, super.preferences);
  @override
  Future<void> writeBackupTo(File file, {SettingsService? settingsService,
      bool validateStructure = false}) async {
    started?.complete();
    await gate?.future;
    if (size case final int size) {
      final writer = await file.open(mode: FileMode.write);
      try { await writer.setPosition(size - 1); await writer.writeByte(0); }
      finally { await writer.close(); }
    } else {
      await super.writeBackupTo(file, settingsService: settingsService,
          validateStructure: validateStructure);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory root;
  late FLauncherDatabase database;
  late SharedPreferences prefs;
  late SettingsService settings;
  late _ControlledBackup backup;
  late AutomaticBackupService service;
  late DateTime clock;
  Future<void> start() async {
    service = AutomaticBackupService(backup, settings, prefs,
        directory: () async => root, now: () => clock);
    await service.initialized;
  }
  setUp(() async {
    root = await Directory.systemTemp.createTemp('cute-auto-backups-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), (_) async => root.path);
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    database = FLauncherDatabase.inMemory();
    await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    backup = _ControlledBackup(database, prefs);
    clock = DateTime(2026, 10, 5, 12);
    await start();
  });
  tearDown(() async {
    service.dispose(); settings.dispose();
    await database.close();
    await root.delete(recursive: true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'), null);
  });

  test('daily copies are opt-in, skip background and catch up on resume', () async {
    await service.checkDue();
    expect(service.entries, isEmpty);
    await service.setEnabled(true);
    expect(service.entries, hasLength(1));
    await service.checkDue();
    expect(service.entries, hasLength(1));
    clock = clock.add(const Duration(days: 2));
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    await service.checkDue();
    expect(service.entries, hasLength(1));
    final completed = Completer<void>();
    void listener() { if (service.entries.length == 2 && !completed.isCompleted) completed.complete(); }
    service.addListener(listener);
    service.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await completed.future.timeout(const Duration(seconds: 10));
    service.removeListener(listener);
    await service.setEnabled(false);
    clock = clock.add(const Duration(days: 2));
    await service.checkDue();
    expect(service.entries, hasLength(2));
  });

  test('portable copies include images and restore through BackupService without secrets', () async {
    await prefs.setString('weather_api_key', 'test-weather-secret');
    await prefs.setString('adb_private_key', 'test-adb-secret');
    await prefs.setBool('overlay_permission', true);
    await prefs.setString('weather_cache', 'local cache');
    final wallpaper = File('${root.path}/wallpaper');
    final banner = File('${root.path}/banner.png');
    await wallpaper.writeAsBytes(kTransparentImage);
    await banner.writeAsBytes(kTransparentImage);
    await prefs.setString('custom_banner_video.app', banner.path);
    await settings.setCardFocusMode(CardFocusMode.remember);
    expect(await service.createNow(), isTrue);
    final point = service.entries.single;
    final data = jsonDecode(await point.file.readAsString()) as Map;
    final map = data['settings'] as Map;
    for (final key in ['weather_api_key', 'adb_private_key', 'weather_cache',
        'overlay_permission', automaticBackupTimeKey, 'custom_banner_video.app']) {
      expect(map.containsKey(key), isFalse, reason: key);
    }
    expect((data['resources'] as Map).keys, containsAll(['wallpaper', 'custom_banner_video.app']));
    await wallpaper.delete(); await banner.delete();
    await settings.setCardFocusMode(CardFocusMode.settings);
    await database.customStatement("UPDATE categories SET name = 'Changed'");
    await service.restore(point);
    expect(settings.cardFocusMode, CardFocusMode.remember);
    expect((await database.getCategories()).map((c) => c.name), contains('Original'));
    expect(await wallpaper.readAsBytes(), kTransparentImage);
    expect(await File(prefs.getString('custom_banner_video.app')!).readAsBytes(), kTransparentImage);
    expect(prefs.getString('weather_api_key'), 'test-weather-secret');
    expect(await point.file.exists(), isTrue);
  });

  test('retention removes only owned copies and count reduction prunes immediately', () async {
    await service.setKeepCount(3);
    final foreign = File('${root.path}/automatic_backups/notes.json');
    await foreign.writeAsString('keep');
    for (var i=0; i<5; i++) {
      clock = clock.add(const Duration(seconds: 1));
      expect(await service.createNow(), isTrue);
    }
    expect(service.entries, hasLength(3));
    expect(service.entries.first.createdAt, clock);
    await service.setKeepCount(1);
    expect(service.entries, hasLength(1));
    expect(await foreign.readAsString(), 'keep');
    service.dispose(); await start();
    expect(service.keepCount, 1);
    expect(service.entries, hasLength(1));
  });

  test('size quota is bounded and oversized or failed copies keep previous points', () async {
    await service.setKeepCount(10);
    backup.size = 60 * 1024 * 1024;
    for(var i=0; i<5; i++) {
      clock = clock.add(const Duration(seconds: 1));
      expect(await service.createNow(), isTrue);
    }
    expect(service.entries, hasLength(4));
    expect(service.entries.fold<int>(0, (sum, e) => sum + e.bytes), lessThanOrEqualTo(AutomaticBackupService.maximumTotalBytes));
    final before = service.entries.map((e) => e.file.path).toList();
    backup.size = 65 * 1024 * 1024;
    expect(await service.createNow(), isFalse);
    expect(service.failed, isTrue);
    expect(service.entries.map((e) => e.file.path), before);
    expect(Directory('${root.path}/automatic_backups').listSync().where((f) => f.path.endsWith('.partial')), isEmpty);
  });

  test('corrupt restore and foreign path are rejected without changing current data', () async {
    await service.createNow();
    final point = service.entries.single;
    await point.file.writeAsString('{broken');
    await settings.setCardFocusMode(CardFocusMode.settings);
    await expectLater(service.restore(point), throwsA(anything));
    expect(settings.cardFocusMode, CardFocusMode.settings);
    expect((await database.getCategories()).single.name, 'Original');
    final foreign = AutomaticBackupEntry(File('${root.path}/outside.json'), clock, 0);
    await expectLater(service.restore(foreign), throwsFormatException);
    expect((await database.getCategories()).single.name, 'Original');
  });

  test('one in-flight capture; background cancels publication and cleans staging', () async {
    await service.createNow();
    backup.gate = Completer<void>(); backup.started = Completer<void>();
    final operation = service.createNow();
    await backup.started!.future;
    expect(await service.createNow(), isFalse);
    await expectLater(service.restore(service.entries.single), throwsStateError);
    service.didChangeAppLifecycleState(AppLifecycleState.paused);
    backup.gate!.complete();
    expect(await operation, isFalse);
    expect(service.entries, hasLength(1));
    expect(Directory('${root.path}/automatic_backups').listSync().where((f) => f.path.endsWith('.partial')), isEmpty);
  });

  test('startup removes abandoned owned staging files and preserves other files', () async {
    service.dispose();
    final folder = Directory('${root.path}/automatic_backups');
    await File('${folder.path}/auto-1-0.json.partial').writeAsString('unfinished');
    final foreign = File('${folder.path}/other.partial');
    await foreign.writeAsString('keep');
    await start();
    expect(await File('${folder.path}/auto-1-0.json.partial').exists(), isFalse);
    expect(await foreign.readAsString(), 'keep');
  });
}
