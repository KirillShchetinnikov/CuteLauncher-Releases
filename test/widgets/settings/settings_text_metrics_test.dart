import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/design_fixture.dart';

void main() {
  for (final font in ['Manrope', 'Google Sans', 'Onest']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('glass labels keep full $font metrics at scale $scale', (
        tester,
      ) async {
        await loadDesignFonts(tester);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            theme: const InterfaceSkin(InterfaceStyle.glass).apply(
              ThemeData.dark().copyWith(
                textTheme: ThemeData.dark().textTheme.copyWith(
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
                  builder: (_) => Center(
                    child: SizedBox(
                      width: 380,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
        for (final element in find.byType(Text).evaluate()) {
          final paragraph = element.renderObject as RenderParagraph;
          final text = (element.widget as Text).data!;
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
      });
    }
  }
}
