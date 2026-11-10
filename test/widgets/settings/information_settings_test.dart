import 'dart:convert';

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
import 'package:flauncher/widgets/weather_glyph.dart';
import 'package:flauncher/widgets/animated_character.dart';
import 'package:flauncher/widgets/date_time_widget.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/information_settings_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/color_palette_dialog.dart';
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


  testWidgets('top-panel layout stays disabled for quick-panel-only grouping', (tester) async {
    await appearance.set('panelInformationPlacements', {
      'time': 'background', 'date': 'background', 'weather': 'hidden',
    });
    await remote.set('combinedInformation', true);
    await pump(tester, const PanelInformationSettingsPage());
    final l = AppLocalizations.of(tester.element(find.byType(PanelInformationSettingsPage)))!;
    await tester.tap(find.text(l.informationLayout));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text(l.informationPosition), 150);
    FocusableSettingsTile control(String title) =>
        tester.widget<FocusableSettingsTile>(find.ancestor(
          of: find.text(title),
          matching: find.byType(FocusableSettingsTile),
        ).first);
    for (final title in [l.informationPosition, l.informationSpacing]) {
      expect(control(title).enabled, isFalse);
    }
    await remote.show('time', false);
    await tester.pumpAndSettle();
    for (final title in [l.informationPosition, l.informationSpacing]) {
      expect(control(title).enabled, isFalse);
    }
    await appearance.set('panelInformationPlacements', {
      'time': 'panel', 'date': 'panel', 'weather': 'hidden',
    });
    await appearance.set('panelInformationStyle', {
      'clockOnRight': true, 'spacing': 12,
    });
    await appearance.set('panelCombinedInformation', true);
    await tester.pumpAndSettle();
    for (final title in [l.informationPosition, l.informationSpacing]) {
      expect(control(title).enabled, isTrue);
    }
    await tester.tap(find.byKey(const ValueKey('information_grouping')));
    await tester.pumpAndSettle();
    for (final title in [l.informationPosition, l.informationSpacing]) {
      expect(control(title).enabled, isFalse);
    }
    await tester.tap(find.text(l.informationPosition));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(appearance.appearance.informationStyle.clockOnRight, isTrue);
    expect(appearance.appearance.informationStyle.spacing, 12);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('placement has one entry point and formats have one page', (tester) async {
    await pump(tester, const InformationObjectsSection());
    final l = AppLocalizations.of(tester.element(find.byType(InformationObjectsSection)))!;
    expect(find.byType(InformationVisibility), findsNothing);
    expect(find.text(l.informationGroup), findsOneWidget);
    expect(find.textContaining('${l.informationTime}:'), findsNothing);
    await tester.tap(find.widgetWithText(FocusableSettingsTile, l.settings));
    await tester.pumpAndSettle();
    expect(find.byType(InformationVisibility), findsOneWidget);
    expect(find.text(l.informationTapAction), findsNothing);
    expect(find.text(l.dateCalendarEnabled), findsNothing);
    final formats = find.text(l.informationComposition);
    final appearance = find.text(l.informationPanelAppearance);
    final background = find.text(l.backgroundInformationAppearance);
    expect(tester.getTopLeft(formats).dy, lessThan(tester.getTopLeft(appearance).dy));
    expect(tester.getTopLeft(appearance).dy, lessThan(tester.getTopLeft(background).dy));
    await tester.tap(formats);
    await tester.pumpAndSettle();
    expect(find.byType(TimeFormatSettingsTile), findsOneWidget);
    expect(find.byType(DateFormatSettingsTile), findsOneWidget);
    expect(find.text(l.dateCalendarEnabled), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('date palette saves separately and restores inheritance', (tester) async {
    await appearance.set('weatherTextColor', 0xff16b44c);
    await appearance.set('panelInformationStyle', {'clockColor': 0xffaa3344});
    await pump(tester, const InformationSectionPage(background: false, section: 'colors'));
    final headings = [for (final id in ['common', 'time', 'date', 'weather'])
      find.byKey(ValueKey('information-$id-section'))];
    final positions = <double>[];
    double? glowY;
    for (final heading in headings) {
      await tester.scrollUntilVisible(heading, 100);
      await tester.pumpAndSettle();
      expect(find.descendant(of: heading, matching: find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.header == true)), findsOneWidget);
      final offset = Scrollable.of(tester.element(heading)).position.pixels;
      positions.add(tester.getTopLeft(heading).dy + offset);
      if (heading == headings.first) {
        glowY = tester.getCenter(find.text('Свечение текста')).dy + offset;
      }
    }
    for (var index = 1; index < positions.length; index++) {
      expect(positions[index], greaterThan(positions[index - 1]));
    }
    expect(glowY, greaterThan(positions.first));
    expect(glowY, lessThan(positions[1]));
    final title = find.text('Цвет даты');
    await tester.scrollUntilVisible(title, -100);
    await tester.pumpAndSettle();
    await tester.ensureVisible(title);
    await tester.pumpAndSettle();
    await tester.tap(title);
    await tester.pumpAndSettle();
    final value = appearancePalette[4];
    await tester.tap(find.byKey(ValueKey('palette-$value')));
    await tester.pumpAndSettle();
    final restored = TileAppearance.decode(appearance.preferences.getString(tileAppearanceKey));
    expect(restored.dateTextColor, Color(value));
    expect(restored.informationStyle.clockColor, const Color(0xffaa3344));
    expect(restored.weatherTextColor, const Color(0xff16b44c));
    await tester.tap(title);
    await tester.pumpAndSettle();
    await tester.tap(find.text('По умолчанию'));
    await tester.pumpAndSettle();
    expect(appearance.appearance.dateTextColor, isNull);
    expect(appearance.appearance.informationStyle.clockColor, const Color(0xffaa3344));
    expect(appearance.appearance.weatherTextColor, const Color(0xff16b44c));
    await tester.pumpWidget(const SizedBox());
  });

  for (final background in [false, true]) {
    for (final split in [false, true]) {
      testWidgets('default color shows inheritance for every object: background=$background split=$split', (tester) async {
        final styleKey = background ? 'panelBackgroundInformationStyle' : 'panelInformationStyle';
        await appearance.set(styleKey, {
          'clockColor': (split ? Colors.black : Colors.white).toARGB32(),
          'color': (split ? Colors.black : Colors.white).toARGB32(),
          'splitColors': split,
          'hoursColor': Colors.black.toARGB32(),
          'minutesColor': Colors.white.toARGB32(),
        });
        for (final key in ['dateTextColor', 'weatherTextColor', 'weatherIconColor']) {
          await appearance.setInformationAppearance(key, Colors.black.toARGB32(), background: background);
        }
        final other = appearance.appearance.forInformation(background: !background);
        final otherStyle = background ? other.informationStyle.values : other.backgroundInformationStyle.values;
        await pump(tester, InformationSectionPage(background: background, section: 'colors'));
        final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
        final titles = [
          if (split) ...[l.clockHoursColor, l.clockMinutesColor] else l.clockTextColor,
          l.informationDateColor, l.weatherTextColor, l.weatherIconColor,
        ];
        for (final title in titles) {
          final row = find.widgetWithText(FocusableSettingsTile, title);
          await tester.scrollUntilVisible(row, 100);
          await tester.pumpAndSettle();
          expect(find.descendant(of: row, matching: find.byIcon(Icons.link)), findsNothing);
          await tester.tap(row);
          await tester.pumpAndSettle();
          await tester.tap(find.text(title == l.weatherIconColor ? l.weatherIconFollowsText : l.defaultOption));
          await tester.pumpAndSettle();
          expect(find.descendant(of: row, matching: find.byIcon(Icons.link)), findsOneWidget);
          expect(tester.widget<Icon>(find.descendant(of: row, matching: find.byIcon(Icons.link))).color,
            split ? Colors.white : Colors.black);
          expect(Focus.of(tester.element(find.text(title))).hasFocus, isTrue);
          await tester.tap(row);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(ValueKey('palette-${appearancePalette[4]}')));
          await tester.pumpAndSettle();
          expect(find.descendant(of: row, matching: find.byIcon(Icons.link)), findsNothing);
          await tester.tap(row);
          await tester.pumpAndSettle();
          await tester.tap(find.text(title == l.weatherIconColor ? l.weatherIconFollowsText : l.defaultOption));
          await tester.pumpAndSettle();
          expect(find.descendant(of: row, matching: find.byIcon(Icons.link)), findsOneWidget);
        }
        final restored = TileAppearance.decode(appearance.preferences.getString(tileAppearanceKey));
        final profile = restored.forInformation(background: background);
        final clock = background ? profile.backgroundInformationStyle : profile.informationStyle;
        expect(profile.dateTextColor, isNull);
        expect(profile.weatherTextColor, isNull);
        expect(profile.weatherIconColor, isNull);
        expect(split ? clock.hoursColor : clock.clockColor, isNull);
        if (split) expect(clock.minutesColor, isNull);
        final restoredOther = restored.forInformation(background: !background);
        expect(restoredOther.dateTextColor, other.dateTextColor);
        expect(restoredOther.weatherTextColor, other.weatherTextColor);
        expect(restoredOther.weatherIconColor, other.weatherIconColor);
        expect(background ? restoredOther.informationStyle.values : restoredOther.backgroundInformationStyle.values, otherStyle);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final profile in [
    (background: false, section: 'typography'),
    (background: false, section: 'colors'),
    (background: true, section: 'colors'),
  ]) {
    for (final scale in [1.0, 1.5]) {
      testWidgets('reset scrolls after controls and is reachable by remote: $profile scale=$scale', (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await appearance.set('panelInformationStyle', {'inheritPanelTypography': false});
        await pump(tester, SizedBox(
          height: 300,
          child: InformationSectionPage(background: profile.background, section: profile.section),
        ), scale: scale);
        final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
        final reset = find.text(profile.section == 'typography'
            ? l.informationResetTypography : l.informationResetPositionSize);
        bool resetFocused() => reset.evaluate().isNotEmpty &&
            Focus.of(tester.element(reset)).hasFocus;
        expect(reset.hitTestable(), findsNothing);
        expect(resetFocused(), isFalse);
        for (var step = 0; step < 30 && !resetFocused(); step++) {
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.pumpAndSettle();
        }
        expect(resetFocused(), isTrue);
        expect(reset.hitTestable(), findsOneWidget);
        final position = Scrollable.of(tester.element(reset)).position;
        expect(position.pixels, greaterThan(0));
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(resetFocused(), isFalse);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(resetFocused(), isTrue);
        // The action leaves the screen together with the rest of the list.
        position.jumpTo(0);
        await tester.pumpAndSettle();
        expect(reset.hitTestable(), findsNothing);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  for (final background in [false, true]) {
    for (final legacy in [false, true]) {
      testWidgets('colors reset confirms and changes only this screen: background=$background legacy=$legacy', (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const retained = {
          'inheritPanelTypography': false, 'size': 20, 'font': 'serif',
          'preset': 'italic', 'italic': true, 'weight': 700,
          'animate': true, 'showColon': false, 'clockOnRight': true, 'spacing': 24,
          'inheritBackground': false, 'background': true,
          'backgroundColor': 0xff443322, 'opacity': .7, 'radius': 12,
        };
        const customColors = {
          'color': 0xffaa3344, 'clockColor': 0xffbb4455,
          'hoursColor': 0xffcc5566, 'minutesColor': 0xffdd6677,
          'splitColors': true, 'glow': true,
        };
        const customProfile = {
          'dateTextColor': 0xff55aacc, 'weatherTextColor': 0xff66bbdd,
          'weatherIconColor': 0xff77ccee, 'weatherIconPack': 'pixel',
        };
        await appearance.preferences.setString(tileAppearanceKey, jsonEncode({
          'panelInformationStyle': {...retained, ...customColors},
          if (!legacy)
            'panelBackgroundInformationStyle': {...retained, 'font': 'manrope', ...customColors},
          ...customProfile,
          if (!legacy) ...{
            'panelInformationAppearance': customProfile,
            'backgroundInformationAppearance': customProfile,
          },
          'panelCombinedInformation': true, 'panelTextColor': 0xff123456,
          'panelTextSize': 21, 'panelFont': 'monospace',
          'panelInformationPlacements': {'time': 'background', 'date': 'panel', 'weather': 'hidden'},
          'panelBackgroundInformationSize': 120,
          'panelBackgroundInformationOffset': 25,
          'panelBackgroundInformationVerticalOffset': 15,
          'panelBackgroundInformationAboveLandscape': true,
          'panelBackgroundInformationAboveWeather': true,
        }));
        final before = appearance.appearance;
        final beforeText = appearance.preferences.getString(tileAppearanceKey);
        final styleKey = background ? 'panelBackgroundInformationStyle' : 'panelInformationStyle';
        final profileKey = TileAppearance.informationAppearanceKey(background);
        await pump(tester, InformationSectionPage(background: background, section: 'colors'));
        final l = AppLocalizations.of(tester.element(find.byType(InformationSectionPage)))!;
        final reset = find.text(l.informationResetPositionSize);
        await tester.scrollUntilVisible(reset, 120);
        await tester.pumpAndSettle();
        expect(reset.hitTestable(), findsOneWidget);
        Focus.of(tester.element(reset)).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(LauncherAlertDialog), findsOneWidget);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(appearance.preferences.getString(tileAppearanceKey), beforeText);
        expect(Focus.of(tester.element(reset)).hasFocus, isTrue);
        var notifications = 0;
        void changed() => notifications++;
        appearance.addListener(changed);
        await tester.tap(reset);
        await tester.pumpAndSettle();
        await tester.tap(find.descendant(of: find.byType(LauncherAlertDialog),
          matching: find.text(l.informationResetPositionSize)).last);
        await tester.pumpAndSettle();
        appearance.removeListener(changed);
        expect(notifications, 1);
        final restored = AppearanceService(appearance.preferences);
        final after = restored.appearance;
        final style = background ? after.backgroundInformationStyle : after.informationStyle;
        expect(style.values, {...retained, if (background && !legacy) 'font': 'manrope'});
        expect(style.splitColors, isFalse);
        final profile = after.forInformation(background: background);
        expect(profile.dateTextColor, isNull);
        expect(profile.weatherTextColor, isNull);
        expect(profile.weatherIconColor, isNull);
        expect(profile.weatherIconPack, WeatherIconPack.outline);
        final beforeOther = before.forInformation(background: !background);
        final afterOther = after.forInformation(background: !background);
        expect(afterOther.dateTextColor, beforeOther.dateTextColor);
        expect(afterOther.weatherTextColor, beforeOther.weatherTextColor);
        expect(afterOther.weatherIconColor, beforeOther.weatherIconColor);
        expect(afterOther.weatherIconPack, beforeOther.weatherIconPack);
        expect(background ? after.informationStyle.values : after.backgroundInformationStyle.values,
          background ? before.informationStyle.values : before.backgroundInformationStyle.values);
        final outsideBefore = {...before.values}..remove(styleKey)..remove(profileKey);
        final outsideAfter = {...after.values}..remove(styleKey)..remove(profileKey);
        if (!background && legacy) outsideAfter.remove('panelBackgroundInformationStyle');
        expect(outsideAfter, outsideBefore);
        restored.dispose();
        expect(reset.hitTestable(), findsOneWidget);
        expect(Focus.of(tester.element(reset)).hasFocus, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }

  testWidgets('weather-only combined block stays visible and actionable without data', (tester) async {
    var opened = false;
    await pump(tester, CombinedInformation(appearance: appearance.appearance,
      showTime: false, showDate: false, showWeather: true,
      timeFormat: settings.timeFormat, dateFormat: settings.dateFormat,
      onPressed: () => opened = true));
    expect(find.byType(WeatherGlyph), findsOneWidget);
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
                    'inheritPanelTypography': false,
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
        'inheritPanelTypography': false,
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
          await appearance.set(key, {'inheritPanelTypography': false, 'font': entry.key, 'weight': 900});
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
    'combined editor retains family and separate style; disables unused layout controls',
    (tester) async {
      await appearance.set('panelCombinedInformation', true);
      await appearance.set('panelClockStyle', {'font': 'serif', 'size': 33});
      await appearance.set('panelInformationStyle', {
        'inheritPanelTypography': false,
        'font': 'manrope',
        'size': 20,
      });
      await pump(tester, const PanelClockStylePage(combined: true));
      await tester.ensureVisible(find.text('Стиль шрифта'));
      Focus.of(tester.element(find.text('Стиль шрифта'))).requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
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
      for (final title in ['Расположение часов и текста', 'Расстояние между часами и текстом']) {
        final tile = find.ancestor(
          of: find.text(title),
          matching: find.byType(FocusableSettingsTile),
        ).first;
        expect(tester.widget<FocusableSettingsTile>(tile).enabled, isFalse);
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  test(
    'separate and combined styling survive mode changes, reload and backup',
    () async {
      await appearance.set('panelClockStyle', {'font': 'serif', 'size': 33});
      await appearance.set('panelInformationStyle', {
        'inheritPanelTypography': false,
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
      expect(restored.informationStyle.inheritsPanelTypography, isFalse);
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
        bool separateColors = false,
      }) => SizedBox(
        height: kToolbarHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: CombinedInformation(
            appearance: TileAppearance({
              if (separateColors) 'dateTextColor': 0xff6699dd,
              if (separateColors) 'weatherTextColor': 0xff55bb77,
              'panelInformationStyle': {
                'inheritPanelTypography': false,
                'font': 'manrope',
                'size': size,
                'color': 0xff80efb0,
                if (separateColors) 'clockColor': 0xffdd7799,
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
        final icon = tester.widget<WeatherGlyph>(find.byType(WeatherGlyph));
        expect(icon.color, const Color(0xff80efb0));
        expect(icon.shadows, isNotEmpty);
        expect(
          tester.widget<Text>(find.text('20°C')).style!.fontFamily,
          'Manrope',
        );
      }
      await pump(tester, block(20, separateColors: true));
      final clock = find.byKey(const Key('statusbar_clock'));
      final digits = tester.widgetList<AnimatedCharacter>(
        find.descendant(of: clock, matching: find.byType(AnimatedCharacter)),
      );
      expect(digits, isNotEmpty);
      expect(digits.map((digit) => digit.textStyle?.color), everyElement(const Color(0xffdd7799)));
      final date = tester.widget<DateTimeWidget>(find.byKey(const Key('statusbar_date'))).textStyle!;
      expect(date.color, const Color(0xff6699dd));
      expect(date.shadows?.single.color, const Color(0xff6699dd));
      expect(tester.widget<Text>(find.text('20°C')).style?.color, const Color(0xff55bb77));
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
