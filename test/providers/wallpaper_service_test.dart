import 'dart:io';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/painting.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../mocks.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late final _MockPathProviderPlatform pathProviderPlatform;
  setUpAll(() {
    pathProviderPlatform = _MockPathProviderPlatform();
    when(pathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) => Future.value("."));
    PathProviderPlatform.instance = pathProviderPlatform;
  });

  group("pickWallpaper", () {
    test("picks and persists a valid image through the picker channel", () async {
      final directory = await Directory.systemTemp.createTemp('cute-picked-wallpaper-');
      final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=');
      final selected = await File('${directory.path}/selected.png').writeAsBytes(bytes);
      when(pathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) async => directory.path);
      const channel = MethodChannel('plugins.flutter.io/image_picker');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return selected.path;
      });
      final launcher = MockFLauncherChannel();
      when(launcher.checkForGetContentAvailability()).thenAnswer((_) async => true);
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      final service = WallpaperService(launcher, settings);
      try {
        await service.reset(); // Wait for initialization before picking.
        final version = service.version;
        await service.pickWallpaper();
        expect(calls.single.method, 'pickImage');
        expect(calls.single.arguments['source'], ImageSource.gallery.index);
        expect(await File('${directory.path}/wallpaper').readAsBytes(), bytes);
        expect(service.wallpaper, isA<FileImage>());
        expect((service.wallpaper as FileImage).file.path, '${directory.path}/wallpaper');
        expect(service.version, version + 1);
      } finally {
        service.dispose();
        settings.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        when(pathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) async => '.');
        await directory.delete(recursive: true);
      }
    });

    test("throws error when no file explorer installed", () async {
      final fLauncherChannel = MockFLauncherChannel();
      when(fLauncherChannel.checkForGetContentAvailability()).thenAnswer((_) => Future.value(false));
      final settingsService = MockSettingsService();
      when(settingsService.timeBasedWallpaperEnabled).thenReturn(false);
      final wallpaperService = WallpaperService(fLauncherChannel, settingsService);
      await untilCalled(pathProviderPlatform.getApplicationDocumentsPath());

      expect(() async => await wallpaperService.pickWallpaper(), throwsA(isInstanceOf<NoFileExplorerException>()));
    });
  });


  test("setGradient", () async {
    final fLauncherChannel = MockFLauncherChannel();
    final settingsService = MockSettingsService();
      when(settingsService.timeBasedWallpaperEnabled).thenReturn(false);
    final wallpaperService = WallpaperService(fLauncherChannel, settingsService);

    await untilCalled(pathProviderPlatform.getApplicationDocumentsPath());
    await wallpaperService.setGradient(FLauncherGradients.greatWhale);

    verify(settingsService.setGradientUuid(FLauncherGradients.greatWhale.uuid));
    expect(wallpaperService.wallpaper, null);
  });

  test('full background reset removes all local images and the displayed provider', () async {
    final directory = await Directory.systemTemp.createTemp('cute-background-reset-');
    when(pathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) async => directory.path);
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final service = WallpaperService(MockFLauncherChannel(), settings);
    try {
      for (final name in ['wallpaper', 'wallpaper_day', 'wallpaper_night']) {
        await File('${directory.path}/$name').writeAsBytes([1]);
      }
      await service.reset();
      for (final name in ['wallpaper', 'wallpaper_day', 'wallpaper_night']) {
        expect(await File('${directory.path}/$name').exists(), isFalse);
      }
      expect(service.wallpaper, isNull);
    } finally {
      service.dispose(); settings.dispose();
      when(pathProviderPlatform.getApplicationDocumentsPath()).thenAnswer((_) async => '.');
      await directory.delete(recursive: true);
    }
  });

  group("getGradient", () {
    test("without uuid from settings", () async {
      final fLauncherChannel = MockFLauncherChannel();
      final settingsService = MockSettingsService();
      when(settingsService.timeBasedWallpaperEnabled).thenReturn(false);
      final wallpaperService = WallpaperService(fLauncherChannel, settingsService);
      when(settingsService.gradientUuid).thenReturn(null);

      await untilCalled(pathProviderPlatform.getApplicationDocumentsPath());
      final gradient = wallpaperService.gradient;

      expect(gradient.uuid, FLauncherGradients.pitchBlack.uuid);
    });

    test("with uuid from settings", () async {
      final fLauncherChannel = MockFLauncherChannel();
      final settingsService = MockSettingsService();
      when(settingsService.timeBasedWallpaperEnabled).thenReturn(false);
      final wallpaperService = WallpaperService(fLauncherChannel, settingsService);
      when(settingsService.gradientUuid).thenReturn(FLauncherGradients.grassShampoo.uuid);
      await untilCalled(pathProviderPlatform.getApplicationDocumentsPath());

      final gradient = wallpaperService.gradient;

      expect(gradient.uuid, FLauncherGradients.grassShampoo.uuid);
    });
  });
}

class _MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() =>
      super.noSuchMethod(Invocation.method(#getApplicationDocumentsPath, []), returnValue: Future<String?>.value());
}
