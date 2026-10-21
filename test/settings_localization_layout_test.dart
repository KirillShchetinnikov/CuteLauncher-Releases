import 'package:flauncher/widgets/settings/watch_next_limits_page.dart';
import 'package:flutter/material.dart';
import 'package:flauncher/providers/launcher_state.dart';
import 'package:mockito/mockito.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/providers/brightness_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/providers/online_wallpaper_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/providers/notifications_service.dart';

import 'flauncher_test.dart' as fixtures;
import 'support/design_fixture.dart' show loadDesignFonts;

import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/memory_page.dart';
import 'package:flauncher/widgets/settings/diagnostics_page.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flauncher/widgets/settings/adb_page.dart';
import 'package:flauncher/widgets/settings/auto_launch_page.dart';

import 'package:flauncher/widgets/settings/cloud_backup_page.dart';
import 'package:flauncher/providers/cloud_backup_service.dart';
import 'package:flauncher/widgets/settings/night_mode_page.dart';
import 'package:flauncher/widgets/settings/brightness_page.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/weather_page.dart';
import 'package:flauncher/widgets/settings/online_wallpaper_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/launcher_sections_panel_page.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/wallpaper_panel_page.dart';
import 'package:flauncher/widgets/settings/data_usage_period_page.dart';
import 'package:flauncher/widgets/settings/date_time_format_page.dart';
import 'package:flauncher/widgets/settings/accent_color_page.dart';
import 'package:flauncher/widgets/settings/misc_panel_page.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/general_settings_page.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flauncher/widgets/settings/accessibility_page.dart';
import 'package:flauncher/widgets/settings/backup_restore_page.dart';
import 'package:flauncher/widgets/settings/app_language_page.dart';
import 'package:flauncher/widgets/settings/blocked_notifications_page.dart';
import 'package:flauncher/widgets/settings/display_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_card_size_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_max_items_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_apps_page.dart';

void main() {
  for (final language in ['ru', 'en']) {
    testWidgets('settings routes fit in $language at 130 percent text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await loadDesignFonts(tester);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final appearance = AppearanceService(prefs);
      final memory = MemoryResources(settings: settings);
      final brightness = BrightnessService(prefs);
      final night = NightModeService(prefs);
      final updates = UpdateService(prefs, environment: () async => {});
      final online = OnlineWallpaperService(prefs);
      final notifications = fixtures.mkNotificationsService();
      when(notifications.blockedPackages).thenReturn({});
      when(notifications.checkPermission()).thenAnswer((_) async => false);
      when(notifications.checkOverlayPermission())
          .thenAnswer((_) async => false);
      when(notifications.hidePersistentNotifications).thenReturn(false);
      when(notifications.systemPopupEnabled).thenReturn(false);
      when(notifications.hasOverlayPermission).thenReturn(false);
      final watchNext = fixtures.mkWatchNextService();
      when(watchNext.hasPermission).thenReturn(true);
      when(watchNext.refresh()).thenAnswer((_) async {});
      final apps = fixtures.mkAppService();
      when(apps.isDefaultLauncher()).thenAnswer((_) async => false);
      when(apps.applications).thenReturn([]);
      when(apps.categories).thenReturn([]);
      when(apps.launcherSections).thenReturn([]);
      final weather = fixtures.mkWeatherService();
      when(weather.configuration).thenReturn(const WeatherConfiguration());
      when(weather.loading).thenReturn(false); when(weather.locating).thenReturn(false);
      when(weather.failure).thenReturn(null);
      when(weather.updatedAt).thenReturn(null);
      final services = [
        settings,
        appearance,
        memory,
        brightness,
        night,
        updates,
        online,
      ];

      try {
        for (final page in <Widget>[
          WatchNextLimitsPage(),
          AppearanceSettingsPage(),
          AutoLaunchPage(),

          CloudBackupPage(),
          AppearancePage(),
          BrightnessPage(),
          SettingsPanelPage(),
          MemoryPage(),
          DiagnosticsPage(),
          GeneralSettingsPage(),
          UpdatesPage(),
          AdbPage(),
          NightModePage(),
          InterfaceSettingsPage(),
          WallpaperPanelPage(),
          StatusBarPanelPage(),
          WeatherPage(),
          OnlineWallpaperPage(),
          GradientPanelPage(),
          ApplicationsPanelPage(),
          LauncherSectionsPanelPage(),
          DataUsagePeriodPage(),
          DateTimeFormatPage(),
          MiscPanelPage(),
          ScreensaverClockStylePage(),
          AccentColorPage(),
          AccessibilityPage(),
          BackupRestorePage(),
          AppLanguagePage(),
          BlockedNotificationsPage(),
          DisplaySettingsPage(),
          NotificationsSettingsPage(),
          ContinueWatchingSettingsPage(),
          ContinueWatchingCardSizePage(),
          ContinueWatchingMaxItemsPage(),
          ContinueWatchingAppsPage(),
        ]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider(create: (_) => CloudBackupService()),
                ChangeNotifierProvider(create: (_) => LauncherState()),
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: appearance),
                ChangeNotifierProvider.value(value: memory),
                ChangeNotifierProvider.value(value: brightness),
                ChangeNotifierProvider.value(value: night),
                ChangeNotifierProvider.value(value: updates),
                ChangeNotifierProvider.value(value: online),
                ChangeNotifierProvider<AppsService>.value(value: apps),
                ChangeNotifierProvider<WatchNextService>.value(
                  value: watchNext,
                ),
                ChangeNotifierProvider<WeatherService>.value(value: weather),
                ChangeNotifierProvider<WallpaperService>.value(
                  value: fixtures.mkWallpaperService(false),
                ),
                ChangeNotifierProvider<NotificationsService>.value(
                  value: notifications,
                ),
              ],
              child: MaterialApp(
                locale: Locale(language),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: Scaffold(
                  body: Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(width: 340, child: page),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$language ${page.runtimeType}',
          );
          for (final element in find.byType(RichText).evaluate()) {
            final paragraph = element.renderObject as RenderParagraph;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason:
                  '$language ${page.runtimeType}: ${paragraph.text.toPlainText()}',
            );
          }
          await tester.pumpWidget(const SizedBox());
          await tester.pumpAndSettle();
        }
      } finally {
        for (final service in services) {
          service.dispose();
        }
      }
    });
  }
}
