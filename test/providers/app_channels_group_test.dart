
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';

import '../mocks.mocks.dart';
import '../support/app_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FLauncherDatabase db;
  late AppsService apps;
  late SettingsService settings;
  late MockFLauncherChannel appsChannel;
  late SharedPreferences prefs;
  Future<void> ready() async {
    while (!apps.initialized) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
    }
  }

  Category group() => apps.categories.singleWhere((c) => c.isAppChannels);
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'selected_app_channels': ['video.app:1', 'video.app:2'],
    });
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    db = FLauncherDatabase.inMemory();
    appsChannel = MockFLauncherChannel();
    when(appsChannel.getApplications()).thenAnswer(
      (_) async => [
        {
          'packageName': 'video.app',
          'name': 'Video',
          'version': '1',
          'sideloaded': false,
        },
      ],
    );
    when(appsChannel.addAppsChangedListener(any)).thenReturn(null);
    apps = AppsService(appsChannel, db);
    await ready();
  });
  tearDown(() async {
    apps.dispose();
    settings.dispose();
    await db.close();
  });

  test(
    'one protected group persists visibility and order without app membership',
    () async {
      expect(group().isSystem, isTrue);
      final id = group().id;
      await apps.moveSection(
        apps.launcherSections.indexWhere((s) => s.id == id),
        0,
      );
      await apps.setCategoryVisible(id, false);
      await apps.deleteSection(0);
      expect(group().id, id);
      await apps.renameCategory(group(), 'Renamed');
      expect(group().name, 'Renamed');
      final app = apps.getApp('video.app')!;
      expect(
        AddToCategoryDialog.availableCategories(
          apps.categories,
          app,
        ).any((c) => c.isAppChannels),
        isFalse,
      );
      await apps.addToCategory(app, group());
      expect(
        (await db.getAppsCategories()).where((row) => row.categoryId == id),
        isEmpty,
      );
      apps.dispose();
      apps = AppsService(appsChannel, db);
      await ready();
      expect(apps.launcherSections.first.id, id);
      expect(group().visible, isFalse);
      expect(group().name, 'Renamed');
      expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
    },
  );

  test(
    'old databases gain one group and reset keeps the selected feeds',
    () async {
      final id = group().id;
      await db.deleteCategory(id);
      final previous = await db.getCategories();
      await db.ensureStandardCategories();
      await db.ensureStandardCategories();
      await apps.refreshState();
      expect(apps.categories.where((c) => c.isAppChannels), hasLength(1));
      for (final before in previous) {
        final after = apps.categories.singleWhere((c) => c.id == before.id);
        expect(
          (after.name, after.order, after.visible),
          (before.name, before.order, before.visible),
        );
      }
      await apps.setCategoryVisible(group().id, false);
      await apps.resetSections();
      expect(group().visible, isTrue);
      expect(apps.categories, hasLength(5));
      expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
    },
  );

  test('hidden group stops queries while its source picker can still discover feeds', () async {
    final channel = FeedChannel()..data = [feed(1), feed(2)];
    final service = AppChannelsService(channel, settings, apps: apps);
    try {
      await service.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(service.channels, hasLength(2));
      expect(channel.events.hasListener, isTrue);
      await apps.setCategoryVisible(group().id, false);
      await Future<void>.delayed(Duration.zero);
      final stoppedAt = channel.requests.length;
      channel.events.add(true);
      await service.refresh();
      await service.poster('content://poster/hidden');
      expect(channel.requests.length, stoppedAt);
      expect(channel.posters, isEmpty);
      expect(channel.events.hasListener, isFalse);
      service.openCatalog();
      await service.refresh();
      expect(channel.requests.length, greaterThan(stoppedAt));
      service.closeCatalog();
      await Future<void>.delayed(Duration.zero);
      expect(channel.events.hasListener, isFalse);
      await apps.setCategoryVisible(group().id, true);
      await service.refresh();
      expect(channel.events.hasListener, isTrue);
      expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
    } finally {
      service.dispose();
      await channel.events.close();
    }
  });
}
