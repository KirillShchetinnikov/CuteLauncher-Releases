import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/settings/app_channels_appearance_page.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/settings_read_only_value.dart';
import 'package:flauncher/widgets/settings/settings_choice_tile.dart';
import 'package:flauncher/widgets/settings/settings_text_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';
import '../../support/app_channels.dart';

void main() {
  testWidgets(
    'Watch Next opens the shared feed appearance page from its settings',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      final watch = MockWatchNextService();
      final apps = MockAppsService();
      final source = Category(id: 7, name: 'My apps');
      when(apps.categories).thenReturn([appChannelsGroup(), source]);
      when(watch.hasPermission).thenReturn(true);
      addTearDown(appearance.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appearance),
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider<WatchNextService>.value(value: watch),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SettingsPanel(
                initialRoute: ContinueWatchingSettingsPage.routeName,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(ContinueWatchingSettingsPage)),
      )!;
      final opener = find.text(l.categoryAppearance);
      await tester.scrollUntilVisible(opener, 100);
      await tester.ensureVisible(opener);
      await tester.pumpAndSettle();
      await tester.tap(opener);
      await tester.pumpAndSettle();
      final page = tester.widget<AppChannelsAppearancePage>(
        find.byType(AppChannelsAppearancePage),
      );
      expect(page.categoryId, ContinueWatchingSection.sectionId);
      expect(
        find.text('${l.categoryAppearance} · ${l.continueWatching}'),
        findsOneWidget,
      );
      final mode = find.widgetWithText(
        SettingsChoiceTile<int>,
        l.contentAppTileStyle,
      );
      final useSourceLabels = find.widgetWithText(
        RoundedSwitchListTile, l.contentUseSourceLabels,
      );
      expect(useSourceLabels, findsNothing);
      expect(
        Focus.of(tester.element(find.text(l.contentAppTileStyle))).hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        FocusManager.instance.primaryFocus?.context
            ?.findAncestorWidgetOfExactType<SettingsSliderTile>()
            ?.title,
        l.tileSize,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(appearance.tilesFor(page.categoryId).tileSize, 136);
      expect(appearance.appearance.tileSize, 128);
      expect(tester.widget<SettingsChoiceTile<int>>(mode).value, -1);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.select);
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsChoiceTile<int>>(mode).value, 0);
      expect(find.text(l.tileSize), findsNothing);
      expect(appearance.tilesFor(page.categoryId).tileSize, 128);
      expect(tester.widget<RoundedSwitchListTile>(useSourceLabels).value, isTrue);
      expect(find.text(l.tileLabelPosition), findsNothing);
      await tester.tap(mode);
      await tester.pumpAndSettle();
      await tester.tap(find.text(source.name));
      await tester.pumpAndSettle();
      expect(tester.widget<SettingsChoiceTile<int>>(mode).value, source.id);
      expect(appearance.tilesFor(page.categoryId).contentAppTileSectionId, source.id);
      await tester.tap(useSourceLabels);
      await tester.pumpAndSettle();
      expect(tester.widget<RoundedSwitchListTile>(useSourceLabels).value, isFalse);
      expect(find.text(l.tileLabelPosition), findsOneWidget);
      expect(find.text(l.tileLabelSize), findsOneWidget);
      expect(find.text(l.tileSize), findsNothing);
      await tester
          .state<NavigatorState>(find.byType(Navigator).last)
          .maybePop();
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(opener)).hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'feed appearance enters without moving the page and restores its opener ${locale.languageCode}',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        await appearance.set('settingsOpacity', .55);
        final group = appChannelsGroup();
        final apps = MockAppsService();
        when(apps.categories).thenReturn([group, fakeCategory()]);
        when(apps.launcherSections).thenReturn(apps.categories);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider<AppsService>.value(value: apps),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SettingsPanel(
                  initialRoute: LauncherSectionPanelPage.routeName,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final navigator = tester.state<NavigatorState>(
          find.byType(Navigator).last,
        );
        navigator.pushReplacementNamed(
          LauncherSectionPanelPage.routeName,
          arguments: 0,
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(LauncherSectionPanelPage)),
        )!;
        final opener = find.text(l.categoryAppearance);
        final name = tester.widget<SettingsReadOnlyValue>(
          find.byType(SettingsReadOnlyValue),
        );
        expect((name.label, name.value), (l.name, l.appChannelsTitle));
        expect(find.byType(SettingsTextTile), findsNothing);
        expect(find.byType(SettingsChoiceTile<String>), findsNothing);
        await tester.tap(opener);
        await tester.pump();
        expect(find.byType(AppChannelsAppearancePage), findsOneWidget);
        expect(find.byType(LauncherSectionPanelPage), findsNothing);
        final layout = find.descendant(
          of: find.byType(AppChannelsAppearancePage),
          matching: find.byType(SettingsPageLayout),
        );
        final bounds = tester.getRect(layout);
        final scroll = tester.state<ScrollableState>(
          find.byType(Scrollable).last,
        );
        final initial = scroll.position.pixels;
        for (var frame = 0; frame < 18; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(tester.getRect(layout), bounds);
          expect(scroll.position.pixels, initial);
          expect(find.byType(AppChannelsAppearancePage), findsOneWidget);
        }
        expect(
          Focus.of(tester.element(find.text(l.contentAppTileStyle))).hasFocus,
          isTrue,
        );
        await navigator.maybePop();
        await tester.pumpAndSettle();
        expect(find.byType(LauncherSectionPanelPage), findsOneWidget);
        expect(Focus.of(tester.element(opener)).hasFocus, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
        settings.dispose();
      },
    );
  }
}
