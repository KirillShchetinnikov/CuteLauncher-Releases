import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FLauncherDatabase db;
  late AppsService service;
  late StreamController<Map<String, dynamic>> events;
  late List<Map<String, dynamic>> catalog;

  Map<String, dynamic> app(
    String package, {
    bool mobile = false,
    bool system = false,
  }) => {
    'packageName': package,
    'name': package,
    'version': '1',
    'sideloaded': mobile,
    'system': system,
  };
  Category section(String key) =>
      service.categories.firstWhere((category) => category.systemKey == key);
  Set<String> contents(String key) =>
      section(key).applications.map((app) => app.packageName).toSet();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'tv_apps_section_order_default_v1': true,
    });
    db = FLauncherDatabase.inMemory();
    catalog = [
      app('tv'),
      app('mobile', mobile: true),
      app('system', system: true),
    ];
    await db.persistApps(
      catalog.map(
        (data) => AppsCompanion.insert(
          packageName: data['packageName'] as String,
          name: data['name'] as String,
          version: '1',
        ),
      ),
    );
    // Different IDs/order, plus a deliberately wrong legacy TV membership.
    for (final entry in [
      'favorites',
      'all_apps',
      'tv_apps',
      'other_apps',
    ].asMap().entries) {
      await db.insertCategory(
        CategoriesCompanion.insert(
          id: Value(entry.key + 1),
          name: entry.value,
          order: entry.key,
          systemKey: Value(entry.value),
        ),
      );
    }
    await db.insertAppsCategories([
      AppsCategoriesCompanion.insert(
        categoryId: 1,
        appPackageName: 'tv',
        order: 0,
      ),
      AppsCategoriesCompanion.insert(
        categoryId: 3,
        appPackageName: 'mobile',
        order: 0,
      ),
    ]);
    final channel = MockFLauncherChannel();
    events = StreamController<Map<String, dynamic>>.broadcast();
    when(channel.getApplications()).thenAnswer((_) async => catalog);
    when(
      channel.addAppsChangedListener(any),
    ).thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
    service = AppsService(channel, db);
    for (var i = 0; i < 200 && !service.initialized; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    expect(service.initialized, isTrue);
  });
  tearDown(() async {
    service.dispose();
    await events.close();
    await db.close();
  });

  for (final key in ['all_apps', 'tv_apps', 'other_apps']) {
    test('$key persists manual order with missing and existing rows', () async {
      catalog.addAll([app('tv2'), app('mobile2', mobile: true)]);
      await service.refreshState();
      await service.hideApplication(service.getApp('system')!);
      await service.setCategorySort(section(key), CategorySort.manual);
      final before = section(key).applications.map((a) => a.packageName).toList();
      expect(before.length, greaterThanOrEqualTo(2));
      final favorites = contents('favorites');

      Future<void> moveAndReload() async {
        final current = section(key).applications.map((a) => a.packageName).toList();
        final expected = [...current.skip(1), current.first];
        service.reorderApplication(section(key), 0, current.length - 1);
        await service.saveApplicationOrderInCategory(section(key));
        final rows = (await db.getAppsCategories())
            .where((row) => row.categoryId == section(key).id)
            .toList();
        for (var i = 0; i < expected.length; i++) {
          expect(rows.singleWhere((row) => row.appPackageName == expected[i]).order, i);
        }
        await service.refreshState();
        expect(section(key).applications.map((a) => a.packageName).toList(), expected);
        expect(contents('favorites'), favorites);
        expect(contents('all_apps'), isNot(contains('system')));
      }

      await moveAndReload();
      // A second save must update rows created by the first save.
      await moveAndReload();
      final savedOrder = section(key).applications.map((a) => a.packageName).toList();
      service.dispose();
      final channel = MockFLauncherChannel();
      when(channel.getApplications()).thenAnswer((_) async => catalog);
      when(channel.addAppsChangedListener(any))
          .thenAnswer((call) => events.stream.listen(call.positionalArguments[0]));
      service = AppsService(channel, db);
      for (var i = 0; i < 200 && !service.initialized; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(service.initialized, isTrue);
      expect(section(key).applications.map((a) => a.packageName).toList(), savedOrder);
    });
  }

  test(
    'automatic catalogs ignore stale links and manual edits never affect them',
    () async {
      expect(contents('all_apps'), {'tv', 'mobile', 'system'});
      expect(contents('tv_apps'), {'tv', 'system'});
      expect(contents('other_apps'), {'mobile'});
      expect(contents('favorites'), {'tv'});
      final mobile = service.getApp('mobile')!;
      expect(
        AddToCategoryDialog.availableCategories(
          service.categories,
          mobile,
        ).map((category) => category.systemKey),
        ['favorites'],
      );
      await service.addToCategory(mobile, section('favorites'));
      await service.addToCategory(mobile, section('favorites'));
      expect(contents('favorites'), {'tv', 'mobile'});
      final saved = await db.getAppsCategories();
      for (final key in ['all_apps', 'tv_apps', 'other_apps']) {
        await service.addToCategory(mobile, section(key));
        await service.removeFromCategory(service.getApp('tv')!, section(key));
      }
      expect(await db.getAppsCategories(), saved);
      expect(contents('all_apps'), {'tv', 'mobile', 'system'});
      expect(contents('tv_apps'), {'tv', 'system'});
      expect(contents('other_apps'), {'mobile'});
      await service.removeFromCategory(mobile, section('favorites'));
      expect(contents('favorites'), {'tv'});
      expect(contents('all_apps'), {'tv', 'mobile', 'system'});
    },
  );

  test('preinstalled launchable apps remain on home while service packages stay in settings', () async {
    catalog.addAll([
      {...app('com.google.android.youtube.tv', system: true), 'launchable': true},
      {...app('com.android.vending', system: true), 'launchable': true},
      {...app('com.google.android.partnersetup', system: true), 'launchable': false},
      {...app('com.android.externalstorage', system: true), 'launchable': false},
    ]);
    await service.refreshState();
    expect(contents('all_apps'), containsAll(['com.google.android.youtube.tv', 'com.android.vending']));
    for (final key in ['all_apps', 'tv_apps', 'other_apps']) {
      expect(contents(key), isNot(contains('com.google.android.partnersetup')));
      expect(contents(key), isNot(contains('com.android.externalstorage')));
    }
    final partner = service.getApp('com.google.android.partnersetup')!;
    expect(partner.isSystem, isTrue);
    expect(partner.isLaunchable, isFalse);
    expect(service.applications.map((app) => app.packageName), contains('com.android.externalstorage'));
    expect((await db.getAppsCategories()).any((row) => row.appPackageName == partner.packageName), isFalse);
  });

  test('swapped preset labels are repaired without swapping IDs or memberships', () async {
    final saved = await db.getAppsCategories();
    await db.updateCategory(1, const CategoriesCompanion(name: Value('All Apps')));
    await db.updateCategory(2, const CategoriesCompanion(name: Value('Favorites')));
    await db.ensureStandardCategories();
    expect(await db.getAppsCategories(), saved);
    await service.refreshState();
    expect(section('favorites').id, 1);
    expect(section('favorites').name, 'Favorites');
    expect(contents('favorites'), {'tv'});
    expect(section('all_apps').id, 2);
    expect(section('all_apps').name, 'All Apps');
    expect(contents('all_apps'), {'tv', 'mobile', 'system'});
    await service.renameCategory(section('favorites'), 'All Apps');
    expect(section('favorites').name, 'Favorites');
    await service.renameCategory(section('favorites'), 'Personal');
    expect(section('favorites').name, 'Personal');
  });

  test('hidden apps stay in manual sections through refresh until explicitly removed', () async {
    final customId = await service.addCategory('Custom');
    Category custom() =>
        service.categories.firstWhere((category) => category.id == customId);
    await service.addToCategory(service.getApp('tv')!, custom());
    await service.hideApplication(service.getApp('tv')!);
    expect(contents('all_apps'), {'mobile', 'system'});
    expect(contents('tv_apps'), {'system'});
    expect(contents('favorites'), {'tv'});
    expect(custom().applications.single.packageName, 'tv');
    await service.refreshState();
    expect(contents('favorites'), {'tv'});
    expect(custom().applications.single.hidden, isTrue);
    await service.removeFromCategory(
      service.getApp('tv')!,
      section('favorites'),
    );
    await service.showApplication(service.getApp('tv')!);
    await service.showApplication(service.getApp('tv')!);
    expect(contents('favorites'), isEmpty);
    expect(custom().applications.map((app) => app.packageName), ['tv']);
    expect(contents('all_apps'), {'tv', 'mobile', 'system'});
    await service.deleteSection(service.launcherSections.indexWhere((section) => section.id == customId));
    expect(contents('favorites'), isEmpty);
    expect(contents('all_apps'), {'tv', 'mobile', 'system'});
  });

  test('install, classification update and removal update automatic lists independently', () async {
    Future<void> send(Map<String, dynamic> event, bool Function() done) async {
      events.add(event);
      for (var i = 0; i < 200 && !done(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      expect(done(), isTrue);
    }

    final fresh = app('new');
    catalog.add(fresh);
    await send({
      'action': 'PACKAGE_ADDED',
      'activityInfo': fresh,
    }, () => service.getApp('new') != null);
    expect(contents('tv_apps'), {'tv', 'system', 'new'});
    expect(contents('favorites'), {'tv'});
    await service.addToCategory(service.getApp('new')!, section('favorites'));
    final stale = service.getApp('new')!;
    final changed = app('new', mobile: true);
    catalog[catalog.indexOf(fresh)] = changed;
    await send({
      'action': 'PACKAGE_CHANGED',
      'activityInfo': changed,
    }, () => service.getApp('new')!.sideloaded);
    expect(contents('tv_apps'), {'tv', 'system'});
    expect(contents('other_apps'), {'mobile', 'new'});
    expect(contents('favorites'), {'tv', 'new'});
    await service.removeFromCategory(stale, section('favorites'));
    expect(contents('favorites'), {'tv'});
    await service.addToCategory(service.getApp('new')!, section('favorites'));
    catalog.remove(changed);
    await send({
      'action': 'PACKAGE_REMOVED',
      'packageName': 'new',
    }, () => service.getApp('new') == null);
    expect(
      service.categories
          .expand((category) => category.applications)
          .any((app) => app.packageName == 'new'),
      isFalse,
    );
    await service.refreshState();
    expect(contents('favorites'), {'tv'});
  });
}
