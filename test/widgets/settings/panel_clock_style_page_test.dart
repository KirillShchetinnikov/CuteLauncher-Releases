import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/date_time_format.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/panel_clock.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';


import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/information_preview.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_menu_layout.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';

void main() {
  late AppearanceService appearance;
  late RemotePanelService panel;
  late SettingsService settings;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    panel = RemotePanelService(prefs);
    settings = SettingsService(prefs);
  });
  tearDown(() {
    appearance.dispose();
    panel.dispose();
    settings.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: panel),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: SizedBox(width: 390, child: page)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final background in [false, true]) {
    testWidgets('composition separates objects and edits clock behavior: background=$background', (tester) async {
      final key = background ? 'panelBackgroundInformationStyle' : 'panelInformationStyle';
      await appearance.set(key, {'showColon': true, 'animate': false});
      final other = background
          ? appearance.appearance.informationStyle.values
          : appearance.appearance.backgroundInformationStyle.values;
      await pump(tester, SettingsMenuLayout(
        onRight: false, informationObscured: true,
        child: InformationDataSettingsPage(background: background),
      ));
      expect(find.byType(InformationPreview), findsNothing);
      expect(tester.widget<SettingsPageLayout>(find.byType(SettingsPageLayout)).header, isNull);
      final l = AppLocalizations.of(tester.element(find.byType(InformationDataSettingsPage)))!;
      final positions = <double>[];
      for (final id in ['time', 'date', 'weather']) {
        final header = find.byKey(ValueKey('information-$id-section'));
        await tester.scrollUntilVisible(header, 100);
        await tester.pumpAndSettle();
        expect(header, findsOneWidget);
        expect(find.descendant(of: header, matching: find.byWidgetPredicate(
          (widget) => widget is Semantics && widget.properties.header == true)),
          findsOneWidget);
        positions.add(tester.getTopLeft(header).dy +
          Scrollable.of(tester.element(header)).position.pixels);
      }
      expect(positions[1], greaterThan(positions[0]));
      expect(positions[2], greaterThan(positions[1]));
      await tester.scrollUntilVisible(find.byKey(const ValueKey('information-time-section')), -100);
      await tester.pumpAndSettle();
      expect(find.text(l.informationTimeFormat), findsOneWidget);
      expect(find.text(l.informationDateFormat), findsOneWidget);
      final colon = find.widgetWithText(RoundedSwitchListTile, l.clockShowColon);
      final animation = find.widgetWithText(RoundedSwitchListTile, l.clockAnimate);
      await tester.scrollUntilVisible(colon, 100);
      Focus.of(tester.element(find.text(l.clockShowColon))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(animation, 100);
      await tester.tap(animation);
      await tester.pumpAndSettle();
      final restored = AppearanceService(await SharedPreferences.getInstance());
      final style = background ? restored.appearance.backgroundInformationStyle : restored.appearance.informationStyle;
      expect(style.showColon, isFalse);
      expect(style.animate, isTrue);
      expect(background ? restored.appearance.informationStyle.values : restored.appearance.backgroundInformationStyle.values, other);
      if (!background) expect(style.inheritsPanelTypography, isTrue);
      restored.dispose();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text(l.temperatureUnit))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text(l.weatherTextFormat))).hasFocus, isTrue);
      expect(find.text(l.weatherTextFormat).hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('panel typography toggles inheritance and resets only this screen', (tester) async {
    const custom = {
      'font': 'serif', 'size': 22, 'weight': 700, 'italic': true,
      'animate': true, 'showColon': false,
      'clockColor': 0xff112233, 'glow': true,
      'clockOnRight': true, 'spacing': 8,
    };
    await appearance.set('panelInformationStyle', custom);
    final originalBackground = appearance.appearance.backgroundInformationStyle.values;
    await pump(tester, const InformationSectionPage(background: false, section: 'typography'));
    final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
    final inherit = find.widgetWithText(RoundedSwitchListTile, l.informationInheritPanelTypography);
    expect(tester.widget<RoundedSwitchListTile>(inherit).value, isTrue);
    for (final title in [l.informationSize, l.panelFont, l.clockPreset, l.clockWeight, l.clockShowColon, l.clockAnimate]) {
      expect(find.text(title), findsNothing);
    }
    expect(find.text(l.informationResetTypography), findsOneWidget);
    await tester.tap(inherit);
    await tester.pumpAndSettle();
    expect(appearance.appearance.informationStyle.inheritsPanelTypography, isFalse);
    expect(find.text(l.informationSize), findsOneWidget);
    expect(find.text(l.panelFont), findsOneWidget);
    expect(find.text(l.clockAnimate), findsNothing);
    expect(find.text(l.clockShowColon), findsNothing);
    await tester.scrollUntilVisible(inherit, -100);
    await tester.tap(inherit);
    await tester.pumpAndSettle();
    expect(find.text(l.panelFont), findsNothing);
    expect(appearance.appearance.informationStyle.values['font'], 'serif');
    await tester.tap(inherit);
    await tester.pumpAndSettle();
    expect(appearance.appearance.informationStyle.textStyle(const TextStyle()).fontSize, 22);
    final restored = AppearanceService(await SharedPreferences.getInstance());
    expect(restored.appearance.informationStyle.inheritsPanelTypography, isFalse);
    expect(restored.appearance.informationStyle.values['font'], 'serif');
    restored.dispose();

    await tester.scrollUntilVisible(find.text(l.informationResetTypography), 120);
    await tester.tap(find.text(l.informationResetTypography));
    await tester.pumpAndSettle();
    await tester.tap(find.text(MaterialLocalizations.of(tester.element(find.byType(LauncherAlertDialog))).cancelButtonLabel));
    await tester.pumpAndSettle();
    expect(appearance.appearance.informationStyle.values['font'], 'serif');
    await tester.tap(find.text(l.informationResetTypography));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(LauncherAlertDialog), matching: find.text(l.informationResetTypography)).last);
    await tester.pumpAndSettle();
    final style = appearance.appearance.informationStyle;
    expect(style.inheritsPanelTypography, isTrue);
    expect(style.values['font'], isNull);
    expect(style.values['italic'], isNull);
    expect(style.values['weight'], 400);
    expect(style.values['size'], 18);
    expect(style.animate, isTrue);
    expect(style.showColon, isFalse);
    expect(style.clockColor, const Color(0xff112233));
    expect(style.values['glow'], isTrue);
    expect(style.clockOnRight, isTrue);
    expect(style.spacing, 8);
    expect(appearance.appearance.backgroundInformationStyle.values, originalBackground);
    expect(find.text(l.panelFont), findsNothing);
    expect(find.text(l.informationResetTypography), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'clock has format controls and no preview, font and remote size persist',
    (tester) async {
      await pump(tester, const PanelClockStylePage());
      expect(find.byType(PanelClock), findsNothing);
      expect(find.byType(TimeFormatSettingsTile), findsNothing);
      await tester.ensureVisible(find.text('Стиль шрифта'));
      Focus.of(tester.element(find.text('Стиль шрифта'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(appearance.appearance.clockStyle.values['font'], isNull);
      expect(appearance.appearance.clockStyle.inheritBackground, isTrue);
      await tester.scrollUntilVisible(find.text('Шрифт текста'), 100);
      Focus.of(tester.element(find.text('Шрифт текста'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(appearance.appearance.clockStyle.values['font'], 'serif');
      Focus.of(tester.element(find.text('Размер текста'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(appearance.appearance.clockStyle.values['size'], 19);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Medeo Serif clock selection persists and offers only weight 400', (tester) async {
    await appearance.set('panelClockStyle', {'weight': 900});
    await pump(tester, const PanelClockStylePage());
    await tester.scrollUntilVisible(find.text('Шрифт текста'), 100);
    Focus.of(tester.element(find.text('Шрифт текста'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(PanelClockStylePage)))!;
    final weight = find.byWidgetPredicate((w) => w is SettingsValueStepper && w.title == l.clockWeight);
    await tester.ensureVisible(weight);
    final control = tester.widget<SettingsValueStepper>(weight);
    expect(control.options, [400]);
    expect(control.value, 400);
    Focus.of(tester.element(find.text(l.clockWeight))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    final restored = AppearanceService(await SharedPreferences.getInstance());
    expect(restored.appearance.clockStyle.values['font'], 'medeo-serif');
    expect(restored.appearance.clockStyle.textStyle(const TextStyle()).fontWeight, FontWeight.w400);
    restored.dispose();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('panel typography never duplicates panel surface settings', (tester) async {
    await pump(tester, const PanelClockStylePage());
    final l = AppLocalizations.of(tester.element(find.byType(PanelClockStylePage)))!;
    expect(find.text(l.clockSharedBackground), findsNothing);
    expect(find.text(l.clockRadius), findsNothing);
    expect(find.text(l.styleBackgroundColor), findsNothing);
    expect(find.byType(TimeFormatSettingsTile), findsNothing);
    expect(find.byType(DateFormatSettingsTile), findsNothing);
  });
  for (final mode in ['panelClockStyle', 'panelInformationStyle', 'panelBackgroundInformationStyle']) {
    testWidgets('clock colors persist without changing the colon: $mode', (tester) async {
      tester.view.physicalSize = const Size(1000, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await appearance.set(mode, {'showColon': false});
      await pump(tester, PanelClockStylePage(
        combined: mode == 'panelInformationStyle',
        background: mode == 'panelBackgroundInformationStyle',
      ));
      final l = AppLocalizations.of(tester.element(find.byType(PanelClockStylePage)))!;
      if (mode == 'panelInformationStyle') {
        await tester.tap(find.text(l.informationInheritPanelTypography));
        await tester.pumpAndSettle();
      }
      Future<void> selectMode(String option) async {
        await tester.tap(find.text(l.clockColorMode));
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(
          of: find.byType(LauncherAlertDialog),
          matching: find.text(option),
        ));
        await tester.pumpAndSettle();
      }

      PanelClockStyle styleOf(AppearanceService service) => switch (mode) {
        'panelClockStyle' => service.appearance.clockStyle,
        'panelInformationStyle' => service.appearance.informationStyle,
        _ => service.appearance.backgroundInformationStyle,
      };

      expect(find.text(l.clockSingleColor), findsOneWidget);
      expect(find.text(l.clockTextColor), findsOneWidget);
      expect(find.text(l.clockMinutesColor), findsNothing);
      await tester.tap(find.text(l.clockTextColor));
      await tester.pumpAndSettle();
      final wholeClock = find.byKey(ValueKey('palette-${appearancePalette[2]}'));
      await tester.tap(wholeClock);
      await tester.pumpAndSettle();
      expect(styleOf(appearance).clockColor, Color(appearancePalette[2]));
      expect(styleOf(appearance).values['color'], isNull);
      await selectMode(l.clockSplitColors);
      expect(find.text(l.clockHoursColor), findsOneWidget);
      expect(find.text(l.clockMinutesColor), findsOneWidget);
      for (final title in [l.clockHoursColor, l.clockMinutesColor]) {
        await tester.scrollUntilVisible(find.text(title), 100);
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        await tester.tap(find.byWidgetPredicate((w) => w.runtimeType.toString() == '_ColorCell').first);
        await tester.pumpAndSettle();
      }
      expect(find.text(l.clockShowColon), findsNothing);
      await selectMode(l.clockSingleColor);
      expect(find.text(l.clockTextColor), findsOneWidget);
      expect(find.text(l.clockMinutesColor), findsNothing);
      final restored = AppearanceService(await SharedPreferences.getInstance());
      final style = styleOf(restored);
      expect(style.splitColors, isFalse);
      expect(style.hoursColor, isNull);
      expect(style.minutesColor, isNull);
      expect(style.showColon, isFalse);
      expect(style.clockColor, Color(appearancePalette[2]));
      restored.dispose();
      await selectMode(l.clockSplitColors);
      expect(styleOf(appearance).hoursColor, Colors.black);
      expect(styleOf(appearance).minutesColor, Colors.black);
      await tester.tap(find.text(l.clockHoursColor));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.defaultOption));
      await tester.pumpAndSettle();
      final current = styleOf(appearance);
      expect(current.hoursColor, isNull);
      expect(current.minutesColor, Colors.black);
      expect(current.showColon, isFalse);
      expect(tester.takeException(), isNull);
    });
  }
  for (final remote in [false, true]) {
    testWidgets('short weekday date is selectable and saved: remote=$remote', (tester) async {
      final previousTime = settings.timeFormat;
      await settings.setDateTimeFormat(compactDateFormat, previousTime);
      await pump(tester, DateTimeFormatPage(remotePanel: remote));
      await tester.tap(find.text('Формат даты'));
      await tester.pumpAndSettle();
      expect(find.text('Вс, 1 Нояб'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(settings.dateFormat, shortWeekdayDateFormat);
      expect(settings.timeFormat, previousTime);
      expect(find.text('Вс, 1 Нояб'), findsOneWidget);
      final restored = SettingsService(await SharedPreferences.getInstance());
      expect(restored.dateFormat, shortWeekdayDateFormat);
      restored.dispose();
      expect(tester.takeException(), isNull);
    });
    testWidgets(
      'date submenu only edits date and its calendar: remote=$remote',
      (tester) async {
        await pump(tester, DateTimeFormatPage(remotePanel: remote));
        expect(find.byType(TimeFormatSettingsTile), findsNothing);
        expect(find.byType(PanelClock), findsNothing);
        expect(find.text('Время'), findsNothing);
        final l = AppLocalizations.of(tester.element(find.byType(DateTimeFormatPage)))!;
        expect(find.text(l.dateCalendarEnabled), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('large clock fits toolbar with 180 percent text scaling', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.8)),
          child: Scaffold(
            body: SizedBox(
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.centerLeft,
                child: PanelClock(
                  style: PanelClockStyle({
                    'font': 'serif',
                    'size': 40,
                    'background': false,
                    'glow': true,
                  }),
                  format: 'HH:mm',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.getSize(find.byType(TopPanelItem)).height,
      lessThanOrEqualTo(kToolbarHeight),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
