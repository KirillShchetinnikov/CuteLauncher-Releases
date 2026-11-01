import 'dart:io';
import 'dart:convert';
import 'package:flauncher/bing_wallpaper.dart';
import 'package:flauncher/online_wallpaper_failure.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/widgets/settings/online_wallpaper_page.dart';
import '../../support/settings_help.dart';

void main() {
  testWidgets('refresh button always downloads Bing again, including immediate offline retry', (tester) async {
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('cute-refresh-ui-')))!;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    var attempts = 0;
    var offline = false;
    Object offlineError = const SocketException('private server address');
    final service = OnlineWallpaperService(prefs, directory: () async => root,
      bingLookup: () async => BingWallpaper(Uri.parse('https://example.com/same.png'), 'Bing image description', DateTime.now().add(const Duration(days: 1))),
      download: (_) async {
        attempts++;
        if (offline) throw offlineError;
        return base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aF8UAAAAASUVORK5CYII=');
      });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      await tester.runAsync(() => root.delete(recursive: true));
    });
    await tester.runAsync(() async {
      while (!service.initialized) { await Future<void>.delayed(Duration.zero); }
      await service.configure(const OnlineWallpaperConfiguration(enabled: true, source: 'bing'));
    });
    await tester.pumpWidget(ChangeNotifierProvider.value(value: service, child: const MaterialApp(
      locale: Locale('ru'), localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: OnlineWallpaperPage()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('24'), findsNothing);
    expect(find.textContaining('Интервал загрузки'), findsNothing);
    for (final isOffline in [false, true, false]) {
      offline = isOffline;
      await tester.runAsync(() async {
        await tester.tap(find.text('Обновить обои'));
        while (service.loading) { await Future<void>.delayed(Duration.zero); }
      });
      await tester.pumpAndSettle();
      expect(service.failed, isOffline);
      if (isOffline) {
        expect(find.textContaining('Скачивание изображения'), findsWidgets);
        expect(find.textContaining('соединение с сервером'), findsWidgets);
        expect(find.textContaining('private server address'), findsNothing);
      } else {
        expect(find.descendant(of: find.byType(OnlineWallpaperPage),
            matching: find.textContaining('соединение с сервером')), findsNothing);
      }
    }
    expect(attempts, 4);
    expect(service.version, 3);
    offline = true;
    offlineError = const WallpaperException(WallpaperFailureReason.http, httpStatus: 429);
    await tester.runAsync(() async {
      await tester.tap(find.text('Обновить обои'));
      while (service.loading) { await Future<void>.delayed(Duration.zero); }
    });
    await tester.pumpAndSettle();
    expect(find.textContaining('HTTP 429'), findsWidgets);
    expect(find.textContaining('Сервер вернул ошибку.'), findsWidgets);
    offline = false;
    await tester.runAsync(() => service.refresh(force: true));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(service.failure, isNull);
    expect(find.textContaining('Bing image description'), findsNothing);
    await toggleSettingsHelp(tester, 'Bing image description');
    expect(find.textContaining('Bing image description'), findsOneWidget);
    await tester.runAsync(() => service.configure(service.configuration.copyWith(source: 'url')));
    await tester.pumpAndSettle();
    expect(service.configuration.source, 'url');
    expect(service.copyright, 'Bing image description');
    expect(service.wallpaper, isNotNull);
    expect(find.textContaining('Bing image description'), findsNothing);
    await tester.runAsync(() => service.configure(service.configuration.copyWith(source: 'bing')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Bing image description'), findsNothing);
    await toggleSettingsHelp(tester, 'Bing image description');
    expect(find.textContaining('Bing image description'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('remote selects Wallhaven theme and interval without enabling downloads', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('cute-wallhaven-ui-')))!;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = OnlineWallpaperService(prefs, directory: () async => root);
    await service.configure(const OnlineWallpaperConfiguration(source: 'bing'));
    await tester.pumpWidget(ChangeNotifierProvider.value(value: service, child: const MaterialApp(
      locale: Locale('ru'), localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: OnlineWallpaperPage()))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(service.configuration.source, 'wallhaven');
    expect(find.text('Тема обоев'), findsOneWidget);
    expect(find.text('Адрес изображения (HTTPS)'), findsNothing);
    await tester.tap(find.text('Тема обоев'));
    await tester.pumpAndSettle();
    for (final theme in ['Разные', 'Природа', 'Космос', 'Города', 'Минимализм']) {
      expect(find.text(theme), findsWidgets);
    }
    await tester.tap(find.text('Космос').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Интервал загрузки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('6 ч').last);
    await tester.pumpAndSettle();
    final saved = OnlineWallpaperConfiguration.decode(prefs.getString(onlineWallpaperKey));
    expect(saved.source, 'wallhaven');
    expect(saved.wallhavenTheme, 'space');
    expect(saved.intervalHours, 6);
    expect(saved.enabled, isFalse);
    expect(find.textContaining('Случайные обои Wallhaven'), findsNothing);
    await toggleSettingsHelp(tester, 'Случайные обои Wallhaven');
    expect(find.textContaining('Случайные обои Wallhaven'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    await tester.runAsync(() => root.delete(recursive: true));
  });
  testWidgets('Reddit source and controls stay hidden until API access is resolved', (tester) async {
    tester.view.physicalSize = const Size(1000, 1800);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('cute-reddit-ui-')))!;
    SharedPreferences.setMockInitialValues({});
    final service = OnlineWallpaperService(await SharedPreferences.getInstance(), directory: () async => root);
    await service.configure(const OnlineWallpaperConfiguration(source: 'bing'));
    await tester.pumpWidget(ChangeNotifierProvider.value(value: service, child: const MaterialApp(
      locale: Locale('ru'), localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: OnlineWallpaperPage()))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Reddit'), findsNothing);
    expect(find.text('Прямая HTTPS-ссылка'), findsOneWidget);
    expect(find.text('Минимальное разрешение'), findsNothing);
    expect(find.text('Тема обоев'), findsNothing);
    expect(service.configuration.source, 'bing');
    expect(service.configuration.enabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    await tester.runAsync(() => root.delete(recursive: true));
  });
  testWidgets('remote source editor rejects insecure URLs without enabling downloads', (tester) async {
    tester.view.physicalSize = const Size(700, 1080);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final root = (await tester.runAsync(() => Directory.systemTemp.createTemp('cute-online-ui-')))!;
    SharedPreferences.setMockInitialValues({});
    final service = OnlineWallpaperService(await SharedPreferences.getInstance(), directory: () async => root);
    await service.configure(const OnlineWallpaperConfiguration(source: 'bing'));
    await tester.pumpWidget(ChangeNotifierProvider.value(value: service, child: const MaterialApp(
      locale: Locale('ru'), localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: OnlineWallpaperPage()))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Прямая HTTPS-ссылка').last);
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Адрес изображения (HTTPS)'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'http://example.com/image.jpg');
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(find.text('Введите прямую HTTPS-ссылку на изображение без данных входа.'), findsOneWidget);
    expect(service.configuration.enabled, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    await tester.runAsync(() => root.delete(recursive: true));
  });
}
