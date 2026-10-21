import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/tile_paint_layer.dart';

void main() {
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
