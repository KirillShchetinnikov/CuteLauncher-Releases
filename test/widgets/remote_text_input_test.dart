import 'dart:async';

import 'package:flauncher/widgets/remote_text_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'floating IME receives remote keys and hidden IME restores traversal',
    (tester) async {
      final events = StreamController<bool>(sync: true);
      final editor = FocusNode();
      final save = FocusNode();
      final focusChanges = <bool>[];
      addTearDown(() {
        editor.dispose();
        save.dispose();
        events.close();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RemoteTextInput(
                  imeVisibility: events.stream,
                  onEditorFocusChanged: focusChanges.add,
                  child: TextField(focusNode: editor, autofocus: true),
                ),
                TextButton(
                  focusNode: save,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(focusChanges, [true]);
      Future<void> visibility(bool value) async {
        events.add(value);
        await tester.pump();
      }

      await visibility(true);
      expect(tester.view.viewInsets.bottom, 0);
      for (final key in [
        LogicalKeyboardKey.arrowDown,
        LogicalKeyboardKey.arrowUp,
        LogicalKeyboardKey.arrowLeft,
        LogicalKeyboardKey.arrowRight,
        LogicalKeyboardKey.select,
        LogicalKeyboardKey.enter,
      ]) {
        expect(
          await tester.sendKeyEvent(key),
          isFalse,
          reason: '$key must reach Android',
        );
        await tester.pump();
        expect(editor.hasFocus, isTrue);
        expect(save.hasFocus, isFalse);
      }
      await visibility(false);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(save.hasFocus, isTrue);
      expect(focusChanges, [true, false]);
      editor.requestFocus();
      await tester.pump();
      expect(focusChanges, [true, false, true]);
      await tester.pumpWidget(const SizedBox());
      expect(focusChanges.last, isFalse);
    },
  );
}
