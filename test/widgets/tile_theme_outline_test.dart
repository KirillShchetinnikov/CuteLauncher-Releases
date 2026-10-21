import 'package:flauncher/widgets/tile_theme_outline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

void main() {
  testWidgets('glow starts at the edge and fades outward without changing image pixels', (tester) async {
    final capture = GlobalKey();
    await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(
      key: capture, child: SizedBox(width: 180, height: 120,
        child: Stack(children: [Positioned(left: 30, top: 30, width: 120, height: 60,
          child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
            const ColoredBox(color: Color(0xff123456)),
            const TileThemeOutline(theme: 'modern', accent: Colors.cyan, radius: 0, borderStyle: 'glow'),
          ]))])),
    ))));
    await tester.pump();
    await tester.runAsync(() async {
      final image = await (capture.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      int alpha(int y) => data.getUint8((y * image.width + 90) * 4 + 3);
      expect(alpha(29), greaterThan(200));
      expect(alpha(29), greaterThan(alpha(25)));
      expect(alpha(25), greaterThan(alpha(19)));
      expect(alpha(13), 0);
      final at = (30 * image.width + 90) * 4;
      expect([data.getUint8(at), data.getUint8(at+1), data.getUint8(at+2)], [0x12, 0x34, 0x56]);
      image.dispose();
    });
  });
  testWidgets('outline paints outside the tile and leaves image edge untouched', (tester) async {
    final capture = GlobalKey();
    const frame = Color(0xff00ff00), banner = Color(0xff123456);
    await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(
      key: capture, child: SizedBox(width: 180, height: 100,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(left: 20, top: 20, width: 120, height: 60,
            child: Stack(clipBehavior: Clip.none, fit: StackFit.expand, children: [
              const ColoredBox(color: banner),
              const TileThemeOutline(theme: 'modern', accent: frame, radius: 0),
            ])),
        ])),
    ))));
    await tester.pump();
    await tester.runAsync(() async {
      final image = await (capture.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage();
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      int pixel(int x, int y) {
        final at = (y * image.width + x) * 4;
        return Color.fromARGB(data.getUint8(at+3), data.getUint8(at), data.getUint8(at+1), data.getUint8(at+2)).toARGB32();
      }
      expect(pixel(80, 17), brighterTileFocusColor(frame).toARGB32());
      expect(pixel(80, 19), Colors.black.toARGB32());
      expect(pixel(80, 20), banner.toARGB32());
      expect(pixel(80, 21), banner.toARGB32());
      image.dispose();
    });
  });
  testWidgets('glow uses the chosen color and no border stops the pulse', (tester) async {
    Future<void> show(String borderStyle) => tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 200, height: 100, child: TileThemeOutline(
        theme: 'modern', accent: const Color(0xff123456),
        borderStyle: borderStyle, pulse: true,
      )),
    ));
    await show('glow');
    await tester.pump(const Duration(milliseconds: 200));
    final paint = tester.widget<CustomPaint>(find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TileGlowPainter));
    expect((paint.painter as TileGlowPainter).color.toARGB32() & 0xffffff, brighterTileFocusColor(const Color(0xff123456)).toARGB32() & 0xffffff);
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await show('none');
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((widget) => widget is CustomPaint &&
      widget.painter is TileGlowPainter), findsNothing);
    expect(tester.binding.transientCallbackCount, 0);
    await show('outline');
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('economy and background stop pulse without changing the preference', (tester) async {
    SharedPreferences.setMockInitialValues({'app_highlight_animation_enabled': true});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final resources = MemoryResources(settings: settings);
    await tester.pumpWidget(ChangeNotifierProvider.value(value: resources,
      child: const MaterialApp(home: SizedBox(width: 200, height: 100,
        child: TileThemeOutline(theme: 'modern', accent: Colors.purple, pulse: true)))));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await settings.setMemorySaverEnabled(true);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    expect(settings.appHighlightAnimationEnabled, isTrue);
    await settings.setMemorySaverEnabled(false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    resources.didChangeAppLifecycleState(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    resources.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
    resources.dispose(); settings.dispose();
    expect(tester.binding.transientCallbackCount, 0);
  });

  testWidgets('hidden subtree stops and resumes the pulse', (tester) async {
    Future<void> show(bool enabled) => tester.pumpWidget(MaterialApp(home: TickerMode(enabled: enabled,
      child: const SizedBox(width: 200, height: 100,
        child: TileThemeOutline(theme: 'modern', accent: Colors.purple, pulse: true)))));
    await show(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await show(false);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await show(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(const SizedBox());
  });
  Future<void> pump(
    WidgetTester tester, {
    String theme = 'modern',
    bool pulse = true,
  }) => tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 200,
        height: 100,
        child: TileThemeOutline(
          theme: theme,
          accent: Colors.purple,
          pulse: pulse,
        ),
      ),
    ),
  );

  testWidgets('pulse stops when disabled and releases its ticker on removal', (
    tester,
  ) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await pump(tester, pulse: false);
    await tester.pumpAndSettle();
    expect(tester.binding.transientCallbackCount, 0);
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('classic and premium themes do not start a repeating pulse', (
    tester,
  ) async {
    for (final theme in ['classic', 'premium']) {
      await pump(tester, theme: theme);
      await tester.pumpAndSettle();
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    }
  });
}
