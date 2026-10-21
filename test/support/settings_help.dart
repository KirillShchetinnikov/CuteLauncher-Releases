import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

Future<void> toggleSettingsHelp(WidgetTester tester, String text) async {
  final help = find.byWidgetPredicate(
    (widget) => widget is SettingsHelp && widget.text.contains(text),
  );
  if (help.evaluate().isEmpty) {
    await tester.scrollUntilVisible(
      help,
      160,
      scrollable: find.byType(Scrollable).first,
    );
  }
  final button = find
      .descendant(of: help, matching: find.byType(FocusableSettingsTile))
      .first;
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
  await tester.pumpAndSettle();
}
