import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

import '../mocks.mocks.dart';

void main() {
  group("AppsService.moveSectionInMemory", () {
    late MockFLauncherChannel channel;
    late MockFLauncherDatabase database;
    late AppsService appsService;

    setUp(() async {
      SharedPreferencesStorePlatform.instance = InMemorySharedPreferencesStore.empty();
      channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      database = MockFLauncherDatabase();

      when(channel.getApplications()).thenAnswer((_) => Future.value([]));
      when(database.getApplications()).thenAnswer((_) => Future.value([]));
      when(database.getAppsCategories()).thenAnswer((_) => Future.value([]));

      // Provide some initial sections
      final cat1 = Category(id: 1, name: "Cat 1", order: 0);
      final cat2 = Category(id: 2, name: "Cat 2", order: 1);
      final spacer1 = LauncherSpacer(id: 1, height: 10, order: 2);

      when(database.getCategories()).thenAnswer((_) => Future.value([cat1, cat2]));
      when(database.getLauncherSpacers()).thenAnswer((_) => Future.value([spacer1]));
      when(database.transaction(any)).thenAnswer((realInvocation) => realInvocation.positionalArguments[0]());
      when(database.wasCreated).thenReturn(false);
      when(database.persistApps(any)).thenAnswer((_) => Future.value());
      when(database.deleteApps(any)).thenAnswer((_) => Future.value());

      appsService = AppsService(channel, database);

      // Wait for initialization
      while (!appsService.initialized) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    });

    test("successfully moves a section forward", () {
      // Initial state: Cat 1 (0), Cat 2 (1), Spacer 1 (2)
      expect(appsService.launcherSections.length, 3);
      expect(appsService.launcherSections[0].id, 1); // Cat 1
      expect(appsService.launcherSections[1].id, 2); // Cat 2
      expect(appsService.launcherSections[2].id, 1); // Spacer 1 (id 1, different type)
      expect(appsService.launcherSections[2], isA<LauncherSpacer>());

      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      appsService.moveSectionInMemory(0, 1);

      expect(notified, isTrue);
      expect(appsService.launcherSections[0].id, 2); // Cat 2
      expect(appsService.launcherSections[1].id, 1); // Cat 1
      expect(appsService.launcherSections[1], isA<Category>());
      expect(appsService.launcherSections[2].id, 1); // Spacer 1
    });

    test("successfully moves a section backward", () {
      // Initial state: Cat 1, Cat 2, Spacer 1
      appsService.moveSectionInMemory(2, 0);

      expect(appsService.launcherSections[0], isA<LauncherSpacer>());
      expect(appsService.launcherSections[1].id, 1); // Cat 1
      expect(appsService.launcherSections[2].id, 2); // Cat 2
    });

    test("does nothing and does not notify if oldIndex is out of bounds", () {
      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      // Negative index
      appsService.moveSectionInMemory(-1, 1);
      expect(notified, isFalse);

      // Index >= length
      appsService.moveSectionInMemory(3, 1);
      expect(notified, isFalse);
    });

    test("does nothing and does not notify if newIndex is out of bounds", () {
      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      // Negative index
      appsService.moveSectionInMemory(0, -1);
      expect(notified, isFalse);

      // Index >= length
      appsService.moveSectionInMemory(0, 3);
      expect(notified, isFalse);
    });

    test("works correctly when moving to the same position", () {
      var notified = false;
      appsService.addListener(() {
        notified = true;
      });

      appsService.moveSectionInMemory(1, 1);

      expect(notified, isTrue);
      expect(appsService.launcherSections[1].id, 2); // Cat 2 remains at index 1
    });
  });
}
