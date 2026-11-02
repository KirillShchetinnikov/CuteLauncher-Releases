import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/tile_artwork.dart';
import 'package:flauncher/tile_image_geometry.dart';

Future<MemoryImage> fixture(
  WidgetTester tester,
  int width,
  int height,
  Color color,
) async {
  return (await tester.runAsync(() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawRect(
      Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
      Paint()..color = color,
    );
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return MemoryImage(data!.buffer.asUint8List());
  }))!;
}

Future<void> decode(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'contain and color have identical safe geometry in a circle; fill changes pixels',
    (tester) async {
      final banner = await fixture(tester, 160, 90, Colors.red);
      final key = GlobalKey();
      Future<void> mount(TileImageMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: RepaintBoundary(
                key: key,
                child: ColoredBox(
                  color: Colors.black,
                  child: SizedBox(
                    width: 100,
                    height: 100,
                    child: TileArtwork(
                      image: banner,
                      mode: mode,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await decode(tester);
      }

      await mount(TileImageMode.contain);
      final original = tester.getRect(find.byType(Image));
      expect(original.width, lessThan(100));
      expect(original.width / original.height, closeTo(160 / 90, .01));
      Future<int> topPixel() async => (await tester.runAsync(() async {
        final image =
            await (key.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final at = (5 * image.width + 50) * 4;
        final color = Color.fromARGB(
          data.getUint8(at + 3),
          data.getUint8(at),
          data.getUint8(at + 1),
          data.getUint8(at + 2),
        ).toARGB32();
        image.dispose();
        return color;
      }))!;
      expect(await topPixel(), Colors.black.toARGB32());
      await mount(TileImageMode.edgeColor);
      expect(tester.getRect(find.byType(Image)), original);
      expect(await topPixel(), Colors.red.toARGB32());
      await mount(TileImageMode.cover);
      expect(tester.getRect(find.byType(Image)).width, greaterThan(100));
      expect(await topPixel(), Colors.red.toARGB32());
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fitting banner is unchanged in all modes; replacement is lazy and cached',
    (tester) async {
      final banner = await fixture(tester, 160, 90, Colors.blue);
      final icon = await fixture(tester, 40, 40, Colors.green);
      var loads = 0;
      Future<void> mount(
        TileImageMode mode,
        double radius, {
        ImageProvider? source,
      }) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 160,
                height: 90,
                child: TileArtwork(
                  image: source ?? banner,
                  mode: mode,
                  borderRadius: BorderRadius.circular(radius),
                  loadIcon: () async {
                    loads++;
                    return icon;
                  },
                ),
              ),
            ),
          ),
        );
        await decode(tester);
      }

      for (final mode in TileImageMode.values) {
        await mount(mode, 0);
        expect(tester.getSize(find.byType(Image)), const Size(160, 90));
        expect(
          tester
              .widgetList<CustomPaint>(find.byType(CustomPaint))
              .where((w) => w.painter is TileEdgePainter),
          isEmpty,
        );
        expect(loads, 0);
      }
      await mount(TileImageMode.icon, 100);
      expect(loads, 1);
      expect(find.byType(TileArtwork), findsNWidgets(2));
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<TileEdgePainter>()
          .single;
      expect(painter.colors.top?.toARGB32(), Colors.green.toARGB32());
      await mount(TileImageMode.contain, 100);
      await mount(TileImageMode.icon, 100);
      expect(loads, 1);
      await mount(
        TileImageMode.icon,
        100,
        source: await fixture(tester, 160, 90, Colors.orange),
      );
      expect(loads, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'missing replacement uses banner color and no-banner icons use the same modes',
    (tester) async {
      final banner = await fixture(tester, 160, 90, Colors.blue);
      final icon = await fixture(tester, 40, 40, Colors.green);
      final pending = Completer<ImageProvider?>();
      var frames = 0, loads = 0;
      Future<void> mount(
        ImageProvider image,
        TileImageMode mode,
        bool isIcon,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: TileArtwork(
                  image: image,
                  mode: mode,
                  isIcon: isIcon,
                  borderRadius: BorderRadius.circular(100),
                  frameBuilder: (_, child, frame, synchronous) {
                    if (frame != null || synchronous) frames++;
                    return child;
                  },
                  loadIcon: () {
                    loads++;
                    return pending.future;
                  },
                ),
              ),
            ),
          ),
        );
        await decode(tester);
      }

      await mount(banner, TileImageMode.icon, false);
      expect(
        frames,
        greaterThan(0),
        reason: 'Home does not await an optional replacement',
      );
      pending.complete(null);
      await decode(tester);
      expect(find.byType(TileArtwork), findsOneWidget);
      final painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .map((w) => w.painter)
          .whereType<TileEdgePainter>()
          .single;
      expect(painter.colors.top?.toARGB32(), Colors.blue.toARGB32());
      await mount(icon, TileImageMode.edgeColor, true);
      final rect = tester.getRect(find.byType(Image));
      await mount(icon, TileImageMode.icon, true);
      expect(tester.getRect(find.byType(Image)), rect);
      expect(loads, 1);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'corrupt replacement returns the full banner instead of nesting it in the icon slot',
    (tester) async {
      final banner = await fixture(tester, 160, 90, Colors.blue);
      var loads = 0;
      Future<void> mount(TileImageMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: TileArtwork(
                  image: banner,
                  mode: mode,
                  borderRadius: BorderRadius.circular(100),
                  loadIcon: () async {
                    loads++;
                    return MemoryImage(Uint8List.fromList([1, 2, 3]));
                  },
                ),
              ),
            ),
          ),
        );
        await decode(tester);
      }

      await mount(TileImageMode.edgeColor);
      final expectedRect = tester.getRect(find.byType(Image));
      await mount(TileImageMode.icon);
      expect(find.byType(TileArtwork), findsOneWidget);
      expect(tester.getRect(find.byType(Image)), expectedRect);
      expect(loads, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'late icon response cannot replace a new source or rebuild after disposal',
    (tester) async {
      final first = await fixture(tester, 160, 90, Colors.blue);
      final second = await fixture(tester, 160, 90, Colors.orange);
      final icon = await fixture(tester, 40, 40, Colors.green);
      final pending = Completer<ImageProvider?>();
      Future<void> mount(ImageProvider image, TileImageMode mode) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                height: 100,
                child: TileArtwork(
                  image: image,
                  mode: mode,
                  borderRadius: BorderRadius.circular(100),
                  loadIcon: () => pending.future,
                ),
              ),
            ),
          ),
        );
        await decode(tester);
      }

      await mount(first, TileImageMode.icon);
      await mount(second, TileImageMode.contain);
      pending.complete(icon);
      await decode(tester);
      expect(find.byType(TileArtwork), findsOneWidget);
      expect(
        (tester.widget<Image>(find.byType(Image)).image as ResizeImage)
            .imageProvider,
        second,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
