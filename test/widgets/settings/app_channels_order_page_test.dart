import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/app_channels_order_page.dart';
import 'package:flauncher/widgets/settings/launcher_section_panel_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';

import '../../mocks.mocks.dart';
import '../../support/app_channels.dart';
import '../../support/gated_preferences.dart';

void main() {
  for (final (language, width) in [
    ('ru', 960.0),
    ('ar', 960.0),
    ('ru', 420.0),
    ('ar', 420.0),
  ]) {
    testWidgets(
      'feed order supports remote, boundaries, repeats and Back: $language $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        const initialOrder = ['video.app:1', 'video.app:2', 'missing.app:3'];
        SharedPreferences.setMockInitialValues({});
        final store = GatedPreferencesStore({
          'flutter.selected_app_channels': initialOrder,
        });
        SharedPreferencesStorePlatform.instance = store;
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final secondTitle = width == 420
            ? 'Продолжить просмотр любимых фильмов'
            : 'Feed 2';
        final channel = FeedChannel()
          ..data = [
            feed(1),
            {
              ...feed(2),
              'name': secondTitle,
              'appName': 'Видеоприложение с длинным названием',
            },
            feed(3),
            feed(4),
          ];
        final service = AppChannelsService(channel, settings);
        final apps = MockAppsService();
        when(apps.launcherSections).thenReturn([appChannelsGroup()]);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: service),
              ChangeNotifierProvider<AppsService>.value(value: apps),
            ],
            child: MaterialApp(
              locale: Locale(language),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.5)),
                child: child!,
              ),
              home: const Scaffold(
                body: LauncherSectionPanelPage(sectionIndex: 0),
              ),
              routes: {
                AppChannelsOrderPage.routeName: (_) =>
                    const Scaffold(body: AppChannelsOrderPage()),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(LauncherSectionPanelPage)),
        )!;
        final readsBeforeEntry = channel.requests.length;
        await tester.ensureVisible(find.text(l.feedsAndOrder));
        await tester.tap(find.text(l.feedsAndOrder));
        await tester.pumpAndSettle();
        expect(channel.requests.length, readsBeforeEntry + 1);
        FocusableSettingsTile row([String key = 'video.app:2']) =>
            tester.widget<FocusableSettingsTile>(find.byKey(ValueKey(key)));
        FocusNode node() => row().focusNode!;
        node().requestFocus();
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.drag_handle), findsAtLeastNWidgets(3));
        expect(find.byIcon(Icons.swap_vert), findsNothing);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<FocusableSettingsTile>(
                find.byKey(const ValueKey('video.app:2')),
              )
              .selected,
          isTrue,
        );
        expect(find.byIcon(Icons.drag_indicator), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
        expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
        expect(find.text(secondTitle), findsOneWidget);
        expect(tester.takeException(), isNull);
        final position = Scrollable.of(
          tester.element(find.byKey(const ValueKey('video.app:2'))),
        ).position;
        final previousOffset = position.pixels;
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        if (width == 960) expect(position.pixels, previousOffset);
        expect(settings.selectedAppChannels, [
          'video.app:2',
          'video.app:1',
          'missing.app:3',
        ]);
        expect(node().hasFocus, isTrue);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(settings.selectedAppChannels.first, 'video.app:2');
        final write = store.writeGate = Completer<void>();
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        write.complete();
        await tester.pumpAndSettle();
        expect(settings.selectedAppChannels, [
          'video.app:1',
          'missing.app:3',
          'video.app:2',
        ]);
        expect(node().hasFocus, isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AppChannelsOrderPage), findsOneWidget);
        final hint = find.text(l.appChannelsOrderHint);
        expect(
          find.ancestor(of: hint, matching: find.byType(Scrollable)),
          findsNothing,
        );
        await tester.scrollUntilVisible(hint, 160);
        await tester.pumpAndSettle();
        expect(hint.hitTestable(), findsOneWidget);
        expect(
          find.ancestor(of: hint, matching: find.byType(SettingsHelp)),
          findsNothing,
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AppChannelsOrderPage), findsNothing);
        expect(
          Focus.of(tester.element(find.text(l.feedsAndOrder))).hasFocus,
          isTrue,
        );
        expect(SettingsService(prefs).selectedAppChannels, [
          'video.app:1',
          'missing.app:3',
          'video.app:2',
        ]);

        final readsBeforeReentry = channel.requests.length;
        await tester.tap(find.text(l.feedsAndOrder));
        await tester.pumpAndSettle();
        expect(channel.requests.length, readsBeforeReentry + 1);
        Future<void> press(LogicalKeyboardKey key) async {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
        }

        const hiddenKey = 'video.app:3';
        node().requestFocus();
        await tester.pumpAndSettle();
        await press(LogicalKeyboardKey.arrowDown);
        expect(row(hiddenKey).focusNode!.hasPrimaryFocus, isTrue);
        await press(LogicalKeyboardKey.arrowLeft);
        expect(row(hiddenKey).selected, isTrue);
        await press(LogicalKeyboardKey.arrowDown);
        await press(LogicalKeyboardKey.arrowUp);
        expect(settings.selectedAppChannels, isNot(contains(hiddenKey)));
        await press(LogicalKeyboardKey.arrowUp);
        expect(settings.selectedAppChannels.last, hiddenKey);
        expect(row(hiddenKey).focusNode!.hasPrimaryFocus, isTrue);
        await press(LogicalKeyboardKey.arrowDown);
        expect(settings.selectedAppChannels, isNot(contains(hiddenKey)));
        expect(row(hiddenKey).focusNode!.hasPrimaryFocus, isTrue);
        await press(LogicalKeyboardKey.arrowLeft);

        const missingKey = 'missing.app:3';
        await press(LogicalKeyboardKey.arrowUp); // Last visible feed.
        await press(LogicalKeyboardKey.arrowUp); // Unavailable feed.
        expect(row(missingKey).focusNode!.hasPrimaryFocus, isTrue);
        await press(LogicalKeyboardKey.arrowRight);
        await press(LogicalKeyboardKey.arrowDown);
        await press(LogicalKeyboardKey.arrowDown);
        expect(settings.selectedAppChannels, ['video.app:1', 'video.app:2']);
        expect(row(missingKey).focusNode!.hasPrimaryFocus, isTrue);
        expect(row(missingKey).selected, isTrue);
        await press(LogicalKeyboardKey.arrowDown);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.tap(find.text(l.feedsAndOrder));
        await tester.pumpAndSettle();
        await press(LogicalKeyboardKey.arrowDown);
        await press(LogicalKeyboardKey.arrowDown);
        expect(row(hiddenKey).focusNode!.hasPrimaryFocus, isTrue);
        await press(LogicalKeyboardKey.arrowDown);
        expect(row(missingKey).focusNode!.hasPrimaryFocus, isTrue);
        await prefs.reload();
        final restored = SettingsService(prefs);
        expect(restored.selectedAppChannels, ['video.app:1', 'video.app:2']);
        expect(restored.appChannelsOrder.hidden, [hiddenKey, missingKey, 'video.app:4']);
        restored.dispose();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
        await channel.events.close();
      },
    );
  }
}
