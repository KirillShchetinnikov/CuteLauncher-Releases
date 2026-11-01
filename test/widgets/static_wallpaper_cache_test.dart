import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/background_raster_cache.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flauncher/image_limits.dart';

void main() {
  const captureKey = ValueKey('capture');
  const gradient = LinearGradient(
    colors: [Color(0x80703050), Color(0xff4080d0)],
  );
  Widget host(Widget child) => MaterialApp(
    home: Center(
      child: RepaintBoundary(
        key: captureKey,
        child: MediaQuery(
          data: const MediaQueryData(devicePixelRatio: 2, size: Size(160, 100)),
          child: SizedBox(width: 160, height: 100, child: child),
        ),
      ),
    ),
  );
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

  testWidgets('explicit still artwork is recached when its pixels change', (
    tester,
  ) async {
    Future<void> show(Color colour) async {
      await tester.pumpWidget(
        host(
          WallpaperBackground(
            image: null,
            gradient: gradient,
            cacheArtwork: true,
            artwork: ColoredBox(color: colour),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(Colors.red);
    expect(find.byType(BackgroundRasterCache), findsOneWidget);
    final before = await pixels(tester);
    await show(Colors.blue);
    final after = await pixels(tester);
    expect(after, isNot(before));
    final cache = tester.widget<BackgroundRasterCache>(
      find.byType(BackgroundRasterCache),
    );
    await tester.pumpWidget(host(cache.child));
    await tester.pumpAndSettle();
    expect(await pixels(tester), after);
  });

  testWidgets('cached video underlay and dimming preserve live composition', (
    tester,
  ) async {
    Uint8List? previous;
    for (final colour in [const Color(0x8030e050), const Color(0x806040f0)]) {
      Future<void> show(bool cached) async {
        await tester.pumpWidget(
          host(
            WallpaperBackground(
              image: null,
              gradient: gradient,
              brightness: .8,
              saturation: .6,
              dimming: .7,
              cacheStaticLayers: cached,
              artwork: ColoredBox(color: colour),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await show(false);
      final original = await pixels(tester);
      await show(true);
      expect(find.byType(BackgroundRasterCache), findsNWidgets(2));
      final current = await pixels(tester);
      final maxDelta = [
        for (var i = 0; i < current.length; i++)
          (current[i] - original[i]).abs(),
      ].reduce((a, b) => a > b ? a : b);
      // Two transparent cached layers introduce bounded 8-bit rounding.
      expect(maxDelta, lessThanOrEqualTo(2));
      if (previous != null) expect(current, isNot(previous));
      previous = current;
    }
  });

  testWidgets(
    'video static layers share the 16 MiB limit and respect memory saver',
    (tester) async {
      for (final economy in [false, true]) {
        await tester.pumpWidget(
          host(
            MediaQuery(
              data: MediaQueryData(
                size: economy ? const Size(160, 100) : const Size(1920, 1080),
                devicePixelRatio: 2,
              ),
              child: WallpaperBackground(
                image: null,
                gradient: gradient,
                memorySaver: economy,
                cacheStaticLayers: true,
                artwork: const ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final caches = tester.widgetList<BackgroundRasterCache>(
          find.byType(BackgroundRasterCache),
        );
        expect(caches, hasLength(2));
        expect(caches.every((cache) => !cache.enabled), isTrue);
      }
    },
  );

  for (final mode in ['gradient', 'cover', 'contain', 'blurred']) {
    testWidgets(
      '$mode cache preserves composition and updated colour adjustments',
      (tester) async {
        final image = mode == 'gradient'
            ? null
            : MemoryImage(
                File('test/fixtures/impeller_resize_320x180.png')
                    .readAsBytesSync(),
              );
        Uint8List? previous;
        for (final brightness in [.8, 1.2]) {
          await tester.pumpWidget(
            host(
              WallpaperBackground(
                image: image,
                gradient: gradient,
                mode: mode,
                brightness: brightness,
                saturation: .6,
                dimming: .7,
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (image != null) {
            await tester.runAsync(
              () => precacheImage(
                sizedImage(image, const Size(160, 100), 2),
                tester.element(find.byType(WallpaperBackground)),
              ),
            );
            await tester.pumpAndSettle();
          }
          final cached = await pixels(tester);
          final cache = tester.widget<BackgroundRasterCache>(
            find.byType(BackgroundRasterCache),
          );
          expect(cache.enabled, isTrue);
          // The same uncached composition is the pre-optimization render path.
          await tester.pumpWidget(host(cache.child));
          await tester.pumpAndSettle();
          expect(await pixels(tester), cached);
          if (previous != null) expect(cached, isNot(previous));
          previous = cached;
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'external artwork stays live and memory saver disables static texture',
    (tester) async {
      final colour = ValueNotifier<Color>(Colors.red);
      await tester.pumpWidget(
        host(
          WallpaperBackground(
            image: null,
            gradient: gradient,
            artwork: ValueListenableBuilder<Color>(
              valueListenable: colour,
              builder: (_, value, _) => ColoredBox(color: value),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BackgroundRasterCache), findsNothing);
      final before = await pixels(tester);
      colour.value = Colors.blue;
      await tester.pump();
      expect(await pixels(tester), isNot(before));
      await tester.pumpWidget(
        host(
          const WallpaperBackground(
            image: null,
            gradient: gradient,
            memorySaver: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<BackgroundRasterCache>(find.byType(BackgroundRasterCache))
            .enabled,
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      colour.dispose();
    },
  );
}
