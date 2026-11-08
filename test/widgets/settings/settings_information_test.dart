import 'package:flauncher/widgets/settings/settings_information.dart';
import 'package:flauncher/widgets/settings/settings_read_only_value.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const hint = '◄ / ► — выбрать; ▲ / ▼ — переместить; OK / Back — закончить.';
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.5, 2.0]) {
      testWidgets(
        'information wraps and skips remote focus $direction $scale',
        (tester) async {
          final first = FocusNode();
          final last = FocusNode();
          addTearDown(first.dispose);
          addTearDown(last.dispose);
          const foreground = Color(0xffb8efd2);
          await tester.pumpWidget(
            MaterialApp(
              theme: ThemeData.dark().copyWith(
                colorScheme: const ColorScheme.dark(onSurface: foreground),
              ),
              home: Scaffold(
                body: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Directionality(
                    textDirection: direction,
                    child: DefaultTextStyle(
                      style: const TextStyle(
                        color: foreground,
                        fontSize: 16,
                        height: 1.5,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: SizedBox(
                          width: 300,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                TextButton(
                                  focusNode: first,
                                  onPressed: () {},
                                  child: const Text('first'),
                                ),
                                const SettingsControlHint(text: hint),
                                const SettingsReadOnlyValue(
                                  label: 'Полностью видимых строк',
                                  value: '3',
                                  wrapLines: true,
                                ),
                                const SettingsMessage(
                                  text: 'Нет данных о рассвете и закате. Выберите город.',
                                  kind: SettingsMessageKind.warning,
                                ),
                                const SettingsEmptyState(
                                  text: 'Карточек пока нет',
                                  icon: Icons.video_library_outlined,
                                ),
                                TextButton(
                                  focusNode: last,
                                  onPressed: () {},
                                  child: const Text('last'),
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
          first.requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
          expect(last.hasFocus, isTrue);
          expect(tester.takeException(), isNull);
          expect(find.text(hint), findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.text(hint),
              matching: find.byType(RichText),
            ),
          );
          expect(paragraph.text.toPlainText(), hint);
          expect((paragraph.text as TextSpan).style!.color, foreground);
          expect(paragraph.didExceedMaxLines, isFalse);
          final rendered = paragraph.text.toPlainText(
            includeSemanticsLabels: false,
          );
          final keysAt = rendered.indexOf('▲\u00a0/\u00a0▼');
          expect(keysAt, greaterThanOrEqualTo(0));
          final keyBoxes = paragraph.getBoxesForSelection(
            TextSelection(baseOffset: keysAt, extentOffset: keysAt + 5),
          );
          expect(keyBoxes, isNotEmpty);
          for (final box in keyBoxes) {
            expect(box.top, closeTo(keyBoxes.first.top, .01));
          }

          final label = tester.getRect(find.text('Полностью видимых строк'));
          final value = tester.getRect(find.text('3'));
          expect(
            direction == TextDirection.ltr
                ? label.right < value.left
                : value.right < label.left,
            isTrue,
          );
        },
      );
    }
  }

  testWidgets(
    'messages announce errors without button semantics or icon duplicates',
    (tester) async {
      final semantics = tester.ensureSemantics();

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                SettingsMessage(
                  text: 'Не удалось обновить погоду',
                  kind: SettingsMessageKind.error,
                ),
                SettingsMessage(text: 'Используются сохранённые данные'),
              ],
            ),
          ),
        ),
      );
      final error = tester.getSemantics(find.byType(SettingsMessage).first);
      expect(
        error,
        matchesSemantics(
          label: 'Не удалось обновить погоду',
          isLiveRegion: true,
        ),
      );
      expect(
        tester.getSemantics(find.byType(SettingsMessage).last),
        matchesSemantics(label: 'Используются сохранённые данные'),
      );
      expect(
        find.descendant(
          of: find.byType(SettingsMessage),
          matching: find.byType(Focus),
        ),
        findsNothing,
      );
      semantics.dispose();
    },
  );
}
