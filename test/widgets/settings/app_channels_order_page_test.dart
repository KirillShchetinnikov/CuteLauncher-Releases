import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/app_channels_order_page.dart';
import 'package:flauncher/widgets/settings/app_channels_settings_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';

import '../../support/app_channels.dart';

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
        SharedPreferences.setMockInitialValues({
          'selected_app_channels': [
            'video.app:1',
            'video.app:2',
            'missing.app:3',
          ],
        });
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
          ];
        final service = AppChannelsService(channel, settings);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: service),
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
              home: const Scaffold(body: AppChannelsSettingsPage()),
              routes: {
                AppChannelsOrderPage.routeName: (_) =>
                    const Scaffold(body: AppChannelsOrderPage()),
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l = AppLocalizations.of(
          tester.element(find.byType(AppChannelsSettingsPage)),
        )!;
        await tester.ensureVisible(find.text(l.reorder));
        await tester.tap(find.text(l.reorder));
        await tester.pumpAndSettle();
        FocusNode node() => tester
            .widget<FocusableSettingsTile>(
              find.byKey(const ValueKey('video.app:2')),
            )
            .focusNode!;
        node().requestFocus();
        await tester.pumpAndSettle();
        expect(find.byIcon(Icons.drag_handle), findsNWidgets(3));
        expect(find.byIcon(Icons.swap_vert), findsNothing);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
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
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        expect(settings.selectedAppChannels, [
          'video.app:1',
          'missing.app:3',
          'video.app:2',
        ]);
        expect(node().hasFocus, isTrue);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(AppChannelsOrderPage), findsOneWidget);
        final hint = find.text(l.backgroundInformationOrderHint);
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
        expect(Focus.of(tester.element(find.text(l.reorder))).hasFocus, isTrue);
        expect(SettingsService(prefs).selectedAppChannels, [
          'video.app:1',
          'missing.app:3',
          'video.app:2',
        ]);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
        await channel.events.close();
      },
    );
  }
}
