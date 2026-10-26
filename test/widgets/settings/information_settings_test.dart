import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/panel_clock_style.dart';
import 'package:flauncher/panel_layout.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/widgets/combined_information.dart';
import 'package:flauncher/widgets/animated_character.dart';
import 'package:flauncher/widgets/date_time_widget.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';

void main() {
  late AppearanceService appearance;
  late SettingsService settings;
  late RemotePanelService remote;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    appearance = AppearanceService(prefs);
    settings = SettingsService(prefs);
    remote = RemotePanelService(prefs);
  });
  tearDown(() {
    appearance.dispose();
    settings.dispose();
    remote.dispose();
  });
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    double scale = 1,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: remote),
        ],
        child: MaterialApp(
          locale: const Locale('ru'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(scale)),
            child: Material(child: child!),
          ),
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(width: 390, child: child),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final popup in [false, true]) {
    testWidgets(
      'group settings and calendar persist in both modes: remote=$popup',
      (tester) async {
        await pump(tester, InformationObjectsSection(remotePanel: popup));
        expect(find.text('Настройки блока'), popup ? findsNothing : findsOneWidget);
        await tester.tap(find.text('Показывать дату'));
        await tester.pumpAndSettle();
        expect(
          popup ? remote.visible('date') : settings.showDateInStatusBar,
          isFalse,
        );
        if (popup) {
          await pump(tester, const InformationSettingsPage());
        } else {
          await tester.tap(find.text('Настройки блока'));
        }
        await tester.pumpAndSettle();
        expect(find.text('Оформление часов'), findsOneWidget);
        expect(find.text('Настройки даты'), findsOneWidget);
        await tester.tap(find.text('Открывать календарь по нажатию на дату'));
        await tester.pumpAndSettle();
        expect(
          appearance.appearance.dateCalendar,
          isTrue,
        );
        await tester.tap(find.text('Объединить часы, дату и погоду'));
        await tester.pumpAndSettle();
        expect(find.text('Оформление часов'), findsNothing);
        expect(find.text('Настройки даты'), findsNothing);
        expect(find.text('Оформление блока'), findsOneWidget);
        expect(find.text('Настройки погоды'), findsOneWidget);
        expect(
          appearance.appearance.dateCalendar,
          isTrue,
        );
        await tester.tap(find.text('Оформление блока'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<PanelClockStylePage>(find.byType(PanelClockStylePage))
              .combined,
          isTrue,
        );
        expect(find.text('Общий размер блока'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );

    testWidgets(
      'combined reorder crosses sides as one persistent unit: remote=$popup',
      (tester) async {
        await appearance.set('panelCombinedInformation', true);
        final right = [
          'time',
          'settings',
          'date',
          'weather',
          ...PanelLayout.buttons.where((id) => id != 'settings'),
        ];
        if (popup) {
          await remote.setPanelOrder([], right);
        } else {
          await appearance.setPanelOrder([], right);
        }
        await pump(tester, PanelOrderPage(remotePanel: popup));
        expect(find.byKey(const ValueKey('time')), findsNothing);
        expect(find.byKey(const ValueKey('date')), findsNothing);
        expect(find.byKey(const ValueKey('weather')), findsNothing);
        final tile = find.byKey(const ValueKey(PanelLayout.informationGroup));
        final node = tester.widget<FocusableSettingsTile>(tile).focusNode!;
        node.requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        final layout = popup
            ? remote.layout
            : appearance.appearance.panelLayout;
        expect(layout.left, ['time', 'date', 'weather']);
        expect(layout.right, isNot(contains('time')));
        expect(node.hasFocus, isTrue);
        final restored = popup ? RemotePanelService(remote.preferences) : null;
        final restoredAppearance = AppearanceService(appearance.preferences);
        expect(
          restored?.layout.left ??
              restoredAppearance.appearance.panelLayout.left,
          ['time', 'date', 'weather'],
        );
        restored?.dispose();
        restoredAppearance.dispose();
        await appearance.set('panelCombinedInformation', false);
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('time')), findsOneWidget);
        expect(find.byKey(const ValueKey('date')), findsOneWidget);
        expect(find.byKey(const ValueKey('weather')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test('font styles preserve every family, size, color and surface', () {
    for (final font in PanelClockStyle.fonts.keys) {
      for (final id in PanelClockStyle.fontStyles.keys) {
        final style = PanelClockStyle({
          'font': font,
          'size': 22,
          'color': 0xff123456,
          'inheritBackground': false,
          'background': true,
          'backgroundColor': 0xff654321,
          'opacity': .37,
          'radius': 5,
          'spacing': 7,
          'clockOnRight': true,
        });
        final next = PanelClockStyle(style.withFontStyle(id));
        expect(
          next.textStyle(const TextStyle()).fontFamily,
          PanelClockStyle.fonts[font],
        );
        for (final key in style.values.keys) {
          expect(
            next.values[key],
            style.values[key],
            reason: '$font / $id / $key',
          );
        }
      }
    }
  });

  testWidgets(
    'toggling digit animation preserves combined glyph positions and size',
    (tester) async {
      for (final font in ['manrope', 'serif', 'monospace']) {
        for (final size in [10, 18, 24]) {
          Widget block(bool animate) => SizedBox(
            height: kToolbarHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: CombinedInformation(
                appearance: TileAppearance({
                  'panelInformationStyle': {
                    'font': font,
                    'size': size,
                    'animate': animate,
                  },
                }),
                showTime: true,
                showDate: true,
                showWeather: false,
                timeFormat: "'12:34'",
                dateFormat: "'Date'",
              ),
            ),
          );
          await pump(tester, block(false));
          final clock = find.byKey(const Key('statusbar_clock'));
          Finder glyphs() => find.descendant(
            of: clock,
            matching: find.byType(AnimatedCharacter),
          );
          final before = glyphs()
              .evaluate()
              .map((e) => tester.getRect(find.byWidget(e.widget)))
              .toList();
          final surface = tester.getRect(find.byType(TopPanelItem));
          for (final animate in [true, false, true]) {
            await pump(tester, block(animate));
            expect(tester.getRect(find.byType(TopPanelItem)), surface);
            expect(
              glyphs()
                  .evaluate()
                  .map((e) => tester.getRect(find.byWidget(e.widget)))
                  .toList(),
              before,
              reason: '$font / $size / animate=$animate',
            );
          }
        }
      }
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'font weight steps through the actual family range independently of italic',
    (tester) async {
      await appearance.set('panelInformationStyle', {
        'font': 'manrope',
        'weight': 200,
        'italic': true,
      });
      await pump(tester, const PanelClockStylePage(combined: true));
      await tester.ensureVisible(find.text('Толщина шрифта'));
      Focus.of(tester.element(find.text('Толщина шрифта'))).requestFocus();
      await tester.pumpAndSettle();
      for (var weight = 300; weight <= 800; weight += 100) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        final style = appearance.appearance.informationStyle;
        expect(style.values['weight'], weight);
        expect(
          style.textStyle(const TextStyle()).fontWeight,
          FontWeight.values[weight ~/ 100 - 1],
        );
        expect(style.preset, 'italic');
      }
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(appearance.appearance.informationStyle.values['weight'], 800);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final combined in [false, true]) {
    testWidgets(
      'font selector updates weight steps and displayed legacy value: combined=$combined',
      (tester) async {
        const options = {
          'manrope': [200, 300, 400, 500, 600, 700, 800],
          'google-sans': [400, 500, 700],
          'monospace': [100, 200, 300, 400, 500, 600, 700],
          'system': [400, 700],
        };
        final key = combined ? 'panelInformationStyle' : 'panelClockStyle';
        for (final entry in options.entries) {
          await appearance.set(key, {'font': entry.key, 'weight': 900});
          await pump(tester, PanelClockStylePage(combined: combined));
          await tester.ensureVisible(find.text('Толщина шрифта'));
          final finder = find.ancestor(
            of: find.text('Толщина шрифта'),
            matching: find.byType(SettingsValueStepper),
          );
          final stepper = tester.widget<SettingsValueStepper>(finder);
          expect(stepper.options, entry.value);
          expect(stepper.value, entry.value.last);
          Focus.of(tester.element(find.text('Толщина шрифта'))).requestFocus();
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pumpAndSettle();
          final style = combined
              ? appearance.appearance.informationStyle
              : appearance.appearance.clockStyle;
          expect(style.values['weight'], entry.value[entry.value.length - 2]);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  testWidgets(
    'combined editor retains family and separate style; hides unused layout controls',
    (tester) async {
      await appearance.set('panelClockStyle', {'font': 'serif', 'size': 33});
      await appearance.set('panelInformationStyle', {
        'font': 'manrope',
        'size': 20,
      });
      await pump(tester, const PanelClockStylePage(combined: true));
      await tester.ensureVisible(find.text('Стиль шрифта'));
      await tester.tap(find.text('Стиль шрифта'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Курсив'));
      await tester.pumpAndSettle();
      expect(appearance.appearance.informationStyle.values['font'], 'manrope');
      expect(appearance.appearance.informationStyle.values['size'], 20);
      expect(appearance.appearance.informationStyle.values['italic'], isTrue);
      expect(appearance.appearance.clockStyle.values, {
        'font': 'serif',
        'size': 33,
      });
      await tester.scrollUntilVisible(
        find.text('Расположение часов и текста'),
        150,
      );
      expect(find.text('Расположение часов и текста'), findsOneWidget);
      await settings.setShowTimeInStatusBar(false);
      await tester.pumpAndSettle();
      expect(find.text('Расположение часов и текста'), findsNothing);
      expect(find.text('Расстояние между часами и текстом'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'separate and combined styling survive mode changes, reload and backup',
    () async {
      await appearance.set('panelClockStyle', {'font': 'serif', 'size': 33});
      await appearance.set('panelInformationStyle', {
        'font': 'manrope',
        'size': 22,
        'clockOnRight': true,
        'spacing': 8,
        'italic': true,
        'glass': true,
      });
      await appearance.set('panelCombinedInformation', true);
      await remote.set('inheritAppearance', false);
      expect(
        remote.appearanceFor(appearance.appearance).combinedInformation,
        isTrue,
      );
      expect(
        remote.appearanceFor(appearance.appearance).informationStyle.values,
        appearance.appearance.informationStyle.values,
      );
      await appearance.set('panelCombinedInformation', false);
      final imported = compatibleSettings({
        tileAppearanceKey: appearance.preferences.getString(tileAppearanceKey)!,
      }, {});
      final restored = TileAppearance.decode(imported[tileAppearanceKey]);
      expect(restored.clockStyle.values['size'], 33);
      expect(
        restored.informationStyle.values,
        appearance.appearance.informationStyle.values,
      );
      expect(restored.active, isFalse);
      expect(
        TileAppearance.validValues({
          'panelInformationStyle': {
            'size': 25,
            'spacing': -1,
            'clockOnRight': 'yes',
            'italic': 'yes',
          },
        })['panelInformationStyle'],
        isEmpty,
      );
    },
  );

  testWidgets(
    'combined styles affect every glyph, real size and physical clock position',
    (tester) async {
      Widget block(
        double size, {
        bool right = false,
        bool date = true,
        bool weather = true,
      }) => SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: CombinedInformation(
            appearance: TileAppearance({
              'panelInformationStyle': {
                'font': 'manrope',
                'size': size,
                'color': 0xff80efb0,
                'weight': 700,
                'italic': true,
                'glow': true,
                'animate': false,
                'clockOnRight': right,
                'inheritBackground': false,
                'background': false,
              },
            }),
            showTime: true,
            showDate: date,
            showWeather: weather,
            timeFormat: 'HH:mm',
            dateFormat: 'dd.MM.yyyy',
            weather: const WeatherData(
              currentTemp: 20,
              currentConditionCode: 800,
            ),
          ),
        ),
      );
      double previousWidth = 0;
      for (var size = 10; size <= 24; size++) {
        await pump(tester, block(size.toDouble()));
        final width = tester.getSize(find.byType(TopPanelItem)).width;
        expect(width, greaterThan(previousWidth), reason: 'size=$size');
        previousWidth = width;
      }
      for (final right in [false, true]) {
        await pump(tester, block(24, right: right));
        final clock = find.byKey(const Key('statusbar_clock'));
        final date = find.byKey(const Key('statusbar_date'));
        expect(tester.getCenter(clock).dx > tester.getCenter(date).dx, right);
        for (final glyph in tester.widgetList<DateTimeWidget>(
          find.byType(DateTimeWidget),
        )) {
          expect(glyph.textStyle!.fontFamily, 'Manrope');
          expect(glyph.textStyle!.color, const Color(0xff80efb0));
          expect(glyph.textStyle!.fontWeight, FontWeight.w700);
          expect(glyph.textStyle!.fontStyle, FontStyle.italic);
          expect(glyph.textStyle!.shadows, isNotEmpty);
        }
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, const Color(0xff80efb0));
        expect(icon.shadows, isNotEmpty);
        expect(
          tester.widget<Text>(find.text('20°C')).style!.fontFamily,
          'Manrope',
        );
      }
      await pump(tester, block(24, date: false, weather: false), scale: 1.8);
      expect(find.byKey(const Key('statusbar_date')), findsNothing);
      expect(find.byType(Icon), findsNothing);
      expect(
        tester.getSize(find.byType(TopPanelItem)).height,
        lessThanOrEqualTo(kToolbarHeight),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
