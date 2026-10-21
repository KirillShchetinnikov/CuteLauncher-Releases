import 'package:flauncher/providers/settings_service.dart';
/*
 * FLauncher
 * Copyright (C) 2021  Г‰tienne Fesser
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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/models/app.dart';
import 'package:flauncher/models/category.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/app_details_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:transparent_image/transparent_image.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("All Applications shows TV and non-TV apps", (tester) async {
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn([
      fakeApp(
        packageName: "me.efesser.flauncher",
        name: "FLauncher",
        sideloaded: false,
        hidden: false,
      ),
      fakeApp(packageName: "other", name: "Other", sideloaded: true),
      fakeApp(packageName: "hidden", name: "Hidden", hidden: true),
    ]);

    await _pumpWidgetWithProviders(tester, appsService);

    expect(find.text("All applications"), findsOneWidget);
    expect(find.text("Other"), findsOneWidget);
    expect(find.text("Hidden"), findsNothing);
    expect(find.text("FLauncher"), findsOneWidget);
  });

  testWidgets('All Applications uses the all_apps category contents and order even when renamed or hidden on home', (tester) async {
    final apps = MockAppsService();
    final youtube = fakeApp(packageName: 'youtube', name: 'YouTube')..isSystem = true;
    final play = fakeApp(packageName: 'play', name: 'Google Play')..isSystem = true;
    final service = fakeApp(packageName: 'partner', name: 'Google Partner Setup')
      ..isSystem = true ..isLaunchable = false;
    final excluded = fakeApp(packageName: 'excluded', name: 'Filtered tile');
    when(apps.applications).thenReturn([youtube, play, service, excluded]);
    final all = fakeCategory(name: 'Renamed catalog')..systemKey = 'all_apps'
      ..visible = false ..applications.addAll([play, youtube]);
    final favorite = fakeCategory(name: 'All Apps')..systemKey = 'favorites'
      ..applications.add(excluded);
    await _pumpWidgetWithProviders(tester, apps, categories: [favorite, all]);
    expect(find.text('Google Play'), findsOneWidget);
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('Google Partner Setup'), findsNothing);
    expect(find.text('Filtered tile'), findsNothing);
    expect(tester.getTopLeft(find.text('Google Play')).dy, lessThan(tester.getTopLeft(find.text('YouTube')).dy));
  });

  testWidgets("System Applications shows system apps", (tester) async {
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn([
      fakeApp(
        packageName: "me.efesser.flauncher",
        name: "FLauncher",
        sideloaded: true,
        hidden: false,
      )..isSystem = true,
      fakeApp(packageName: "com.google.android.partnersetup", name: "Google Partner Setup")
        ..isSystem = true ..isLaunchable = false,
      fakeApp(packageName: "user", name: "User app"),
      fakeApp(packageName: "hidden", name: "Hidden system", hidden: true)..isSystem = true,
    ]);

    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.byIcon(Icons.android));
    await tester.pumpAndSettle();

    expect(find.text("System apps"), findsOneWidget);
    expect(find.text("Google Partner Setup"), findsOneWidget);
    expect(find.text("User app"), findsNothing);
    expect(find.text("Hidden system"), findsNothing);
    expect(find.text("FLauncher"), findsOneWidget);
  });

  testWidgets("Hidden Applications shows hidden apps", (tester) async {
    final appsService = MockAppsService();
    when(appsService.applications).thenReturn([
      fakeApp(
        packageName: "me.efesser.flauncher",
        name: "FLauncher",
        sideloaded: false,
        hidden: true,
      )
    ]);

    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.byIcon(Icons.visibility_off_outlined).last);
    await tester.pumpAndSettle();

    expect(find.text("Hidden Apps"), findsOneWidget);
    expect(find.text("FLauncher"), findsOneWidget);
  });

  testWidgets("'Add' opens AddToCategoryDialog", (tester) async {
    final appsService = MockAppsService();
    final application = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    when(appsService.applications).thenReturn([application]);
    when(appsService.launcherSections).thenReturn([fakeCategory()]);

    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.text("FLauncher"));
    await tester.pumpAndSettle();

    when(appsService.categories).thenReturn([fakeCategory()]);
    await tester.tap(find.text("Add to Category"));
    await tester.pumpAndSettle();
    expect(find.byType(AddToCategoryDialog), findsOneWidget);
  });

  testWidgets('shared details remove membership without offering All Apps', (tester) async {
    final apps = MockAppsService();
    final app = fakeApp(packageName: 'sample.app', name: 'Sample');
    when(apps.applications).thenReturn([app]);
    await _pumpWidgetWithProviders(tester, apps);
    final all = fakeCategory(name: 'All catalog')..systemKey = 'all_apps';
    all.applications.add(app);
    final favorites = fakeCategory(name: 'Favorites')..systemKey = 'favorites';
    favorites.applications.add(app);
    when(apps.categories).thenReturn([all, favorites]);
    when(apps.removeFromCategory(app, favorites)).thenAnswer((_) async {});
    await tester.tap(find.text('Sample'));
    await tester.pumpAndSettle();
    expect(find.text('sample.app'), findsOneWidget);
    expect(find.text('Add to Fav'), findsNothing);
    await tester.tap(find.text('Remove from category'));
    await tester.pumpAndSettle();
    expect(find.text('All catalog'), findsNothing);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    verify(apps.removeFromCategory(app, favorites)).called(1);
    expect(find.byType(AppDetailsPage), findsOneWidget);
  });

  testWidgets('details keep removal action when the app has no manual memberships', (tester) async {
    final apps = MockAppsService();
    final app = fakeApp(packageName: 'sample', name: 'Sample');
    when(apps.applications).thenReturn([app]);
    await _pumpWidgetWithProviders(tester, apps);
    await tester.tap(find.text('Sample'));
    await tester.pumpAndSettle();
    final l = AppLocalizations.of(tester.element(find.byType(AppDetailsPage)))!;
    await tester.tap(find.text(l.removeFromCategory));
    await tester.pumpAndSettle();
    expect(find.text(l.noRemovableCategories), findsOneWidget);
    expect(find.byType(AddToCategoryDialog), findsNothing);
    expect(find.byType(AppDetailsPage), findsOneWidget);
    verifyNever(apps.removeFromCategory(any, any));
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets("'Info' calls openAppInfo on AppsService", (tester) async {
    final appsService = MockAppsService();
    final application = fakeApp(
      packageName: "me.efesser.flauncher",
      name: "FLauncher",
      version: "1.0.0",
    );
    when(appsService.applications).thenReturn([application]);
    when(appsService.launcherSections).thenReturn([fakeCategory()]);

    await _pumpWidgetWithProviders(tester, appsService);

    await tester.tap(find.text("FLauncher"));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text("Application info"));
    await tester.tap(find.text("Application info"));
    await tester.pumpAndSettle();
    verify(appsService.openAppInfo(application));
  });
}

Future<void> _pumpWidgetWithProviders(WidgetTester tester, MockAppsService appsService, {List<Category>? categories}) async {
  when(appsService.categories).thenReturn(categories ?? [
    fakeCategory()..systemKey = 'all_apps'
      ..applications.addAll(appsService.applications.where((app) => !app.hidden && app.isLaunchable)),
  ]);
  when(appsService.hasCustomBanner(any)).thenAnswer((_) async => false);
  when(appsService.getAppIcon(any)).thenAnswer((_) async => kTransparentImage);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppsService>.value(value: appsService),
ChangeNotifierProvider<SettingsService>.value(value: MockSettingsService()..stubHide()),
      ],
      builder: (_, _) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          AppDetailsPage.routeName: (context) {
            final app = ModalRoute.of(context)!.settings.arguments as App;
            return Scaffold(body: AppDetailsPage(application: app));
          },
        },
        home: Scaffold(body: ApplicationsPanelPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

extension on MockSettingsService { void stubHide() { when(settingsMenuOnRight).thenReturn(false); when(hideLauncherTile).thenReturn(false); when(appKeyClickEnabled).thenReturn(false); } }
