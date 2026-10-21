import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/widgets/settings/panel_clock_style_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/settings_style_page.dart';
import 'dart:io';

import 'package:flauncher/gradients.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/memory_page.dart';
import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/settings/adb_action_confirmation.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';

import '../support/design_fixture.dart';

class DesignState {
  final String name;
  final String theme;
  final String language;
  final double scale;
  final Size size;
  final Color accent;
  final bool brightWallpaper;
  final bool economy;
  final bool focused;
  final bool topFocus;
  final bool bottom;
  final bool longLabels;
  final bool settingsMenuOnRight;
  final String? route;
  final String? dialog;
  final Map<String, dynamic> appearance;
  final Map<String, dynamic> category;
  final int rightSteps, downSteps;
  const DesignState(
    this.name, {
    this.theme = 'modern',
    this.language = 'ru',
    this.scale = 1,
    this.size = const Size(1920, 1080),
    this.accent = const Color(0xFF9674FF),
    this.brightWallpaper = false,
    this.economy = false,
    this.focused = true,
    this.topFocus = false,
    this.bottom = false,
    this.longLabels = false,
    this.settingsMenuOnRight = false,
    this.route,
    this.dialog,
    this.appearance = const {},
    this.category = const {},
    this.rightSteps = 0, this.downSteps = 0,
  });
}

const designStates = [
  DesignState('home-modern-focused'),
  DesignState('settings-clock-style', route: PanelClockStylePage.routeName,
    appearance: {'panelClockStyle': {'preset': 'elegant', 'inheritBackground': false, 'font': 'serif', 'size': 24, 'color': 0xffffd54f, 'background': false}}),
  DesignState('settings-date', route: DateTimeFormatPage.routeName),
  DesignState('home-clock-digital', appearance: {'panelClockStyle': {
    'preset': 'digital', 'inheritBackground': false, 'font': 'monospace', 'size': 32, 'weight': 700,
    'color': 0xff80efb0, 'backgroundColor': 0xff101820, 'radius': 4}}),
  DesignState('calendar-ru', dialog: 'calendar'),
  DesignState('calendar-rtl-large', dialog: 'calendar', language: 'ar', scale: 1.3),
  DesignState('home-shared-rows', category: {'layout': 'rows', 'rows': 2, 'columns': 4},
    appearance: {'labels': 'selected', 'focusScale': .15, 'inactiveOpacity': .4}, rightSteps: 4, downSteps: 1),
  DesignState('home-grid-window', category: {'layout': 'grid', 'columns': 4, 'maxRows': 1},
    appearance: {'labels': 'all'}, downSteps: 2),
  DesignState('home-free-three-rows', category: {'layout': 'rows', 'rows': 3, 'columns': 0},
    appearance: {'sectionScroll': 'free', 'size': 80, 'labels': 'all', 'sectionIcons': true}),
  DesignState('home-large-lift', category: {'layout': 'row', 'columns': 2},
    appearance: {'focusEffect': 'lift', 'focusLift': 50, 'labels': 'selected', 'sectionTitles': false}),
  DesignState('home-modern-idle', focused: false),
  DesignState('home-top-button', topFocus: true),
  DesignState('home-classic', theme: 'classic'),
  DesignState('home-premium', theme: 'premium'),
  DesignState('home-capsule', theme: 'capsule'),
  DesignState(
    'home-zero-radius-opacity',
    appearance: {'radius': 0, 'opacity': 0, 'labelSize': 20},
    longLabels: true,
  ),
  DesignState(
    'home-light-accent-bright',
    accent: Color(0xFFFFFF99),
    brightWallpaper: true,
  ),
  DesignState('home-dark-accent', accent: Color(0xFF17224A)),
  DesignState(
    'home-720p-large',
    size: Size(1280, 720),
    scale: 1.3,
    longLabels: true,
  ),
  DesignState('home-rtl', language: 'ar'),
  DesignState(
    'home-blur',
    appearance: {
      'blurTiles': true,
      'blurPanel': true,
      'opacity': .6,
    },
  ),
  DesignState(
    'home-blur-economy',
    economy: true,
    appearance: {
      'blurTiles': true,
      'blurPanel': true,
      'opacity': .6,
    },
  ),
  DesignState('settings-memory', route: MemoryPage.routeName),
  DesignState('settings-memory-bottom', route: MemoryPage.routeName, bottom: true),
  DesignState('settings-memory-saver', route: MemorySaverPage.routeName),
  DesignState('settings-root', route: 'settings_panel'),
  DesignState(
    'settings-root-720p-large',
    route: 'settings_panel',
    size: Size(1280, 720),
    scale: 1.3,
  ),
  DesignState('settings-root-bottom', route: 'settings_panel', bottom: true),
  DesignState('settings-nested', route: InterfaceSettingsPage.routeName),
  DesignState('settings-nested-right', route: InterfaceSettingsPage.routeName, settingsMenuOnRight: true),
  DesignState('dialog-editor-left', route: InterfaceSettingsPage.routeName, dialog: 'city'),
  DesignState('dialog-editor-right', route: InterfaceSettingsPage.routeName, dialog: 'city', settingsMenuOnRight: true),
  DesignState('dialog-adb-left', route: InterfaceSettingsPage.routeName, dialog: 'adb'),
  DesignState('dialog-adb-right', route: InterfaceSettingsPage.routeName, dialog: 'adb', settingsMenuOnRight: true, accent: Color(0xFFFFFF99)),
  DesignState(
    'settings-appearance-large',
    route: AppearanceSettingsPage.routeName,
    scale: 1.3,
  ),
  DesignState('settings-style', route: SettingsStylePage.routeName,
    appearance: {'settingsColor': 0xff14532d, 'settingsOpacity': .8,
      'settingsTextColor': 0xffffd54f, 'settingsTextSize': 20}),
  DesignState('settings-notification-style', route: SettingsStylePage.notificationsRouteName,
    appearance: {'noticeColor': 0xff1e3a8a, 'noticeOpacity': .75,
      'noticeTextColor': 0xffffffff, 'noticeTextSize': 18, 'noticeWidth': 400}, bottom: true),
  DesignState('settings-preview', route: AppearancePage.routeName),
  DesignState(
    'settings-preview-720p-large',
    route: AppearancePage.routeName,
    size: Size(1280, 720),
    scale: 1.3,
  ),
  DesignState(
    'settings-preview-classic',
    route: AppearancePage.routeName,
    theme: 'classic',
  ),
  DesignState(
    'settings-preview-premium',
    route: AppearancePage.routeName,
    theme: 'premium',
  ),
  DesignState(
    'settings-preview-capsule',
    route: AppearancePage.routeName,
    theme: 'capsule',
  ),
  DesignState(
    'settings-preview-zero',
    route: AppearancePage.routeName,
    appearance: {
      'radius': 0,
      'opacity': 0,
      'focusEffect': 'scale',
      'focusStrength': .2,
    },
  ),
  DesignState(
    'settings-preview-bottom',
    route: AppearancePage.routeName,
    bottom: true,
  ),
  DesignState(
    'settings-rtl-large',
    route: StatusBarPanelPage.routeName,
    language: 'ar',
    scale: 1.3,
  ),
  DesignState('settings-top-appearance', route: 'panel_appearance'),
  DesignState('settings-top-objects', route: StatusBarObjectsPage.routeName),
  DesignState(
    'home-top-custom',
    appearance: {
      'panelButtonsOrder': ['time', 'date', 'weather'],
      'panelInfoOrder': ['traffic', 'network', 'nightMode', 'sleepTimer', 'notifications', 'inputs', 'systemSettings', 'settings'],
      'panelColor': 0xff1e3a8a,
      'panelOpacity': .5,
      'panelTextSize': 22,
      'panelTextColor': 0xffffd54f,
      'panelFont': 'serif',
      'blurPanel': true,
    },
  ),
];

