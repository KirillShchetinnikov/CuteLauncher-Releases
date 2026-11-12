import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/overlay_appearance.dart';
import 'package:flauncher/overlay_position.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/settings_sync.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/remote_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/volume_widget_settings_page.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.mocks.dart';

void main() {
  test('volume overlay is opt-in and included in top-panel backups', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    expect(settings.showVolumeOverlay, isFalse);
    expect(settings.volumeOverlayPosition, OverlayPosition.topRight);
    expect(settings.volumeOverlayAppearance, OverlayAppearance.topPanel);
    await settings.setShowVolumeOverlay(true);
    await settings.setVolumeOverlayPosition(OverlayPosition.bottomRight);
    await settings.setVolumeOverlayAppearance(OverlayAppearance.dark);
    final restored = SettingsService(prefs);
    expect(restored.showVolumeOverlay, isTrue);
    expect(restored.volumeOverlayPosition, OverlayPosition.bottomRight);
    expect(restored.volumeOverlayAppearance, OverlayAppearance.dark);
    expect(settings.exportSettingsMap()[volumeOverlayAppearanceKey], 'dark');
    await settings.importSettingsMap({volumeOverlayAppearanceKey: 'invalid'});
    expect(settings.volumeOverlayAppearance, OverlayAppearance.dark);
    await settings.importSettingsMap({volumeOverlayAppearanceKey: 'topPanel'});
    expect(settings.volumeOverlayAppearance, OverlayAppearance.topPanel);
    expect(syncSettingsKeys, contains(volumeOverlayAppearanceKey));
    expect(
      backupSyncPartGroup('setting:$volumeOverlayAppearanceKey'),
      BackupSyncGroup.topPanel,
    );
    expect(settings.exportSettingsMap()['show_volume_overlay'], isTrue);
    await settings.importSettingsMap({'show_volume_overlay': 'false'});
    expect(settings.showVolumeOverlay, isTrue);
    await settings.importSettingsMap({'show_volume_overlay': false});
    expect(settings.showVolumeOverlay, isFalse);
    await settings.importSettingsMap({volumeOverlayPositionKey: 'center'});
    expect(settings.volumeOverlayPosition, OverlayPosition.bottomRight);
    await settings.importSettingsMap({volumeOverlayPositionKey: 'widget'});
    expect(settings.volumeOverlayPosition, OverlayPosition.widget);
    expect(syncSettingsKeys, contains('show_volume_overlay'));
    expect(
      backupSyncPartGroup('setting:show_volume_overlay'),
      BackupSyncGroup.topPanel,
    );
    settings.dispose();
    restored.dispose();
  });

  test(
    'volume interval defaults, bounds, backup validation and sync group',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      expect(settings.volumeUpdateInterval, 3);
      await settings.setVolumeUpdateInterval(7);
      final restored = SettingsService(prefs);
      expect(restored.volumeUpdateInterval, 7);
      final exported = settings.exportSettingsMap();
      expect(exported['volume_update_interval'], 7);
      await settings.setVolumeUpdateInterval(99);
      expect(settings.volumeUpdateInterval, 10);
      await settings.setVolumeUpdateInterval(0);
      expect(settings.volumeUpdateInterval, 1);
      await settings.importSettingsMap(exported);
      expect(settings.volumeUpdateInterval, 7);
      for (final invalid in [0, 11, '2', 1.5, false]) {
        await settings.importSettingsMap({'volume_update_interval': invalid});
        expect(settings.volumeUpdateInterval, 7);
      }
      expect(syncSettingsKeys, contains('volume_update_interval'));
      expect(
        backupSyncPartGroup('setting:volume_update_interval'),
        BackupSyncGroup.topPanel,
      );
      settings.dispose();
      restored.dispose();
    },
  );

  for (final remote in [false, true]) {
    for (final right in [false, true]) {
      testWidgets(
        'both panels open the shared interval page; remote=$remote right=$right',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'settings_menu_on_right': right,
          });
          final prefs = await SharedPreferences.getInstance();
          final settings = SettingsService(prefs);
          final appearance = AppearanceService(prefs);
          final panel = RemotePanelService(prefs);
          final network = MockNetworkService();
          final notifications = MockNotificationsService();
          final inputs = MockTvInputsService();
          when(network.hasUsageStatsPermission).thenReturn(false);
          when(notifications.hasPermission).thenReturn(false);
          when(inputs.hasInputs).thenReturn(false);
          when(inputs.initialized).thenReturn(true);
          final initialVisibility = remote
              ? panel.visible('audio')
              : settings.showVolumeInStatusBar;
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: appearance),
                ChangeNotifierProvider.value(value: panel),
                ChangeNotifierProvider<NetworkService>.value(value: network),
                ChangeNotifierProvider<NotificationsService>.value(
                  value: notifications,
                ),
                ChangeNotifierProvider<TvInputsService>.value(value: inputs),
              ],
              child: MaterialApp(
                locale: const Locale('ru'),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: SettingsPanel(
                  initialRoute: remote
                      ? RemotePanelPage.routeName
                      : StatusBarObjectsPage.routeName,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final l = AppLocalizations.of(
            tester.element(find.byType(SettingsPanel)),
          )!;
          if (remote) {
            await tester.tap(find.text(l.topPanelObjects));
            await tester.pumpAndSettle();
          }
          final entry = find.text(l.volumeWidgetSettings);
          await tester.scrollUntilVisible(
            entry,
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.ensureVisible(entry);
          await tester.pumpAndSettle();
          await tester.tap(entry);
          await tester.pumpAndSettle();
          expect(find.byType(VolumeWidgetSettingsPage), findsOneWidget);
          expect(
            tester
                .widget<SidePanelDialog>(find.byType(SidePanelDialog))
                .isRightSide,
            right,
          );
          expect(
            tester
                .widget<SidePanelDialog>(find.byType(SidePanelDialog))
                .topInset,
            kToolbarHeight,
          );
          expect(
            tester
                .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
                .value,
            3,
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
          await tester.pumpAndSettle();
          expect(settings.volumeUpdateInterval, 4);
          final overlay = find.widgetWithText(
            RoundedSwitchListTile,
            l.showVolumeOverlay,
          );
          expect(tester.widget<RoundedSwitchListTile>(overlay).value, isFalse);
          await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
          await tester.sendKeyEvent(LogicalKeyboardKey.select);
          await tester.pumpAndSettle();
          expect(settings.showVolumeOverlay, isTrue);
          expect(tester.widget<RoundedSwitchListTile>(overlay).value, isTrue);
          expect(find.text(l.remoteAccessSettings), findsOneWidget);
          final where = find.text(l.overlayWhereToShow);
          await tester.ensureVisible(where);
          await tester.tap(where);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.noticeBottomLeft));
          await tester.pumpAndSettle();
          expect(settings.volumeOverlayPosition, OverlayPosition.bottomLeft);
          final appearanceChoice = find.text(l.overlayAppearance);
          await tester.ensureVisible(appearanceChoice);
          await tester.tap(appearanceChoice);
          await tester.pumpAndSettle();
          await tester.tap(find.text(l.overlayAppearanceDark));
          await tester.pumpAndSettle();
          expect(settings.volumeOverlayAppearance, OverlayAppearance.dark);
          await tester.binding.handlePopRoute();
          await tester.pumpAndSettle();
          expect(find.byType(VolumeWidgetSettingsPage), findsNothing);
          expect(
            remote ? panel.visible('audio') : settings.showVolumeInStatusBar,
            initialVisibility,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          settings.dispose();
          appearance.dispose();
          panel.dispose();
        },
      );
    }
  }
}
