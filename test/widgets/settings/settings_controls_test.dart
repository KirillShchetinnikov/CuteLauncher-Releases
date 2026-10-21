import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flauncher/widgets/settings/settings_time_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(
  WidgetTester tester,
  Widget Function(StateSetter) content,
) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: StatefulBuilder(builder: (_, state) => content(state)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void focus(WidgetTester tester, String title) =>
    Focus.of(tester.element(find.text(title).first)).requestFocus();

void main() {
  testWidgets('choice values keep the arrow at the same right edge', (tester) async {
    Future<double> arrowRight(String value) async {
      await pump(tester, (_) => Center(
        child: SizedBox(width: 320, child: SettingsChoiceTile<String>(
          title: 'Выбор',
          value: value,
          options: [value],
          label: (v) => v,
          onChanged: (_) {},
        )),
      ));
      expect(tester.widget<Text>(find.text(value)).textAlign, TextAlign.end);
      expect(tester.takeException(), isNull);
      return tester.getRect(find.byIcon(Icons.chevron_right_rounded)).right;
    }

    final shortRight = await arrowRight('Да');
    final longRight = await arrowRight('Ничего не делать');
    expect(longRight, closeTo(shortRight, 0.01));
  });

  testWidgets(
    'small numeric choices stop at endpoints and vertical movement preserves value',
    (tester) async {
      var value = 1;
      await pump(
        tester,
        (state) => ListView(
          children: [
            SettingsValueStepper(
              title: 'Колонки',
              options: const [1, 2, 3],
              value: value,
              label: (v) => '$v',
              autofocus: true,
              onChanged: (v) => state(() => value = v as int),
            ),
            FocusableSettingsTile(
              title: const Text('Следующая'),
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(find.byType(Slider), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(value, 1);
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
      }
      expect(value, 3);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(value, 3);
      expect(Focus.of(tester.element(find.text('Следующая'))).hasFocus, isTrue);
    },
  );

  testWidgets(
    'large uneven numeric presets use slider and only one focus target',
    (tester) async {
      const options = [
        80,
        90,
        100,
        110,
        120,
        130,
        135,
        140,
        150,
        160,
        170,
        180,
      ];
      num value = 135;
      await pump(
        tester,
        (state) => ListView(
          children: [
            SettingsValueStepper(
              title: 'Размер',
              options: options,
              value: value,
              label: (v) => '$v dp',
              autofocus: true,
              onChanged: (v) => state(() => value = v as num),
            ),
            FocusableSettingsTile(
              title: const Text('Следующая'),
              onPressed: () {},
            ),
          ],
        ),
      );
      expect(find.byType(Slider), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(value, 140);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Следующая'))).hasFocus, isTrue);
      expect(value, 140);
    },
  );

  testWidgets('named options open a selected list and restore focus', (
    tester,
  ) async {
    var value = 'Ряд';
    await pump(
      tester,
      (state) => SettingsValueStepper(
        title: 'Размещение',
        options: const ['Ряд', 'Сетка'],
        value: value,
        label: (v) => '$v',
        autofocus: true,
        onChanged: (v) => state(() => value = v as String),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(value, 'Ряд');
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'Сетка');
    expect(Focus.of(tester.element(find.text('Размещение'))).hasFocus, isTrue);
  });

  testWidgets(
    'text exists only in editor, cancel and save preserve focus and resources',
    (tester) async {
      var value = 'Гостиная';
      await pump(
        tester,
        (state) => SettingsTextTile(
          title: 'Название',
          value: value,
          onChanged: (v) => state(() => value = v),
        ),
      );
      expect(find.byType(TextField), findsNothing);
      focus(tester, 'Название');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Отменено');
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(value, 'Гостиная');
      expect(Focus.of(tester.element(find.text('Название'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Спальня');
      tester.testTextInput.hide();
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(value, 'Спальня');
      expect(find.byType(TextField), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('time edits hours and minutes without saving a cancelled draft', (
    tester,
  ) async {
    var value = 22 * 60 + 17;
    await pump(
      tester,
      (state) => SettingsTimeTile(
        title: 'Начало',
        value: value,
        onChanged: (v) => state(() => value = v),
      ),
    );
    await tester.tap(find.text('Начало'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(value, 22 * 60 + 17);
    await tester.tap(find.text('Начало'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(value, 22 * 60 + 18);
  });

  testWidgets(
    'switch has one remote stop, password is masked and disabled values do not change',
    (tester) async {
      var checked = false;
      var changed = false;
      await pump(
        tester,
        (state) => ListView(
          children: [
            RoundedSwitchListTile(
              title: const Text('Звук'),
              secondary: const Icon(Icons.volume_up),
              autofocus: true,
              value: checked,
              onChanged: (v) => state(() => checked = v),
            ),
            SettingsTextTile(
              title: 'Пароль',
              value: 'secret',
              obscureText: true,
              onChanged: (_) {},
            ),
            SettingsValueStepper(
              title: 'Недоступно',
              options: const [1, 2],
              value: 1,
              enabled: false,
              label: (v) => '$v',
              onChanged: (_) => changed = true,
            ),
          ],
        ),
      );
      expect(find.text('secret'), findsNothing);
      expect(find.text('••••••'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(checked, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text('Пароль'))).hasFocus, isTrue);
      await tester.tap(find.text('Недоступно'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(changed, isFalse);
    },
  );
}
