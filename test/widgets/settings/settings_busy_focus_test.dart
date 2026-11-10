import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_checkbox_tile.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final kind in [
    'action',
    'switch',
    'checkbox',
    'choice',
    'text',
    'stepper',
    'slider',
  ]) {
    testWidgets(
      '$kind keeps focus while busy and never steals it on completion',
      (tester) async {
        var busy = false;
        var calls = 0;
        late StateSetter rebuild;
        Widget control() => switch (kind) {
          'switch' => RoundedSwitchListTile(
            title: const Text('Setting'),
            value: false,
            busy: busy,
            onChanged: (_) => calls++,
          ),
          'checkbox' => SettingsCheckboxTile(
            title: const Text('Setting'),
            value: false,
            busy: busy,
            onChanged: (_) => calls++,
          ),
          'choice' => SettingsChoiceTile<int>(
            title: 'Setting',
            value: 0,
            options: const [0, 1],
            label: (v) => '$v',
            busy: busy,
            onChanged: (_) => calls++,
          ),
          'text' => SettingsTextTile(
            title: 'Setting',
            value: '',
            busy: busy,
            onChanged: (_) => calls++,
          ),
          'stepper' => SettingsValueStepper(
            title: 'Setting',
            value: 0,
            options: const [0, 1],
            label: (v) => '$v',
            busy: busy,
            onChanged: (_) => calls++,
          ),
          'slider' => SettingsSliderTile(
            title: 'Setting',
            value: 0,
            options: const [0, 1],
            label: (v) => '$v',
            busy: busy,
            onChanged: (_) => calls++,
          ),
          _ => FocusableSettingsTile(
            title: const Text('Setting'),
            busy: busy,
            onPressed: () => calls++,
          ),
        };
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  return SettingsPageLayout(
                    title: const Text('Page'),
                    child: ListView(
                      children: [
                        control(),
                        FocusableSettingsTile(
                          title: const Text('Next'),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final original = FocusManager.instance.primaryFocus;
        rebuild(() => busy = true);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(original));
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.tap(find.text('Setting'));
        await tester.pumpAndSettle();
        expect(calls, 0);
        expect(find.byType(Dialog), findsNothing);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text('Next'))).hasFocus, isTrue);
        rebuild(() => busy = false);
        await tester.pumpAndSettle();
        expect(Focus.of(tester.element(find.text('Next'))).hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(FocusManager.instance.primaryFocus, same(original));
      },
    );
  }

  testWidgets('clicking the switch itself focuses its owning row', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Column(
            children: [
              FocusableSettingsTile(
                autofocus: true,
                title: const Text('Other'),
                onPressed: () {},
              ),
              RoundedSwitchListTile(
                title: const Text('Switch'),
                value: false,
                onChanged: (_) => calls++,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(Focus.of(tester.element(find.text('Switch'))).hasFocus, isTrue);
  });
}
