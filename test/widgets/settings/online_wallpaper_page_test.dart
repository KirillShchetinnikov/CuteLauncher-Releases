import 'dart:io';
import 'dart:convert';
import 'package:flauncher/bing_wallpaper.dart';
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
    final service = OnlineWallpaperService(prefs, directory: () async => root,
      bingLookup: () async => BingWallpaper(Uri.parse('https://example.com/same.png'), 'Bing image description', DateTime.now().add(const Duration(days: 1))),
      download: (_) async {
        attempts++;
        if (offline) throw const SocketException('offline');
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
        await tester.tap(find.text('Проверить обновления'));
        while (service.loading) { await Future<void>.delayed(Duration.zero); }
      });
      await tester.pumpAndSettle();
      expect(service.failed, isOffline);
    }
    expect(attempts, 4);
    expect(service.version, 3);
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
