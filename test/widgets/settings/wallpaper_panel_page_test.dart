import 'dart:io';
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
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
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
    await tester.tap(find.text('Параметры'));
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
    testWidgets('shows a message when the document provider cannot read the image', (tester) async {
      final settings = MockSettingsService();
      final wallpaper = MockWallpaperService();
      when(wallpaper.pickWallpaper()).thenAnswer((_) async => throw PlatformException(code: 'document_failed'));
      await _pumpWidgetWithProviders(tester, settings, wallpaper);
      await tester.tap(find.text('Open image'));
      await tester.pumpAndSettle();
      expect(find.text('Could not change the wallpaper. Check file access and try again.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets("opens file explorer if available", (tester) async {
      final settingsService = MockSettingsService();
      final wallpaperService = MockWallpaperService();

      await _pumpWidgetWithProviders(tester, settingsService, wallpaperService);

      await tester.tap(find.text("Open image"));
      await tester.pumpAndSettle();
      verify(wallpaperService.pickWallpaper());
    });

    testWidgets("shows action notice if not file explorer available", (tester) async {
      final settingsService = MockSettingsService();
      final wallpaperService = MockWallpaperService();
      when(wallpaperService.pickWallpaper()).thenThrow(NoFileExplorerException());

      await _pumpWidgetWithProviders(tester, settingsService, wallpaperService);

      await tester.tap(find.text("Open image"));
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
