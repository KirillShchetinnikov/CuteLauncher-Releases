import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Counts visible dimming layers, including the barriers of parent routes.
void expectSinglePanelBackdrop(WidgetTester tester, {double top = 0}) {
  final colors = [
    for (final barrier in tester.widgetList<ModalBarrier>(
      find.byType(ModalBarrier),
    ))
      if (barrier.color != null && barrier.color!.a > 0) barrier.color!,
    for (final box in tester.widgetList<ColoredBox>(
      find.descendant(
        of: find.byType(LauncherPanelBackdrop),
        matching: find.byType(ColoredBox),
      ),
    ))
      box.color,
  ];
  expect(colors, [Colors.black.withValues(alpha: .5)]);
  if (find.byType(LauncherPanelBackdrop).evaluate().isNotEmpty) {
    expect(tester.getTopLeft(find.byType(LauncherPanelBackdrop)).dy, top);
  }
}
