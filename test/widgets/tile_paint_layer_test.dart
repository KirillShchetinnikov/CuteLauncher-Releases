import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/tile_paint_layer.dart';

void main() {
  testWidgets('outer scrolling keeps the shared tile layer cached', (
    tester,
  ) async {
    final scroll = ScrollController();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 200,
            child: SingleChildScrollView(
              controller: scroll,
              child: const RepaintBoundary(
                child: TilePaintLayer(
                  child: SizedBox(
                    height: 600,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: RaisedTile(
                          raised: true,
                          child: ColoredBox(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final layer = tester.renderObject(find.byType(TilePaintLayer));
    var paints = 0;
    final previous = debugOnProfilePaint;
    debugOnProfilePaint = (object) {
      previous?.call(object);
      if (identical(object, layer)) paints++;
    };
    addTearDown(() => debugOnProfilePaint = previous);
    scroll.animateTo(
      80,
      duration: const Duration(milliseconds: 160),
      curve: Curves.linear,
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 16));
    expect(
      paints,
      0,
      reason: 'Only scrolling inside the owner changes raised tile transforms',
    );
    debugOnProfilePaint = previous;
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });
  for (final axis in Axis.values) {
    testWidgets('raised artwork follows cached $axis viewport on every frame', (
      tester,
    ) async {
      final capture = GlobalKey();
      final scroll = ScrollController();
      const tileKey = ValueKey('scrolling-artwork');
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 200,
                height: 200,
                child: ColoredBox(
                  color: Colors.white,
                  child: TilePaintLayer(
                    child: SingleChildScrollView(
                      controller: scroll,
                      scrollDirection: axis,
                      child: SizedBox(
                        width: axis == Axis.horizontal ? 600 : 200,
                        height: axis == Axis.vertical ? 600 : 200,
                        child: Stack(
                          children: [
                            Positioned(
                              left: 100,
                              top: 100,
                              width: 40,
                              height: 40,
                              child: RaisedTile(
                                raised: true,
                                child: ColoredBox(
                                  key: tileKey,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      scroll.animateTo(
        80,
        duration: const Duration(milliseconds: 160),
        curve: Curves.linear,
      );
      await tester.pump();
      for (var frame = 0; frame < 10; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        final expected = tester
            .getRect(find.byKey(tileKey))
            .shift(-boundary.localToGlobal(Offset.zero));
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          var left = image.width, top = image.height;
          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              final p = (y * image.width + x) * 4;
              if (data.getUint8(p) == 244 &&
                  data.getUint8(p + 1) == 67 &&
                  data.getUint8(p + 2) == 54) {
                if (x < left) left = x;
                if (y < top) top = y;
              }
            }
          }
          image.dispose();
          expect(
            left,
            closeTo(expected.left, 1),
            reason: 'frame $frame, horizontal paint position',
          );
          expect(
            top,
            closeTo(expected.top, 1),
            reason: 'frame $frame, vertical paint position',
          );
        });
      }
      await tester.pumpWidget(const SizedBox());
      scroll.dispose();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'new selection immediately paints and receives taps above shrinking tiles in every direction',
    (tester) async {
      final capture = GlobalKey();
      final selected = ValueNotifier(3);
      addTearDown(selected.dispose);
      final tapped = <int>[];
      const colors = [Colors.red, Colors.green, Colors.blue, Colors.orange];
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 200,
                height: 200,
                child: TilePaintLayer(
                  child: ValueListenableBuilder<int>(
                    valueListenable: selected,
                    builder: (_, current, _) => Stack(
                      children: [
                        for (var i = 0; i < 4; i++)
                          Positioned(
                            left: (i % 2) * 40,
                            top: (i ~/ 2) * 40,
                            width: 100,
                            height: 100,
                            child: RepaintBoundary(
                              child: RaisedTile(
                                // Previous selections remain raised throughout their shrink animations.
                                raised: true,
                                foreground: i == current,
                                child: GestureDetector(
                                  onTap: () => tapped.add(i),
                                  child: AnimatedScale(
                                    scale: i == current ? 1.3 : 1,
                                    duration: const Duration(milliseconds: 150),
                                    child: ColoredBox(color: colors[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      for (final current in [0, 1, 0, 2, 0, 3, 1, 3, 2]) {
        selected.value = current;
        await tester.pump();
        for (final delay in [
          Duration.zero,
          const Duration(milliseconds: 16),
          const Duration(milliseconds: 59),
        ]) {
          await tester.pump(delay);
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(capture),
          );
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final at = (70 * image.width + 70) * 4;
            final color = Color.fromARGB(
              data.getUint8(at + 3),
              data.getUint8(at),
              data.getUint8(at + 1),
              data.getUint8(at + 2),
            );
            image.dispose();
            expect(
              color.toARGB32(),
              colors[current].toARGB32(),
              reason: 'selection $current after $delay',
            );
          });
          await tester.tapAt(boundary.localToGlobal(const Offset(70, 70)));
          expect(tapped.last, current);
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('raised tile crosses cached sliver rows without being covered', (
    tester,
  ) async {
    final capture = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: capture,
            child: SizedBox(
              width: 200,
              height: 200,
              child: SingleChildScrollView(
                child: TilePaintLayer(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          children: [
                            SizedBox(
                              width: 100,
                              child: RaisedTile(
                                raised: true,
                                child: Transform.translate(
                                  offset: const Offset(0, 80),
                                  child: const ColoredBox(color: Colors.red),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: const [
                            SizedBox(
                              width: 200,
                              child: ColoredBox(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final at = (160 * image.width + 60) * 4;
      expect(data.getUint8(at), 244);
      expect(data.getUint8(at + 1), 67);
      expect(data.getUint8(at + 2), 54);
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
  testWidgets('selected tile paints above later rows and cached siblings', (
    tester,
  ) async {
    final capture = GlobalKey();
    final raised = ValueNotifier(true);
    final shift = ValueNotifier(Offset.zero);
    addTearDown(shift.dispose);
    addTearDown(raised.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: capture,
            child: SizedBox(
              width: 200,
              height: 200,
              child: TilePaintLayer(
                child: Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: 100,
                      height: 100,
                      child: RepaintBoundary(
                        child: ValueListenableBuilder<bool>(
                          valueListenable: raised,
                          builder: (_, value, _) => RaisedTile(
                            raised: value,
                            child: ValueListenableBuilder<Offset>(
                              valueListenable: shift,
                              builder: (_, offset, _) => Transform.translate(
                                offset: offset,
                                child: const ColoredBox(color: Colors.red),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 40,
                      top: 40,
                      width: 100,
                      height: 100,
                      child: RepaintBoundary(
                        child: ColoredBox(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    Future<Color> pixel() async {
      final boundary =
          capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
      return (await tester.runAsync(() async {
        final image = await boundary.toImage();
        final data = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final at = (60 * image.width + 60) * 4;
        final color = Color.fromARGB(
          data.getUint8(at + 3),
          data.getUint8(at),
          data.getUint8(at + 1),
          data.getUint8(at + 2),
        );
        image.dispose();
        return color;
      }))!;
    }

    await tester.pump();
    expect((await pixel()).toARGB32(), Colors.red.toARGB32());
    shift.value = const Offset(100, 0);
    await tester.pump();
    expect((await pixel()).toARGB32(), Colors.blue.toARGB32());
    shift.value = Offset.zero;
    await tester.pump();
    expect((await pixel()).toARGB32(), Colors.red.toARGB32());
    raised.value = false;
    await tester.pump();
    expect((await pixel()).toARGB32(), Colors.blue.toARGB32());
    raised.value = true;
    await tester.pump();
    expect((await pixel()).toARGB32(), Colors.red.toARGB32());
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
