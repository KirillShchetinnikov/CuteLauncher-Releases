import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/settings_checkbox_tile.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui_components_test.dart' as components;

void main() {
  for (final brightness in Brightness.values) {
    for (final enabled in [true, false]) {
      testWidgets(
        'Calm controls follow accent changes: $brightness enabled=$enabled',
        (tester) async {
          for (final accent in [Colors.teal, Colors.deepOrange]) {
            final colors = ColorScheme.fromSeed(
              seedColor: accent,
              brightness: brightness,
            ).copyWith(primary: accent);
            const skin = InterfaceSkin(InterfaceStyle.calm);
            final theme = skin.apply(
              ThemeData(
                colorScheme: colors,
                extensions: const [skin, LauncherStyle()],
              ),
            );
            await tester.pumpWidget(
              MaterialApp(
                theme: theme,
                home: Scaffold(
                  body: SizedBox(
                    width: 380,
                    child: Column(
                      children: [
                        SettingsOptionTile(
                          title: const Text('Choice'),
                          selected: true,
                          autofocus: true,
                          enabled: enabled,
                          onPressed: () {},
                        ),
                        SettingsCheckboxTile(
                          title: const Text('Checked'),
                          value: true,
                          enabled: enabled,
                          onChanged: (_) {},
                        ),
                        RoundedSwitchListTile(
                          title: const Text('On'),
                          value: true,
                          enabled: enabled,
                          onChanged: (_) {},
                        ),
                        RoundedSwitchListTile(
                          title: const Text('Off'),
                          value: false,
                          enabled: enabled,
                          onChanged: (_) {},
                        ),
                        LauncherDialogButton(
                          onPressed: enabled ? () {} : null,
                          child: const Text('Action'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final border =
                (components.surface(tester, 'Choice').border! as Border).top;
            expect(border.color, enabled ? accent : Colors.transparent);
            expect(border.width, 2.5);
            final check = tester.widget<Icon>(find.byIcon(Icons.check));
            final checkbox = tester.widget<Icon>(find.byIcon(Icons.check_box));
            expect(check.color, enabled ? accent : theme.disabledColor);
            expect(checkbox.color, enabled ? accent : theme.disabledColor);
            BoxDecoration switchSurface(String label) => tester
                .widgetList<Container>(
                  find.descendant(
                    of: find.descendant(
                      of: find.widgetWithText(RoundedSwitchListTile, label),
                      matching: find.byType(SkinSwitch),
                    ),
                    matching: find.byType(Container),
                  ),
                )
                .map((c) => c.decoration)
                .whereType<BoxDecoration>()
                .firstWhere((d) => d.gradient != null);
            expect(switchSurface('On').color, accent);
            expect(
              switchSurface('Off').color,
              colors.onSurface.withValues(alpha: .2),
            );
            final button = tester.widget<TextButton>(
              find.widgetWithText(TextButton, 'Action'),
            );
            expect(
              button.style!.side!.resolve({WidgetState.focused})!.color,
              theme.colorScheme.onSurface,
            );
            expect(
              button.style!.backgroundColor!.resolve({WidgetState.focused}),
              accent.withValues(alpha: .18),
            );
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }
}
