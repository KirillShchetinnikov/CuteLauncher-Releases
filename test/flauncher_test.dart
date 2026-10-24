import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/wallpaper_background.dart';
import 'package:flauncher/widgets/app_artwork_background.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/widgets/settings/remote_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flauncher/flauncher.dart';
import 'package:flauncher/database.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/home_section.dart';

import 'package:flauncher/widgets/app_card.dart';
import 'package:flauncher/widgets/appearance_surface.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import 'helpers.dart';
import 'mocks.dart';
import 'mocks.mocks.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  testWidgets('app artwork follows focused cards in the real launcher and preserves wallpaper', (tester) async {
    SharedPreferences.setMockInitialValues({'background_source': 'app', 'card_focus_mode': 'first'});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    await appearance.set('focusPulse', false);
    final settings = SettingsService(prefs);
    final apps = mkAppService();
    final category = fakeCategory(type: CategoryType.row)
      ..applications.addAll([fakeApp(packageName: 'art.first'), fakeApp(packageName: 'art.second')]);
    when(apps.launcherSections).thenReturn([category]);
    when(apps.categories).thenReturn([category]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance);
    expect(find.byType(AppArtworkBackground), findsOneWidget);
    getFocusNodeForApp(tester, 'art.first')!.requestFocus();
    await tester.pumpAndSettle();
    expect(appearance.focusedAppImage.value, isNotNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'art.second'), isTrue);
    final state = tester.state<FLauncherState>(find.byType(FLauncher));
    state.returnHome();
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'art.first'), isTrue);
    await settings.setBackgroundSource('picture');
    await tester.pumpAndSettle();
    expect(find.byType(AppArtworkBackground), findsNothing);
    expect(find.byType(WallpaperBackground), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    settings.dispose(); appearance.dispose();
  });
  for (final onRight in [false, true]) {
    testWidgets('remote settings preview survives nested pages and closes: right=$onRight', (tester) async {
      SharedPreferences.setMockInitialValues({
        'auto_hide_app_bar': true,
        'settings_menu_on_right': onRight,
        'show_time_in_status_bar': false,
        'show_date_in_status_bar': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final panel = RemotePanelService(prefs);
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      for (final id in RemotePanelService.ids) {
        if (!['settings', 'time'].contains(id)) await panel.show(id, false);
      }
      await panel.set('inheritAppearance', false);
      await panel.setAppearance('panelColor', 0xff123456);
      await panel.setAppearance('panelOpacity', .4);
      final apps = mkAppService();
      when(apps.launcherSections).thenReturn([]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings,
        appearance: appearance, remotePanel: panel, pixelRatio: 2,
        locale: Locale(onRight ? 'en' : 'ru'));
      final bar = find.byType(FocusAwareAppBar);
      final state = tester.state<FocusAwareAppBarState>(bar);
      state.focusSettings();
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined).first);
      await tester.pumpAndSettle();
      final root = tester.element(find.byType(SettingsPanelPage));
      Navigator.of(root).pushNamed(StatusBarPanelPage.routeName);
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(tester.element(find.byType(StatusBarPanelPage)))!;
      await tester.tap(find.text(l.remotePanel));
      await tester.pumpAndSettle();
      expect(panel.previewActive, isTrue);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, same(panel));
      expect(tester.getSize(find.byKey(const Key('top_panel_visibility'))).height, kToolbarHeight);
      void expectClearToolbar() {
        final side = find.byType(SidePanelDialog);
        expect(tester.widget<SidePanelDialog>(side).topInset, kToolbarHeight);
        final navigator = find.descendant(of: side, matching: find.byType(Navigator));
        final rect = tester.getRect(navigator);
        expect(rect.top, greaterThanOrEqualTo(kToolbarHeight));
        expect(rect.bottom, lessThanOrEqualTo(540));
      }
      expectClearToolbar();
      var appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color,
          const Color(0xff123456).withValues(alpha: .4));
      await panel.setAppearance('panelOpacity', .7);
      await tester.pumpAndSettle();
      appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color,
          const Color(0xff123456).withValues(alpha: .7));
      await tester.tap(find.text(l.appearanceSettings));
      await tester.pumpAndSettle();
      expect(find.byType(AppearancePage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.tap(find.text(l.remotePanelInheritAppearance));
      await tester.pumpAndSettle();
      expect(panel.inheritAppearance, isTrue);
      appBar = tester.widget<AppBar>(find.descendant(of: bar, matching: find.byType(AppBar)));
      expect((appBar.flexibleSpace! as ColoredBox).color.a, 0);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      await tester.tap(find.text(l.topPanelObjects));
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelObjectsPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.tap(find.descendant(of: find.byKey(const ValueKey('time')), matching: find.byType(Switch)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('statusbar_clock')), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      final order = find.text(l.panelObjectOrder);
      await tester.ensureVisible(order);
      await tester.tap(order);
      await tester.pumpAndSettle();
      expect(find.byType(PanelOrderPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      expectClearToolbar();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(RemotePanelPage), findsOneWidget);
      expect(panel.previewActive, isTrue);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(panel.previewActive, isFalse);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, isNull);
      await tester.tap(find.text(l.remotePanel));
      await tester.pumpAndSettle();
      expect(panel.previewActive, isTrue);
      Navigator.of(tester.element(find.byType(RemotePanelPage)), rootNavigator: true).pop();
      await tester.pumpAndSettle();
      expect(panel.previewActive, isFalse);
      expect(tester.widget<FocusAwareAppBar>(bar).remotePanel, isNull);
      expect(prefs.getString(RemotePanelService.preferenceKey), isNot(contains('preview')));
      await tester.pumpWidget(const SizedBox());
      settings.dispose(); appearance.dispose(); panel.dispose();
    });
  }
  for (final mode in ['row', 'rows', 'grid']) {
    testWidgets('RTL $mode mirrors tiles, navigation and movement', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final top = fakeCategory(type: mode == 'grid' ? CategoryType.grid : CategoryType.row, columnsCount: 4)
        ..applications.addAll(List.generate(16, (i) => fakeApp(packageName: 'rtl.top.$i')));
      final bottom = fakeCategory(order: 1, type: mode == 'grid' ? CategoryType.grid : CategoryType.row, columnsCount: 4)
        ..applications.addAll(List.generate(16, (i) => fakeApp(packageName: 'rtl.bottom.$i')));
      if (mode != 'grid') {
        await appearance.setTapeRows(top.id, mode == 'rows' ? 2 : 1);
        await appearance.setTapeRows(bottom.id, mode == 'rows' ? 2 : 1);
      }
      when(apps.launcherSections).thenReturn([top, bottom]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(),
          appearance: appearance, locale: const Locale('ar'));
      Finder card(String id) => find.byWidgetPredicate((w) => w is AppCard && w.application.packageName == id);
      expect(tester.getCenter(card('rtl.top.0')).dx,
          greaterThan(tester.getCenter(card('rtl.top.1')).dx));
      expect(tester.getRect(card('rtl.top.0')).right, lessThanOrEqualTo(1920));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.1'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, mode == 'row' ? 'rtl.bottom.1' : mode == 'rows' ? 'rtl.top.9' : 'rtl.top.5'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.1'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rtl.top.0'), isTrue);
      tester.widget<AppCard>(card('rtl.top.0')).onMove(AxisDirection.left);
      verify(apps.reorderApplication(top, 0, 1)).called(1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final rows in [1, 2]) {
    testWidgets('down from settings restores the scrolled tape app: $rows rows', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final tape = fakeCategory(type: CategoryType.row)
        ..applications.addAll(List.generate(rows * 14, (i) => fakeApp(packageName: 'top.return.$i')));
      await appearance.setTapeRows(tape.id, rows);
      when(apps.launcherSections).thenReturn([tape]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
      for (var i = 0; i < 10; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
      }
      expect(isAppCardFocused(tester, 'top.return.10'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(getSettingsFocusNode(tester)!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'top.return.10'), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'top.return.11'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('Home resets the tape navigation column to its current first card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final appearance = AppearanceService(prefs);
    final settings = SettingsService(prefs);
    await settings.setCardFocusMode(CardFocusMode.first);
    await settings.setAppHighlightAnimationEnabled(false);
    await settings.setAppKeyClickEnabled(false);
    final apps = mkAppService();
    final tape = fakeCategory(type: CategoryType.row)
      ..applications.addAll(List.generate(20, (i) => fakeApp(packageName: 'home.column.$i')));
    await appearance.setTapeRows(tape.id, 2);
    when(apps.launcherSections).thenReturn([tape]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings, appearance: appearance);
    for (var i = 0; i < 9; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.19'), isTrue);
    tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.0'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'home.column.10'), isTrue);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose(); settings.dispose();
  });
  for (final type in [CategoryType.row, CategoryType.grid]) {
    testWidgets('sort mode changes reorder focused tiles immediately: $type', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      final apps = mkAppService();
      final a = fakeApp(packageName: 'sort.a', name: 'A');
      final b = fakeApp(packageName: 'sort.b', name: 'B');
      final c = fakeApp(packageName: 'sort.c', name: 'C');
      final category = fakeCategory(sort: CategorySort.manual, type: type)
        ..applications.addAll([c, b, a]);
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
      getFocusNodeForApp(tester, 'sort.b')!.requestFocus();
      await tester.pumpAndSettle();
      List<String> order() => tester.widgetList<AppCard>(find.byType(AppCard))
          .map((card) => card.application.packageName).toList();
      for (final sort in [CategorySort.alphabetical, CategorySort.manual, CategorySort.mostUsed, CategorySort.alphabetical]) {
        category.sort = sort;
        final expected = sort == CategorySort.alphabetical ? [a, b, c] : [c, b, a];
        category.applications..clear()..addAll(expected);
        await appearance.set('animateReordering', true);
        await tester.pumpAndSettle();
        expect(order(), expected.map((app) => app.packageName).toList());
        expect(isAppCardFocused(tester, 'sort.b'), isTrue);
      }
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('active section stays opaque in top bar and settings; other sections stay dim', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('inactiveOpacity', .2);
    final apps = mkAppService();
    final top = fakeCategory(name: 'Top')..applications.add(fakeApp(packageName: 'opacity.top'));
    final bottom = fakeCategory(name: 'Bottom')..applications.add(fakeApp(packageName: 'opacity.bottom'));
    when(apps.launcherSections).thenReturn([top, bottom]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
    double opacity(String name) => tester.widget<AnimatedOpacity>(find.descendant(
      of: find.byWidgetPredicate((w) => w is HomeSection && w.category.name == name),
      matching: find.byType(AnimatedOpacity)).first).opacity;
    for (final entry in [('Top', 'opacity.top', 'Bottom'), ('Bottom', 'opacity.bottom', 'Top')]) {
      getFocusNodeForApp(tester, entry.$2)!.requestFocus();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
      expect(opacity(entry.$3), .2);
      final settingsNode = getSettingsFocusNode(tester)!;
      settingsNode.requestFocus();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsPanelPage), findsOneWidget);
      expect(opacity(entry.$1), 1);
      expect(opacity(entry.$3), .2);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(opacity(entry.$1), 1);
    }
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });
  for (final titles in [true, false]) {
    testWidgets('selected name stays in header without moving bottom grid, titles=$titles', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('sectionTitles', titles);
      await appearance.set('sectionPosition', 1);
      await appearance.set('focusEffect', 'border');
      final apps = mkAppService();
      final category = fakeCategory(name: 'Мои приложения', type: CategoryType.grid, columnsCount: 4);
      category.applications.addAll(List.generate(8, (i) => fakeApp(
        packageName: 'header.$i', name: i == 0 ? 'Первое' : 'Очень длинное название выбранного приложения $i',
      )));
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps,
        mkSettingsService(), appearance: appearance);
      getFocusNodeForApp(tester, 'header.0')!.requestFocus();
      await tester.pumpAndSettle();
      final before = getFocusNodeForApp(tester, 'header.0')!.rect;
      await appearance.set('labels', 'selected');
      await tester.pumpAndSettle();
      final label = find.byKey(ValueKey(('selected-app-label', category.id)));
      expect(tester.widget<Text>(label).data, 'Первое');
      expect(tester.getRect(label).bottom, lessThan(getFocusNodeForApp(tester, 'header.0')!.rect.top));
      if (titles) {
        expect(getFocusNodeForApp(tester, 'header.0')!.rect, before);
        expect((tester.getCenter(label).dy - tester.getCenter(find.text('Мои приложения')).dy).abs(), lessThan(1));
      } else {
        expect(find.text('Мои приложения'), findsNothing);
      }
      final cell = getFocusNodeForApp(tester, 'header.1')!.rect;
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(label).data, 'Очень длинное название выбранного приложения 1');
      expect(getFocusNodeForApp(tester, 'header.1')!.rect, cell);
      expect(isAppCardFocused(tester, 'header.1'), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  for (final type in [CategoryType.row, CategoryType.grid]) {
    testWidgets('Up reaches settings even when an update is available: $type', (tester) async {
      SharedPreferences.setMockInitialValues({automaticUpdatesKey: true,
        updateCheckTimeKey: DateTime.now().millisecondsSinceEpoch});
      final updates = UpdateService(await SharedPreferences.getInstance(),
        environment: () async => {'play': false, 'version': '1.0.0',
          'versionCode': 1, 'abis': ['armeabi-v7a']});
      updates.release = AppRelease('v1.0.0+2', Uri.parse('https://github.com/update.apk'), 3, null);
      final apps = mkAppService();
      final category = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'notice.app'));
      when(apps.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), updates: updates);
      getFocusNodeForApp(tester, 'notice.app')!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isSettingsIconFocused(tester), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'notice.app'), isTrue);
      await updates.setNotificationsEnabled(false);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(isSettingsIconFocused(tester), isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      updates.dispose();
    });
  }
  for (final labels in ['none', 'selected', 'all']) {
    testWidgets('outline shadow toggle preserves grid cell bounds with labels=$labels', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('labels', labels);
      await appearance.set('focusEffect', 'border');
      final service = mkAppService();
      final category = fakeCategory(type: CategoryType.grid, columnsCount: 4);
      category.applications.addAll(List.generate(8, (i) => fakeApp(packageName: 'shadow.$i')));
      when(service.launcherSections).thenReturn([category]);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), service,
        mkSettingsService(), appearance: appearance);
      await tester.pumpAndSettle();
      final before = [for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect];
      await appearance.set('focusShadow', true);
      await tester.pumpAndSettle();
      expect([for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect], before);
      await appearance.set('focusShadow', false);
      await tester.pumpAndSettle();
      expect([for (var i = 0; i < 8; i++) getFocusNodeForApp(tester, 'shadow.$i')!.rect], before);
      await tester.pumpWidget(const SizedBox());
      appearance.dispose();
    });
  }
  testWidgets('limited category grid keeps every row reachable by remote', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final service = mkAppService();
    final category = Category(id: 77, name: 'Applications', type: CategoryType.grid, columnsCount: 6);
    category.applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'limited.$i')));
    when(service.launcherSections).thenReturn([category]);
    await appearance.setCategory(77, 'maxRows', 2);
    await appearance.setCategory(77, 'padding', 16);
    await appearance.setCategory(77, 'background', 0x8011141B);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, mkSettingsService(), appearance: appearance);
    getFocusNodeForApp(tester, 'limited.0')!.requestFocus();
    await tester.pumpAndSettle();
    for (var row = 1; row < 5; row++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(getFocusNodeForApp(tester, 'limited.${row * 6}')!.hasFocus, isTrue);
    }
    for (var row = 3; row >= 0; row--) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(getFocusNodeForApp(tester, 'limited.${row * 6}')!.hasFocus, isTrue);
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  testWidgets('each size step changes grid tiles; fixed columns win over global size', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final category = fakeCategory(columnsCount: 6)
      ..applications.addAll(List.generate(30, (i) => fakeApp(packageName: 'size.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'layout', 'auto');
    await appearance.set('size', 128);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    final tile = find.byKey(const Key('size.0'));
    final before = tester.getSize(tile);
    await appearance.set('size', 136);
    await tester.pumpAndSettle();
    expect(tester.getSize(tile).width - before.width, closeTo(8 * 16 / 9, 0.01));
    await appearance.setCategory(category.id, 'layout', 'columns');
    await tester.pumpAndSettle();
    final fixed = tester.getSize(tile);
    await appearance.set('size', 160);
    await tester.pumpAndSettle();
    expect(tester.getSize(tile), fixed);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'size.6'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  testWidgets('multiple rows scroll together, preserve order and never wrap', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final category = fakeCategory()..applications.addAll(List.generate(23, (i) => fakeApp(packageName: 'rows.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'layout', 'rows');
    await appearance.setCategory(category.id, 'rows', 2);
    await appearance.setCategory(category.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    final start = tester.getTopLeft(find.byKey(const Key('rows.12'))).dx;
    for(var i=1;i<=6;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
    expect(isAppCardFocused(tester, 'rows.6'), isTrue);
    expect(tester.getTopLeft(find.byKey(const Key('rows.16'))).dx,
        closeTo(tester.getTopLeft(find.byKey(const Key('rows.4'))).dx, .1));
    expect(tester.getTopLeft(find.byKey(const Key('rows.16'))).dx, lessThan(start + 4 * 250));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rows.18'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rows.6'), isTrue);
    for(var i=0;i<20;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
    expect(isAppCardFocused(tester, 'rows.11'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  for (final spacerHeight in [10, 250]) {
    testWidgets('first tile preserves full top spacer and category title: $spacerHeight', (tester) async {
      final apps = mkAppService();
      final category = fakeCategory(name: 'All apps')
        ..applications.addAll(List.generate(60, (i) => fakeApp(packageName: 'spacer.$i')));
      when(apps.launcherSections).thenReturn([
        LauncherSpacer(id: 9999, height: spacerHeight), category,
      ]);
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.set('sectionScroll', 'free');
      addTearDown(appearance.dispose);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
      getFocusNodeForApp(tester, 'spacer.0')!.requestFocus(); await tester.pumpAndSettle();
      final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
      expect(scroll.offset, 0);
      final title = tester.getRect(find.text('All apps'));
      final spacer = tester.getRect(find.byKey(const Key('9999')));
      expect(spacer.height, spacerHeight);
      expect(title.top, greaterThanOrEqualTo(spacer.bottom));
      expect(title.top, greaterThan(0));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('anchored sections keep position at both ends; free mode preserves selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    final apps = mkAppService();
    final first = fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName: 'anchor.first'));
    final last = fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName: 'anchor.last'));
    when(apps.launcherSections).thenReturn([first,last]);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
    final y = tester.getTopLeft(find.byKey(const Key('anchor.first'))).dy;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'anchor.last'), isTrue);
    expect(tester.getTopLeft(find.byKey(const Key('anchor.last'))).dy, closeTo(y, 1));
    await appearance.set('sectionScroll', 'free'); await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'anchor.last'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox()); appearance.dispose();
  });

  testWidgets('grid remembers desired column and leaves only at the data edge', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    final apps = mkAppService();
    final grid = fakeCategory()..applications.addAll(List.generate(10, (i) => fakeApp(packageName: 'edge.$i')));
    final row = fakeCategory(type: CategoryType.row)..applications.addAll(List.generate(10, (i) => fakeApp(packageName: 'next.$i')));
    when(apps.launcherSections).thenReturn([grid, row]);
    await appearance.setCategory(grid.id, 'layout', 'grid');
    await appearance.setCategory(grid.id, 'columns', 4);
    await appearance.setCategory(grid.id, 'maxRows', 2);
    await appearance.setCategory(row.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    Future<void> key(LogicalKeyboardKey key) async { await tester.sendKeyEvent(key); await tester.pumpAndSettle(); }
    for (var i = 0; i < 3; i++) { await key(LogicalKeyboardKey.arrowRight); }
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'edge.7'), isTrue);
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'edge.9'), isTrue);
    await key(LogicalKeyboardKey.arrowUp); expect(isAppCardFocused(tester, 'edge.7'), isTrue);
    await key(LogicalKeyboardKey.arrowDown);
    await key(LogicalKeyboardKey.arrowDown); expect(isAppCardFocused(tester, 'next.1'), isTrue);
    await key(LogicalKeyboardKey.arrowUp); expect(isAppCardFocused(tester, 'edge.9'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('rapid arrows, relayout and removal preserve a single meaningful selection', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    addTearDown(appearance.dispose);
    final apps = mkAppService();
    final category = fakeCategory(type: CategoryType.row)
      ..applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'rapid.$i')));
    when(apps.launcherSections).thenReturn([category]);
    await appearance.setCategory(category.id, 'columns', 4);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance, pixelRatio: 2);
    for (var i = 0; i < 6; i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); }
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rapid.6'), isTrue);
    for (final mode in ['rows', 'grid', 'row']) {
      await appearance.setCategory(category.id, 'layout', mode);
      await tester.pumpAndSettle();
      expect(isAppCardFocused(tester, 'rapid.6'), isTrue);
      final packages = tester.widgetList<AppCard>(find.byType(AppCard)).map((c) => c.application.packageName).toList();
      expect(packages.toSet().length, packages.length);
    }
    category.applications.removeWhere((a) => a.packageName == 'rapid.6');
    await appearance.set('horizontalGap', 18);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'rapid.7'), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    getSettingsFocusNode(tester)!.requestFocus();
    await tester.pumpAndSettle();
    expect(isSettingsIconFocused(tester), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final sort in [CategorySort.mostUsed, CategorySort.lastUsed]) {
    for (final type in [CategoryType.row, CategoryType.grid]) {
      testWidgets('usage order refreshes immediately with section focused: $sort $type', (tester) async {
        SharedPreferences.setMockInitialValues({});
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        final apps = mkAppService();
        final appearance = AppearanceService(await SharedPreferences.getInstance());
        final category = fakeCategory(sort: sort, type: type)
          ..applications.addAll([
            fakeApp(packageName: 'usage.a'),
            fakeApp(packageName: 'usage.b'),
            ...List.generate(38, (i) => fakeApp(packageName: 'usage.extra.$i')),
          ]);
        when(apps.launcherSections).thenReturn([category]);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, mkSettingsService(), appearance: appearance);
        getFocusNodeForApp(tester, 'usage.b')!.requestFocus();
        await tester.pumpAndSettle();
        List<String> order() => tester.widgetList<AppCard>(find.byType(AppCard))
            .map((card) => card.application.packageName).toList();
        final launched = category.applications[1];
        when(apps.launchApp(launched)).thenAnswer((_) async {
          launched.launchCount++;
          category.applications.remove(launched);
          category.applications.add(launched);
          // A provider notification rebuilds the section after recording usage.
          await appearance.set('animateReordering', true);
          return true;
        });
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        verify(apps.launchApp(launched)).called(1);
        expect(launched.launchCount, 1);
        expect(order().last, 'usage.b');
        expect(isAppCardFocused(tester, 'usage.b'), isTrue);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pumpAndSettle();
        expect(order().last, 'usage.b');
        expect(isAppCardFocused(tester, 'usage.b'), isTrue);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
      });
    }
  }

  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("Home page shows categories with apps", (tester) async {
    final appsService = mkAppService();
    final favoritesCategory = fakeCategory(name: "Favorites", order: 0, type: CategoryType.row);
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    favoritesCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.1",
      name: "FLauncher 1",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "2.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      favoritesCategory,
      applicationsCategory,
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);
    expect(find.byType(HomeSection), findsNWidgets(2));
    expect(find.byKey(Key("me.efesser.flauncher.2")), findsOneWidget);

    expect(find.byKey(Key("me.efesser.flauncher.1")), findsOneWidget);

    // This was changed by how the the image is made, I don't know what it now should be
    //expect(tester.widget(find.byKey(Key("background"))), isA<Container>());

  });

  for (final type in CategoryType.values) {
    testWidgets('startup focuses first usable category: $type', (tester) async {
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy = FocusHighlightStrategy.alwaysTouch;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      final apps = mkAppService();
      final hidden = fakeCategory(type: type)..visible = false;
      final first = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'startup.first'));
      when(apps.launcherSections).thenReturn([hidden, first]);
      final settings = mkSettingsService();
      when(settings.cardFocusMode).thenReturn(CardFocusMode.first);
      await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
      expect(isAppCardFocused(tester, 'startup.first'), isTrue);
      final surface = find.descendant(
        of: find.byWidgetPredicate((widget) => widget is AppCard &&
            widget.application.packageName == 'startup.first'),
        matching: find.byType(AppearanceSurface),
      );
      expect(tester.widget<AppearanceSurface>(surface).focused, isTrue);
      expect(tester.takeException(), isNull);
    });
  }

  for (final type in CategoryType.values) {
    for (final custom in [false, true]) {
      testWidgets('hidden app remains visible and focusable in manual section: $type, custom=$custom', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final db = FLauncherDatabase.inMemory();
        final channel = MockFLauncherChannel();
        when(channel.getApplications()).thenAnswer((_) async => [
          {'packageName': 'manual.hidden', 'name': 'Hidden candidate', 'version': '1', 'sideloaded': false},
          {'packageName': 'manual.other', 'name': 'Other', 'version': '1', 'sideloaded': false},
        ]);
        when(channel.addAppsChangedListener(any)).thenReturn(null);
        when(channel.getApplicationIcon(any)).thenAnswer((_) async => kTransparentImage);
        when(channel.getApplicationBanner(any)).thenAnswer((_) async => kTransparentImage);
        late AppsService apps;
        late Category manual;
        try {
          await tester.runAsync(() async {
            apps = AppsService(channel, db);
            for (var i = 0; i < 200 && !apps.initialized; i++) {
              await Future<void>.delayed(const Duration(milliseconds: 5));
            }
            expect(apps.initialized, isTrue);
            final id = custom ? await apps.addCategory('Custom')
                : apps.categories.firstWhere((category) => category.systemKey == 'favorites').id;
            manual = apps.categories.firstWhere((category) => category.id == id);
            await apps.setCategoryType(manual, type);
            manual = apps.categories.firstWhere((category) => category.id == id);
            await apps.addToCategory(apps.getApp('manual.hidden')!, manual);
            await apps.addToCategory(apps.getApp('manual.other')!, manual);
            for (final category in apps.categories.where((category) => category.id != manual.id)) {
              await apps.setCategoryVisible(category.id, false);
            }
          });
          final settings = mkSettingsService();
          when(settings.cardFocusMode).thenReturn(CardFocusMode.first);
          await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.hideApplication(apps.getApp('manual.hidden')!));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsOneWidget);
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          expect(apps.categories.where((category) => category.isAutomatic).every((category) =>
              category.applications.every((app) => app.packageName != 'manual.hidden')), isTrue);
          await tester.runAsync(() => apps.removeFromCategory(apps.getApp('manual.other')!, manual));
          await tester.pumpAndSettle();
          await tester.runAsync(apps.refreshState);
          await tester.pumpAndSettle();
          tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.addToCategory(apps.getApp('manual.other')!, manual));
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.other'), isTrue);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'manual.hidden'), isTrue);
          await tester.runAsync(() => apps.removeFromCategory(apps.getApp('manual.hidden')!, manual));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsNothing);
          expect(isAppCardFocused(tester, 'manual.other'), isTrue);
          await tester.runAsync(() => apps.showApplication(apps.getApp('manual.hidden')!));
          await tester.pumpAndSettle();
          expect(find.byKey(const Key('manual.hidden')), findsNothing);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.runAsync(() async { apps.dispose(); await db.close(); });
        }
      });
    }
  }

  for (final remember in [false,true]) {
    for (final type in CategoryType.values) {
    testWidgets('section entry uses nearest edge card despite legacy memory: $remember, $type', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(await SharedPreferences.getInstance());
      await appearance.preferences.setString('tile_appearance', '{"rememberSection":$remember}');
      final apps=mkAppService();
      final top=fakeCategory(type: CategoryType.row)..applications.add(fakeApp(packageName:'memory.top'));
      final bottom=fakeCategory(type: type)..applications.addAll(List.generate(10,(i)=>fakeApp(packageName:'memory.$i')));
      when(apps.launcherSections).thenReturn([top,bottom]);
      await _pumpWidgetWithProviders(tester,mkWallpaperService(),apps,mkSettingsService(),appearance:appearance);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
      for(var i=0;i<3;i++) { await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight); await tester.pumpAndSettle(); }
      expect(isAppCardFocused(tester,'memory.3'),isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp); await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); await tester.pumpAndSettle();
      expect(isAppCardFocused(tester,'memory.0'),isTrue);
      await tester.pumpWidget(const SizedBox());appearance.dispose();
    });
    }
  }

  for (final type in CategoryType.values) {
    for (final mode in CardFocusMode.values) {
      testWidgets('Home restores selected section in $type, mode=$mode', (tester) async {
        SharedPreferences.setMockInitialValues({});
        final settings = SettingsService(await SharedPreferences.getInstance());
        await settings.setCardFocusMode(mode);
        await settings.setAppKeyClickEnabled(false);
        await settings.setAppHighlightAnimationEnabled(false);
        final apps = mkAppService();
        final top = fakeCategory(type: type)..applications.add(fakeApp(packageName: 'return.top'));
        final bottom = fakeCategory(type: type)..applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'return.$i')));
        when(apps.launcherSections).thenReturn([top, bottom]);
        await _pumpWidgetWithProviders(tester, mkWallpaperService(), apps, settings);
        getFocusNodeForApp(tester, 'return.1')!.requestFocus();
        await tester.pumpAndSettle();
        if (type == CategoryType.row) {
          for (var i = 0; i < 9; i++) {
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
            await tester.pumpAndSettle();
          }
        } else {
          getFocusNodeForApp(tester, 'return.10')!.requestFocus();
          await tester.pumpAndSettle();
        }
        expect(isAppCardFocused(tester, 'return.10'), isTrue);
        tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar)).focusSettings();
        await tester.pumpAndSettle();
        tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
        await tester.pumpAndSettle();
        if (mode == CardFocusMode.settings) {
          expect(isSettingsIconFocused(tester), isTrue);
        } else {
          expect(isAppCardFocused(tester, mode == CardFocusMode.remember ? 'return.10' : 'return.top'), isTrue);
          bottom.visible = false;
          settings.reload();
          await tester.pumpAndSettle();
          tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
          await tester.pumpAndSettle();
          expect(isAppCardFocused(tester, 'return.top'), isTrue);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        settings.dispose();
      });
    }
  }

  testWidgets('returnHome restores launcher and focuses settings', (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([fakeCategory(name: 'Applications')]);
    await _pumpWidgetWith(tester, appsService);
    final state = tester.state<FLauncherState>(find.byType(FLauncher));
    final launcher = Provider.of<LauncherState>(tester.element(find.byType(FLauncher)), listen: false);
    launcher.toggleLauncherVisibility();
    await tester.pumpAndSettle();
    expect(launcher.launcherVisible, isFalse);
    state.returnHome();
    await tester.pumpAndSettle();
    expect(launcher.launcherVisible, isTrue);
    expect(isSettingsIconFocused(tester), isTrue);
  });

  testWidgets('returnHome keeps the list at the top when a large tile loses focus', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('size', 256);
    await appearance.set('aspectRatio', 1);
    final service = mkAppService();
    final category = fakeCategory(name: 'Applications', type: CategoryType.grid, columnsCount: 6);
    category.applications.addAll(List.generate(60, (i) => fakeApp(packageName: 'home.$i')));
    when(service.launcherSections).thenReturn([category]);
    final settings = mkSettingsService();
    when(settings.cardFocusMode).thenReturn(CardFocusMode.settings);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, settings, appearance: appearance, pixelRatio: 2);
    getFocusNodeForApp(tester, 'home.8')!.requestFocus();
    await tester.pumpAndSettle();
    final scroll = tester.widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first).controller!;
    scroll.jumpTo(300);
    await tester.pump();
    tester.state<FLauncherState>(find.byType(FLauncher)).returnHome();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(isSettingsIconFocused(tester), isTrue);
    expect(scroll.offset, 0);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  testWidgets('compact square tiles with large labels fit TV grid and remote follows effective columns', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final appearance = AppearanceService(await SharedPreferences.getInstance());
    await appearance.set('labels', 'all');
    await appearance.set('size', 64);
    await appearance.set('aspectRatio', 1);
    await appearance.set('labelSize', 20);
    await appearance.set('horizontalGap', 48);
    await appearance.set('focusEffect', 'border');
    final service = mkAppService();
    final category = fakeCategory(name: 'Приложения с длинными названиями', type: CategoryType.grid, columnsCount: 6);
    await appearance.setCategory(category.id, 'layout', 'auto');
    category.applications.addAll(List.generate(24, (i) => fakeApp(packageName: 'geometry.$i', name: 'Очень длинное русское название приложения $i')));
    when(service.launcherSections).thenReturn([category]);
    final settings = mkSettingsService();
    when(settings.appHighlightAnimationEnabled).thenReturn(false);
    await _pumpWidgetWithProviders(tester, mkWallpaperService(), service, settings, appearance: appearance, pixelRatio: 2);
    getFocusNodeForApp(tester, 'geometry.0')!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(isAppCardFocused(tester, 'geometry.8'), isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    appearance.dispose();
  });

  testWidgets("Home page shows category empty-state", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 0, type: CategoryType.grid);
    final favoritesCategory = fakeCategory(name: "Favorites", order: 1, type: CategoryType.row);
    when(appsService.launcherSections).thenReturn([
      applicationsCategory,
      favoritesCategory,
    ]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.text("Applications"), findsOneWidget);
    expect(find.text("Favorites"), findsOneWidget);

    expect(find.byType(HomeSection), findsNWidgets(2));
    expect(find.text("This category is empty."), findsNWidgets(2));
  });

  testWidgets("Home page displays background image", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWith(tester, appsService);

    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets("Home page displays background gradient", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([]);

    await _pumpWidgetWithProviders(tester, mkWallpaperService(false), appsService, mkSettingsService());

    expect(tester.widget<WallpaperBackground>(find.byType(WallpaperBackground)).image, isNull);
  });

  testWidgets("Pressing select on settings icon opens SettingsPanel", (tester) async {
    final appsService = mkAppService();
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      fakeCategory(name: "Applications", order: 1),
    ]);
    await _pumpWidgetWith(tester, appsService);

    final settingsNode = getSettingsFocusNode(tester);
    settingsNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPanelPage), findsOneWidget);
  });

  testWidgets("Pressing select on app opens ApplicationInfoPanel", (tester) async {
    final appsService = mkAppService();
    final app = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    final fav = fakeCategory(name: "Favorites", order: 0);
    final apps = fakeCategory(name: "Applications", order: 1);
    apps.applications.add(app);
    when(appsService.launcherSections).thenReturn([
      fav,
      apps,
    ]);
    await _pumpWidgetWith(tester, appsService);

    final inkWellFinder = find.descendant(
      of: find.byKey(Key("me.efesser.flauncher")),
      matching: find.byType(InkWell),
    );
    final FocusNode focusNode = tester.widget<InkWell>(inkWellFinder).focusNode!;
    focusNode.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 500));

    verify(appsService.launchApp(app));
  });

  testWidgets("Long pressing on app opens ApplicationInfoPanel", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pump();

    expect(find.byType(ApplicationInfoPanel), findsOneWidget);
  });

  testWidgets("AppCard moves in grid", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("AppCard reorder cancels on Back button", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.grid);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonB);
    await tester.pump();
    verify(appsService.cancelReorderApplication(applicationsCategory));
  });

  testWidgets("AppCard moves in row", (tester) async {
    final appsService = mkAppService();
    final applicationsCategory = fakeCategory(name: "Applications", order: 1, type: CategoryType.row);
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    ));
    applicationsCategory.applications.add(fakeApp(
      packageName: "me.efesser.flauncher.2",
      name: "FLauncher 2",
      version: "1.0.0",
    ));
    when(appsService.launcherSections).thenReturn([
      fakeCategory(name: "Favorites", order: 0),
      applicationsCategory,
    ]);
    await _pumpWidgetWith(tester, appsService);

    await tester.longPress(find.byKey(Key("me.efesser.flauncher")));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Reorder"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    verify(appsService.reorderApplication(applicationsCategory, 0, 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    verify(appsService.saveApplicationOrderInCategory(applicationsCategory));
  });

  testWidgets("Moving down does not skip row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 3 rows like the following:
     * ▭ ▭ ▭
     * ▭ ▭
     * ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv3",
        name: "tv 3",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
    ]);
    final gamesCat = fakeCategory(name: "games", order: 2);
    gamesCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.game1",
        name: "game 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.game2",
        name: "game 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.game3",
        name: "game 3",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
      gamesCat,
    ]);

    await _pumpWidgetWith(tester, appsService);
    // when
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue); // first-card mode still visits each row

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    Element? game2 = findAppCardByPackageName(tester, "me.efesser.game2");
    expect(game2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.game2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);
    expect(isAppCardFocused(tester, "me.efesser.game2"), isFalse);
  });

  testWidgets("Moving left or right stays on the same row", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1, columnsCount: 5);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music3",
        name: "music 3",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music4",
        name: "music 4",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music5",
        name: "music 5",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    Element? music1 = findAppCardByPackageName(tester, "me.efesser.music1");
    expect(music1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);

    // check right direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    Element? music2 = findAppCardByPackageName(tester, "me.efesser.music2");
    expect(music2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music1"), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);

    // check if right on the last app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    Element? music5 = findAppCardByPackageName(tester, "me.efesser.music5");
    expect(music5, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.music5"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    Element? tv2 = findAppCardByPackageName(tester, "me.efesser.tv2");
    expect(tv2, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music2"), isTrue);

    // check left direction
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);

    // check if going left on the first app stays on the same app
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.music1"), isTrue);
  });

  testWidgets("Moving right or up can go the settings icon", (tester) async {
    // given
    final appsService = mkAppService();

    /*
     * we are creating 2 rows like the following:
     * ▭ ▭
     * ▭ ▭ ▭
     */
    final tvCat = fakeCategory(name: "tv", order: 0);
    tvCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.tv1",
        name: "tv 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.tv2",
        name: "tv 2",
        version: "1.0.0",
      ),
    ]);
    final musicCat = fakeCategory(name: "music", order: 1);
    musicCat.applications.addAll([
      fakeApp(
        packageName: "me.efesser.music1",
        name: "music 1",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music2",
        name: "music 2",
        version: "1.0.0",
      ),
      fakeApp(
        packageName: "me.efesser.music3",
        name: "music 3",
        version: "1.0.0",
      ),
    ]);
    when(appsService.launcherSections).thenReturn([
      tvCat,
      musicCat,
    ]);

    await _pumpWidgetWith(tester, appsService);

    // then
    Element? tv1 = findAppCardByPackageName(tester, "me.efesser.tv1");
    expect(tv1, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();


    Element? settingsIcon = findSettingsIcon(tester);
    expect(settingsIcon, isNotNull);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isFalse);
    expect(isSettingsIconFocused(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isFalse);
    expect(isAppCardFocused(tester, "me.efesser.tv1"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(isAppCardFocused(tester, "me.efesser.tv2"), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(isSettingsIconFocused(tester), isTrue);
  });
}

SettingsService mkSettingsService() {
  final settingsService = MockSettingsService();
  final demo = ValueNotifier<LandscapeDemoFrame?>(null);
  addTearDown(demo.dispose);
  when(settingsService.landscapeDemo).thenReturn(demo);
  when(settingsService.appKeyClickEnabled).thenReturn(false);
  when(settingsService.showSleepTimerInStatusBar).thenReturn(false);
  when(settingsService.showNightModeInStatusBar).thenReturn(false);
  when(settingsService.settingsMenuOnRight).thenReturn(false);
  when(settingsService.backgroundSource).thenReturn('picture');
  when(settingsService.wallpaperFit).thenReturn('cover');
  when(settingsService.wallpaperBrightness).thenReturn(1);
  when(settingsService.wallpaperSaturation).thenReturn(1);
  when(settingsService.wallpaperDimming).thenReturn(1);
  when(settingsService.memorySaverEnabled).thenReturn(false);
  when(settingsService.watchNextAppLimits).thenReturn({});
  when(settingsService.rememberCategoryFocus).thenReturn(false);
  when(settingsService.cardFocusMode).thenReturn(CardFocusMode.first);
  when(settingsService.dateFormat).thenReturn(SettingsService.defaultDateFormat);
  when(settingsService.timeFormat).thenReturn(SettingsService.defaultTimeFormat);
  when(settingsService.appHighlightAnimationEnabled).thenReturn(false);
  when(settingsService.showCategoryTitles).thenReturn(true);
  when(settingsService.autoHideAppBarEnabled).thenReturn(false);
  when(settingsService.showInputsWidgetInStatusBar).thenReturn(true);
  when(settingsService.showSystemSettingsInStatusBar).thenReturn(true);
  when(settingsService.showNetworkIndicatorInStatusBar).thenReturn(true);
  when(settingsService.showDataWidgetInStatusBar).thenReturn(true);
  when(settingsService.showDateInStatusBar).thenReturn(true);
  when(settingsService.showTimeInStatusBar).thenReturn(true);
  when(settingsService.accentColorHex).thenReturn('00ff00');
  when(settingsService.showAppNamesBelowIcons).thenReturn(true);
  when(settingsService.themes).thenReturn('classic');
  when(settingsService.screensaverClockStyle).thenReturn('classic');
  when(settingsService.hideHighlightOutlineOnHomescreen).thenReturn(false);
  when(settingsService.appSelectorTransitionAnimationEnabled).thenReturn(true);
  when(settingsService.showContinueWatching).thenReturn(false);
  when(settingsService.continueWatchingOrder).thenReturn(0);
  when(settingsService.showNotificationsWidgetInStatusBar).thenReturn(true);
  when(settingsService.autoHideNotificationsWidget).thenReturn(false);
  when(settingsService.showWeatherInStatusBar).thenReturn(false);
  when(settingsService.showWeatherWarnings).thenReturn(false);
  when(settingsService.useFahrenheit).thenReturn(false);
  return settingsService;
}

WallpaperService mkWallpaperService([bool wallpaper = true]) {
  final wallpaperService = MockWallpaperService();
  when(wallpaperService.gradient).thenReturn(FLauncherGradients.greatWhale);
  when(wallpaperService.wallpaper).thenReturn(wallpaper ? Image.asset('assets/icon.png').image : null);
  when(wallpaperService.version).thenReturn(0);
  return wallpaperService;
}

TvInputsService mkTvInputsService() {
  final tvInputsService = MockTvInputsService();
  when(tvInputsService.hasInputs).thenReturn(false);
  when(tvInputsService.initialized).thenReturn(false);
  return tvInputsService;
}

NotificationsService mkNotificationsService() {
  final notificationsService = MockNotificationsService();
  when(notificationsService.getNotificationCount(any)).thenReturn(0);
  when(notificationsService.hasPermission).thenReturn(false);
  when(notificationsService.notifications).thenReturn([]);
  return notificationsService;
}

WatchNextService mkWatchNextService() {
  final watchNextService = MockWatchNextService();
  when(watchNextService.programs).thenReturn([]);
  return watchNextService;
}

WeatherService mkWeatherService() {
  final weatherService = MockWeatherService();
  when(weatherService.hasWeather).thenReturn(false);
  when(weatherService.weatherData).thenReturn(null);
  when(weatherService.isBreezyInstalled).thenReturn(false);
  return weatherService;
}

AppsService mkAppService() {
  final appsService = MockAppsService();
  when(appsService.isTileHidden(any)).thenReturn(false);
    when(appsService.launchApp(any)).thenAnswer((_) async => true);
  when(appsService.initialized).thenReturn(true);
  when(appsService.getAppBanner(any)).thenAnswer((_) async => kTransparentImage);
  when(appsService.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
  when(appsService.pendingReorderFocusPackage).thenReturn(null);
  when(appsService.hasCustomBanner(any)).thenAnswer((_) async => false);
  when(appsService.isAppInFavorites(any)).thenReturn(false);
  return appsService;
}


Future<void> _pumpWidgetWith(
  WidgetTester tester,
  AppsService appsService,
  ) async {
  return _pumpWidgetWithProviders(tester, mkWallpaperService(), appsService, mkSettingsService());
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  WallpaperService wallpaperService,
  AppsService appsService,
  SettingsService settingsService,
  {AppearanceService? appearance, UpdateService? updates, RemotePanelService? remotePanel, double pixelRatio = 1, Locale? locale}) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = pixelRatio;
  final network = MockNetworkService();
  when(network.networkType).thenReturn(NetworkType.Unknown);
  when(network.cellularNetworkType).thenReturn(CellularNetworkType.Unknown);
  when(network.wirelessNetworkSignalLevel).thenReturn(0);
  when(network.hasInternetAccess).thenReturn(false);
  when(network.vpnActive).thenReturn(false);
  when(network.dailyDataUsage).thenReturn(0);
  when(network.hasUsageStatsPermission).thenReturn(false);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        if (remotePanel != null) ChangeNotifierProvider.value(value: remotePanel),
        if (updates != null) ChangeNotifierProvider<UpdateService>.value(value: updates),
        if (appearance != null) ChangeNotifierProvider<AppearanceService>.value(value: appearance),
        ChangeNotifierProvider<WallpaperService>.value(value: wallpaperService),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<TvInputsService>.value(value: mkTvInputsService()),
        ChangeNotifierProvider<NotificationsService>.value(value: mkNotificationsService()),
        ChangeNotifierProvider<WatchNextService>.value(value: mkWatchNextService()),
        ChangeNotifierProvider<WeatherService>.value(value: mkWeatherService()),
        ChangeNotifierProvider(create: (_) => LauncherState()),
        ChangeNotifierProvider<NetworkService>(create: (_) => network),
      ],
      builder: (_, _) => MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: FLauncher(),
      ),
    ),
  );
  await tester.pump(Duration(seconds: 30), EnginePhase.sendSemanticsUpdate);
  // Image decoding runs outside the fake test clock. Wait before interacting
  // with the home screen, which is now revealed only after decoding completes.
  await tester.runAsync(() async => Future<void>.delayed(const Duration(milliseconds: 50)));
  await tester.pumpAndSettle();
}

FocusNode? getFocusNodeForApp(WidgetTester tester, String packageName) {
  final appCardFinder = find.byWidgetPredicate((widget) =>
    widget is AppCard && widget.application.packageName == packageName
  );
  if (appCardFinder.evaluate().isEmpty) return null;
  final inkWellFinder = find.descendant(
    of: appCardFinder,
    matching: find.byType(InkWell),
  );
  if (inkWellFinder.evaluate().isEmpty) return null;
  final inkWell = tester.widget<InkWell>(inkWellFinder);
  return inkWell.focusNode;
}

FocusNode? getSettingsFocusNode(WidgetTester tester) {
  try {
    final appBarState = tester.state<FocusAwareAppBarState>(find.byType(FocusAwareAppBar));
    return appBarState.settingsFocusNode;
  } catch (e) {
    return null;
  }
}

bool isAppCardFocused(WidgetTester tester, String packageName) {
  final focusNode = getFocusNodeForApp(tester, packageName);
  return focusNode?.hasFocus ?? false;
}

bool isSettingsIconFocused(WidgetTester tester) {
  final focusNode = getSettingsFocusNode(tester);
  return focusNode?.hasFocus ?? false;
}
