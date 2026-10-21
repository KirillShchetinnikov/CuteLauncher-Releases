import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/app_focus_color.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/tile_appearance.dart';

void main() {
  test('dynamic border preserves hue and contrasts with dark or uniform banners', () {
    for (final average in [Colors.black, const Color(0xff121212), const Color(0xff2288cc),
      const Color(0xffff0000), const Color(0xff00ff00), const Color(0xff888888), const Color(0xffb8b8b8), Colors.white]) {
      final border = readableAppFocusColor(average);
      final a = average.computeLuminance(), b = border.computeLuminance();
      final contrast = a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
      expect(contrast, greaterThanOrEqualTo(2));
      if (HSLColor.fromColor(average).saturation > .1) {
        expect(HSLColor.fromColor(border).hue, closeTo(HSLColor.fromColor(average).hue, 1));
      }
    }
  });

  testWidgets('image color is memoized and invalid images fall back', (tester) async {
    await tester.runAsync(() async {
      final first = appFocusColor(kTransparentImage);
      expect(identical(first, appFocusColor(kTransparentImage)), isTrue);
      expect(await first, isNull);
      expect(await appFocusColor(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
  testWidgets('focus settings preview and remote enlargement preserve menu focus', (tester) async {
    tester.view.physicalSize = const Size(1200, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    final tile = Object();
    service.registerPreviewTile(tile, () => const Rect.fromLTWH(650, 100, 100, 100));
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: service),
      ChangeNotifierProvider.value(value: settings),
    ], child: MaterialApp(locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppearancePage(section: 'focus')))));
    await tester.pumpAndSettle();
    expect(service.focusPreviewTile, tile);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(service.appearance.focusScale, .15);
    await service.set('focusScale', .5);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(service.appearance.focusScale, .5);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(service.appearance.focusScale, .45);
    expect(AppearanceService(prefs).appearance.focusScale, .45);
    await service.set('focusEffect', 'lift');
    await tester.pumpAndSettle();
    expect(find.text('Высота подъёма'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(service.focusPreviewTile, isNull);
    expect(tester.takeException(), isNull);
    service.dispose();
    settings.dispose();
  });
  test('average color weights transparency and ignores invisible pixels', () {
    expect(averageRgbaColor(Uint8List.fromList([
      255, 0, 0, 255, 0, 0, 255, 255, 0, 255, 0, 0,
    ])), const Color(0xff800080));
    expect(averageRgbaColor(Uint8List(4)), isNull);
  });

  test('enlargement reaches 50 percent only for scale and ignores gaps', () {
    final appearance = TileAppearance(TileAppearance.validValues({
      'focusEffect': 'scale', 'focusScale': .5, 'focusLift': 50,
      'focusBorderColor': 'dynamic', 'horizontalGap': 8,
    }));
    expect(appearance.focusLift, 25);
    expect(appearance.dynamicFocusColor, isTrue);
    expect(const LauncherStyle().tileFocusScale('modern', appearance,
      width: 200, focused: true), 1.5);
    expect(const LauncherStyle().tileFocusScale('modern', appearance,
      width: 200, focused: false), 1);
    expect(TileAppearance.validValues({'focusScale': .55, 'focusLift': -5}), isEmpty);
    for (final effect in ['border', 'lift']) {
      final other = TileAppearance({...appearance.values, 'focusEffect': effect});
      expect(other.focusScale, 0);
      expect(const LauncherStyle().tileFocusScale('modern', other,
        width: 200, focused: true), 1);
    }
    final legacy = TileAppearance.decode('{"focusEffect":"shadow"}');
    expect(legacy.focusEffect, 'border');
    expect(legacy.showFocusShadow, isFalse);
    expect(TileAppearance.validValues({'focusShadow': true})['focusShadow'], isTrue);

  });

  test('lift caps saved and imported legacy heights at 25', () {
    for (final height in [0, 5, 10, 15, 20, 25, 30, 35, 50]) {
      final expected = height.clamp(0, 25).toDouble();
      expect(TileAppearance({'focusLift': height}).focusLift, expected);
      expect(TileAppearance.decode('{"focusLift":$height}').focusLift, expected);
      expect(TileAppearance.validValues({'focusLift': height})['focusLift'], expected);
    }
    expect(const TileAppearance().focusLift, 10);
    expect(TileAppearance.validValues({'focusLift': 51}), isEmpty);
  });

  testWidgets('preview chooses an uncovered tile and clears on exit', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final service = AppearanceService(await SharedPreferences.getInstance());
    final left = Object(), right = Object(), hidden = Object();
    service.registerPreviewTile(left, () => const Rect.fromLTWH(50, 100, 100, 100));
    service.registerPreviewTile(right, () => const Rect.fromLTWH(650, 100, 100, 100));
    service.registerPreviewTile(hidden, () => const Rect.fromLTWH(450, -50, 100, 100));
    service.beginFocusPreview(const Rect.fromLTRB(400, 0, 800, 600));
    expect(service.focusPreviewTile, right);
    service.beginFocusPreview(const Rect.fromLTRB(0, 0, 400, 600));
    expect(service.focusPreviewTile, left);
    service.endFocusPreview();
    expect(service.focusPreviewTile, isNull);
    await tester.pump();
    service.unregisterPreviewTile(left);
    service.beginFocusPreview(const Rect.fromLTRB(0, 0, 400, 600));
    expect(service.focusPreviewTile, isNull);
    service.dispose();
  });
}
