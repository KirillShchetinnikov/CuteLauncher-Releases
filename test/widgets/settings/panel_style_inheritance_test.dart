import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/widgets/settings/notifications_panel.dart';
import 'package:flauncher/widgets/settings/settings_panel.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/application_info_panel.dart';
import 'package:flauncher/widgets/add_to_category_dialog.dart';
import 'package:flauncher/widgets/watch_next_info_panel.dart';
import 'package:flauncher/models/watch_next_program.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.mocks.dart';
import '../../mocks.dart';

void main() {
  for (final panel in [
    'settings',
    'inputs',
    'notifications',
    'options',
    'application',
    'category',
    'watchNext',
  ]) {
    testWidgets('$panel inherits live settings style without fading content', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final appearance = AppearanceService(prefs);
      final settings = SettingsService(prefs);
      final inputs = MockTvInputsService();
      final notifications = MockNotificationsService();
      final apps = MockAppsService();
      final watchNext = MockWatchNextService();
      final application = fakeApp(
        packageName: 'sample.app',
        name: 'Sample app',
      );
      when(apps.categories).thenReturn([fakeCategory()]);
      when(apps.hasCustomBanner(any)).thenAnswer((_) async => false);
      when(apps.isAppInFavorites(any)).thenReturn(false);
      when(inputs.inputs).thenReturn([]);
      when(notifications.notifications).thenReturn([
        NotificationItem(
          key: 'sample',
          packageName: 'sample.app',
          title: 'Sample notification',
          text: 'Body',
          isClearable: true,
        ),
      ]);
      when(notifications.hidePersistentNotifications).thenReturn(false);
      when(apps.applications).thenReturn([]);
      when(apps.getAppIcon(any))
          .thenAnswer((_) => Completer<Uint8List>().future);
      addTearDown(appearance.dispose);
      addTearDown(settings.dispose);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: appearance),
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider<TvInputsService>.value(value: inputs),
            ChangeNotifierProvider<NotificationsService>.value(
              value: notifications,
            ),
            ChangeNotifierProvider<AppsService>.value(value: apps),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: switch (panel) {
              'settings' => const SettingsPanel(),
              'inputs' => const InputsPanel(),
              'application' => ApplicationInfoPanel(
                category: null,
                application: application,
              ),
              'category' => AddToCategoryDialog(application),
              'watchNext' => WatchNextInfoPanel(
                program: WatchNextProgram(
                  id: 7,
                  packageName: 'sample.app',
                  title: 'Sample program',
                  description: 'Sample description',
                  watchNextType: 0,
                  lastEngagementTime: 0,
                  playbackPosition: 0,
                  duration: 0,
                  intentUri: '',
                  posterArtUri: '',
                ),
                watchNextService: watchNext,
                appsService: apps,
              ),
              _ => const NotificationsPanel(),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (panel == 'options') {
        await tester.tap(find.text('Sample notification'));
        await tester.pumpAndSettle();
      }
      final sidePanel = find.byType(SidePanelDialog).last;
      final material = find
          .descendant(of: sidePanel, matching: find.byType(Material))
          .first;
      expect(tester.widget<Material>(material).color!.a, 1);
      await appearance.set('settingsColor', 0xff123456);
      await appearance.set('settingsTextColor', 0xffffcc80);
      await appearance.set('settingsTextSize', 20);
      // Popup notification styling must not override these side panels.
      await appearance.set('noticeColor', 0xff008800);
      await appearance.set('noticeOpacity', .8);
      for (final opacity in [.35, 0.0, 1.0]) {
        await appearance.set('settingsOpacity', opacity);
        await tester.pumpAndSettle();
        expect(
          tester.widget<Material>(material).color,
          const Color(0xff123456).withValues(alpha: opacity),
        );
        final content = tester.element(material);
        if (panel == 'settings' || panel == 'inputs') {
          // The panel color alone misses extra dimming behind its surface.
          final scaffold = find
              .ancestor(of: sidePanel, matching: find.byType(Scaffold))
              .first;
          expect(
            tester.widget<Scaffold>(scaffold).backgroundColor,
            Colors.transparent,
          );
        }
        final theme = Theme.of(content);
        expect(theme.colorScheme.onSurface, const Color(0xffffcc80));
        expect(theme.textTheme.bodyMedium!.color, const Color(0xffffcc80));
        expect(theme.iconTheme.color, const Color(0xffffcc80));
        expect(MediaQuery.textScalerOf(content).scale(16), 20);
        // Explicit header/description styles must use the panel theme too.
        for (final label in switch (panel) {
          'application' => ['Sample app'],
          'category' => ['Add to...'],
          'watchNext' => ['Sample description'],
          _ => <String>[],
        }) {
          final text = tester.widget<Text>(find.text(label));
          expect(text.style!.color, const Color(0xffffcc80));
        }
        expect(tester.takeException(), isNull);
      }
    });
  }
}
