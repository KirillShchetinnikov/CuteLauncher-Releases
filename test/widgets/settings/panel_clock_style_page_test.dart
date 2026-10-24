import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/panel_clock.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';

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
      expect(find.byType(TimeFormatSettingsTile), findsOneWidget);
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
  testWidgets(
    'default color copies the common color and preserves custom background settings',
    (tester) async {
      await appearance.set('panelTextBackgroundColor', 0xff14532d);
      await pump(tester, const PanelClockStylePage());
      final l = AppLocalizations.of(
        tester.element(find.byType(PanelClockStylePage)),
      )!;
      await tester.scrollUntilVisible(find.text(l.clockSharedBackground), 150);
      final tile = find.ancestor(
        of: find.text(l.clockSharedBackground),
        matching: find.byType(RoundedSwitchListTile),
      );
      expect(tester.widget<RoundedSwitchListTile>(tile).value, isTrue);
      expect(find.text(l.styleBackgroundColor), findsNothing);
      await Scrollable.ensureVisible(
        tester.element(find.text(l.clockSharedBackground)),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.clockSharedBackground));
      await tester.pumpAndSettle();
      await appearance.set('panelClockStyle', {
        ...appearance.appearance.clockStyle.values,
        'opacity': .37,
        'radius': 3,
        'background': true,
      });
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text(l.styleBackgroundColor), 100);
      await Scrollable.ensureVisible(
        tester.element(find.text(l.styleBackgroundColor)),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.styleBackgroundColor));
      await tester.pumpAndSettle();
      expect(find.byType(ColorPaletteDialog), findsOneWidget);
      await tester.ensureVisible(find.text(l.clockDefaultBackground));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l.clockDefaultBackground));
      await tester.pumpAndSettle();
      final clock = appearance.appearance.clockStyle;
      expect(clock.inheritBackground, isFalse);
      expect(clock.values['backgroundColor'], 0xff14532d);
      expect(clock.values['opacity'], .37);
      expect(clock.values['radius'], 3);
      expect(clock.values['background'], isTrue);
      expect(find.text(l.styleBackgroundColor), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  for (final remote in [false, true]) {
    testWidgets(
      'date submenu only edits date and its calendar: remote=$remote',
      (tester) async {
        await pump(tester, DateTimeFormatPage(remotePanel: remote));
        expect(find.byType(TimeFormatSettingsTile), findsNothing);
        expect(find.byType(PanelClock), findsNothing);
        expect(find.text('Время'), findsNothing);
        await tester.tap(find.text('Открывать календарь по нажатию на дату'));
        await tester.pumpAndSettle();
        expect(
          remote ? panel.dateCalendar : appearance.appearance.dateCalendar,
          isTrue,
        );
        expect(
          remote ? appearance.appearance.dateCalendar : panel.dateCalendar,
          isFalse,
        );
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
