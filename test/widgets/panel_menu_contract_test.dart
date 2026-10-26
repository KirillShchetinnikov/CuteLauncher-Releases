import 'package:flauncher/widgets/traffic_usage_menu.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/apps_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/providers/sleep_timer_service.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/widgets/launcher_dialog.dart';
import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/menu_header.dart';
import 'package:flauncher/widgets/night_mode_menu.dart';
import 'package:flauncher/widgets/sleep_timer_menu.dart';
import 'package:flauncher/widgets/network_summary_dialog.dart';
import 'package:flauncher/widgets/panel_calendar_dialog.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/widgets/settings/notifications_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  for (final name in [
    'night',
    'sleep',
    'calendar',
    'network',
    'traffic',
    'inputs',
    'notifications',
  ]) {
    testWidgets(
      '$name shares menu geometry, style, dismissal and restored focus',
      (tester) async {
        tester.view.physicalSize = const Size(960, 540);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final appearance = AppearanceService(prefs);
        await appearance.set('settingsColor', 0xff123456);
        await appearance.set('settingsTextColor', 0xffddeeff);
        await appearance.set('settingsOpacity', .4);
        await appearance.set('settingsInterfaceFont', 'manrope');
        await appearance.set('noticeColor', 0xffaa0000);
        final channels = [
          SleepTimerService.channel,
          const MethodChannel('cutelauncher/night'),
          const MethodChannel('cutelauncher/tcl_blue_light'),
        ];
        for (final channel in channels) {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            channel,
            (_) async => {'permission': false, 'exactAllowed': true},
          );
          addTearDown(
            () => tester.binding.defaultBinaryMessenger
                .setMockMethodCallHandler(channel, null),
          );
        }
        final night = NightModeService(prefs);
        final sleep = SleepTimerService();
        final network = MockNetworkService();
        final inputs = MockTvInputsService();
        final notifications = MockNotificationsService();
        final apps = MockAppsService();
        when(network.getSummary()).thenAnswer(
          (_) async => {
            'networkType': 1,
            'internetAccess': false,
            'ssid': 'A long Wi-Fi connection',
            'rssi': -65,
            'linkSpeed': 144,
            'frequency': 5180,
            'addresses': '192.168.1.25',
          },
        );
        when(network.getTrafficUsage(any)).thenAnswer((_) async => {'rxBytes': 1024, 'txBytes': 2048, 'totalBytes': 3072});
        when(inputs.inputs).thenReturn([]);
        when(notifications.notifications).thenReturn([]);
        when(notifications.hidePersistentNotifications).thenReturn(false);
        when(apps.applications).thenReturn([]);
        final opener = FocusNode();
        for (final locale in ['ru', 'en']) {
          for (final skin in InterfaceStyle.values) {
            for (final right in [false, true]) {
              await settings.setSettingsMenuOnRight(right);
              await tester.pumpWidget(
                MultiProvider(
                  providers: [
                    ChangeNotifierProvider.value(value: appearance),
                    ChangeNotifierProvider.value(value: settings),
                    ChangeNotifierProvider.value(value: night),
                    ChangeNotifierProvider.value(value: sleep),
                    ChangeNotifierProvider<NetworkService>.value(
                      value: network,
                    ),
                    ChangeNotifierProvider<TvInputsService>.value(
                      value: inputs,
                    ),
                    ChangeNotifierProvider<NotificationsService>.value(
                      value: notifications,
                    ),
                    ChangeNotifierProvider<AppsService>.value(value: apps),
                  ],
                  child: MaterialApp(
                    locale: Locale(locale),
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    supportedLocales: AppLocalizations.supportedLocales,
                    theme: ThemeData.dark().copyWith(
                      extensions: [InterfaceSkin(skin)],
                    ),
                    builder: (context, child) => MediaQuery(
                      data: MediaQuery.of(context)
                          .copyWith(textScaler: const TextScaler.linear(1.6)),
                      child: child!,
                    ),
                    home: Scaffold(
                      body: Align(
                        alignment: right
                            ? Alignment.topRight
                            : Alignment.topLeft,
                        child: Builder(
                          builder: (context) => TextButton(
                            focusNode: opener,
                            child: const Text('open'),
                            onPressed: () async {
                              final box =
                                  opener.context!.findRenderObject()
                                      as RenderBox;
                              final anchor =
                                  box.localToGlobal(Offset.zero) & box.size;
                              await showLauncherDialog<void>(
                                context: context,
                                highlightRect: anchor,
                                styleDialog: false,
                                useSafeArea: false,
                                barrierColor: Colors.transparent,
                                builder: (_) => switch (name) {
                                  'night' => NightModeMenu(anchor: anchor),
                                  'sleep' => SleepTimerMenu(anchor: anchor),
                                  'calendar' => PanelCalendarDialog(
                                    anchor: anchor,
                                  ),
                                  'network' => NetworkSummaryDialog(
                                    service: network,
                                    anchor: anchor,
                                  ),
                                  'traffic' => TrafficUsageMenu(anchor: anchor),
                                  'inputs' => InputsPanel(anchor: anchor),
                                  _ => NotificationsPanel(anchor: anchor),
                                },
                              );
                              opener.requestFocus();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              await tester.tap(find.text('open'));
              await tester.pump();
              final openingBackdrop = find.descendant(
                of: find.byType(LauncherPanelBackdrop),
                matching: find.byType(ClipPath),
              );
              final openingClip = tester.widget<ClipPath>(openingBackdrop);
              final openingRect = tester.getRect(find.byType(LauncherPanelBackdrop));
              final openingAnchor = tester.widget<SidePanelDialog>(
                find.byType(SidePanelDialog)).anchor!;
              final openingPath = openingClip.clipper!
                  .getClip(tester.getSize(openingBackdrop));
              expect(openingPath.contains(openingAnchor.center - openingRect.topLeft),
                  isFalse, reason: 'Opening frame must preserve the button cutout');
              await tester.pumpAndSettle();
              final panel = find.byType(SidePanelDialog);
              final header = tester.widget<MenuHeader>(
                find.descendant(of: panel, matching: find.byType(MenuHeader)),
              );
              expect(header.hint != null, name == 'notifications');
              if (name == 'sleep' || name == 'night') {
                final divider = find.descendant(
                    of: panel, matching: find.byType(Divider)).first;
                expect(tester.getTopLeft(divider).dy,
                    greaterThanOrEqualTo(tester.getBottomLeft(find.byType(MenuHeader)).dy));
              }
              final titleContext = tester.element(find.descendant(
                of: find.byType(MenuHeader), matching: find.byType(Text)).first);
              expect(DefaultTextStyle.of(titleContext).style.fontSize,
                  Theme.of(titleContext).textTheme.titleLarge!.fontSize);
              expect(DefaultTextStyle.of(titleContext).style.color,
                  const Color(0xffddeeff));
              expect(
                panel,
                findsOneWidget,
                reason: '$locale $skin right=$right',
              );
              final surface = find
                  .descendant(of: panel, matching: find.byType(Material))
                  .first;
              final rect = tester.getRect(surface);
              final configuration = tester.widget<SidePanelDialog>(panel);
              final anchor = configuration.anchor!;
              expect(rect.top, closeTo((anchor.bottom < configuration.topInset ? configuration.topInset : anchor.bottom) + 8, .1));
              expect(rect.left, greaterThanOrEqualTo(12));
              expect(rect.right, lessThanOrEqualTo(948));
              expect(rect.bottom, lessThanOrEqualTo(528));
              expect(
                tester.widget<Material>(surface).color,
                const Color(0xff123456).withValues(alpha: .4),
              );
              final context = tester.element(surface);
              expect(InterfaceSkin.of(context).style, skin);
              expect(
                Theme.of(context).colorScheme.onSurface,
                const Color(0xffddeeff),
              );
              expect(
                Theme.of(context).textTheme.bodyMedium!.fontFamily,
                'Manrope',
              );
              expect(
                MediaQuery.textScalerOf(context).scale(16),
                closeTo(25.6, .01),
              );
              expect(
                find.text(AppLocalizations.of(context)!.close),
                findsNothing,
              );
              expect(tester.takeException(), isNull);
              if (right) {
                await tester.tapAt(const Offset(0, 500));
              } else {
                await tester.binding.handlePopRoute();
              }
              await tester.pumpAndSettle();
              expect(find.byType(SidePanelDialog), findsNothing);
              expect(opener.hasFocus, isTrue);
              await tester.pumpWidget(const SizedBox());
            }
          }
        }
        opener.dispose();
        night.dispose();
        sleep.dispose();
        appearance.dispose();
        settings.dispose();
      },
    );
  }
}
