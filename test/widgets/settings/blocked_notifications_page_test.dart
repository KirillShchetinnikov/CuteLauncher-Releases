import 'package:flauncher/widgets/settings/settings_read_only_value.dart';
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
  testWidgets('large catalog is lazy and live notifications do not rebuild it', (tester) async {
    final notifications = _LiveNotifications();
    final apps = MockAppsService();
    when(notifications.blockedPackages).thenReturn({});
    when(apps.applications).thenReturn(List.generate(2000,
      (i) => fakeApp(packageName: 'app.$i', name: 'App $i')));
    var iconRequests = 0;
    when(apps.getAppIcon(any)).thenAnswer((_) async {
      iconRequests++;
      return Uint8List(0);
    });
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
    expect(tester.widget<ListView>(find.byType(ListView)).childrenDelegate,
      isA<SliverChildBuilderDelegate>());
    expect(iconRequests, inExclusiveRange(0, 40));
    clearInteractions(apps);
    notifications.notifyListeners();
    await tester.pumpAndSettle();
    verifyNever(apps.applications);
    expect(tester.takeException(), isNull);
  });
  testWidgets('blocked apps appear once and enabled switches unblock them', (tester) async {
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
    final countRow = find.byType(SettingsReadOnlyValue);
    expect(find.descendant(of: countRow, matching: find.text('Заблокированные приложения')), findsOneWidget);
    expect(find.descendant(of: countRow, matching: find.text('2')), findsOneWidget);
    expect(find.text('Уведомления заблокированы'), findsNothing);
    expect(find.byType(RoundedSwitchListTile), findsNWidgets(2));
    expect(tester.widget<RoundedSwitchListTile>(find.byType(RoundedSwitchListTile).first).value, isTrue);
    await tester.tap(find.byType(RoundedSwitchListTile).first);
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

class _LiveNotifications extends MockNotificationsService {
  final _notifier = ChangeNotifier();
  @override
  void addListener(VoidCallback? listener) => _notifier.addListener(listener!);
  @override
  void removeListener(VoidCallback? listener) => _notifier.removeListener(listener!);
  @override
  void notifyListeners() => _notifier.notifyListeners();
  @override
  void dispose() => _notifier.dispose();
}
