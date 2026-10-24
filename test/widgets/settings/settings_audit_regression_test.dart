import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/watch_next_service.dart';
import 'package:flauncher/providers/wallpaper_service.dart';
import 'package:flauncher/gradients.dart';
import 'package:flauncher/widgets/settings/gradient_panel_page.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flauncher/widgets/settings/accent_color_page.dart';
import 'package:flauncher/widgets/settings/applications_panel_page.dart';
import 'package:flauncher/widgets/settings/blocked_notifications_page.dart';
import 'package:flauncher/widgets/settings/continue_watching_apps_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  for (final language in ['ru', 'en']) {
    for (final page in ['accent', 'apps', 'notifications', 'watchNext', 'gradients']) {
      testWidgets(
        'audit: $page preserves settings text and long labels in $language',
        (tester) async {
          tester.view.physicalSize = const Size(350, 540);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          final settings = SettingsService(prefs);
          final appearance = AppearanceService(prefs);
          await appearance.set('settingsTextColor', 0xffbbccdd);
          await appearance.set('settingsTextSize', 20);
          final apps = MockAppsService();
          final notifications = MockNotificationsService();
          final watchNext = MockWatchNextService();
          final name = List.filled(8, 'Long application name').join(' ');
          final app = fakeApp(packageName: 'sample.app', name: name);
          when(apps.applications).thenReturn([app]);
          when(apps.categories).thenReturn([
            fakeCategory()
              ..systemKey = 'all_apps'
              ..applications.add(app),
          ]);
          when(apps.getAppIcon(any))
              .thenAnswer((_) => Completer<Uint8List>().future);
          when(notifications.blockedPackages).thenReturn({});
          when(watchNext.programs).thenReturn([]);
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider.value(value: settings),
                ChangeNotifierProvider.value(value: appearance),
                ChangeNotifierProvider<AppsService>.value(value: apps),
                ChangeNotifierProvider<NotificationsService>.value(
                  value: notifications,
                ),
                ChangeNotifierProvider<WatchNextService>.value(
                  value: watchNext,
                ),
                ChangeNotifierProvider<WallpaperService>.value(value: MockWallpaperService()),
              ],
              child: MaterialApp(
                locale: Locale(language),
                theme: ThemeData.dark(),
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.3)),
                  child: child!,
                ),
                home: Scaffold(
                  body: SettingsPanelStyle(
                    builder: (_) => switch (page) {
                      'accent' => const AccentColorPage(),
                      'apps' => const ApplicationsPanelPage(),
                      'notifications' => const BlockedNotificationsPage(),
                      'gradients' => const GradientPanelPage(),
                      _ => const ContinueWatchingAppsPage(),
                    },
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (page == 'gradients') {
            for (final gradient in FLauncherGradients.all) {
              await tester.scrollUntilVisible(
                find.text(gradient.name),
                140,
                scrollable: find.byType(Scrollable).first,
              );
              await tester.pumpAndSettle();
              final paragraph = tester.renderObject<RenderParagraph>(find.descendant(
                of: find.text(gradient.name), matching: find.byType(RichText)));
              expect(paragraph.didExceedMaxLines, isFalse, reason: gradient.name);
              expect(tester.takeException(), isNull);
            }
            await tester.scrollUntilVisible(
              find.text(FLauncherGradients.pitchBlack.name),
              -140,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
          }
          if (page == 'watchNext') {
            await tester.scrollUntilVisible(
              find.text(name),
              200,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          for (final element in find.byType(RichText).evaluate()) {
            final paragraph = element.renderObject as RenderParagraph;
            expect(
              paragraph.didExceedMaxLines,
              isFalse,
              reason: paragraph.text.toPlainText(),
            );
          }
          final label = page == 'accent'
              ? find.text(
                  AppLocalizations.of(
                    tester.element(find.byType(AccentColorPage)),
                  )!.colorPurple,
                )
              : page == 'gradients' ? find.text(FLauncherGradients.pitchBlack.name) : find.text(name).last;
          expect(label, findsOneWidget);
          final text = tester.widget<Text>(label);
          final context = tester.element(label);
          expect(
            text.style?.color ?? DefaultTextStyle.of(context).style.color,
            const Color(0xffbbccdd),
          );
          expect(MediaQuery.textScalerOf(context).scale(16), closeTo(26, .01));
          if (page == 'watchNext') {
            final l = AppLocalizations.of(context)!;
            expect(find.text(l.enabled), findsOneWidget);
            expect(find.text('Allowed'), findsNothing);
            expect(find.text('Blocked'), findsNothing);
          }
          await tester.pumpWidget(const SizedBox());
          appearance.dispose();
          settings.dispose();
        },
      );
    }
  }
}

