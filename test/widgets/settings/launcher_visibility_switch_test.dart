import 'package:flauncher/providers/apps_service.dart';
import 'package:mockito/mockito.dart';
import '../../mocks.mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('launcher tile switch updates and persists its value', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final apps = MockAppsService();
    when(apps.applications).thenReturn([]);
    when(apps.categories).thenReturn([]);
    await tester.pumpWidget(MultiProvider(providers: [ChangeNotifierProvider<SettingsService>.value(value: settings), ChangeNotifierProvider<AppsService>.value(value: apps)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: HomeParametersPage()),
      ),
    ));
    final toggle = find.text('Hide CuteLauncher in the app grid');
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.hideLauncherTile, isTrue);
    expect(SettingsService(prefs).hideLauncherTile, isTrue);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(settings.hideLauncherTile, isFalse);
    final androidToggle = find.text('Hide Android settings in app tiles');
    await tester.ensureVisible(androidToggle);
    expect(settings.hideAndroidSettingsTile, isTrue);
    await tester.tap(androidToggle);
    await tester.pumpAndSettle();
    expect(settings.hideAndroidSettingsTile, isFalse);
    expect(SettingsService(prefs).hideAndroidSettingsTile, isFalse);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<AppsService>.value(value: apps),
    ], child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: ApplicationsPanelPage()),
    )));
    await tester.pumpAndSettle();
    expect(toggle, findsNothing);
  });
}
