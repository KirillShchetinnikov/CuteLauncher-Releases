import 'dart:ui' show SemanticsAction, Tristate;

import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/theme/launcher_colors.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester,
  Widget child,
  InterfaceStyle skin, {
  Brightness brightness = Brightness.dark,
  double scale = 1,
}) async {
  tester.view.physicalSize = const Size(960, 540);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        brightness: brightness,
        extensions: [InterfaceSkin(skin), const LauncherStyle()],
      ),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(body: child),
    ),
  );
  await tester.pumpAndSettle();
}

BoxDecoration surface(WidgetTester tester, String label) =>
    tester
            .widgetList<Container>(
              find.descendant(
                of: find.ancestor(
                  of: find.text(label),
                  matching: find.byType(FocusableSettingsTile),
                ),
                matching: find.byType(Container),
              ),
            )
            .firstWhere((c) => c.decoration is BoxDecoration)
            .decoration!
        as BoxDecoration;

void main() {
  for (final skin in InterfaceStyle.values) {
    for (final brightness in Brightness.values) {
      testWidgets('focus, saved choice and press differ: $skin $brightness', (
        tester,
      ) async {
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final semantics = tester.ensureSemantics();
        var calls = 0;
        await pump(
          tester,
          SizedBox(
            width: 380,
            child: Column(
              children: [
                SettingsOptionTile(
                  title: const Text('Saved'),
                  selected: true,
                  onPressed: () {},
                ),
                SettingsOptionTile(
                  title: const Text('Target'),
                  selected: false,
                  autofocus: true,
                  onPressed: () => calls++,
                ),
              ],
            ),
          ),
          skin,
          brightness: brightness,
        );
        final saved = tester.getSemantics(find.text('Saved'));
        final target = tester.getSemantics(find.text('Target'));
        expect((saved.flagsCollection.isSelected == Tristate.isTrue), isTrue);
        expect((target.flagsCollection.isSelected == Tristate.isTrue), isFalse);
        expect((target.flagsCollection.isFocused == Tristate.isTrue), isTrue);
        expect(target.flagsCollection.isButton, isTrue);
        expect(
          (surface(tester, 'Saved').border! as Border).top.color.a,
          lessThan(1),
        );
        final targetBorder = (surface(tester, 'Target').border! as Border).top;
        final colors = Theme.of(tester.element(find.text('Target')))
            .colorScheme;
        expect(targetBorder.width, skin == InterfaceStyle.calm ? 2.5 : 1.5);
        expect(targetBorder.color, colors.primary);
        expect(find.byIcon(Icons.check), findsOneWidget);
        final before = surface(tester, 'Target');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(surface(tester, 'Target'), isNot(before));
        await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(calls, 1);
        semantics.dispose();
        expect(tester.takeException(), isNull);
      });
    }
    for (final value in [false, true]) {
      for (final enabled in [false, true]) {
        testWidgets('switch semantics once: $skin $value $enabled', (
          tester,
        ) async {
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final semantics = tester.ensureSemantics();
          var calls = 0;
          await pump(
            tester,
            SizedBox(
              width: 380,
              child: RoundedSwitchListTile(
                title: const Text('Switch'),
                value: value,
                enabled: enabled,
                autofocus: enabled,
                onChanged: (_) => calls++,
              ),
            ),
            skin,
          );
          final node = tester.getSemantics(find.text('Switch'));
          expect(node.label, 'Switch');
          expect((node.flagsCollection.isToggled != Tristate.none), isTrue);
          expect((node.flagsCollection.isToggled == Tristate.isTrue), value);
          expect((node.flagsCollection.isEnabled == Tristate.isTrue), enabled);
          expect(node.flagsCollection.isButton, isFalse);
          expect(
            node.getSemanticsData().hasAction(SemanticsAction.tap),
            enabled,
          );
          await tester.tap(find.text('Switch'));
          await tester.pumpAndSettle();
          expect(calls, enabled ? 1 : 0);
          semantics.dispose();
        });
      }
    }
  }

  testWidgets('slider has one named adjustable node and bounds its actions', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final semantics = tester.ensureSemantics();
    num value = 0;
    await pump(
      tester,
      StatefulBuilder(
        builder: (context, setState) => SizedBox(
          width: 380,
          child: SettingsSliderTile(
            title: 'Size',
            options: const [0, 1, 2],
            value: value,
            label: (v) => '$v',
            autofocus: true,
            onChanged: (v) => setState(() => value = v),
          ),
        ),
      ),
      InterfaceStyle.standard,
    );
    expect(find.bySemanticsLabel('Size'), findsOneWidget);
    var node = tester.getSemantics(find.bySemanticsLabel('Size'));
    expect(node.getSemanticsData().label, 'Size');
    expect(node.getSemanticsData().value, '0');
    expect(
      (node.getSemanticsData().flagsCollection.isFocused == Tristate.isTrue),
      isTrue,
    );
    expect(
      node.getSemanticsData().hasAction(SemanticsAction.decrease),
      isFalse,
    );
    tester.binding.renderViews.single.owner!.semanticsOwner!.performAction(
      node.id,
      SemanticsAction.increase,
    );
    await tester.pumpAndSettle();
    node = tester.getSemantics(find.bySemanticsLabel('Size'));
    expect(value, 1);
    expect(node.getSemanticsData().value, '1');
    semantics.dispose();
  });

  testWidgets('both side panels stay inside TV safe area at large text', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final right in [false, true]) {
      await pump(
        tester,
        SidePanelDialog(
          isRightSide: right,
          width: 380,
          child: const Text('Параметры главного экрана'),
        ),
        InterfaceStyle.glass,
        scale: 1.6,
      );
      final panel = tester.getRect(find.text('Параметры главного экрана'));
      expect(panel.left, greaterThanOrEqualTo(48));
      expect(panel.right, lessThanOrEqualTo(912));
      expect(panel.top, greaterThanOrEqualTo(27));
      expect(panel.bottom, lessThanOrEqualTo(513));
      expect(tester.takeException(), isNull);
    }
  });

  test(
    'accent text and card roles remain readable on their opaque surfaces',
    () {
      for (final accent in [
        Colors.black,
        Colors.white,
        Colors.yellow,
        Colors.blue,
        const Color(0xff9674ff),
        const Color(0xff777777),
      ]) {
        expect(
          LauncherColors.contrast(LauncherColors.onAccent(accent), accent),
          greaterThanOrEqualTo(4.5),
        );
      }
      for (final foreground in [
        const Color(0xfff4f5f8),
        const Color(0xffb9bfcd),
      ]) {
        expect(
          LauncherColors.contrast(foreground, const Color(0xff1c2029)),
          greaterThanOrEqualTo(4.5),
        );
      }
    },
  );

  testWidgets('long dialog actions stack and primary differs from cancel', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await pump(
      tester,
      Builder(
        builder: (context) => Theme(
          data: launcherDialogTheme(context),
          child: LauncherAlertDialog(
            title: const Text('Подтверждение'),
            content: const Text('Длинные подписи сохраняют читаемость'),
            actions: [
              LauncherDialogButton(
                autofocus: true,
                onPressed: () {},
                child: const Text('Отмена без изменения настроек'),
              ),
              LauncherDialogButton(
                primary: true,
                onPressed: () {},
                child: const Text(
                  'Применить выбранные параметры ко всем разделам',
                ),
              ),
            ],
          ),
        ),
      ),
      InterfaceStyle.standard,
      scale: 1.6,
    );
    final buttons = find.byType(TextButton);
    expect(
      tester.getRect(buttons.first).bottom,
      lessThanOrEqualTo(tester.getRect(buttons.last).top),
    );
    final a = tester
        .widget<TextButton>(buttons.first)
        .style!
        .backgroundColor!
        .resolve({});
    final b = tester
        .widget<TextButton>(buttons.last)
        .style!
        .backgroundColor!
        .resolve({});
    expect(a, isNot(b));
    expect(tester.takeException(), isNull);
  });
}
