import 'dart:ui' as ui;
import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flauncher/weather_format_template.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/weather_text_format_dialog.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/weather_display_text.dart';
import 'package:flauncher/widgets/weather_glyph.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    bool singleLine = false,
    double scale = 1,
    Locale locale = const Locale('ru'),
    WeatherTextFormat? format,
    Stream<bool>? imeVisibility,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              child: const Text('open'),
              onPressed: () => showLauncherDialog<WeatherTextFormat>(
                context: context,
                builder: (_) => WeatherTextFormatDialog(
                  format: format ?? WeatherTextFormat.standard,
                  fahrenheit: false,
                  singleLine: singleLine,
                  imeVisibility: imeVisibility,
                  weather: const WeatherData(
                    currentTemp: 6,
                    feelsLikeTemp: 2,
                    currentConditionCode: 803,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  final input = find.byKey(const Key('weather_format_input'));
  final firstInsert = find.byKey(
    const ValueKey('weather_format_add_temperature'),
  );

  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'reset restores a valid draft and keeps footer navigation: $locale',
      (tester) async {
        await mount(tester, locale: locale, scale: 1.5);
        await tester.tap(input);
        await tester.enterText(input, '{UNKNOWN}');
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('weather_format_error')), findsOneWidget);
        final reset = find.byKey(const Key('weather_format_reset'));
        await tester.tap(reset);
        await tester.pumpAndSettle();
        final expected = weatherFormatTemplate(
          WeatherTextFormat.standard,
          russian: locale.languageCode == 'ru',
          warnings: true,
        );
        final controller = tester.widget<TextField>(input).controller!;
        expect(controller.text, expected);
        expect(
          controller.selection,
          TextSelection.collapsed(offset: expected.length),
        );
        expect(find.byKey(const Key('weather_format_error')), findsNothing);
        expect(
          tester.widget<LauncherDialogButton>(reset).focusNode!.hasFocus,
          isTrue,
        );
        final save = find.byKey(const Key('weather_format_save'));
        final cancelLabel = MaterialLocalizations.of(tester.element(input))
            .cancelButtonLabel;
        final cancel = find.widgetWithText(LauncherDialogButton, cancelLabel);
        expect(
          tester.getRect(reset).center.dy,
          tester.getRect(cancel).center.dy,
        );
        final next = locale.languageCode == 'ar'
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        await tester.sendKeyEvent(next);
        await tester.pumpAndSettle();
        expect(
          tester.widget<LauncherDialogButton>(cancel).focusNode!.hasFocus,
          isTrue,
        );
        await tester.sendKeyEvent(next);
        await tester.pumpAndSettle();
        expect(
          tester.widget<LauncherDialogButton>(save).focusNode!.hasFocus,
          isTrue,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final singleLine in [false, true]) {
    testWidgets(
      'legend is visible while editor instructions stay in collapsed help: singleLine=$singleLine',
      (tester) async {
        final semantics = tester.ensureSemantics();
        try {
          await mount(tester, singleLine: singleLine);
          final l = AppLocalizations.of(tester.element(input))!;
          final help = tester.widget<SettingsHelp>(find.byType(SettingsHelp));
          expect(
            help.text,
            [
              l.weatherTextHelp,
              if (singleLine) l.weatherCompactLayout,
            ].join('\n\n'),
          );
          expect(find.text(help.text), findsNothing);
          for (final field in weatherTemplateNames.keys) {
            expect(
              find
                  .byKey(ValueKey('weather_format_legend_${field.name}'))
                  .hitTestable(),
              findsOneWidget,
            );
          }
          final label = tester
              .getSemantics(firstInsert)
              .getSemanticsData()
              .label;
          expect(label, contains(l.weatherTextTemperature));
          expect(label, contains('{ТЕМП}'));
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pumpAndSettle();
          expect(find.text(help.text), findsOneWidget);
          expect(
            find.byKey(const ValueKey('weather_format_legend_temperature')),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
        } finally {
          semantics.dispose();
        }
      },
    );
  }

  for (final floating in [false, true]) {
    testWidgets(
      'opening IME ignores its late end-of-text selection: floating=$floating',
      (tester) async {
        final events = StreamController<bool>(sync: true);
        addTearDown(events.close);
        addTearDown(tester.view.resetViewInsets);
        await mount(tester, imeVisibility: events.stream);
        await tester.tap(input);
        const text = 'Моя {TEMP} / {CITY}';
        await tester.enterText(input, text);
        final controller = tester.widget<TextField>(input).controller!;
        const caret = TextSelection.collapsed(offset: 4);
        controller.selection = caret;
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        if (floating) {
          // Reopening by tapping an already focused field must also keep it.
          await tester.tapAt(
            tester.getBottomRight(input) - const Offset(16, 16),
          );
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        }
        await tester.pumpAndSettle();
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump();
        expect(controller.selection, caret);
        events.add(true);
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        if (!floating) {
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        }
        await tester.pumpAndSettle();
        expect(controller.selection, caret);
        // Once open, choosing the end is a normal cursor movement and must work.
        tester.testTextInput.updateEditingValue(
          const TextEditingValue(
            text: text,
            selection: TextSelection.collapsed(offset: text.length),
          ),
        );
        await tester.pump();
        expect(controller.selection.extentOffset, text.length);
      },
    );
  }

  testWidgets('first composing edit during IME opening is preserved', (
    tester,
  ) async {
    final events = StreamController<bool>(sync: true);
    addTearDown(events.close);
    await mount(tester, imeVisibility: events.stream);
    await tester.tap(input);
    const text = 'Моя {TEMP} / {CITY}';
    await tester.enterText(input, text);
    final controller = tester.widget<TextField>(input).controller!;
    const selection = TextSelection(baseOffset: 10, extentOffset: 4);
    controller.selection = selection;
    tester.testTextInput.hide();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    await tester.pump();
    expect(controller.selection, selection);
    const edit = TextEditingValue(
      text: 'Моя X / {CITY}',
      selection: TextSelection.collapsed(offset: 5),
      composing: TextRange(start: 4, end: 5),
    );
    tester.testTextInput.updateEditingValue(edit);
    events.add(true);
    await tester.pumpAndSettle();
    expect(controller.value, edit);
  });

  testWidgets(
    'returning focus guards IME selection without an activation key',
    (tester) async {
      final events = StreamController<bool>(sync: true);
      addTearDown(events.close);
      await mount(tester, imeVisibility: events.stream);
      await tester.tap(input);
      const text = 'Моя {TEMP} / {CITY}';
      await tester.enterText(input, text);
      final controller = tester.widget<TextField>(input).controller!;
      const caret = TextSelection.collapsed(offset: 4);
      controller.selection = caret;
      tester.testTextInput.hide();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      tester
          .state<EditableTextState>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          )
          .requestKeyboard();
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        ),
      );
      await tester.pump();
      expect(controller.selection, caret);
      events.add(true);
      await tester.pumpAndSettle();
      expect(controller.selection, caret);
    },
  );

  testWidgets('hardware cursor movement cancels the IME opening guard', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(input);
    await tester.enterText(input, 'Моя {TEMP} / {CITY}');
    final controller = tester.widget<TextField>(input).controller!;
    controller.selection = const TextSelection.collapsed(offset: 4);
    tester.testTextInput.hide();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(controller.selection.extentOffset, 3);
  });

  for (final width in [800.0, 960.0]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets(
        'down exits insertion buttons in one press: width=$width scale=$scale',
        (tester) async {
          tester.view.physicalSize = Size(width, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mount(tester, scale: scale);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<LauncherDialogButton>(firstInsert)
                .focusNode!
                .hasPrimaryFocus,
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          final help = tester.widget<FocusableSettingsTile>(
            find
                .descendant(
                  of: find.byType(SettingsHelp),
                  matching: find.byType(FocusableSettingsTile),
                )
                .first,
          );
          final buttons = tester.widgetList<LauncherDialogButton>(
            find.byType(LauncherDialogButton),
          );
          final focused = buttons
              .where((b) => b.focusNode?.hasPrimaryFocus == true)
              .map((b) => b.key)
              .toList();
          expect(
            help.focusNode!.hasPrimaryFocus,
            isTrue,
            reason: 'Actual button focus: $focused',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
          expect(
            buttons.any(
              (button) =>
                  button.focusNode?.hasPrimaryFocus == true &&
                  (button.key == const Key('weather_format_reset') ||
                      button.key is! ValueKey<String>),
            ),
            isTrue,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
          await tester.pumpAndSettle();
          expect(help.focusNode!.hasPrimaryFocus, isTrue);
        },
      );
    }
  }

  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'horizontal traversal reaches a single row and restores the last function: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(640, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await mount(tester, locale: locale, scale: 1.5);
        final buttons = tester
            .widgetList<LauncherDialogButton>(
              find.byWidgetPredicate(
                (w) =>
                    w is LauncherDialogButton &&
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'weather_format_add_',
                    ),
              ),
            )
            .toList();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final forward = locale.languageCode == 'ar'
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        for (var i = 0; i < buttons.length; i++) {
          expect(buttons[i].focusNode!.hasPrimaryFocus, isTrue);
          expect(buttons.where((b) => b.focusNode!.hasPrimaryFocus).length, 1);
          await tester.sendKeyEvent(forward);
          await tester.pumpAndSettle();
        }
        expect(buttons.last.focusNode!.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        final help = tester.widget<FocusableSettingsTile>(
          find
              .descendant(
                of: find.byType(SettingsHelp),
                matching: find.byType(FocusableSettingsTile),
              )
              .first,
        );
        expect(help.focusNode!.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(buttons.last.focusNode!.hasPrimaryFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(
          tester.widget<TextField>(input).focusNode!.hasPrimaryFocus,
          isTrue,
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(buttons.last.focusNode!.hasPrimaryFocus, isTrue);
        final backward = forward == LogicalKeyboardKey.arrowLeft
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        for (var i = buttons.length - 1; i >= 0; i--) {
          expect(buttons[i].focusNode!.hasPrimaryFocus, isTrue);
          await tester.sendKeyEvent(backward);
          await tester.pumpAndSettle();
        }
        expect(buttons.first.focusNode!.hasPrimaryFocus, isTrue);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'horizontal traversal skips a disabled newline and help still opens for reading',
    (tester) async {
      await mount(
        tester,
        format: WeatherTextFormat.fromBlocks(const [
          WeatherTextBlock(WeatherTextField.temperature),
          WeatherTextBlock(WeatherTextField.lineBreak),
          WeatherTextBlock(WeatherTextField.city),
        ])!,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      for (var i = 0; i < 4; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(
        tester
            .widget<LauncherDialogButton>(
              find.byKey(const ValueKey('weather_format_add_warning')),
            )
            .focusNode!
            .hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<LauncherDialogButton>(
              find.byKey(const ValueKey('weather_format_add_city')),
            )
            .focusNode!
            .hasPrimaryFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      final help = tester.widget<FocusableSettingsTile>(
        find
            .descendant(
              of: find.byType(SettingsHelp),
              matching: find.byType(FocusableSettingsTile),
            )
            .first,
      );
      expect(help.focusNode!.hasPrimaryFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(help.focusNode!.hasFocus, isFalse);
      expect(
        FocusManager.instance.primaryFocus!.context!
            .findAncestorWidgetOfExactType<SettingsHelp>(),
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'keeps a middle caret across focus, IME resize and repeated activation',
    (tester) async {
      addTearDown(tester.view.resetViewInsets);
      await mount(tester);
      await tester.tap(input);
      await tester.enterText(input, 'Моя {ТЕМП} / {ГОРОД}');
      final field = tester.widget<TextField>(input);
      final controller = field.controller!;
      const selection = TextSelection.collapsed(offset: 4);
      controller.selection = selection;
      for (var i = 0; i < 3; i++) {
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(field.focusNode!.hasFocus, isFalse);
        expect(controller.selection, selection);
        if (i == 1) {
          // An IME may clear the selection when detaching from the field.
          controller.selection = const TextSelection.collapsed(offset: -1);
          await tester.pump();
        }
        if (i == 2) {
          await tester.tapAt(
            tester.getBottomRight(input) - const Offset(16, 16),
          );
        } else {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        }
        await tester.pumpAndSettle();
        expect(field.focusNode!.hasFocus, isTrue);
        expect(controller.selection, selection);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);
        expect(controller.selection, selection);
        tester.view.resetViewInsets();
        await tester.pumpAndSettle();
        expect(controller.selection, selection);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'retains a selection and inserts at its extent after reopening the keyboard',
    (tester) async {
      await mount(tester);
      await tester.tap(input);
      await tester.enterText(input, 'Мой {ТЕМП}!');
      final controller = tester.widget<TextField>(input).controller!;
      const selection = TextSelection(baseOffset: 10, extentOffset: 4);
      controller.selection = selection;
      tester.testTextInput.hide();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(controller.selection, selection);
      tester.testTextInput.hide();
      final city = find.byKey(const ValueKey('weather_format_add_city'));
      await tester.tap(city);
      await tester.pumpAndSettle();
      expect(controller.text, 'Мой {ГОРОД}!');
      expect(controller.selection, const TextSelection.collapsed(offset: 11));
    },
  );

  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'paints an unfocused static caret before and after insertion: $locale',
      (tester) async {
        await mount(tester, locale: locale, scale: 1.5);
        await tester.tap(input);
        await tester.enterText(
          input,
          'Моя ${'длинная подпись ' * 12}{TEMP} / {CITY}',
        );
        final controller = tester.widget<TextField>(input).controller!;
        controller.selection = const TextSelection.collapsed(offset: 4);
        tester.testTextInput.hide();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        Future<void> expectCaretPixel() async {
          final editable = tester
              .state<EditableTextState>(
                find.descendant(of: input, matching: find.byType(EditableText)),
              )
              .renderEditable;
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find
                .ancestor(of: input, matching: find.byType(RepaintBoundary))
                .first,
          );
          final rect = editable.getLocalRectForCaret(
            controller.selection.extent,
          );
          final point = editable.localToGlobal(rect.center, ancestor: boundary);
          expect((Offset.zero & boundary.size).contains(point), isTrue);
          final pixels = await tester.runAsync(() async {
            final image = await boundary.toImage(pixelRatio: 1);
            final data = (await image.toByteData(
              format: ui.ImageByteFormat.rawRgba,
            ))!;
            final offset =
                (point.dy.floor() * image.width + point.dx.floor()) * 4;
            final rgb = [
              data.getUint8(offset),
              data.getUint8(offset + 1),
              data.getUint8(offset + 2),
            ];
            image.dispose();
            return rgb;
          });
          final color = Theme.of(tester.element(input)).colorScheme.primary
              .toARGB32();
          expect(pixels, [
            (color >> 16) & 255,
            (color >> 8) & 255,
            color & 255,
          ]);
          expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
        }

        await expectCaretPixel();
        controller.selection = TextSelection.collapsed(
          offset: controller.text.length,
        );
        final button = find.byKey(const ValueKey('weather_format_add_city'));
        await tester.tap(button);
        await tester.pumpAndSettle();
        await expectCaretPixel();
        expect(
          tester.widget<TextField>(input).scrollController!.offset,
          greaterThan(0),
        );
        await tester.pump(const Duration(seconds: 1));
        await expectCaretPixel();
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('keeps conditional affixes of an unchanged legacy draft', (
    tester,
  ) async {
    await mount(
      tester,
      format: WeatherTextFormat.fromBlocks(const [
        WeatherTextBlock(WeatherTextField.temperature),
        WeatherTextBlock(WeatherTextField.city, before: ' / ', after: '!'),
      ])!,
    );
    final preview = tester.widget<WeatherDisplayText>(
      find.byKey(const Key('weather_format_preview')),
    );
    expect(preview.text, '$weatherInlineIcon 6°C');
    expect(
      tester.widget<TextField>(input).controller!.text,
      '{ЗНАЧ} {ТЕМП} / {ГОРОД}!',
    );
  });

  testWidgets(
    'starts at the first control without IME and returns up from insertion buttons',
    (tester) async {
      await mount(tester);
      final focus = tester.widget<TextField>(input).focusNode!;
      expect(focus.hasFocus, isTrue);
      expect(tester.testTextInput.isVisible, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        tester.widget<LauncherDialogButton>(firstInsert).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        tester.widget<LauncherDialogButton>(firstInsert).focusNode!.hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(focus.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'inserts and replaces at the cursor while preserving the button focus',
    (tester) async {
      await mount(tester);
      await tester.tap(input);
      await tester.enterText(input, 'Мой {ТЕМП}!');
      final controller = tester.widget<TextField>(input).controller!;
      controller.selection = const TextSelection(
        baseOffset: 4,
        extentOffset: 10,
      );
      final city = find.byKey(const ValueKey('weather_format_add_city'));
      await tester.ensureVisible(city);
      await tester.tap(city);
      await tester.pumpAndSettle();
      expect(controller.text, 'Мой {ГОРОД}!');
      expect(controller.selection.extentOffset, 11);
      expect(tester.widget<TextField>(input).focusNode!.hasFocus, isFalse);
      await tester.ensureVisible(firstInsert);
      await tester.tap(firstInsert);
      await tester.pumpAndSettle();
      expect(controller.text, 'Мой {ГОРОД}{ТЕМП}!');
      expect(
        tester.widget<LauncherDialogButton>(firstInsert).focusNode!.hasFocus,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('highlights the erroneous token, blocks save and recovers', (
    tester,
  ) async {
    await mount(tester);
    await tester.tap(input);
    await tester.enterText(input, 'Мой {ТЕМПП} {ТЕМП}');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weather_format_error')), findsOneWidget);
    final l = AppLocalizations.of(tester.element(input))!;
    expect(find.textContaining(l.weatherTemplateUnknownError), findsOneWidget);
    final controller =
        tester.widget<TextField>(input).controller!
            as WeatherTemplateEditingController;
    final context = tester.element(input);
    final span = controller.buildTextSpan(
      context: context,
      withComposing: true,
    );
    final children = span.children!.cast<TextSpan>();
    expect(
      children
          .where((s) => s.style?.color == Theme.of(context).colorScheme.error)
          .map((s) => s.text)
          .join(),
      '{ТЕМПП}',
    );
    expect(
      tester
          .widget<LauncherDialogButton>(
            find.byKey(const Key('weather_format_save')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(input, '{ТЕМП}{ПЕР}({ОЩУЩ})');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('weather_format_error')), findsNothing);
    expect(
      tester
          .widget<LauncherDialogButton>(
            find.byKey(const Key('weather_format_save')),
          )
          .onPressed,
      isNotNull,
    );
    expect(
      tester
          .widget<WeatherDisplayText>(
            find.byKey(const Key('weather_format_preview')),
          )
          .text,
      '6°C\n(2°C)',
    );
  });

  testWidgets(
    'allows one break even with a date and disables only a second insertion',
    (tester) async {
      await mount(tester, singleLine: true);
      await tester.tap(input);
      await tester.enterText(input, '{ТЕМП}{ПЕР}({ОЩУЩ})');
      await tester.pumpAndSettle();
      expect(find.text('6°C (2°C)'), findsOneWidget);
      expect(find.byKey(const Key('weather_format_error')), findsNothing);
      final newline = find.byKey(
        const ValueKey('weather_format_add_lineBreak'),
      );
      expect(tester.widget<LauncherDialogButton>(newline).onPressed, isNull);
      await tester.enterText(input, '{ТЕМП}{ПЕР}({ОЩУЩ}){ПЕР}');
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(input))!;
      expect(find.text(l.weatherTemplateBreakError), findsOneWidget);
      expect(
        tester
            .widget<LauncherDialogButton>(
              find.byKey(const Key('weather_format_save')),
            )
            .onPressed,
        isNull,
      );
    },
  );

  testWidgets(
    'places condition glyphs inline and allows a format without any icon',
    (tester) async {
      await mount(tester);
      await tester.tap(input);
      await tester.enterText(input, '{ТЕМП}{ПЕР}Калуга {УСЛ}');
      await tester.pumpAndSettle();
      expect(find.byType(WeatherGlyph), findsOneWidget);
      final temp = tester.getRect(find.text('6°C'));
      final icon = tester.getRect(find.byType(WeatherGlyph));
      expect(icon.top, greaterThanOrEqualTo(temp.bottom));
      await tester.enterText(input, '{ТЕМП}');
      await tester.pumpAndSettle();
      expect(find.byType(WeatherGlyph), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'keeps preview and input above the keyboard at large text: $locale',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);
        await mount(tester, locale: locale, scale: 1.5);
        final dialog = find.byKey(const Key('weather_format_body'));
        final beforeKeyboard = tester.getRect(dialog);
        await tester.tap(input);
        await tester.enterText(input, '{TEMP}{BR}({FEELS})');
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        final preview = tester.getRect(
          find.byKey(const Key('weather_format_preview')),
        );
        final field = tester.getRect(input);
        final shifted = tester.getRect(dialog);
        expect(shifted.top, lessThan(beforeKeyboard.top));
        expect(shifted.bottom, lessThanOrEqualTo(240));
        expect(preview.bottom, lessThanOrEqualTo(field.top));
        expect(field.bottom, lessThanOrEqualTo(240));
        expect(tester.takeException(), isNull);
        tester.view.resetViewInsets();
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        expect(
          tester.getRect(dialog).center.dy,
          closeTo(beforeKeyboard.center.dy, 1),
        );
      },
    );
  }
}