void main() {
  for (final state in designStates) {
    testWidgets(state.name, (tester) async {
      final fixture = await pumpDesignFixture(
        tester,
        size: state.size,
        theme: state.theme,
        language: state.language,
        scale: state.scale,
        accent: state.accent,
        economy: state.economy,
        longLabels: state.longLabels,
        settingsMenuOnRight: state.settingsMenuOnRight,
        appearanceValues: state.appearance,
        categoryValues: state.category,
        gradient: state.brightWallpaper
            ? FLauncherGradients.saintPetersburg
            : null,
      );
      if (state.route == MemoryPage.routeName) {
        const channel = MethodChannel('me.efesser.flauncher/method');
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getProcessMemoryUsage') {
            return {
              'pssBytes': 48 * 1024 * 1024,
              'rssBytes': 72 * 1024 * 1024,
              'graphicsBytes': 12 * 1024 * 1024,
            };
          }
          return null;
        });
        addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));
      }
      if (state.route != null) {
        final context = tester.element(find.byIcon(Icons.settings_outlined));
        showLauncherDialog<void>(
          context: context,
          styleDialog: false,
          barrierColor: Colors.transparent,
          builder: (_) => SettingsPanel(initialRoute: state.route),
        );
      } else if (state.topFocus) {
        // The first top button owns its real production FocusNode.
        final focus = tester
            .widgetList<Focus>(
              find.ancestor(
                of: find.byIcon(Icons.settings_outlined),
                matching: find.byType(Focus),
              ),
            )
            .firstWhere(
              (focus) => focus.focusNode != null && focus.canRequestFocus,
            );
        focus.focusNode!.requestFocus();
      } else if (state.focused) {
        tester
            .widget<InkWell>(
              find
                  .descendant(
                    of: find.byKey(const Key('demo.0')).first,
                    matching: find.byType(InkWell),
                  )
                  .first,
            )
            .focusNode!
            .requestFocus();
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
      }
      await tester.pumpAndSettle();
      for (var i = 0; i < state.rightSteps; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle();
      }
      for (var i = 0; i < state.downSteps; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
      }
      if (state.dialog != null) {
        final context = state.dialog == 'calendar'
            ? tester.element(find.byIcon(Icons.settings_outlined))
            : tester.element(find.byType(InterfaceSettingsPage));
        final l = AppLocalizations.of(context)!;
        if (state.dialog == 'calendar') {
          showLauncherDialog<void>(context: context,
            builder: (_) => PanelCalendarDialog(today: DateTime(2026, 10, 4)));
        } else if (state.dialog == 'adb') {
          confirmAdbAction(context, l.adbHome, 'home', [
            "cmd package set-home-activity 'example.launcher/MainActivity'",
          ]);
        } else {
          final tile = SettingsTextTile(title: l.weatherLocationManual, value: 'Moscow', onChanged: (_) {});
          (tile.build(context) as FocusableSettingsTile).onPressed!();
        }
        await tester.pumpAndSettle();
      }
      if (state.bottom) {
        await tester.drag(find.byType(Scrollable).last, const Offset(0, -2000));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
      // Finders capture the logical viewport (960×540 / 640×360), DPR is 2.
      await expectLater(
        find.byKey(fixture.boundary),
        matchesGoldenFile('goldens/${state.name}.png'),
      );
      debugDisableShadows = true;
    }, skip: !Platform.isWindows || !AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == state.language,
    )); // Render only locales supported by the current build.
  }
}
