// Regression checks for the original audit findings.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/backup_service.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import '../mocks.mocks.dart';

Future<void> initialized(WatchNextService service) async {
  final limit = DateTime.now().add(const Duration(seconds: 3));
  while (!service.initialized && DateTime.now().isBefore(limit)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(service.initialized, true);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('malformed backup preserves preferences and database', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themes', 'classic');
    final database = FLauncherDatabase.inMemory();
    final originalId = await database.insertCategory(CategoriesCompanion.insert(name: 'Original', order: 0));
    final dir = await Directory.systemTemp.createTemp('cutelauncher_audit');
    final file = File('${dir.path}/invalid.json');
    await file.writeAsString(jsonEncode({'version': 1, 'settings': {'themes': 'premium'}, 'apps': 'invalid', 'categories': [], 'appsCategories': [], 'spacers': []}));
    try {
      await expectLater(BackupService(database, prefs).importBackup(file), throwsFormatException);
      expect(prefs.getString('themes'), 'classic');
      expect((await database.getCategories()).single.id, originalId);
    } finally {
      await database.close();
      await dir.delete(recursive: true);
    }
  });

  test('permission check error is not reported as granted', () async {
    const channel = MethodChannel('me.efesser.flauncher/method');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (_) async => throw PlatformException(code: 'unavailable'));
    final service = BrightnessService(await SharedPreferences.getInstance());
    await service.checkPermission();
    expect(service.hasPermission, false);
    service.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('Watch Next poster and failed-delete regressions', () async {
    final channel = MockFLauncherChannel();
    final stream = StreamController<dynamic>.broadcast();
    var uri = 'content://poster/old';
    when(channel.checkWatchNextPermission()).thenAnswer((_) async => true);
    when(channel.getWatchNextPrograms()).thenAnswer((_) async => [{'id': 7, 'posterArtUri': uri}]);
    when(channel.getWatchNextPoster(any)).thenAnswer((inv) async => Uint8List.fromList([inv.positionalArguments[0] == 'content://poster/old' ? 1 : 2]));
    when(channel.addWatchNextChangedListener(any)).thenAnswer((inv) => stream.stream.listen(inv.positionalArguments[0]));
    when(channel.deleteWatchNextProgram(7)).thenAnswer((_) async => false);
    final service = WatchNextService(channel);
    try {
      await initialized(service);
      uri = 'content://poster/new';
      await service.refresh();
      expect(service.programs.single.posterArtUri, uri);
      expect(service.programs.single.posterBytes, [2]);
      verify(channel.getWatchNextPoster('content://poster/new')).called(1);
      expect(await service.deleteProgram(service.programs.single), false);
      expect(service.programs.single.id, 7);
    } finally {
      service.dispose();
      await stream.close();
    }
  });

  test('deleting a custom section named TV Apps never populates another manual section', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final db = MockFLauncherDatabase();
    final app = App(packageName: 'app.test', name: 'Test', version: '1', hidden: false);
    final tv = Category(id: 1, name: 'TV Apps', order: 0);
    final other = Category(id: 2, name: 'Other', order: 1);
    when(channel.getApplications()).thenAnswer((_) async => [{'packageName': app.packageName, 'name': app.name, 'version': app.version, 'sideloaded': false}]);
    when(channel.getApplicationIcon(any)).thenAnswer((_) async => Uint8List(0));
    when(channel.getApplicationBanner(any)).thenAnswer((_) async => Uint8List(0));
    when(db.getApplications()).thenAnswer((_) async => [app]);
    when(db.getCategories()).thenAnswer((_) async => [tv, other]);
    when(db.getAppsCategories()).thenAnswer((_) async => [AppCategory(categoryId: 1, appPackageName: app.packageName, order: 0)]);
    when(db.getLauncherSpacers()).thenAnswer((_) async => []);
    when(db.wasCreated).thenReturn(false);
    when(db.transaction(any)).thenAnswer((inv) => inv.positionalArguments[0]());
    when(db.nextAppCategoryOrder(2)).thenAnswer((_) async => 0);
    final service = AppsService(channel, db);
    final limit = DateTime.now().add(const Duration(seconds: 3));
    while (!service.initialized && DateTime.now().isBefore(limit)) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(service.initialized, true);
    await service.deleteSection(0);
    expect(service.categories.length, 1);
    expect(service.categories.single.applications, isEmpty);
    expect(service.applications.single.categoryOrders, isEmpty);
    verifyNever(db.insertAppsCategories(any));
    service.dispose();
  });
}
