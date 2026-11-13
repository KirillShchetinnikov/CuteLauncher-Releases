import 'dart:io';
import 'package:flauncher/image_limits.dart';
import 'package:flauncher/local_background_media.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
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
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/video_folder_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/video_folder_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.mocks.dart';

void main() {
  testWidgets('video folder source opens its settings and can skip to the next file', (tester) async {
    SharedPreferences.setMockInitialValues({
      'background_source': videoFolderSource,
      videoFolderKey: 'file:///storage/videos',
    });
    final preferences = await SharedPreferences.getInstance();
    final settings = SettingsService(preferences);
    final launcher = LauncherState();
    const channel = MethodChannel('me.efesser.flauncher/method');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method != 'listWallpaperVideos') return null;
      return [
        for (final name in ['01.mp4', '02.mp4'])
          {'uri': 'file:///storage/videos/$name', 'name': name, 'modified': 0, 'size': 512},
      ];
    });
    final videos = VideoFolderService(preferences, settings, launcher);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      videos.dispose();
      launcher.dispose();
      settings.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: videos),
      ],
      child: const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: WallpaperPanelPage()),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Videos from folder'), findsOneWidget);
    final l = AppLocalizations.of(tester.element(find.byType(WallpaperPanelPage)))!;
    await tester.tap(find.text(l.backgroundParameters));
    await tester.pumpAndSettle();
    expect(find.byType(VideoFolderPage), findsOneWidget);
    expect(videos.clip?.name, '01.mp4');
    await tester.tap(find.text(l.videoFolderNext));
    await tester.pumpAndSettle();
    expect(videos.clip?.name, '02.mp4');
  });

  testWidgets(
    'scheduled wallpaper distinguishes empty and unavailable slots without polling',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = SettingsService(await SharedPreferences.getInstance());
      await settings.setBackgroundSource('scheduled');
      final wallpaper = MockWallpaperService();
      when(wallpaper.selection('day'))
          .thenAnswer((_) async => (name: null, available: false));
      when(wallpaper.selection('night'))
          .thenAnswer((_) async => (name: 'night.png', available: false));
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider<WallpaperService>.value(value: wallpaper),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: WallpaperPanelPage(parameters: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('night.png · File unavailable'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      verify(wallpaper.selection('day')).called(1);
      verify(wallpaper.selection('night')).called(1);
      await tester.pumpWidget(const SizedBox());
      settings.dispose();
      wallpaper.dispose();
    },
  );

  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });


  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  for (final appSource in [false, true]) {
  testWidgets('${appSource ? 'App artwork' : 'Gradient'} source opens fallback Parameters and selects a gradient', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final wallpaper = MockWallpaperService();
    final online = OnlineWallpaperService(prefs, directory: () async => Directory.systemTemp,
      bingLookup: () async => throw const SocketException('offline'));
    await tester.runAsync(() async {
      while (!online.initialized) { await Future<void>.delayed(Duration.zero); }
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      settings.dispose(); online.dispose(); wallpaper.dispose();
    });
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider<WallpaperService>.value(value: wallpaper),
      ChangeNotifierProvider.value(value: online),
    ], child: const MaterialApp(locale: Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WallpaperPanelPage()))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Background source'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(appSource ? 'Selected app colours' : 'Gradient'));
    await tester.pumpAndSettle();
    expect(settings.backgroundSource, appSource ? 'app' : 'gradient');
    expect(find.byType(GradientPanelPage), findsNothing);
    await tester.tap(find.text(AppLocalizations.of(tester.element(find.byType(WallpaperPanelPage)))!.backgroundParameters));
    await tester.pumpAndSettle();
    expect(find.byType(GradientPanelPage), findsOneWidget);
    final gradient = FLauncherGradients.greatWhale;
    await tester.tap(find.descendant(
      of: find.byKey(Key('gradient-${gradient.uuid}')),
      matching: find.byType(InkWell)));
    await tester.pumpAndSettle();
    verify(wallpaper.setGradient(gradient)).called(1);
    expect(tester.takeException(), isNull);
  });

  }
  testWidgets('one background source persists and Parameters opens its second level', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final online = OnlineWallpaperService(prefs, directory: () async => Directory.systemTemp,
      bingLookup: () async => throw const SocketException('offline'));
    await tester.runAsync(() async {
      while (!online.initialized) { await Future<void>.delayed(Duration.zero); }
    });
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: online),
    ], child: const MaterialApp(locale: Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WallpaperPanelPage()))));
    await tester.pumpAndSettle();
    expect(find.text('Онлайн-обои'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(settings.backgroundSource, 'picture');
    expect(find.text('Онлайн-обои'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Онлайн-обои'));
    await tester.pumpAndSettle();
    expect(settings.backgroundSource, 'online');
    expect(online.configuration.enabled, isTrue);
    await tester.tap(find.text('Источник фона'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Градиент').last);
    await tester.pumpAndSettle();
    expect(SettingsService(prefs).backgroundSource, 'gradient');
    expect(online.configuration.enabled, isFalse);
    expect(settings.timeBasedWallpaperEnabled, isFalse);
    expect(find.byIcon(Icons.check), findsNothing);
    // Online parameters are a separate route, without an independent enable switch.
    await tester.tap(find.text('Источник фона'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Онлайн-обои'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки источника'));
    await tester.pumpAndSettle();
    expect(ModalRoute.of(tester.element(find.text('Источник изображения')))!.transitionDuration, Duration.zero);
    expect(ModalRoute.of(tester.element(find.text('Источник изображения')))!.reverseTransitionDuration, Duration.zero);
    expect(find.textContaining('Интервал загрузки'), findsNothing);
    expect(find.text('Использовать онлайн-обои'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    settings.dispose(); online.dispose();
  });

  group("'Custom'", () {
    for (final result in ['success', 'cancel', 'format', 'imageSize', 'videoSize', 'codec']) {
      testWidgets('file selection reports $result clearly', (tester) async {
        final settings = MockSettingsService();
        final wallpaper = MockWallpaperService();
        when(wallpaper.pickWallpaper(picker: anyNamed('picker'))).thenAnswer((_) async {
          if (result == 'format') throw const BackgroundMediaException(BackgroundMediaFailure.format);
          if (result == 'imageSize') throw const ImageInputException(ImageInputFailure.bytes);
          if (result == 'videoSize') throw PlatformException(code: 'document_too_large');
          if (result == 'codec') throw const BackgroundMediaException(BackgroundMediaFailure.videoCodec);
          return result == 'success';
        });
        await _pumpWidgetWithProviders(tester, settings, wallpaper);
        await tester.tap(find.text('Choose file'));
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(tester.element(find.byType(WallpaperPanelPage)))!;
        final message = switch (result) {
          'success' => l.backgroundFileApplied,
          'format' => l.backgroundFormatError,
          'imageSize' => l.backgroundFileTooLarge('8'),
          'videoSize' => l.backgroundFileTooLarge('256'),
          'codec' => l.backgroundVideoCodecError,
          _ => null,
        };
        if (message != null) expect(find.text(message), findsOneWidget);
        if (result == 'cancel') expect(find.text(l.backgroundFileApplied), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('shows a message when the document provider cannot read the image', (tester) async {
      final settings = MockSettingsService();
      final wallpaper = MockWallpaperService();
      when(wallpaper.pickWallpaper(picker: anyNamed('picker'))).thenAnswer((_) async => throw PlatformException(code: 'document_failed'));
      await _pumpWidgetWithProviders(tester, settings, wallpaper);
      await tester.tap(find.text('Choose file'));
      await tester.pumpAndSettle();
      expect(find.text('Could not change the wallpaper. Check file access and try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("opens file explorer if available", (tester) async {
      final settingsService = MockSettingsService();
      final wallpaperService = MockWallpaperService();
      when(wallpaperService.pickWallpaper(picker: anyNamed('picker'))).thenAnswer((_) async => false);

      await _pumpWidgetWithProviders(tester, settingsService, wallpaperService);

      await tester.tap(find.text("Choose file"));
      await tester.pumpAndSettle();
      verify(wallpaperService.pickWallpaper(picker: anyNamed('picker')));
    });

    testWidgets("shows action notice if not file explorer available", (tester) async {
      final settingsService = MockSettingsService();
      final wallpaperService = MockWallpaperService();
      when(wallpaperService.pickWallpaper(picker: anyNamed('picker'))).thenThrow(NoFileExplorerException());

      await _pumpWidgetWithProviders(tester, settingsService, wallpaperService);

      await tester.tap(find.text("Choose file"));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text("Please install a file explorer in order to pick a picture."), findsOneWidget);
    });
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  SettingsService settingsService,
  WallpaperService wallpaperService,
) async {
  when(settingsService.timeBasedWallpaperEnabled).thenReturn(false);
  when(settingsService.backgroundSource).thenReturn('picture');
  when(settingsService.appKeyClickEnabled).thenReturn(false);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<WallpaperService>.value(value: wallpaperService),
      ],
      builder: (_, _) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          GradientPanelPage.routeName: (_) => Container(key: Key("GradientPanelPage")),
        },
        home: Scaffold(body: WallpaperPanelPage(parameters: true)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
