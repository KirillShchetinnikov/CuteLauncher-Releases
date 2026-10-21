import 'package:flauncher/widgets/focus_keyboard_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final key in [LogicalKeyboardKey.select, LogicalKeyboardKey.info]) {
    testWidgets(
      'holding ${key.keyLabel} fires the menu once until a new press',
      (tester) async {
        var menus = 0;
        var presses = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: FocusKeyboardListener(
              onLongPress: (_) {
                menus++;
                return KeyEventResult.handled;
              },
              onPressed: (_) {
                presses++;
                return KeyEventResult.handled;
              },
              builder: (_) => const Focus(autofocus: true, child: SizedBox()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.sendKeyDownEvent(key);
        await tester.pump(const Duration(milliseconds: 500));
        expect(menus, 1);
        for (var i = 0; i < 3; i++) {
          await tester.sendKeyRepeatEvent(key);
          await tester.pump(const Duration(milliseconds: 600));
          expect(menus, 1);
        }
        await tester.sendKeyUpEvent(key);
        expect(presses, 0);
        await tester.sendKeyDownEvent(key);
        await tester.pump(const Duration(milliseconds: 500));
        expect(menus, 2);
        await tester.sendKeyUpEvent(key);
        await tester.sendKeyEvent(LogicalKeyboardKey.select);
        expect(presses, 1);
      },
    );
  }
}
