import 'package:flauncher/widgets/menu_header.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('headers without control hints use less height', (tester) async {
    Future<double> height({Widget? hint}) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: MenuHeader(
                title: const Text('Входы'),
                hint: hint,
                actions: [
                  MenuHeaderAction(
                    tooltip: 'Настройки',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      return tester.getSize(find.byType(MenuHeader)).height;
    }

    final compact = await height();
    expect(compact, 36);
    final expanded = await height(hint: const Text('◄ / OK / ►'));
    expect(expanded, greaterThan(compact));
    expect(tester.getSize(find.byType(IconButton)).height, 36);
    expect(find.text('◄ / OK / ►'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('◄ / OK / ►')).dy,
      greaterThanOrEqualTo(
        tester.getBottomLeft(find.byType(IconButton)).dy + 4,
      ),
    );
    final titleContext = tester.element(find.text('Входы'));
    expect(
      DefaultTextStyle.of(titleContext).style.fontSize,
      Theme.of(titleContext).textTheme.titleLarge!.fontSize,
    );
  });

  testWidgets(
    'compact header grows for large multiline titles and supports focus',
    (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: SingleChildScrollView(
                child: MenuHeader(
                  title: const Text('Очень длинное название виджета'),
                  actions: [
                    MenuHeaderAction(
                      focusNode: node,
                      tooltip: 'Настройки',
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () => pressed = true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      node.requestFocus();
      await tester.pump();
      expect(node.hasFocus, isTrue);
      expect(tester.getSize(find.byType(MenuHeader)).height, greaterThan(48));
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(IconButton));
      expect(pressed, isTrue);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
