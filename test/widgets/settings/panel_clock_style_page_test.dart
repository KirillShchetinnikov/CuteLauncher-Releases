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


import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
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

  testWidgets(
    'clock has format controls and no preview, font and remote size persist',
    (tester) async {
      await pump(tester, const PanelClockStylePage());
      expect(find.byType(PanelClock), findsNothing);
      expect(find.byType(TimeFormatSettingsTile), findsNothing);
      await tester.ensureVisible(find.text('Стиль шрифта'));
      await tester.tap(find.text('Стиль шрифта'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Курсив'));
      await tester.pumpAndSettle();
      expect(appearance.appearance.clockStyle.values['font'], isNull);
      expect(appearance.appearance.clockStyle.inheritBackground, isTrue);
      await tester.scrollUntilVisible(find.text('Шрифт текста'), 100);
      await tester.tap(find.text('Шрифт текста'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('С засечками'));
      await tester.pumpAndSettle();
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
    await tester.tap(find.text('Шрифт текста'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Medeo Serif'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(PanelClockStylePage)))!;
    final weight = find.byWidgetPredicate((w) => w is SettingsValueStepper && w.title == l.clockWeight);
    await tester.ensureVisible(weight);
    final control = tester.widget<SettingsValueStepper>(weight);
    expect(control.options, [400]);
    expect(control.value, 400);
    Focus.of(tester.element(find.text(l.clockWeight))).requestFocus();
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
  for (final remote in [false, true]) {
    testWidgets('short weekday date is selectable and saved: remote=$remote', (tester) async {
      final previousTime = settings.timeFormat;
      await settings.setDateTimeFormat(compactDateFormat, previousTime);
      await pump(tester, DateTimeFormatPage(remotePanel: remote));
      await tester.tap(find.text('Дата'));
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
