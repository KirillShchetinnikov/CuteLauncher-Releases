import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('catalog changes hide disabled tiles and restore saved layout on enable', () async {
    final db = FLauncherDatabase.inMemory();
    final channel = MockFLauncherChannel();
    late void Function(Map<String, dynamic>) onEvent;
    when(channel.addAppsChangedListener(any)).thenAnswer((call) {
      onEvent = call.positionalArguments.single;
      return null;
    });
    final movie = <String, dynamic>{
      'packageName': 'movies', 'name': 'Movies',
      'version': '1', 'sideloaded': false,
    };
    var enabled = true;
    when(channel.getApplications()).thenAnswer((_) async => enabled ? [movie] : []);
    final service = AppsService(channel, db);
    while (!service.initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
    Future<void> catalogChanged() async {
      final notified = Completer<void>();
      void listener() { if (!notified.isCompleted) notified.complete(); }
      service.addListener(listener);
      try {
        onEvent({'action': 'CATALOG_CHANGED'});
        await notified.future.timeout(const Duration(seconds: 5));
      } finally {
        service.removeListener(listener);
      }
    }
    try {
      final categoryId = service.categories.firstWhere((c) => c.systemKey == 'tv_apps').id;
      await db.updateApp('movies', const AppsCompanion(launchCount: Value(17)));
      await service.refreshState();
      final membership = await db.getAppsCategories();
      expect(service.categories.firstWhere((c) => c.id == categoryId).applications, hasLength(1));

      enabled = false;
      await catalogChanged();
      expect(service.applications, isEmpty);
      expect(service.categories.every((c) => c.applications.isEmpty), isTrue);
      expect((await db.getApplications()).single.launchCount, 17);
      expect(await db.getAppsCategories(), membership);

      enabled = true;
      await catalogChanged();
      expect(service.applications.single.launchCount, 17);
      expect(service.categories.firstWhere((c) => c.id == categoryId).applications.single.packageName, 'movies');
      expect(await db.getAppsCategories(), membership);
    } finally {
      service.dispose();
      await db.close();
    }
  });

  test('own launcher follows visibility preference in all apps', () async {
    final db = FLauncherDatabase.inMemory();
    final channel = MockFLauncherChannel();
    final settings = SettingsService(await SharedPreferences.getInstance());
    expect(settings.appKeyClickEnabled, isFalse);
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    when(channel.getApplications()).thenAnswer((_) async => [
      {'packageName': 'self', 'name': 'CuteLauncher', 'version': '1', 'sideloaded': false},
      {'packageName': 'tv', 'name': 'TV', 'version': '1', 'sideloaded': false},
    ]);
    final service = AppsService(channel, db, settingsService: settings, ownPackageName: 'self');
    while (!service.initialized) { await Future<void>.delayed(const Duration(milliseconds: 1)); }
    try {
      List<String> packages() => service.categories.firstWhere((c) => c.systemKey == 'all_apps').applications.map((a) => a.packageName).toList();
      expect(packages(), contains('self'));
      await settings.setHideLauncherTile(true);
      expect(packages(), isNot(contains('self')));
      final self = service.applications.firstWhere((app) => app.packageName == 'self');
      expect(self.hidden, false);
      expect(service.isTileHidden(self), true);
      await service.showApplication(self);
      expect(settings.hideLauncherTile, false);
      expect(service.isTileHidden(self), false);
      expect(packages(), contains('self'));
      await service.hideApplication(self);
      await settings.setHideLauncherTile(true);
      await service.showApplication(self);
      expect(self.hidden, false);
      expect(settings.hideLauncherTile, false);

      await settings.setHideLauncherTile(false);
      expect(packages(), contains('self'));
    } finally { service.dispose(); settings.dispose(); await db.close(); }
  });

  test('section reset restores defaults and keeps hidden apps and launch statistics', () async {
    final db = FLauncherDatabase.inMemory();
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    when(channel.getApplications()).thenAnswer((_) async => [
      {'packageName': 'tv', 'name': 'TV', 'version': '1', 'sideloaded': false},
      {'packageName': 'other', 'name': 'Other', 'version': '1', 'sideloaded': true},
    ]);
    final service = AppsService(channel, db);
    while (!service.initialized) { await Future<void>.delayed(const Duration(milliseconds: 1)); }
    try {
      await db.updateApp('tv', const AppsCompanion(hidden: Value(true), launchCount: Value(17)));
      await service.addCategory('Custom');
      await service.addSpacer(250);
      await service.refreshState();
      await service.resetSections();
      final categories = await db.getCategories();
      expect(categories.map((c) => c.systemKey), ['all_apps', 'tv_apps', 'other_apps', 'favorites']);
      expect(categories.first.sort, CategorySort.alphabetical);
      expect(categories.every((c) => c.visible && c.columnsCount == 6 && c.rowHeight == 110), isTrue);
      expect(await db.getLauncherSpacers(), isEmpty);
      final tv = (await db.getApplications()).firstWhere((a) => a.packageName == 'tv');
      expect(tv.hidden, isTrue);
      expect(tv.launchCount, 17);
      final membership = await db.getAppsCategories();
      expect(membership.map((m) => (m.categoryId, m.appPackageName)),
        unorderedEquals([(categories[1].id, 'tv'), (categories[2].id, 'other')]));
      await service.resetSections();
      expect(await db.getCategories(), hasLength(4));
    } finally { service.dispose(); await db.close(); }
  });

  for (final result in [true, false, null]) {
    test('launch result $result updates recency only after success', () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();
      final service = await _buildInitialisedAppsService(channel, database);
      final app = App.fromSystem({'packageName': 'test.app', 'name': 'Test', 'version': '1', 'sideloaded': false});
      final previous = DateTime(2020);
      app.lastLaunchedAt = previous;
      when(channel.launchApp(any)).thenAnswer((_) async {
        if (result == null) throw StateError('launch failed');
        expect(app.lastLaunchedAt, previous);
        return result;
      });
      when(database.updateApp(any, any)).thenAnswer((_) async => true);
      try {
        expect(await service.launchApp(app), result == true);
        if (result == true) {
          expect(app.lastLaunchedAt!.isAfter(previous), isTrue);
          expect(app.launchCount, 1);
          verify(database.updateApp('test.app', any)).called(1);
        } else {
          expect(app.lastLaunchedAt, previous);
          expect(app.launchCount, 0);
          verifyNever(database.updateApp(any, any));
        }
      } finally {
        service.dispose();
      }
    });
  }

  test('successful launch reorders recent category and preserves manual order', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final database = MockFLauncherDatabase();
    final first = App.fromSystem({'packageName': 'a', 'name': 'A', 'version': '1', 'sideloaded': false});
    final second = App.fromSystem({'packageName': 'b', 'name': 'B', 'version': '1', 'sideloaded': false});
    first.lastLaunchedAt = DateTime(2020);
    second.lastLaunchedAt = DateTime(2021);
    when(channel.getApplications()).thenAnswer((_) async => [
      {'packageName': 'a', 'name': 'A', 'version': '1', 'sideloaded': false},
      {'packageName': 'b', 'name': 'B', 'version': '1', 'sideloaded': false},
    ]);
    when(channel.getApplicationIcon(any)).thenAnswer((_) async => Uint8List(0));
    when(channel.getApplicationBanner(any)).thenAnswer((_) async => Uint8List(0));
    when(database.getApplications()).thenAnswer((_) async => [first, second]);
    when(database.getCategories()).thenAnswer((_) async => [
      Category(id: 1, name: 'Recent', order: 0, sort: CategorySort.lastUsed),
      Category(id: 2, name: 'Manual', order: 1, sort: CategorySort.manual),
    ]);
    when(database.getAppsCategories()).thenAnswer((_) async => [
      for (final id in [1, 2]) ...[
        AppCategory(categoryId: id, appPackageName: 'a', order: 1),
        AppCategory(categoryId: id, appPackageName: 'b', order: 0),
      ],
    ]);
    when(database.getLauncherSpacers()).thenAnswer((_) async => []);
    when(database.wasCreated).thenReturn(false);
    when(database.transaction(any)).thenAnswer((call) => call.positionalArguments[0]());
    when(database.persistApps(any)).thenAnswer((_) async {});
    when(database.updateApp(any, any)).thenAnswer((_) async => true);
    when(channel.launchApp(any)).thenAnswer((_) async => true);
    final service = AppsService(channel, database);
    while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
    try {
      expect(service.categories.first.applications.first.packageName, 'b');
      expect(await service.launchApp(first), isTrue);
      expect(service.categories.first.applications.first.packageName, 'a');
      expect(service.categories.last.applications.first.packageName, 'b');
    } finally { service.dispose(); }
  });

  test('frequency sorts by count and breaks ties by package', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final service = await _buildInitialisedAppsService(channel, MockFLauncherDatabase());
    final a = App(packageName: 'a', name: 'Z', version: '1', hidden: false, launchCount: 2);
    final b = App(packageName: 'b', name: 'A', version: '1', hidden: false, launchCount: 5);
    final c = App(packageName: 'c', name: 'B', version: '1', hidden: false, launchCount: 2);
    final category = Category.withApplications(name: 'Frequent', sort: CategorySort.mostUsed, applications: [c,a,b]);
    service.sortCategory(category);
    expect(category.applications.map((a) => a.packageName), ['b','a','c']);
    service.dispose();
  });

  test('concurrent successful launches each persist a count', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final db = MockFLauncherDatabase();
    final service = await _buildInitialisedAppsService(channel, db);
    when(channel.launchApp(any)).thenAnswer((_) async => true);
    when(db.updateApp(any, any)).thenAnswer((_) async { await Future<void>.delayed(Duration.zero); });
    final app = App(packageName: 'a', name: 'A', version: '1', hidden: false);
    await Future.wait([service.launchApp(app), service.launchApp(app), service.launchApp(app)]);
    expect(app.launchCount, 3);
    final writes = verify(db.updateApp('a', captureAny)).captured.cast<AppsCompanion>();
    expect(writes.map((w) => w.launchCount.value), [1,2,3]);
    service.dispose();
  });

  test('concurrent image requests share a load; missing image is cached', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final db = MockFLauncherDatabase();
    final service = await _buildInitialisedAppsService(channel, db);
    var reads = 0;
    when(channel.getApplicationIcon('a')).thenAnswer((_) async {
      reads++;
      await Future<void>.delayed(Duration.zero);
      return Uint8List(2);
    });
    try {
      final images = await Future.wait([service.getAppIcon('a'), service.getAppIcon('a')]);
      expect(reads, 1);
      expect(identical(images[0], images[1]), isTrue);
      await service.getAppBanner('missing');
      await service.getAppBanner('missing');
      verify(channel.getApplicationBanner('missing')).called(1);
    } finally { service.dispose(); }
  });

  test('invalid custom banner keeps the previous setting', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final service = await _buildInitialisedAppsService(channel, MockFLauncherDatabase());
    final directory = await Directory.systemTemp.createTemp('cute-banner-');
    final file = await File('${directory.path}/bad.png').writeAsBytes([1,2,3]);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_banner_a', 'previous.png');
    try {
      await expectLater(service.setCustomAppBanner('a', file.path), throwsA(isA<ImageInputException>()));
      expect(prefs.getString('custom_banner_a'), 'previous.png');
      expect(await file.exists(), isTrue);
    } finally { service.dispose(); await directory.delete(recursive: true); }
  });

  test('pending image does not refill a cache after memory pressure', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final service = await _buildInitialisedAppsService(channel, MockFLauncherDatabase());
    final pending = Completer<Uint8List>();
    when(channel.getApplicationIcon('late')).thenAnswer((_) => pending.future);
    final reading = service.getAppIcon('late');
    await pumpEventQueue();
    service.clearImageCaches();
    pending.complete(Uint8List(100));
    await reading;
    expect(service.imageCacheBytes, 0);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_banner_keep', 'original.png');
    service.clearImageCaches();
    expect(prefs.getString('custom_banner_keep'), 'original.png');
    service.dispose();
  });

  test('queued loads from before cache clearing are discarded', () async {
    final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
    final service = await _buildInitialisedAppsService(channel, MockFLauncherDatabase());
    final a = Completer<Uint8List>(); final b = Completer<Uint8List>();
    when(channel.getApplicationIcon('a')).thenAnswer((_) => a.future);
    when(channel.getApplicationIcon('b')).thenAnswer((_) => b.future);
    final reading = Future.wait([service.getAppIcon('a'), service.getAppIcon('b'), service.getAppIcon('queued')]);
    await pumpEventQueue();
    service.clearImageCaches();
    a.complete(Uint8List(1)); b.complete(Uint8List(1));
    await reading;
    verifyNever(channel.getApplicationIcon('queued'));
    expect(service.imageCacheBytes, 0);
    service.dispose();
  });

  group("removeCustomAppBanner", () {
    test("removes custom banner and deletes file if it exists", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();
      final appsService = await _buildInitialisedAppsService(channel, database);

      // Create a temp file
      final tempFile =
          await File('${Directory.systemTemp.path}/test_banner.png').create();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_banner_test.app', tempFile.path);

      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      await appsService.removeCustomAppBanner('test.app');

      expect(await tempFile.exists(), isFalse);
      expect(prefs.containsKey('custom_banner_test.app'), isFalse);
      expect(notified, isTrue);
    });

    test("handles file deletion errors gracefully", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();
      final appsService = await _buildInitialisedAppsService(channel, database);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'custom_banner_test.app', '/invalid/path/that/does/not/exist.png');

      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      // Should not throw an exception
      await appsService.removeCustomAppBanner('test.app');

      expect(prefs.containsKey('custom_banner_test.app'), isFalse);
      expect(notified, isTrue);
    });

    test("works when custom banner path is null", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();
      final appsService = await _buildInitialisedAppsService(channel, database);

      final prefs = await SharedPreferences.getInstance();

      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      // Should not throw an exception
      await appsService.removeCustomAppBanner('test.app');

      expect(prefs.containsKey('custom_banner_test.app'), isFalse);
      expect(notified, isTrue);
    });
  });

  group("AppsService Category Integration", () {
    test("loads categories with apps correctly", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final testApp1 = App(
          packageName: "app.1", name: "App 1", version: "1.0.0", hidden: false);
      final testApp2 = App(
          packageName: "app.2", name: "App 2", version: "1.0.0", hidden: false);
      final testApp3 = App(
          packageName: "app.3", name: "App 3", version: "1.0.0", hidden: false);
      final hiddenApp = App(
          packageName: "app.hidden",
          name: "Hidden App",
          version: "1.0.0",
          hidden: true);

      final category = Category(id: 1, name: "Test Category", order: 0);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.1',
              'name': 'App 1',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.2',
              'name': 'App 2',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.3',
              'name': 'App 3',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.hidden',
              'name': 'Hidden App',
              'version': '1.0.0',
              'sideloaded': false
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications()).thenAnswer(
          (_) => Future.value([testApp1, testApp2, testApp3, hiddenApp]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([category]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([
        AppCategory(categoryId: 1, appPackageName: "app.1", order: 1),
        AppCategory(categoryId: 1, appPackageName: "app.2", order: 0),
        AppCategory(categoryId: 1, appPackageName: "app.3", order: 2),
        AppCategory(categoryId: 1, appPackageName: "app.hidden", order: 3),
      ]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.wasCreated).thenReturn(false);
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.deleteApps(any)).thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);

      // Wait for initialization
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final categories = appsService.categories;
      expect(categories.length, 1);
      expect(categories[0].name, "Test Category");

      final appsInCategory = categories[0].applications;
      // Manual membership remains visible even when the app is hidden.
      expect(appsInCategory.length, 4);

      // Should be ordered by the 'order' in AppCategory (0: app.2, 1: app.1, 2: app.3)
      expect(appsInCategory[0].packageName, "app.2");
      expect(appsInCategory[1].packageName, "app.1");
      expect(appsInCategory[2].packageName, "app.3");
    });

    test("saveApplicationOrderInCategory updates local categoryOrders map",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final testApp1 = App(
          packageName: "app.1", name: "App 1", version: "1.0.0", hidden: false);
      final testApp2 = App(
          packageName: "app.2", name: "App 2", version: "1.0.0", hidden: false);
      final category = Category(id: 1, name: "Test Category", order: 0);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.1',
              'name': 'App 1',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.2',
              'name': 'App 2',
              'version': '1.0.0',
              'sideloaded': false
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications())
          .thenAnswer((_) => Future.value([testApp1, testApp2]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([category]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([
            AppCategory(categoryId: 1, appPackageName: "app.1", order: 0),
            AppCategory(categoryId: 1, appPackageName: "app.2", order: 1),
          ]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.wasCreated).thenReturn(false);
      when(database.replaceAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);

      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final categoryObj = appsService.categories.first;

      // Let's reorder them locally: move app 1 to the end
      appsService.reorderApplication(categoryObj, 0, 1);

      // Now save
      await appsService.saveApplicationOrderInCategory(categoryObj);

      // Verify that local categoryOrders reflect the new indices (app.2 order is 0, app.1 order is 1)
      expect(testApp2.categoryOrders[1], 0);
      expect(testApp1.categoryOrders[1], 1);
    });

    test("sortCategory sorts alphabetically case-insensitively", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final appB =
          App(packageName: "b", name: "bravo", version: "1.0", hidden: false);
      final appA =
          App(packageName: "a", name: "Alpha", version: "1.0", hidden: false);
      final appC =
          App(packageName: "c", name: "charlie", version: "1.0", hidden: false);

      final category = Category(
          id: 1,
          name: "Test Category",
          order: 0,
          sort: CategorySort.alphabetical);
      category.applications.addAll([appB, appC, appA]);

      final appsService = await _buildInitialisedAppsService(channel, database);
      appsService.sortCategory(category);

      expect(category.applications.map((a) => a.packageName).toList(),
          ["a", "b", "c"]);
    });

    test("default categories places TV Apps section before Non-TV Apps section",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      when(database.insertCategory(any)).thenAnswer((inv) {
        return Future.value(1);
      });
      when(database.insertAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = await _buildInitialisedAppsService(channel, database);
      await appsService.addCategory("TV Apps");
      await appsService.addCategory("Non-TV Apps");

      expect((appsService.launcherSections[0] as Category).name, "TV Apps");
      expect((appsService.launcherSections[1] as Category).name, "Non-TV Apps");
    });

    test(
        "initializes when manually sorted category has app missing AppsCategories row",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final orderedApp = App(
          packageName: "app.ordered",
          name: "Ordered App",
          version: "1.0.0",
          hidden: false);
      final orphanApp = App(
          packageName: "app.orphan",
          name: "Orphan App",
          version: "1.0.0",
          hidden: false);
      final tvCategory =
          Category(id: 1, name: "TV Apps", systemKey: "tv_apps", order: 0, sort: CategorySort.manual);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.ordered',
              'name': 'Ordered App',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.orphan',
              'name': 'Orphan App',
              'version': '1.0.0',
              'sideloaded': false
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications())
          .thenAnswer((_) => Future.value([orderedApp, orphanApp]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([tvCategory]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([
            AppCategory(categoryId: 1, appPackageName: "app.ordered", order: 0),
          ]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.wasCreated).thenReturn(false);
      when(database.nextAppCategoryOrder(1)).thenAnswer((_) => Future.value(1));
      when(database.insertAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);

      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(appsService.initialized, isTrue);

      final tvApps = appsService.categories.first;
      expect(tvApps.applications.map((app) => app.packageName).toList(),
          ["app.ordered", "app.orphan"]);
      expect(orderedApp.categoryOrders[1], 0);
      expect(orphanApp.categoryOrders[1], 1);

      final captured =
          verify(database.insertAppsCategories(captureAny)).captured;
      expect(captured.length, 1);
      final batch = captured.first as List<AppsCategoriesCompanion>;
      expect(batch.length, 1);
      expect(batch.first.appPackageName.value, "app.orphan");
      expect(batch.first.order.value, 1);
    });

    test(
        "hidden orphaned app is repaired in database but not shown in category",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final visibleApp = App(
          packageName: "app.visible",
          name: "Visible App",
          version: "1.0.0",
          hidden: false);
      final hiddenOrphan = App(
          packageName: "app.hidden",
          name: "Hidden App",
          version: "1.0.0",
          hidden: true);
      final tvCategory =
          Category(id: 1, name: "TV Apps", systemKey: "tv_apps", order: 0, sort: CategorySort.manual);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.visible',
              'name': 'Visible App',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.hidden',
              'name': 'Hidden App',
              'version': '1.0.0',
              'sideloaded': false
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications())
          .thenAnswer((_) => Future.value([visibleApp, hiddenOrphan]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([tvCategory]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([
            AppCategory(categoryId: 1, appPackageName: "app.visible", order: 0),
          ]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.wasCreated).thenReturn(false);
      when(database.nextAppCategoryOrder(1)).thenAnswer((_) => Future.value(1));
      when(database.insertAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final tvApps = appsService.categories.first;
      expect(tvApps.applications.length, 1);
      expect(tvApps.applications.first.packageName, "app.visible");
      expect(hiddenOrphan.categoryOrders[1], 1);
      verify(database.insertAppsCategories(any)).called(1);
    });

    test("multiple orphaned apps receive deterministic non-conflicting orders",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final orphanB = App(
          packageName: "app.b", name: "Bravo", version: "1.0.0", hidden: false);
      final orphanA = App(
          packageName: "app.a", name: "Alpha", version: "1.0.0", hidden: false);
      final tvCategory =
          Category(id: 1, name: "TV Apps", systemKey: "tv_apps", order: 0, sort: CategorySort.manual);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.a',
              'name': 'Alpha',
              'version': '1.0.0',
              'sideloaded': false
            },
            {
              'packageName': 'app.b',
              'name': 'Bravo',
              'version': '1.0.0',
              'sideloaded': false
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications())
          .thenAnswer((_) => Future.value([orphanA, orphanB]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([tvCategory]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.wasCreated).thenReturn(false);
      when(database.nextAppCategoryOrder(1)).thenAnswer((_) => Future.value(0));
      when(database.insertAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect(orphanA.categoryOrders[1], 0);
      expect(orphanB.categoryOrders[1], 1);
      expect(
          appsService.categories.first.applications
              .map((app) => app.packageName)
              .toList(),
          ["app.a", "app.b"]);
    });

    test("orphaned sideloaded app is assigned to Non-TV Apps category",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final sideloadedApp = App(
          packageName: "app.sideloaded",
          name: "Sideloaded",
          version: "1.0.0",
          hidden: false);
      final tvCategory =
          Category(id: 1, name: "TV Apps", systemKey: "tv_apps", order: 0, sort: CategorySort.manual);
      final nonTvCategory = Category(
          id: 2, name: "Non-TV Apps", systemKey: "other_apps", order: 1, sort: CategorySort.manual);

      when(channel.getApplications()).thenAnswer((_) => Future.value([
            {
              'packageName': 'app.sideloaded',
              'name': 'Sideloaded',
              'version': '1.0.0',
              'sideloaded': true
            },
          ]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));

      when(database.getApplications())
          .thenAnswer((_) => Future.value([sideloadedApp]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([tvCategory, nonTvCategory]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.wasCreated).thenReturn(false);
      when(database.nextAppCategoryOrder(2)).thenAnswer((_) => Future.value(0));
      when(database.insertAppsCategories(any))
          .thenAnswer((_) => Future.value());

      final appsService = AppsService(channel, database);
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      final nonTvApps =
          appsService.categories.firstWhere((c) => c.name == "Non-TV Apps");
      expect(nonTvApps.applications.map((app) => app.packageName).toList(),
          ["app.sideloaded"]);
      expect(sideloadedApp.categoryOrders[2], 0);
    });

    test("sortCategory does not throw when manual order is missing", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final appWithOrder = App(
          packageName: "app.ordered",
          name: "Ordered",
          version: "1.0.0",
          hidden: false);
      appWithOrder.categoryOrders[1] = 0;
      final appWithoutOrder = App(
          packageName: "app.missing",
          name: "Missing",
          version: "1.0.0",
          hidden: false);
      final category =
          Category(id: 1, name: "TV Apps", systemKey: "tv_apps", order: 0, sort: CategorySort.manual);
      category.applications.addAll([appWithoutOrder, appWithOrder]);

      final appsService = await _buildInitialisedAppsService(channel, database);
      appsService.sortCategory(category);

      expect(category.applications.first.packageName, "app.ordered");
      expect(category.applications.last.packageName, "app.missing");
    });

    test("sortCategory last-used ordering is unchanged", () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final older = App(
          packageName: "older", name: "Older", version: "1.0.0", hidden: false);
      older.lastLaunchedAt = DateTime(2024, 1, 1);
      final newer = App(
          packageName: "newer", name: "Newer", version: "1.0.0", hidden: false);
      newer.lastLaunchedAt = DateTime(2025, 1, 1);
      final category = Category(
          id: 1, name: "Recent", order: 0, sort: CategorySort.lastUsed);
      category.applications.addAll([older, newer]);

      final appsService = await _buildInitialisedAppsService(channel, database);
      appsService.sortCategory(category);

      expect(category.applications.map((app) => app.packageName).toList(),
          ["newer", "older"]);
    });

    test(
        "existing install with Non-TV Apps above TV Apps is reordered so TV Apps is on top",
        () async {
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      final database = MockFLauncherDatabase();

      final nonTvCat = Category(id: 1, name: "Non-TV Apps", order: 0);
      final tvCat = Category(id: 2, name: "TV Apps", order: 1);

      when(channel.getApplications()).thenAnswer((_) => Future.value([]));
      when(channel.getApplicationIcon(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(channel.getApplicationBanner(any))
          .thenAnswer((_) => Future.value(Uint8List(0)));
      when(database.getApplications()).thenAnswer((_) => Future.value([]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([]));
      when(database.getCategories())
          .thenAnswer((_) => Future.value([nonTvCat, tvCat]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
      when(database.transaction(any)).thenAnswer(
          (realInvocation) => realInvocation.positionalArguments[0]());
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.updateCategories(any)).thenAnswer((_) => Future.value());
      when(database.updateSpacers(any)).thenAnswer((_) => Future.value());
      when(database.updateCategory(any, any))
          .thenAnswer((_) => Future<void>.value());
      when(database.wasCreated).thenReturn(false);

      final appsService = AppsService(channel, database);
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      expect((appsService.launcherSections[0] as Category).name, "TV Apps");
      expect((appsService.launcherSections[1] as Category).name, "Non-TV Apps");
    });
  });
}

Future<AppsService> _buildInitialisedAppsService(
  MockFLauncherChannel channel,
  MockFLauncherDatabase database,
) async {
  when(channel.getApplications()).thenAnswer((_) => Future.value([]));
  when(channel.getApplicationIcon(any))
      .thenAnswer((_) => Future.value(Uint8List(0)));
  when(channel.getApplicationBanner(any))
      .thenAnswer((_) => Future.value(Uint8List(0)));
  when(database.getApplications()).thenAnswer((_) => Future.value([]));
  when(database.getAppsCategories()).thenAnswer((_) => Future.value([]));
  when(database.getCategories()).thenAnswer((_) => Future.value([]));
  when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([]));
  when(database.transaction(any))
      .thenAnswer((realInvocation) => realInvocation.positionalArguments[0]());
  when(database.wasCreated).thenReturn(false);
  final appsService = AppsService(channel, database);

  while (!appsService.initialized) {
    await Future.delayed(const Duration(milliseconds: 10));
  }

  await untilCalled(channel.addAppsChangedListener(any));
  clearInteractions(channel);
  clearInteractions(database);
  return appsService;
}
