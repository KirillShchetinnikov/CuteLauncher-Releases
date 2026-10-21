import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
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
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/display_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
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

    await tester.tap(find.text("Advanced"));
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

    await tester.tap(find.text("Night mode and brightness"));
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

    await tester.tap(find.text("Launcher and TV controls"));
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
    final titles = ['Home screen', 'Appearance', 'Applications', 'Night mode and brightness', 'Launcher and TV controls', 'Advanced', 'Android TV settings'];
    var previous = -1.0;
    for (final title in titles) {
      final y = tester.getTopLeft(find.text(title)).dy;
      expect(y, greaterThan(previous));
      previous = y;
    }
    expect(find.text('About CuteLauncher'), findsNothing);
    expect(find.text('Miscellaneous'), findsNothing);
    await tester.tap(find.text('Appearance'));
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
    PackageInfoPlatform.instance = _MockPackageInfoPlatform();

    await _pumpWidgetWithProviders(tester, settingsService, appsService, general: true);

    await tester.tap(find.text("About CuteLauncher"));
    await tester.pumpAndSettle();
    expect(find.byType(CuteLauncherAboutDialog), findsOneWidget);
    expect(find.text('Original project'), findsNothing);
    expect(find.text('Installed: v1.0.0+1'), findsOneWidget);
    expect(find.textContaining('io.github.kirillshchetinnikov.cutelauncher'), findsOneWidget);
    expect(Focus.of(tester.element(find.text('Close'))).hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(CuteLauncherAboutDialog), findsNothing);
  });

  testWidgets("Upstream donation entry is not shown", (tester) async {
    final settingsService = MockSettingsService();
    when(settingsService.appKeyClickEnabled).thenReturn(false);
    final appsService = MockAppsService();
    when(appsService.launcherSections).thenReturn([]);
    when(appsService.applications).thenReturn([]);
    when(settingsService.appHighlightAnimationEnabled).thenReturn(true);
    when(settingsService.accentColorHex).thenReturn("7C4DFF");

    await _pumpWidgetWithProviders(tester, settingsService, appsService);

    expect(find.text("Support & Donate"), findsNothing);
    expect(find.byType(DonateDialog), findsNothing);
  });
}

Future<void> _pumpWidgetWithProviders(
  WidgetTester tester,
  SettingsService settingsService,
  AppsService appsService, {bool general = false}
) async {
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settingsService),
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
          AppearanceSettingsPage.routeName: (_) => Container(key: const Key("AppearanceSettingsPage")),
          InterfaceSettingsPage.routeName: (_) => Container(key: Key("InterfaceSettingsPage")),
          DisplaySettingsPage.routeName: (_) => Container(key: Key("DisplaySettingsPage")),
          NotificationsSettingsPage.routeName: (_) => Container(key: Key("NotificationsSettingsPage")),
          GeneralSettingsPage.routeName: (_) => Container(key: Key("GeneralSettingsPage")),
          AccessibilityPage.routeName: (_) => Container(key: Key("AccessibilityPage")),
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
