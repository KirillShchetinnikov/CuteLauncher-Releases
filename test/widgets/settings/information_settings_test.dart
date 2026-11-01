import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/information_placement.dart';
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
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
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


  test('every placement combination groups only visible panel members', () {
    for (final time in InformationPlacement.destinations) {
      for (final date in InformationPlacement.destinations) {
        for (final weather in InformationPlacement.destinations) {
          final placements = {'time': time, 'date': date, 'weather': weather};
          for (final requested in [false, true]) {
            final value = TileAppearance({
              'panelInformationPlacements': placements,
              'panelCombinedInformation': requested,
            });
            final composition = InformationPanelComposition(value, settings);
            final members = placements.entries.where((e) => e.value == 'panel').map((e) => e.key).toSet();
            expect(composition.members, members);
            expect(composition.combined, requested && members.length >= 2);
            expect(composition.excluded, InformationPlacement.ids.toSet().difference(members));
            if (members.isNotEmpty) {
              expect(composition.action, members.contains('weather')
                  ? (members.length > 1 ? 'both' : 'weather') : 'calendar');
            }
          }
        }
      }
    }
  });

  test('home grouping freezes the legacy quick-panel choice and reloads independently', () async {
    expect(remote.combinedInformation(false), isFalse);
    await appearance.set('panelCombinedInformation', true);
    expect(remote.combinedInformation(true), isFalse);
    await remote.show('weather', false);
    expect(remote.combinedInformation(true), isFalse);
    await remote.set('combinedInformation', true);
    await appearance.set('panelCombinedInformation', false);
    final restored = RemotePanelService(remote.preferences);
    addTearDown(restored.dispose);
    expect(restored.combinedInformation(false), isTrue);
    expect(appearance.appearance.combinedInformation, isFalse);
    expect(restored.visible('weather'), isFalse);
  });


  testWidgets('shared layout controls remain available for quick-panel-only grouping', (tester) async {
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'hidden',
    });
    await remote.set('combinedInformation', true);
    await pump(tester, const PanelInformationSettingsPage());
    final l = AppLocalizations.of(tester.element(find.byType(PanelInformationSettingsPage)))!;
    await tester.scrollUntilVisible(find.text(l.informationPosition), 150);
    expect(find.text(l.informationPosition), findsOneWidget);
    await remote.show('time', false);
    await tester.pumpAndSettle();
    expect(find.text(l.informationPosition), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('placement has one entry point and formats have one page', (tester) async {
    await pump(tester, const InformationObjectsSection());
    final l = AppLocalizations.of(tester.element(find.byType(InformationObjectsSection)))!;
    expect(find.byType(InformationVisibility), findsNothing);
    await tester.tap(find.text(l.informationGroup));
    await tester.pumpAndSettle();
    expect(find.byType(InformationVisibility), findsOneWidget);
    expect(find.text(l.informationTapAction), findsNothing);
    expect(find.text(l.dateCalendarEnabled), findsNothing);
    await tester.scrollUntilVisible(find.text(l.informationData), 100);
    await tester.tap(find.text(l.informationData));
    await tester.pumpAndSettle();
    expect(find.byType(TimeFormatSettingsTile), findsOneWidget);
    expect(find.byType(DateFormatSettingsTile), findsOneWidget);
    expect(find.text(l.dateCalendarEnabled), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('weather-only combined block stays visible and actionable without data', (tester) async {
    var opened = false;
    await pump(tester, CombinedInformation(appearance: appearance.appearance,
      showTime: false, showDate: false, showWeather: true,
      timeFormat: settings.timeFormat, dateFormat: settings.dateFormat,
      onPressed: () => opened = true));
    expect(find.byIcon(Icons.cloud_outlined), findsOneWidget);
    expect(find.text('—'), findsOneWidget);
    await tester.tap(find.byType(TopPanelItem));
    await tester.pumpAndSettle();
    expect(opened, isTrue);
    expect(tester.getSize(find.byType(TopPanelItem)).width, greaterThan(24));
    await tester.pumpWidget(const SizedBox());
  });

  for (final popup in [false, true]) {
    testWidgets('grouping is disabled for a singleton: remote=$popup', (tester) async {
      await appearance.set('panelInformationPlacements', {'time': 'background', 'date': 'panel', 'weather': 'hidden'});
      await appearance.set('panelCombinedInformation', true);
      await remote.set('combinedInformation', true);
      await remote.show('time', false);
      await remote.show('weather', false);
      await pump(tester, InformationGroupingControl(remotePanel: popup));
      var toggle = tester.widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile));
      expect(toggle.enabled, isFalse);
      expect(toggle.value, isFalse);
      final l = AppLocalizations.of(tester.element(find.byType(InformationGroupingControl)))!;
      expect(find.text(l.informationGroupingMinimum), findsOneWidget);
      if (popup) {
        await remote.show('weather', true);
      } else {
        await appearance.set('panelInformationPlacements', {'time': 'background', 'date': 'panel', 'weather': 'panel'});
      }
      await tester.pumpAndSettle();
      toggle = tester.widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile));
      expect(toggle.enabled, isTrue);
      expect(toggle.value, isTrue);
      await tester.tap(find.byType(RoundedSwitchListTile));
      await tester.pumpAndSettle();
      expect(popup ? remote.combinedInformation(true) : appearance.appearance.combinedInformation, isFalse);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets(
      'combined reorder crosses sides as one persistent unit: remote=$popup',
      (tester) async {
        await settings.setShowWeatherInStatusBar(true);
        await appearance.set('panelCombinedInformation', true);
        await remote.set('combinedInformation', true);
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
        if (popup) {
          await remote.set('combinedInformation', false);
        } else {
          await appearance.set('panelCombinedInformation', false);
        }
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
      await appearance.set('panelCombinedInformation', true);
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
      await remote.set('combinedInformation', true);
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
