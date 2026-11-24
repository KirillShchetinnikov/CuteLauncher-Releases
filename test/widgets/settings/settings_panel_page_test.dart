import 'package:flauncher/widgets/settings/settings_destinations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/donate_dialog.dart';
import 'package:flauncher/widgets/settings/flauncher_about_dialog.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:package_info_plus_platform_interface/package_info_data.dart';
import 'package:package_info_plus_platform_interface/package_info_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:provider/provider.dart';

import '../../mocks.mocks.dart';

void main() {
  setUpAll(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.single.physicalSize = Size(1280, 720);
    binding.platformDispatcher.views.single.devicePixelRatio = 1.0;
    // Scale-down the font size because the font 'Ahem' used when running tests is much wider than Roboto
    binding.platformDispatcher.textScaleFactorTestValue = 0.8;
  });

  testWidgets("'Applications' opens ApplicationsPanelPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Applications"));
    await tester.pumpAndSettle();
    expect(find.byKey(Key("ApplicationsPanelPage")), findsOneWidget);
  });

  testWidgets("'Interface' opens InterfaceSettingsPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Home screen"));
    await tester.pumpAndSettle();
    expect(find.byKey(Key("InterfaceSettingsPage")), findsOneWidget);
  });

  testWidgets("'System' opens GeneralSettingsPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Launcher settings"));
    await tester.pumpAndSettle();
    expect(find.byKey(Key("GeneralSettingsPage")), findsOneWidget);
  });

  testWidgets("'Display & screensaver' opens DisplaySettingsPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Launcher features"));
    await tester.pumpAndSettle();
    expect(find.byKey(Key("DisplaySettingsPage")), findsOneWidget);
  });

  testWidgets("'Notifications' opens NotificationsSettingsPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    expect(find.text("Notifications"), findsNothing);
  });

  testWidgets("'Accessibility' opens AccessibilityPage", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Default launcher and ADB"));
    await tester.pumpAndSettle();
    expect(find.byKey(Key("AccessibilityPage")), findsOneWidget);
  });

  testWidgets("'Android settings' calls AppsService", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    await tester.tap(find.text("Android TV settings"));
    await tester.pumpAndSettle();
    verify(appsService.openSettings());
  });

  testWidgets('root has six ordered sections and one external action', (tester) async {
    final settings = MockSettingsService();
    when(settings.appKeyClickEnabled).thenReturn(false);
    final apps = MockAppsService();
    await _pumpWidgetWithProviders(tester, settings, apps);
    final titles = ['Home screen', 'Widgets and panels', 'Launcher features', 'Default launcher and ADB', 'Applications', 'Launcher settings', 'Diagnostics', 'Android TV settings'];
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous));
      previous = y;
    }
    expect(find.text('About CuteLauncher'), findsNothing);
    expect(find.text('Miscellaneous'), findsNothing);
    await tester.tap(find.text('Widgets and panels'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('AppearanceSettingsPage')), findsOneWidget);
  });

  testWidgets("'About CuteLauncher' opens about dialog", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
    when(settingsService.accentColorHex).thenReturn("7C4DFF");
    when(settingsService.appLanguage).thenReturn('');
    when(settingsService.fileManagerPreference).thenReturn(FileManagerPreference.ask);
    when(settingsService.memorySaverEnabled).thenReturn(false);
    PackageInfoPlatform.instance = _MockPackageInfoPlatform();

    await _pumpWidgetWithProviders(tester, settingsService, appsService, general: true);

    await tester.scrollUntilVisible(find.text("About CuteLauncher"), 250);
    await tester.pumpAndSettle();
    await tester.tap(find.text("About CuteLauncher"));
    await tester.pumpAndSettle();
    expect(find.byType(CuteLauncherAboutDialog), findsOneWidget);
    expect(find.text('Original project'), findsNothing);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.textContaining('io.github.kirillshchetinnikov.cutelauncher'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Close'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CuteLauncherAboutDialog), findsNothing);
  });

  for (final update in [false, true]) {
    testWidgets('Up and OK open the header action (update: $update)', (tester) async {
      final settingsService = MockSettingsService();
      when(settingsService.appKeyClickEnabled).thenReturn(false);
      final appsService = MockAppsService();
      when(appsService.launcherSections).thenReturn([]);
      when(appsService.applications).thenReturn([]);
      when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
      when(settingsService.accentColorHex).thenReturn("7C4DFF");

      await _pumpWidgetWithProviders(tester, settingsService, appsService, update: update);
      final label = update ? 'Update available · 1.8.2-test.10' : 'Support the developer';
      final logo = find.image(const AssetImage('assets/about-icon.png'));
      final brand = tester.getRect(find.text('CuteLauncher'));
      final title = tester.getRect(find.text('Settings'));
      final button = tester.getRect(find.widgetWithText(TextButton, label));
      expect(tester.getSize(logo), const Size(44, 44));
      expect(brand.left, title.left);
      expect(brand.left, greaterThan(tester.getRect(logo).right));
      expect(brand.top, greaterThanOrEqualTo(title.bottom));
      expect(button.left, tester.getRect(logo).left);
      expect(button.top, greaterThanOrEqualTo(brand.bottom));
      expect(tester.widget<Text>(find.text(label)).maxLines, 1);
      expect(Focus.of(tester.element(find.text('Home screen'))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(Focus.of(tester.element(find.text(label))).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(update ? find.byKey(const Key('UpdatesPage')) : find.byType(DonateDialog), findsOneWidget);
    });
  }
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  SettingsService settingsService,
  AppsService appsService, {bool general = false, bool update = false}
) async {
  SharedPreferences.setMockInitialValues({});
  final appearance = AppearanceService(await SharedPreferences.getInstance());
  final updates = UpdateService(await SharedPreferences.getInstance(), environment: () async => null);
  if (update) {
    updates.release = AppRelease('1.8.2-test.10+280', Uri(), 1, null);
  }
  addTearDown(updates.dispose);
  addTearDown(appearance.dispose);
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<UpdateService>.value(value: updates),
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
        ChangeNotifierProvider<AppearanceService>.value(value: appearance),
        ChangeNotifierProvider<AppsService>.value(value: appsService),
      ],
      builder: (_, _) => MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routes: {
          UpdatesPage.routeName: (_) => Container(key: const Key('UpdatesPage')),
          WidgetsAndPanelsPage.routeName: (_) => Container(key: const Key("AppearanceSettingsPage")),
          InterfaceSettingsPage.routeName: (_) => Container(key: Key("InterfaceSettingsPage")),
          LauncherFunctionsPage.routeName: (_) => Container(key: Key("DisplaySettingsPage")),
          NotificationsSettingsPage.routeName: (_) => Container(key: Key("NotificationsSettingsPage")),
          GeneralSettingsPage.routeName: (_) => Container(key: Key("GeneralSettingsPage")),
          LauncherAccessPage.routeName: (_) => Container(key: Key("AccessibilityPage")),
          ApplicationsPanelPage.routeName: (_) => Container(key: Key("ApplicationsPanelPage")),
        },
        home: Material(child: general ? const GeneralSettingsPage() : const SettingsPanelPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _MockPackageInfoPlatform with MockPlatformInterfaceMixin implements PackageInfoPlatform {
  @override
  Future<PackageInfoData> getAll({String? baseUrl}) async => PackageInfoData(
        appName: "CuteLauncher",
        packageName: "io.github.kirillshchetinnikov.cutelauncher",
        version: "1.0.0",
        buildNumber: "1",
        buildSignature: "",
      );
}
