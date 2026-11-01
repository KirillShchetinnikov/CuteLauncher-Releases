import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('focusing a fully visible row does not restart scrolling', (
    tester,
  ) async {
    final controller = ScrollController();
    final nodes = List.generate(30, (_) => FocusNode());
    addTearDown(controller.dispose);
    addTearDown(() {
      for (final node in nodes) {
        node.dispose();
      }
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 400,
            child: ListView.builder(
              controller: controller,
              itemExtent: 80,
              itemCount: nodes.length,
              itemBuilder: (_, i) => FocusableSettingsTile(
                focusNode: nodes[i],
                title: Text('Row $i'),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(400);
    await tester.pumpAndSettle();
    nodes[6].requestFocus();
    await tester.pumpAndSettle();
    expect(nodes[6].hasFocus, isTrue);
    expect(controller.offset, 400);
    nodes[7].requestFocus();
    await tester.pumpAndSettle();
    expect(controller.offset, 400);
  });

  testWidgets('remote reaches both ends of a lazy settings list', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 350,
            height: 400,
            child: SettingsPageLayout(
              title: const Text('Menu'),
              child: ListView.builder(
                itemCount: 80,
                itemBuilder: (_, i) => FocusableSettingsTile(
                  title: Text('Row $i'),
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    String? focusedRow() =>
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<FocusableSettingsTile>()
                ?.title
            is Text
        ? (FocusManager.instance.primaryFocus!.context!
                      .findAncestorWidgetOfExactType<FocusableSettingsTile>()!
                      .title
                  as Text)
              .data
        : null;
    expect(focusedRow(), 'Row 0');
    for (var i = 0; i < 100; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    expect(focusedRow(), 'Row 79');
    for (var i = 0; i < 100; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
    }
    expect(focusedRow(), 'Row 0');
    expect(tester.takeException(), isNull);
  });
}
