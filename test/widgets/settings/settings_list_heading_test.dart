import 'package:flauncher/theme/settings_section_tokens.dart';
import 'package:flauncher/widgets/settings/settings_list_heading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 1.5, 2.0]) {
      for (final long in [false, true]) {
        testWidgets(
          'rule follows final word: $direction scale=$scale long=$long',
          (tester) async {
            final title = direction == TextDirection.ltr
                ? (long ? 'Отображаемые разделы главного экрана' : 'Разделы')
                : (long ? 'الأقسام المعروضة على الشاشة الرئيسية' : 'الأقسام');
            const color = Color(0xffeeeeee);
            await tester.pumpWidget(
              MaterialApp(
                theme: ThemeData(
                  textTheme: const TextTheme(
                    titleMedium: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      height: 1.5,
                      color: color,
                    ),
                  ),
                ),
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: Directionality(
                    textDirection: direction,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: 300,
                        child: SettingsListHeading(title: title),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final paragraphFinder = find.descendant(
              of: find.byType(SettingsListHeading),
              matching: find.byType(RichText),
            );
            final paragraph = tester.renderObject<RenderParagraph>(
              paragraphFinder,
            );
            final lastBox = paragraph
                .getBoxesForSelection(
                  TextSelection(
                    baseOffset: title.length - 1,
                    extentOffset: title.length,
                  ),
                )
                .last;
            final lastWordEdge = paragraph.localToGlobal(
              Offset(
                direction == TextDirection.ltr ? lastBox.right : lastBox.left,
                lastBox.top,
              ),
            );
            final rule = find.byKey(
              const ValueKey('settings-list-heading-rule'),
            );
            final line = tester.getRect(rule);
            const gap = SettingsSectionTokens.listHeadingRuleGap;
            if (direction == TextDirection.ltr) {
              expect(line.left, closeTo(lastWordEdge.dx + gap, 1));
              expect(line.right, closeTo(288, .01));
            } else {
              expect(line.right, closeTo(lastWordEdge.dx - gap, 1));
              expect(line.left, closeTo(12, .01));
            }
            expect(
              line.width,
              greaterThanOrEqualTo(
                SettingsSectionTokens.listHeadingMinRule - 1,
              ),
            );
            expect(line.top, greaterThanOrEqualTo(lastWordEdge.dy));
            expect(
              line.bottom,
              lessThanOrEqualTo(
                paragraph.localToGlobal(Offset(0, lastBox.bottom)).dy,
              ),
            );
            expect(tester.widget<Text>(find.text(title)).style!.color, color);
            expect(
              find.byWidgetPredicate(
                (w) => w is Semantics && w.properties.header == true,
              ),
              findsOneWidget,
            );
            expect(
              find.descendant(
                of: find.byType(SettingsListHeading),
                matching: find.byType(Focus),
              ),
              findsNothing,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('heading does not add a keyboard stop', (tester) async {
    final first = FocusNode(), second = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: Column(
              children: [
                TextButton(
                  focusNode: first,
                  autofocus: true,
                  onPressed: () {},
                  child: const Text('First'),
                ),
                const SettingsListHeading(title: 'Скрытые разделы'),
                TextButton(
                  focusNode: second,
                  onPressed: () {},
                  child: const Text('Second'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(first.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(second.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
}
