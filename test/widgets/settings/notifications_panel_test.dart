import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/notifications_panel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/notifications_settings_page.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';

import '../../mocks.mocks.dart';
import '../panel_backdrop_assertions.dart';

void main() {
  testWidgets(
    'remote actions, side options, focus recovery and persistent filter',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final channel = MockFLauncherChannel();
      final apps = MockAppsService();
      final stream = StreamController<List<Map<dynamic, dynamic>>>.broadcast();
      var items = <Map<dynamic, dynamic>>[
        for (final key in ['a', 'b', 'p'])
          {
            'key': key,
            'packageName': 'app.$key',
            'title': 'Title $key',
            'text': 'Body $key',
            'isClearable': key != 'p',
          },
      ];
      when(channel.checkNotificationListenerPermission())
          .thenAnswer((_) async => true);
      when(channel.checkOverlayPermission()).thenAnswer((_) async => true);
      when(channel.getActiveNotifications()).thenAnswer((_) async => items);
      when(channel.addNotificationsChangedListener(any)).thenAnswer(
        (call) => stream.stream.listen(
          call.positionalArguments.first
              as void Function(List<Map<dynamic, dynamic>>),
        ),
      );
      when(channel.dismissNotification(any)).thenAnswer((call) async {
        items = items
            .where((n) => n['key'] != call.positionalArguments.first)
            .toList();
        return true;
      });
      when(apps.applications).thenReturn([]);
      when(apps.getAppIcon(any))
          .thenAnswer((_) => Completer<Uint8List>().future);
      final notifications = NotificationsService(channel);
      while (!notifications.initialized) {
        await tester.pump();
      }
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(() {
        notifications.dispose();
        settings.dispose();
        stream.close();
      });
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NotificationsService>.value(
              value: notifications,
            ),
            ChangeNotifierProvider<AppsService>.value(value: apps),
            ChangeNotifierProvider<SettingsService>.value(value: settings),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const NotificationsPanel(isRightSide: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder row(String key) => find.byKey(ValueKey('notification-$key'));
      expect(
        tester.widget<FocusableSettingsTile>(row('a')).focusNode!.hasFocus,
        true,
      );
      expect(find.byIcon(Icons.block), findsNothing);
      expect(
        find.descendant(of: row('a'), matching: find.byType(IconButton)),
        findsNothing,
      );
      expect(
        find.descendant(of: row('a'), matching: find.byIcon(Icons.close)),
        findsOneWidget,
      );
      expect(
        find.text('◄ — закрыть · OK — параметры · ► — блокировать приложение'),
        findsOneWidget,
      );
      final labels = AppLocalizations.of(
        tester.element(find.byType(NotificationsPanel)),
      )!;
      final header = tester.getCenter(find.text(labels.notifications));
      expect(header.dy, 65);
      for (final tooltip in [
        labels.hidePersistentNotificationsHint,
        labels.notificationSettingsButton,
        labels.clearAll,
      ]) {
        final button = find.byTooltip(tooltip);
        expect((tester.getCenter(button).dy - header.dy).abs(), lessThan(2));
        final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
        await mouse.addPointer();
        await mouse.moveTo(tester.getCenter(button));
        await tester.pump(const Duration(seconds: 2));
        await tester.pumpAndSettle();
        expect(find.text(tooltip), findsOneWidget);
        expect(
          tester.getBottomLeft(find.text(tooltip)).dy,
          lessThan(tester.getTopLeft(button).dy),
        );
        await mouse.removePointer();
        await tester.pumpAndSettle();
      }
      for (final tooltip in [
        labels.hidePersistentNotificationsHint,
        labels.notificationSettingsButton,
      ]) {
        final button = tester.widget<IconButton>(
          find.descendant(
            of: find.byTooltip(tooltip),
            matching: find.byType(IconButton),
          ),
        );
        final buttonFinder = find.descendant(
          of: find.byTooltip(tooltip),
          matching: find.byType(IconButton),
        );
        final buttonElement = tester.element(buttonFinder);
        button.focusNode!.requestFocus();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1999));
        expect(find.text(tooltip), findsNothing);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pumpAndSettle();
        expect(find.text(tooltip), findsOneWidget);
        expect(tester.element(buttonFinder), same(buttonElement));
        expect(button.focusNode!.hasFocus, true);
        tester
            .widget<FocusableSettingsTile>(row('a'))
            .focusNode!
            .requestFocus();
        await tester.pumpAndSettle();
        expect(find.text(tooltip), findsNothing);
      }
      for (var i = 0; i < 3; i++) {
        final quickButton = tester.widget<IconButton>(
          find.descendant(
            of: find.byTooltip(labels.hidePersistentNotificationsHint),
            matching: find.byType(IconButton),
          ),
        );
        quickButton.focusNode!.requestFocus();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));
        tester
            .widget<FocusableSettingsTile>(row('a'))
            .focusNode!
            .requestFocus();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(seconds: 2));
        expect(find.text(labels.hidePersistentNotificationsHint), findsNothing);
        for (final tooltip in [
          labels.hidePersistentNotificationsHint,
          labels.notificationSettingsButton,
        ]) {
          tester
              .widget<IconButton>(
                find.descendant(
                  of: find.byTooltip(tooltip),
                  matching: find.byType(IconButton),
                ),
              )
              .focusNode!
              .requestFocus();
          await tester.pumpAndSettle();
          await tester.pump(const Duration(seconds: 2));
          await tester.pumpAndSettle();
          expect(find.text(tooltip), findsOneWidget);
        }
      }
      tester.widget<FocusableSettingsTile>(row('p')).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(
        find.text(labels.persistentNotificationCannotDelete),
        findsOneWidget,
      );
      expect(
        tester.widget<FocusableSettingsTile>(row('b')).focusNode!.hasFocus,
        true,
      );
      verifyNever(channel.dismissNotification('p'));
      tester.widget<FocusableSettingsTile>(row('a')).focusNode!.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expectSinglePanelBackdrop(tester);
      await tester.pumpAndSettle();
      verifyNever(channel.dismissNotification(any));
      expect(find.text('Параметры уведомления'), findsOneWidget);
      expect(find.text(labels.delete), findsOneWidget);
      expect(find.text(labels.blockAppNotifications), findsOneWidget);
      expect(
        find.text('${labels.blockAppNotifications} (app.a)'),
        findsNothing,
      );
      expect(
        tester
            .widget<SidePanelDialog>(find.byType(SidePanelDialog).last)
            .isRightSide,
        true,
      );
      await Navigator.of(tester.element(find.text('Параметры уведомления')))
          .maybePop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FocusableSettingsTile>(row('a')).focusNode!.hasFocus,
        true,
      );
      // Blocking removes an earlier row from the same app as well.
      items = [
        {
          'key': 'a0',
          'packageName': 'app.a',
          'title': 'Earlier',
          'text': 'Body',
          'isClearable': true,
        },
        ...items,
      ];
      stream.add(items);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(notifications.isPackageBlocked('app.a'), true);
      expect(row('a'), findsNothing);
      expect(
        tester.widget<FocusableSettingsTile>(row('b')).focusNode!.hasFocus,
        true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      verify(channel.dismissNotification('b')).called(1);
      expect(
        tester.widget<FocusableSettingsTile>(row('p')).focusNode!.hasFocus,
        true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      verifyNever(channel.dismissNotification('p'));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text(labels.delete));
      await tester.pumpAndSettle();
      expect(find.text('Параметры уведомления'), findsOneWidget);
      verifyNever(channel.dismissNotification('p'));
      items = [
        {
          'key': 'c',
          'packageName': 'app.c',
          'title': 'New',
          'text': 'Body',
          'isClearable': true,
        },
      ];
      stream.add(items);
      await tester.pumpAndSettle();
      await Navigator.of(tester.element(find.text('Параметры уведомления')))
          .maybePop();
      await tester.pumpAndSettle();
      expect(
        tester.widget<FocusableSettingsTile>(row('c')).focusNode!.hasFocus,
        true,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.text(labels.delete));
      await tester.pumpAndSettle();
      verify(channel.dismissNotification('c')).called(1);
      expect(find.text('Параметры уведомления'), findsNothing);
      items = [
        {
          'key': 'p',
          'packageName': 'app.p',
          'title': 'Persistent',
          'text': 'Body',
          'isClearable': false,
        },
      ];
      stream.add(items);
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(NotificationsPanel)),
      )!;
      expect(find.byTooltip(l.hidePersistentNotificationsHint), findsOneWidget);
      await tester.tap(find.byTooltip(l.hidePersistentNotificationsHint));
      await tester.pumpAndSettle();
      expect(find.text(l.allCaughtUp), findsOneWidget);
      final hide = tester.widget<IconButton>(
        find
            .descendant(
              of: find.byTooltip(l.hidePersistentNotificationsHint),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(hide.focusNode!.hasFocus, true);
      await tester.tap(find.byTooltip(l.notificationSettingsButton));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsSettingsPage), findsOneWidget);
      expect(find.byKey(const ValueKey("notification-backdrop")), findsNothing);
      expect(
        tester.widget<ModalBarrier>(find.byType(ModalBarrier).last).color,
        anyOf(isNull, Colors.transparent),
      );
      expect(find.byTooltip(l.hidePersistentNotificationsHint), findsNothing);
      expect(
        find.descendant(
          of: find.byType(NotificationsPanel),
          matching: find.text(l.notifications),
        ),
        findsNothing,
      );
      await Navigator.of(
        tester.element(find.byType(NotificationsSettingsPage)),
        rootNavigator: true,
      ).maybePop();
      await tester.pumpAndSettle();
      final settingsButton = tester.widget<IconButton>(
        find
            .descendant(
              of: find.byTooltip(l.notificationSettingsButton),
              matching: find.byType(IconButton),
            )
            .first,
      );
      expect(settingsButton.focusNode!.hasFocus, true);
      expect(
        find.byKey(const ValueKey("notification-backdrop")),
        findsOneWidget,
      );
      expect(find.byTooltip(l.hidePersistentNotificationsHint), findsOneWidget);
      expect(find.text(l.notificationSettingsButton), findsNothing);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text(l.notificationSettingsButton), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
