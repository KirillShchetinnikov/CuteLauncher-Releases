import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/memory_resources.dart';
import 'package:flauncher/widgets/settings/memory_page.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/widgets/settings/appearance_page.dart';
import 'package:flauncher/widgets/settings/backup_restore_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_settings_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_card_size_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_max_items_page.dart';
import 'package:flauncher/widgets/settings/screensaver_clock_style_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/interface_settings_page.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.mocks.dart';

void main() {
  final pages = <String, Widget>{
    'memory': const MemoryPage(),
    'memory saver': const MemorySaverPage(),
    'home': const InterfaceSettingsPage(),
    'tiles': const AppearancePage(),
    'backup': const BackupRestorePage(),
    'updates': const UpdatesPage(),
    'notifications': const NotificationsSettingsPage(),
    'continue watching': const ContinueWatchingSettingsPage(),
    'card size': const ContinueWatchingCardSizePage(),
    'card count': const ContinueWatchingMaxItemsPage(),
    'clock style': const ScreensaverClockStylePage(),
  };
  for (final language in ['ru', 'en']) {
    for (final entry in pages.entries) {
      testWidgets('full content width: ${entry.key}, $language', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final appearance = AppearanceService(prefs);
        final memory = MemoryResources(settings: settings);
        final updates = UpdateService(
          prefs,
          environment: () async => {
            'play': false,
            'version': '1.0.0',
            'versionCode': 1,
            'abis': ['x86_64'],
          },
        );
        final notifications = MockNotificationsService();
        when(notifications.hasPermission).thenReturn(false);
        final watchNext = MockWatchNextService();
        when(watchNext.hasPermission).thenReturn(false);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsService>.value(value: settings),
              ChangeNotifierProvider<MemoryResources>.value(value: memory),
              ChangeNotifierProvider<AppearanceService>.value(
                value: appearance,
              ),
              ChangeNotifierProvider<UpdateService>.value(value: updates),
              ChangeNotifierProvider<NotificationsService>.value(
                value: notifications,
              ),
              ChangeNotifierProvider<WatchNextService>.value(value: watchNext),
            ],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: 360,
                    child: MediaQuery(
                      data: const MediaQueryData(
                        textScaler: TextScaler.linear(1.3),
                      ),
                      child: entry.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final viewport = tester.getRect(find.byType(Scrollbar).first);
        for (final tile in find.byType(FocusableSettingsTile).evaluate()) {
          final rect = tester.getRect(find.byWidget(tile.widget));
          expect(rect.left, closeTo(viewport.left + 14, .01));
          expect(rect.right, closeTo(viewport.right, .01));
        }
        for (final button in find.byType(InkWell).evaluate()) {
          final rect = tester.getRect(find.byWidget(button.widget));
          expect(rect.left, closeTo(viewport.left + 14, .01));
          expect(rect.right, closeTo(viewport.right, .01));
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        memory.dispose();
        settings.dispose();
        appearance.dispose();
        updates.dispose();
      });
    }
  }
}
