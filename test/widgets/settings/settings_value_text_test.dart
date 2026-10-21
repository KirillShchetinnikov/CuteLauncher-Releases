import 'package:flauncher/widgets/settings/settings_value_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
