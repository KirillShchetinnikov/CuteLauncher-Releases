import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final rtl in [false, true]) {
    for (final scale in [1.0, 1.4]) {
      testWidgets(
        'choice reveals last selection with scrollbar gutter: rtl=$rtl scale=$scale',
        (tester) async {
          tester.view.physicalSize = const Size(960, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          var value = 29;
          await tester.pumpWidget(
            MaterialApp(
              locale: Locale(rtl ? 'ar' : 'ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: StatefulBuilder(
                  builder: (context, setState) => SettingsChoiceTile<int>(
                    title: 'Choice',
                    value: value,
                    options: List.generate(30, (index) => index),
                    label: (value) => 'Option $value',
                    onChanged: (next) => setState(() => value = next),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Choice'));
          await tester.pumpAndSettle();
          final dialog = find.byType(AlertDialog);
          final scroll = find.descendant(
            of: dialog,
            matching: find.byType(SingleChildScrollView),
          );
          expect(scroll, findsOneWidget);
          void expectVisible(int index) {
            final row = find.widgetWithText(
              SettingsOptionTile,
              'Option $index',
            );
            final rect = tester.getRect(row);
            final viewport = tester.getRect(scroll);
            expect(rect.top, greaterThanOrEqualTo(viewport.top - .5));
            expect(rect.bottom, lessThanOrEqualTo(viewport.bottom + .5));
            expect(
              rtl ? rect.left - viewport.left : viewport.right - rect.right,
              greaterThanOrEqualTo(14 - .5),
            );
            expect(
              Focus.of(
                tester.element(
                  find.descendant(
                    of: row,
                    matching: find.text('Option $index'),
                  ),
                ),
              ).hasFocus,
              isTrue,
            );
          }

          expectVisible(29);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expectVisible(28);
          expect(value, 29);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(value, 29);
          expect(
            Focus.of(tester.element(find.text('Choice'))).hasFocus,
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expectVisible(29);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(value, 28);
          expect(dialog, findsNothing);
          expect(
            Focus.of(tester.element(find.text('Choice'))).hasFocus,
            isTrue,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
