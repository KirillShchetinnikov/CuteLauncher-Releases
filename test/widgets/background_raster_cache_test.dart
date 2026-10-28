import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/background_raster_cache.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/foreground_work.dart';
import 'package:provider/provider.dart';

void main() {
  const captureKey = ValueKey('capture');
  Future<Uint8List> pixels(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(captureKey),
    );
    return (await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      try {
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        return Uint8List.fromList(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      } finally {
        image.dispose();
      }
    }))!;
  }

  Widget host(
    Widget child, {
    bool enabled = true,
    double pixelRatio = 2,
    Size size = const Size(120, 80),
  }) => MaterialApp(
    home: Center(
      child: RepaintBoundary(
        key: captureKey,
        child: MediaQuery(
          data: MediaQueryData(devicePixelRatio: pixelRatio),
          child: SizedBox.fromSize(
            size: size,
            child: BackgroundRasterCache(enabled: enabled, child: child),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'cached background preserves translucent gradients and clipping pixels',
    (tester) async {
      const scene = Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0x806070f0), Color(0xffa08030)],
              ),
            ),
          ),
          ClipOval(child: ColoredBox(color: Color(0x6077ee44))),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x60000000),
                  Color(0x20000000),
                  Color(0x80000000),
                ],
              ),
            ),
          ),
        ],
      );
      await tester.pumpWidget(host(scene, enabled: false));
      await tester.pump();
      final live = await pixels(tester);
      await tester.pumpWidget(host(scene));
      await tester.pump();
      expect(await pixels(tester), live);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'nested repaint updates cached pixels without rebuilding the cache widget',
    (tester) async {
      final color = ValueNotifier<Color>(Colors.red);
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            child: ValueListenableBuilder<Color>(
              valueListenable: color,
              builder: (_, value, _) => ColoredBox(color: value),
            ),
          ),
        ),
      );
      await tester.pump();
      final before = await pixels(tester);
      color.value = const Color(0xff0000ff);
      await tester.pump();
      final after = await pixels(tester);
      expect(after, isNot(before));
      expect(after[0], 0);
      expect(after[2], 255);
      await tester.pumpWidget(const SizedBox());
      color.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'opacity layer changes invalidate the snapshot even without a child repaint',
    (tester) async {
      final opacity = ValueNotifier(1.0);
      await tester.pumpWidget(
        host(
          ValueListenableBuilder<double>(
            valueListenable: opacity,
            builder: (_, value, child) => Opacity(opacity: value, child: child),
            child: const RepaintBoundary(child: ColoredBox(color: Colors.red)),
          ),
        ),
      );
      await tester.pump();
      expect((await pixels(tester))[3], 255);
      opacity.value = .5;
      await tester.pump();
      expect((await pixels(tester))[3], closeTo(128, 1));
      await tester.pumpWidget(const SizedBox());
      opacity.dispose();
    },
  );

  testWidgets(
    'cache releases on pressure and pause, remains live, and resumes safely',
    (tester) async {
      final resources = MemoryResources();
      final color = ValueNotifier<Color>(Colors.red);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: resources,
          child: host(
            ValueListenableBuilder<Color>(
              valueListenable: color,
              builder: (_, value, _) => ColoredBox(color: value),
            ),
          ),
        ),
      );
      await tester.pump();
      await pixels(tester);
      expect(
        resources.cacheActivity['background_raster_bytes'],
        120 * 80 * 4 * 4,
      );
      expect(resources.encodedImages.bytes, 0);
      tester.binding.handleMemoryPressure();
      expect(resources.cacheActivity['background_raster_bytes'], 0);
      await tester.pump();
      color.value = const Color(0xff0000ff);
      await tester.pump();
      expect((await pixels(tester))[2], 255);
      expect(resources.cacheActivity['background_raster_bytes'], 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await pixels(tester);
      expect(
        resources.cacheActivity['background_raster_bytes'],
        greaterThan(0),
      );
      resources.clearRecoverableCaches();
      expect(resources.cacheActivity['background_raster_bytes'], 0);
      await tester.pumpWidget(const SizedBox());
      expect(resources.cacheActivity, isEmpty);
      color.dispose();
      resources.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'oversized snapshots fall back to live painting and do not allocate a texture',
    (tester) async {
      final resources = MemoryResources();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: resources,
          child: host(
            const ColoredBox(color: Color(0xff0000ff)),
            pixelRatio: 32,
          ),
        ),
      );
      await tester.pump();
      expect((await pixels(tester))[2], 255);
      expect(resources.cacheActivity['background_raster_bytes'], 0);
      await tester.pumpWidget(const SizedBox());
      resources.dispose();
    },
  );

  testWidgets(
    'snapshot activation waits for Home readiness and can be cancelled',
    (tester) async {
      var now = DateTime(2026);
      final work = ForegroundWork(now: () => now);
      final resources = MemoryResources();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: work),
            ChangeNotifierProvider.value(value: resources),
          ],
          child: host(const ColoredBox(color: Colors.red)),
        ),
      );
      await tester.pump();
      await pixels(tester);
      expect(resources.cacheActivity['background_raster_bytes'], 0);
      work.homeReady();
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await pixels(tester);
      expect(
        resources.cacheActivity['background_raster_bytes'],
        greaterThan(0),
      );
      await tester.pumpWidget(const SizedBox());
      resources.dispose();
      work.dispose();
    },
  );

  testWidgets('resize and disabling discard the previous texture', (
    tester,
  ) async {
    final resources = MemoryResources();
    Future<void> show(Size size, bool enabled) async {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: resources,
          child: host(
            const ColoredBox(color: Color(0xff0000ff)),
            size: size,
            enabled: enabled,
          ),
        ),
      );
      await tester.pump();
      expect((await pixels(tester))[2], 255);
    }

    await show(const Size(120, 80), true);
    expect(resources.cacheActivity['background_raster_bytes'], 120 * 80 * 16);
    await show(const Size(80, 60), true);
    expect(resources.cacheActivity['background_raster_bytes'], 80 * 60 * 16);
    await show(const Size(80, 60), false);
    expect(resources.cacheActivity['background_raster_bytes'], 0);
    await tester.pumpWidget(const SizedBox());
    resources.dispose();
  });
}
