import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/design_fixture.dart';

void main() {
  for (final font in ['Manrope', 'Google Sans', 'Onest', 'Outfit', 'Roboto']) {
    for (final scale in [1.0, 1.3, 1.6]) {
      testWidgets('glass labels keep full $font metrics at scale $scale', (
        tester,
      ) async {
        await loadDesignFonts(tester);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            theme: const InterfaceSkin(InterfaceStyle.glass).apply(
              ThemeData.dark().copyWith(
                textTheme: ThemeData.dark().textTheme
                    .apply(fontFamily: font)
                    .copyWith(
                      bodyMedium: TextStyle(
                        fontFamily: font,
                        fontSize: 22,
                        height: 1.3,
                      ),
                    ),
              ),
            ),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: SettingsPanelStyle(
                  builder: (context) => Center(
                    child: SizedBox(
                      width: 380,
                      child: ListView(
                        children: [
                          Text(
                            'Кнопка Home и запуск',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const Text('Доступ к специальным возможностям'),
                          const Text('Отключено'),
                          FocusableSettingsTile(
                            title: const Text(
                              'Перейти в специальные возможности',
                            ),
                            leading: const Icon(Icons.accessibility_new),
                            onPressed: () {},
                          ),
                          FocusableSettingsTile(
                            title: const Text(
                              'Включить службу специальных возможностей CuteLauncher через ADB',
                            ),
                            onPressed: () {},
                          ),
                          RoundedSwitchListTile(
                            title: const Text('Переопределять кнопку Home'),
                            value: false,
                            onChanged: (_) {},
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Применить настройки'),
                          ),
                          FocusableSettingsTile(
                            title: const Text('Имя'),
                            trailing: const Text('Все приложения'),
                            onPressed: () {},
                          ),
                          FocusableSettingsTile(
                            title: const Text('Сортировать'),
                            trailing: const Text('По частоте запусков'),
                            onPressed: () {},
                          ),
                          FocusableSettingsTile(
                            title: const Text('Оформление раздела'),
                            leading: const Icon(Icons.palette_outlined),
                            onPressed: () {},
                          ),
                          FocusableSettingsTile(
                            title: const Text('Показывать раздел'),
                            trailing: const Icon(Icons.check),
                            onPressed: () {},
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
        await tester.pumpAndSettle();
        // Every row is built and checked after scrolling and a focus repaint.
        for (final label in [
          'Кнопка Home и запуск',
          'Перейти в специальные возможности',
          'Включить службу специальных возможностей CuteLauncher через ADB',
          'Переопределять кнопку Home',
          'Применить настройки',
          'Имя',
          'Сортировать',
          'Оформление раздела',
          'Показывать раздел',
        ]) {
          await tester.scrollUntilVisible(find.text(label), 80);
          await tester.pumpAndSettle();
          final tile = find.ancestor(
            of: find.text(label),
            matching: find.byType(FocusableSettingsTile),
          );
          if (tile.evaluate().isNotEmpty) {
            Focus.of(tester.element(find.text(label))).requestFocus();
            await tester.pumpAndSettle();
          }
          for (final element in find.byType(Text).evaluate()) {
            final paragraph = element.renderObject as RenderParagraph;
            final text = (element.widget as Text).data!;
            if (font == 'Manrope') {
              final style = paragraph.text.style!;
              expect(style.height, greaterThanOrEqualTo(1.5), reason: text);
              expect(
                paragraph.textHeightBehavior?.applyHeightToFirstAscent ?? true,
                isTrue,
                reason: text,
              );
              expect(
                paragraph.textHeightBehavior?.applyHeightToLastDescent ?? true,
                isTrue,
                reason: text,
              );
            }
            final boxes = paragraph.getBoxesForSelection(
              TextSelection(baseOffset: 0, extentOffset: text.length),
            );
            expect(boxes, isNotEmpty);
            for (final box in boxes) {
              // Paragraph baselines round to pixels; allow half a logical pixel.
              expect(box.top, greaterThanOrEqualTo(-0.5), reason: text);
              expect(
                box.bottom,
                lessThanOrEqualTo(paragraph.size.height + 0.5),
                reason: text,
              );
            }
            expect(paragraph.didExceedMaxLines, isFalse, reason: text);
          }
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
}
