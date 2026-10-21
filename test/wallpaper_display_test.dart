import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flauncher/widgets/settings/wallpaper_display_page.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('removing the identity filter preserves rendered pixels and alpha', (tester) async {
    const key = ValueKey('pixels');
    Future<List<int>> capture(bool identity) async {
      const wallpaper = WallpaperBackground(image: null, dimming: 0,
        gradient: LinearGradient(colors: [Color(0x60ff0044), Color(0xb00088ff)]));
      await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(key: key,
        child: SizedBox(width: 80, height: 48, child: identity ? const ColorFiltered(
          colorFilter: ColorFilter.matrix([1,0,0,0,0, 0,1,0,0,0, 0,0,1,0,0, 0,0,0,1,0]),
          child: wallpaper) : wallpaper)))));
      await tester.pumpAndSettle();
      final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      return (await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 1);
        try {
          final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
          return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes).toList();
        } finally { image.dispose(); }
      }))!;
    }
    final before = await capture(true);
    final after = await capture(false);
    expect(after, before);
  });
  testWidgets('neutral wallpaper adjustments bypass the filter, non-neutral values retain it', (tester) async {
    Future<void> show(double brightness, double saturation) => tester.pumpWidget(MaterialApp(home: WallpaperBackground(
      image: null, brightness: brightness, saturation: saturation,
      gradient: const LinearGradient(colors: [Colors.red, Colors.blue]))));
    await show(1, 1); expect(find.byType(ColorFiltered), findsNothing);
    await show(.8, 1); expect(find.byType(ColorFiltered), findsOneWidget);
    await show(1, 0); expect(find.byType(ColorFiltered), findsOneWidget);
    await show(1, 1); expect(find.byType(ColorFiltered), findsNothing);
  });
  testWidgets('display editor changes placement with remote keys', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    await tester.pumpWidget(ChangeNotifierProvider.value(value: settings,
      child: const MaterialApp(locale: Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: SizedBox(width: 380, child: WallpaperDisplayPage())))));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(settings.wallpaperFit, 'contain');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(settings.wallpaperFit, 'blurred');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    settings.dispose();
  });
  test('wallpaper settings persist, reject invalid backup and reset', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    expect(settings.wallpaperFit, 'cover');
    await settings.setWallpaperFit('blurred');
    await settings.setWallpaperAdjustment('wallpaper_saturation', 0);
    await settings.setWallpaperAdjustment('wallpaper_brightness', double.nan);
    final restored = SettingsService(prefs);
    expect(restored.wallpaperFit, 'blurred');
    expect(restored.wallpaperSaturation, 0);
    expect(restored.wallpaperBrightness, 1);
    expect(settings.exportSettingsMap()['wallpaper_fit'], 'blurred');
    expect(settings.exportSettingsMap()['wallpaper_saturation'], 0);
    expect(compatibleSettings({'wallpaper_fit': 'stretch', 'wallpaper_dimming': 3}, {}), isEmpty);
    expect(compatibleSettings({'wallpaper_fit': 'contain', 'wallpaper_dimming': 0}, {}),
      {'wallpaper_fit': 'contain', 'wallpaper_dimming': 0});
    await settings.resetAppearanceSettings();
    expect(settings.wallpaperFit, 'cover');
    expect(settings.wallpaperSaturation, 1);
    settings.dispose(); restored.dispose();
  });

  testWidgets('whole image, blurred copy, economy and corrupt image fallback', (tester) async {
    final image = MemoryImage(base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/l9sAAAAASUVORK5CYII='));
    Future<void> pump(String mode, {bool economy = false, ImageProvider? provider}) async {
      await tester.pumpWidget(MaterialApp(home: WallpaperBackground(
        image: provider ?? image, mode: mode, memorySaver: economy,
        gradient: const LinearGradient(colors: [Colors.red, Colors.blue]))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await pump('cover');
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.cover);
    await pump('contain');
    expect(tester.widget<Image>(find.byType(Image)).fit, BoxFit.contain);
    await pump('blurred');
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(Image), findsNWidgets(2));
    await pump('blurred', economy: true);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    await pump('contain', provider: MemoryImage(base64Decode('AAAA')));
    expect(find.byType(DecoratedBox), findsNWidgets(2));
  });
}
