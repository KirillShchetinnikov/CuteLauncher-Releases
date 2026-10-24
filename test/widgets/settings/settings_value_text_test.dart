import 'package:flauncher/widgets/settings/settings_value_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Manrope values keep ink clear of paragraph raster bounds', (
    tester,
  ) async {
    final loader = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/manrope.ttf'));
    await loader.load();
    for (final value in ['Все приложения', 'По частоте запусков', 'Слева', 'Справа']) {
      for (final scale in [1.0, 1.5]) {
        for (final offset in [0.0, .25, .5, .75]) {
          final key = GlobalKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Transform.translate(
                    offset: Offset(0, offset),
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        height: 1.3,
                        color: Colors.white,
                      ),
                      textHeightBehavior: const TextHeightBehavior(
                        applyHeightToFirstAscent: false,
                        applyHeightToLastDescent: false,
                      ),
                      child: MediaQuery(
                        data: MediaQueryData(
                          textScaler: TextScaler.linear(scale),
                        ),
                        child: SizedBox(
                          width: 100,
                          child: RepaintBoundary(
                            key: key,
                            child: SettingsValueText(
                              text: Text(value),
                              alignment: TextAlign.end,
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
          final boundary =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 2);
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            var first = image.height;
            var last = -1;
            for (var y = 0; y < image.height; y++) {
              for (var x = 0; x < image.width; x++) {
                if (data.getUint8((y * image.width + x) * 4 + 3) > 128) {
                  if (y < first) first = y;
                  last = y;
                }
              }
            }
            expect(
              first,
              greaterThanOrEqualTo(2),
              reason: '$value / $scale / $offset: top',
            );
            expect(
              last,
              lessThan(image.height - 2),
              reason: '$value / $scale / $offset: bottom',
            );
            image.dispose();
          });
        }
      }
    }
  });
  for (final scale in [1.0, 1.3]) {
    testWidgets('long words remain whole at text scale $scale', (tester) async {
      const value = 'Сверхдлинноеслово Настроено вариант-выбора';
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Center(
              child: SizedBox(
                width: 70,
                child: SettingsValueText(
                  text: Text(value, style: TextStyle(fontSize: 20)),
                  alignment: TextAlign.end,
                ),
              ),
            ),
          ),
        ),
      );
      final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
      expect(
        tester.widget<Text>(find.text(value)).style!.fontSize,
        lessThan(20),
      );
      for (final word in RegExp(r'\S+').allMatches(value)) {
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: word.start, extentOffset: word.end),
        );
        expect(boxes, isNotEmpty);
        expect(
          boxes.every((box) => (box.top - boxes.first.top).abs() < 0.01),
          isTrue,
        );
      }
      expect(paragraph.didExceedMaxLines, isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('short words wrap between words without shrinking', (
    tester,
  ) async {
    const value = 'One two three';
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 110,
            child: SettingsValueText(
              text: Text(value, style: TextStyle(fontSize: 20)),
              alignment: TextAlign.end,
            ),
          ),
        ),
      ),
    );
    expect(tester.widget<Text>(find.text(value)).style!.fontSize, 20);
    final paragraph = tester.renderObject<RenderParagraph>(find.text(value));
    final first = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 0, extentOffset: 3),
    );
    final last = paragraph.getBoxesForSelection(
      const TextSelection(baseOffset: 8, extentOffset: 13),
    );
    expect(last.first.top, greaterThan(first.first.top));
  });
}
