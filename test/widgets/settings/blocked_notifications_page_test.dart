import 'dart:async';
import 'dart:typed_data';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/blocked_notifications_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import '../../mocks.dart';
import '../../mocks.mocks.dart';

void main() {
  testWidgets('blocked rows have compact unblock actions and no redundant status', (tester) async {
    final notifications = MockNotificationsService();
    final apps = MockAppsService();
    when(notifications.blockedPackages).thenReturn({'app.one', 'unknown.app'});
    when(apps.applications).thenReturn([fakeApp(packageName: 'app.one', name: 'Приложение с длинным названием')]);
    when(apps.getAppIcon(any)).thenAnswer((_) => Completer<Uint8List>().future);
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<NotificationsService>.value(value: notifications),
      ChangeNotifierProvider<AppsService>.value(value: apps),
    ], child: MaterialApp(locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Align(alignment: Alignment.centerLeft,
        child: SizedBox(width: 380, child: BlockedNotificationsPage()))))));
    await tester.pumpAndSettle();
    expect(find.text('Блокировка уведомлений от приложений'), findsOneWidget);
    expect(find.text('Заблокированные приложения (2)'), findsOneWidget);
    expect(find.text('Уведомления заблокированы'), findsNothing);
    expect(find.text('Разблокировать'), findsNWidgets(2));
    await tester.tap(find.text('Разблокировать').first);
    verify(notifications.unblockPackage('app.one')).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('entry focuses an application and collapsed help scrolls with the list', (tester) async {
    final notifications = MockNotificationsService();
    final apps = MockAppsService();
    when(notifications.blockedPackages).thenReturn({});
    when(apps.applications).thenReturn(List.generate(20,
      (i) => fakeApp(packageName: 'app.$i', name: 'App $i')));
    when(apps.getAppIcon(any)).thenAnswer((_) => Completer<Uint8List>().future);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<NotificationsService>.value(value: notifications),
        ChangeNotifierProvider<AppsService>.value(value: apps),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: BlockedNotificationsPage()),
      ),
    ));
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    final position = tester.state<ScrollableState>(find.descendant(of: list, matching: find.byType(Scrollable))).position;
    expect(FocusManager.instance.primaryFocus?.context?.findAncestorWidgetOfExactType<RoundedSwitchListTile>(), isNotNull);
    position.jumpTo(0);
    await tester.pumpAndSettle();
    final hint = find.byKey(const ValueKey('notification-apps-hint'));
    expect(find.ancestor(of: hint, matching: list), findsOneWidget);
    expect(position.pixels, 0);
    final toggle = find.byType(RoundedSwitchListTile).first;
    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    verify(notifications.blockPackage(any)).called(1);
    await tester.drag(list, const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });
}
