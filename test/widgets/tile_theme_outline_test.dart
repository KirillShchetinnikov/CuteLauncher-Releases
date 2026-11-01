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
  for (final glow in [false, true]) {
    testWidgets('isolated ${glow ? 'glow' : 'outline'} pulse preserves pixels and overflow', (tester) async {
      const capture = ValueKey('outline-capture');
      const accent = Color(0xff7b46bd);
      final color = brighterTileFocusColor(accent);
      Future<ui.Image> render(Widget child, double scale) async {
        await tester.pumpWidget(MaterialApp(home: Center(child: RepaintBoundary(
          key: capture, child: SizedBox(width: 360, height: 260,
            child: ColoredBox(color: const Color(0xff273847), child: Center(
              child: Transform.scale(scale: scale, child: SizedBox(width: 120, height: 70, child: child)),
            )),
          ),
        ))));
        await tester.pump();
        return (await tester.runAsync(() => tester.renderObject<RenderRepaintBoundary>(
            find.byKey(capture)).toImage()))!;
      }
      for (final scale in [1.0, 1.17, 2.0]) {
        final actual = await render(TileThemeOutline(theme: 'modern', accent: accent,
            pulse: true, radius: 13.4, borderStyle: glow ? 'glow' : 'outline'), scale);
        final painter = tester.widget<CustomPaint>(find.byWidgetPredicate((w) => w is CustomPaint &&
            (w.painter is TileOutlinePainter || w.painter is TileGlowPainter))).painter;
        final opacity = painter is TileGlowPainter ? painter.color.a : (painter as TileOutlinePainter).color.a;
        final expected = await render(CustomPaint(painter: glow
            ? TileGlowPainter(color: color.withValues(alpha: opacity), radius: 13.4)
            : TileOutlinePainter(color: color.withValues(alpha: opacity), radius: 13.4,
                width: 2, separator: 2)), scale);
        await tester.runAsync(() async {
          final a = (await actual.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
          final b = (await expected.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();
          var maxDifference = 0;
          for (var i = 0; i < a.length; i++) {
            final delta = (a[i] - b[i]).abs();
            if (delta > maxDifference) maxDifference = delta;
          }
          expect(maxDifference, lessThanOrEqualTo(3), reason: 'scale $scale, opacity $opacity');
        });
        actual.dispose(); expected.dispose();
      }
    });
  }
  for (final border in ['outline', 'glow']) {
    testWidgets('$border freezes pulse during either nested scroll and resumes after both stop', (tester) async {
      final vertical = ScrollController(), horizontal = ScrollController();
      await tester.pumpWidget(MaterialApp(home: SizedBox(width: 300, height: 200,
        child: SingleChildScrollView(controller: vertical, child: SizedBox(height: 1200,
          child: SingleChildScrollView(controller: horizontal, scrollDirection: Axis.horizontal,
            child: SizedBox(width: 1600, child: Align(alignment: Alignment.topLeft,
              child: SizedBox(width: 100, height: 60, child: TileThemeOutline(
                theme: 'modern', accent: Colors.cyan, pulse: true, borderStyle: border,
              )),
            )),
          ),
        )),
      )));
      Color color() {
        final painter = tester.widget<CustomPaint>(find.byWidgetPredicate((w) =>
            w is CustomPaint && (w.painter is TileGlowPainter || w.painter is TileOutlinePainter))).painter;
        return painter is TileGlowPainter ? painter.color : (painter as TileOutlinePainter).color;
      }
      await tester.pump(const Duration(milliseconds: 200));
      final initial = color();
      await tester.pump(const Duration(milliseconds: 200));
      expect(color(), isNot(initial));
      final frozen = color();
      vertical.animateTo(200, duration: const Duration(milliseconds: 300), curve: Curves.linear);
      horizontal.animateTo(200, duration: const Duration(milliseconds: 600), curve: Curves.linear);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(color(), frozen);
      expect(tester.binding.transientCallbackCount, 2,
          reason: 'Only the two scroll animations should tick');
      await tester.pump(const Duration(milliseconds: 200));
      expect(vertical.position.isScrollingNotifier.value, isFalse);
      expect(horizontal.position.isScrollingNotifier.value, isTrue);
      expect(color(), frozen);
      expect(tester.binding.transientCallbackCount, 1);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 200));
      expect(color(), isNot(frozen));
      vertical.animateTo(0, duration: const Duration(seconds: 1), curve: Curves.linear);
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      vertical.dispose(); horizontal.dispose();
      expect(tester.takeException(), isNull);
    });
  }
  for (final glow in [true, false]) {
    for (final scale in [1.0, 1.17, 2.0]) {
      testWidgets('${glow ? 'glow' : 'outline'} has no dark seams at fractional corner joins x$scale', (tester) async {
        await tester.runAsync(() async {
          for (final radius in [13.4, 35.7]) {
            for (final opacity in [1.0, .55]) {
              final recorder = ui.PictureRecorder();
              final canvas = Canvas(recorder);
              const origin = Offset(32.25, 32.5);
              const size = Size(140, 80);
              canvas.translate(origin.dx, origin.dy);
              canvas.scale(scale);
              final color = Colors.white.withValues(alpha: opacity);
              final CustomPainter painter = glow
                  ? TileGlowPainter(color: color, radius: radius)
                  : TileOutlinePainter(color: color, radius: radius, width: 4, separator: 0);
              painter.paint(canvas, size);
              final picture = recorder.endRecording();
              final image = await picture.toImage(400, 250);
              final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
              int alpha(int x, int y) => bytes.getUint8((y * image.width + x) * 4 + 3);
              final distance = glow ? 4.0 : 2.0;
              // Compare each join with the middle of the same straight edge.
              // A rounded corner is tangent here, so alpha must be continuous.
              for (final y in [-distance, size.height + distance]) {
                final py = (origin.dy + y * scale).floor();
                final reference = alpha((origin.dx + size.width / 2 * scale).floor(), py);
                for (final x in [radius, size.width - radius]) {
                  final join = (origin.dx + x * scale).floor();
                  for (var dx = -1; dx <= 1; dx++) {
                    expect(alpha(join + dx, py), greaterThanOrEqualTo(reference - 8),
                        reason: 'horizontal join r=$radius alpha=$opacity at $x,$y');
                  }
                }
              }
              for (final x in [-distance, size.width + distance]) {
                final px = (origin.dx + x * scale).floor();
                final reference = alpha(px, (origin.dy + size.height / 2 * scale).floor());
                for (final y in [radius, size.height - radius]) {
                  final join = (origin.dy + y * scale).floor();
                  for (var dy = -1; dy <= 1; dy++) {
                    expect(alpha(px, join + dy), greaterThanOrEqualTo(reference - 8),
                        reason: 'vertical join r=$radius alpha=$opacity at $x,$y');
                  }
                }
              }
              image.dispose();
              picture.dispose();
            }
          }
        });
      });
    }
  }
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
  testWidgets('system reduced motion stops and resumes the pulse', (tester) async {
    Future<void> show(bool disabled) => tester.pumpWidget(MaterialApp(home: MediaQuery(
      data: MediaQueryData(disableAnimations: disabled),
      child: const SizedBox(width: 200, height: 100,
        child: TileThemeOutline(theme: 'modern', accent: Colors.purple, pulse: true)),
    )));
    await show(false);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await show(true);
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.binding.transientCallbackCount, 0);
    expect(find.byWidgetPredicate((widget) => widget is CustomPaint &&
        widget.painter is TileOutlinePainter), findsOneWidget);
    await show(false);
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
