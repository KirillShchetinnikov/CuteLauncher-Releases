import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final package in ['com.android.tv.settings', 'com.android.settings', 'vendor.settings']) {
    test('Android settings tile defaults to hidden and preserves membership ($package)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final database = FLauncherDatabase.inMemory();
      final channel = MockFLauncherChannel();
      when(channel.addAppsChangedListener(any)).thenReturn(null);
      when(channel.getApplicationIcon(any)).thenAnswer((_) async => Uint8List(0));
      when(channel.getApplicationBanner(any)).thenAnswer((_) async => Uint8List(0));
      when(channel.getApplications()).thenAnswer((_) async => [
        {'packageName': package, 'name': 'Settings', 'version': '1', 'sideloaded': false,
          if (package == 'vendor.settings') 'action': 'android.settings.SETTINGS'},
        {'packageName': 'another.app', 'name': 'Other', 'version': '1', 'sideloaded': false},
      ]);
      final service = AppsService(channel, database, settingsService: settings);
      while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
      bool visible() => service.categories.expand((c) => c.applications).any((a) => a.packageName == package);
      try {
        final app = service.getApp(package)!;
        await service.addToCategory(app, service.categories.firstWhere((c) => c.name == 'Favorites'));
        expect(visible(), isFalse);
        expect(app.hidden, isFalse);
        final backup = settings.exportSettingsMap();
        await settings.setHideAndroidSettingsTile(false);
        expect(visible(), isTrue);
        expect(SettingsService(prefs).hideAndroidSettingsTile, isFalse);
        await settings.importSettingsMap(backup);
        expect(visible(), isFalse);
        await service.refreshState();
        expect(visible(), isFalse);
        await service.hideApplication(app);
        await settings.setHideAndroidSettingsTile(false);
        expect(visible(), isTrue);
        expect(service.categories.where((category) => category.isAutomatic).expand((category) => category.applications).any((app) => app.packageName == package), isFalse);
      } finally {
        service.dispose(); settings.dispose(); await database.close();
      }
    });
  }
  for (final package in ['io.github.kirillshchetinnikov.cutelauncher', 'io.github.kirillshchetinnikov.cutelauncher.debug']) {
    test('self tile visibility preserves manual hiding ($package)', () async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final database = FLauncherDatabase.inMemory();
      final channel = MockFLauncherChannel();
    when(channel.addAppsChangedListener(any)).thenReturn(null);
      when(channel.getApplicationIcon(any)).thenAnswer((_) async => Uint8List(0));
      when(channel.getApplicationBanner(any)).thenAnswer((_) async => Uint8List(0));
      when(channel.getApplications()).thenAnswer((_) async => [
        {'packageName': package, 'name': 'CuteLauncher', 'version': '1', 'sideloaded': false},
        {'packageName': 'another.app', 'name': 'Other', 'version': '1', 'sideloaded': false},
      ]);
      final service = AppsService(channel, database, settingsService: settings, ownPackageName: package);
      while (!service.initialized) {
        await Future<void>.delayed(Duration.zero);
      }
      bool hasSelf() => service.categories.expand((c) => c.applications).any((a) => a.packageName == package);
      try {
        final own = service.getApp(package)!;
        await service.addToCategory(own, service.categories.firstWhere((c) => c.name == 'Favorites'));
        await settings.setHideLauncherTile(true);
        expect(hasSelf(), isFalse);
        expect(own.hidden, isFalse);
        await service.refreshState();
        expect(hasSelf(), isFalse);
        final backup = settings.exportSettingsMap();
        await settings.setHideLauncherTile(false);
        expect(service.categories.where((category) => category.isAutomatic).expand((category) => category.applications).where((app) => app.packageName == package).length, 2);
        expect(service.categories.firstWhere((category) => category.systemKey == 'favorites').applications.single.packageName, package);
        await settings.importSettingsMap(backup);
        expect(settings.hideLauncherTile, isTrue);
        await service.hideApplication(service.getApp(package)!);
        await settings.setHideLauncherTile(false);
        expect(hasSelf(), isTrue);
        expect(service.categories.where((category) => category.isAutomatic).expand((category) => category.applications).any((app) => app.packageName == package), isFalse);
        expect(service.categories.expand((c) => c.applications).any((a) => a.packageName == 'another.app'), isTrue);
      } finally {
        service.dispose();
        settings.dispose();
        await database.close();
      }
    });
  }
}
