import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/category_appearance_page.dart';
import 'package:flauncher/widgets/settings/reset_style_tile.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';

import '../../mocks.mocks.dart';
import '../../support/app_channels.dart';

void main() {
  for (final locale in [const Locale('ru'), const Locale('ar')]) {
    testWidgets(
      'feed appearance exposes effective controls, saves and resets ${locale.languageCode}',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final appearance = AppearanceService(prefs);
        final settings = SettingsService(prefs);
        final group = appChannelsGroup();
        final apps = MockAppsService();
        when(apps.categories).thenReturn([group]);
        when(apps.launcherSections).thenReturn([group]);
        await settings.setSelectedAppChannels(['video.app:1']);
        await appearance.set('sectionTitles', false);
        await appearance.set('sectionOpacity', .75);
        await appearance.set('sectionRadius', 12);
        await appearance.setCategoryTile(group.id, 'sectionOpacity', .35);
        await appearance.setCategoryTile(group.id, 'sectionRadius', 64);
        await appearance.setCategory(group.id, 'layout', 'grid');
        await appearance.setCategory(group.id, 'columns', 6);
        tester.view.physicalSize = const Size(1000, 1800);
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AppsService>.value(value: apps),
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: settings),
            ],
            child: MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: Scaffold(
                body: CategoryAppearancePage(categoryId: group.id),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(SettingsPageLayout).first),
        )!;
        expect(find.text(l.layout), findsNothing);
        expect(find.text(l.tileProportions), findsNothing);
        expect(find.text(l.tileRowCount), findsNothing);
        expect(find.text(l.tileIconScale), findsNothing);
        expect(find.text(l.tileVerticalGap), findsNothing);
        expect(find.text(l.homeSectionIcons), findsNothing);
        final size = find.byWidgetPredicate(
          (w) => w is SettingsValueStepper && w.title == l.tileSize,
        );
        expect(tester.widget<SettingsValueStepper>(size).enabled, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(
          appearance.tilesFor(group.id).tileSize,
          136,
        );
        expect(appearance.appearance.tileSize, 128);
        final scroll = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(
          find.text(l.showSectionTitles),
          160,
          scrollable: scroll,
        );
        await tester.tap(find.text(l.showSectionTitles));
        await tester.pumpAndSettle();
        expect(appearance.tilesFor(group.id).sectionTitles, isTrue);
        expect(appearance.appearance.sectionTitles, isFalse);
        final restored = AppearanceService(prefs);
        expect(restored.tilesFor(group.id).sectionTitles, isTrue);
        expect(
          restored.tilesFor(group.id).tileSize,
          appearance.tilesFor(group.id).tileSize,
        );
        restored.dispose();
        await tester.scrollUntilVisible(
          find.byType(ResetStyleTile),
          160,
          scrollable: scroll,
        );
        await tester.tap(find.byType(ResetStyleTile));
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(appearance.tilesFor(group.id).sectionTitles, isTrue);
        await tester.ensureVisible(find.byType(ResetStyleTile));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ResetStyleTile));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.resetSectionToGlobal).last);
        await tester.pumpAndSettle();
        expect(appearance.tilesFor(group.id).sectionTitles, isFalse);
        expect(appearance.tilesFor(group.id).sectionOpacity, .75);
        expect(appearance.tilesFor(group.id).sectionRadius, 12);
        expect(appearance.tilesFor(group.id).tileSize, 128);
        expect(settings.selectedAppChannels, ['video.app:1']);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        appearance.dispose();
        settings.dispose();
      },
    );
  }
}
