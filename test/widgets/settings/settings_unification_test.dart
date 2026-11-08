import 'dart:ui' show SemanticsAction, Tristate, CheckedState;

import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/theme/launcher_colors.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/settings_checkbox_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../ui_components_test.dart' as components;

void main() {
  for (final skin in InterfaceStyle.values) {
    for (final enabled in [false, true]) {
      for (final checked in [false, true]) {
        testWidgets(
          'checkbox has one checked action: $skin $enabled $checked',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            var calls = 0;
            await components.pump(
              tester,
              SizedBox(
                width: 380,
                child: SettingsCheckboxTile(
                  title: const Text('Application'),
                  value: checked,
                  enabled: enabled,
                  autofocus: true,
                  onChanged: (value) {
                    expect(value, !checked);
                    calls++;
                  },
                ),
              ),
              skin,
            );
            final node = tester.getSemantics(find.text('Application'));
            expect(node.label, 'Application');
            expect(
              node.getSemanticsData().flagsCollection.isChecked ==
                  CheckedState.isTrue,
              checked,
            );
            expect(
              node.getSemanticsData().flagsCollection.isEnabled ==
                  Tristate.isTrue,
              enabled,
            );
            expect(node.getSemanticsData().flagsCollection.isButton, isFalse);
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.tap),
              enabled,
            );
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            expect(calls, enabled ? 1 : 0);
            await tester.tap(find.text('Application'));
            await tester.pumpAndSettle();
            expect(calls, enabled ? 2 : 0);
            semantics.dispose();
          },
        );
      }
      for (final below in [false, true]) {
        testWidgets(
          'stepper merges label, value and focus: $skin $enabled below=$below',
          (tester) async {
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            final semantics = tester.ensureSemantics();
            dynamic value;
            await components.pump(
              tester,
              StatefulBuilder(
                builder: (context, setState) => SizedBox(
                  width: 380,
                  child: SettingsValueStepper(
                    title: 'Count',
                    leading: const Icon(
                      Icons.numbers,
                      semanticLabel: 'Decorative',
                    ),
                    options: const [null, 1, 2],
                    value: value,
                    label: (v) => v == null ? 'Automatic' : '$v',
                    enabled: enabled,
                    autofocus: true,
                    valueBelow: below,
                    onChanged: (v) => setState(() => value = v),
                  ),
                ),
              ),
              skin,
            );
            expect(find.bySemanticsLabel('Count'), findsOneWidget);
            var node = tester.getSemantics(find.bySemanticsLabel('Count'));
            expect(node.getSemanticsData().label, 'Count');
            expect(node.getSemanticsData().value, 'Automatic');
            expect(
              node.getSemanticsData().flagsCollection.isFocused ==
                  Tristate.isTrue,
              enabled,
            );
            expect(
              node.getSemanticsData().flagsCollection.isEnabled ==
                  Tristate.isTrue,
              enabled,
            );
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.increase),
              enabled,
            );
            expect(
              node.getSemanticsData().hasAction(SemanticsAction.decrease),
              isFalse,
            );
            if (enabled) {
              tester.binding.renderViews.single.owner!.semanticsOwner!
                  .performAction(node.id, SemanticsAction.increase);
              await tester.pumpAndSettle();
              expect(value, 1);
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
              await tester.pumpAndSettle();
              node = tester.getSemantics(find.bySemanticsLabel('Count'));
              expect(value, 2);
              expect(
                node.getSemanticsData().hasAction(SemanticsAction.increase),
                isFalse,
              );
              expect(
                node.getSemanticsData().hasAction(SemanticsAction.decrease),
                isTrue,
              );
            }
            semantics.dispose();
          },
        );
      }
    }
  }
  test('all palette marks use contrast of at least 4.5:1', () {
    for (final value in appearancePalette) {
      final color = Color(value);
      expect(
        LauncherColors.contrast(LauncherColors.onAccent(color), color),
        greaterThanOrEqualTo(4.5),
      );
    }
  });
}
