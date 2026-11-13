import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/notifications_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/providers/weather_service.dart';
import 'package:flauncher/widgets/focus_aware_app_bar.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/remote_panel_page.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mocks.mocks.dart';

void main() {
  test(
    'NAS and USB switches persist independently and round-trip through backup',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      expect(settings.showNasInStatusBar, true);
      expect(settings.showUsbInStatusBar, true);
      await settings.setShowNasInStatusBar(false);
      expect(settings.showUsbInStatusBar, true);
      final backup = settings.exportSettingsMap();
      await settings.setShowUsbInStatusBar(false);
      await settings.importSettingsMap(backup);
      expect(settings.showNasInStatusBar, false);
      expect(settings.showUsbInStatusBar, true);
      final restored = SettingsService(prefs);
      expect(restored.showNasInStatusBar, false);
      expect(restored.showUsbInStatusBar, true);
      restored.dispose();
      settings.dispose();
    },
  );
  for (final remoteMode in [false, true]) {
    testWidgets(
      'NAS toggle requires firmware support but no mounted share: remote=$remoteMode',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({
          'show_usb_in_status_bar': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final remote = RemotePanelService(prefs);
        final appearance = AppearanceService(prefs);
        final storage = StorageStatusService();
        addTearDown(settings.dispose);
        addTearDown(remote.dispose);
        addTearDown(appearance.dispose);
        addTearDown(storage.dispose);
        await remote.show('usb', false);
        final inputs = MockTvInputsService();
        final network = MockNetworkService();
        final notifications = MockNotificationsService();
        when(inputs.hasInputs).thenReturn(false);
        when(inputs.initialized).thenReturn(true);
        when(network.hasUsageStatsPermission).thenReturn(false);
        when(notifications.hasPermission).thenReturn(false);
        const channel = MethodChannel('cutelauncher/storage_status');
        final watches = <bool>[];
        var nasSupported = false;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'watch') watches.add(call.arguments as bool);
            if (call.method == 'snapshot') {
              return {'nasSupported': nasSupported, 'nas': false};
            }
            return null;
          },
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: remote),
              ChangeNotifierProvider.value(value: appearance),
              ChangeNotifierProvider.value(value: storage),
              ChangeNotifierProvider<TvInputsService>.value(value: inputs),
              ChangeNotifierProvider<NetworkService>.value(value: network),
              ChangeNotifierProvider<NotificationsService>.value(
                value: notifications,
              ),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: remoteMode
                    ? const RemotePanelObjectsPage()
                    : const StatusBarObjectsPage(),
              ),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();
        final nas = find.byKey(ValueKey(remoteMode ? 'nas' : 'show_nas'));
        final usb = find.byKey(ValueKey(remoteMode ? 'usb' : 'show_usb'));
        RoundedSwitchListTile toggle(Finder finder) => tester.widget(finder);
        bool savedNas() =>
            remoteMode ? remote.visible('nas') : settings.showNasInStatusBar;

        expect(watches, [true]);
        expect(toggle(nas).enabled, false);
        expect(toggle(nas).value, false);
        expect(savedNas(), true);
        expect(toggle(usb).enabled, true);

        Future<void> refresh(bool supported) async {
          nasSupported = supported;
          await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(const MethodCall('changed')),
            (_) {},
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pumpAndSettle();
        }

        await refresh(true);
        expect(toggle(nas).enabled, true);
        expect(toggle(nas).value, true);
        await tester.tap(nas);
        await tester.pumpAndSettle();
        expect(savedNas(), false);

        await refresh(false);
        await tester.tap(nas);
        await tester.pumpAndSettle();
        expect(savedNas(), false);

        await refresh(true);
        await tester.tap(nas);
        await tester.pumpAndSettle();
        expect(savedNas(), true);

        await tester.pumpWidget(const SizedBox());
        expect(watches, [true, false]);
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      },
    );

    testWidgets(
      'connected icons, actions, independent switches and removal focus: remote=$remoteMode',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'show_network_indicator_in_status_bar': false,
          'show_data_widget_in_status_bar': false,
          'show_date_in_status_bar': false,
          'show_time_in_status_bar': false,
          'show_weather_in_status_bar': false,
          'show_volume_in_status_bar': false,
        });
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final remote = RemotePanelService(prefs);
        final storage = StorageStatusService();
        final inputs = MockTvInputsService();
        final notifications = MockNotificationsService();
        final weather = MockWeatherService();
        when(inputs.hasInputs).thenReturn(false);
        when(inputs.initialized).thenReturn(true);
        when(notifications.hasPermission).thenReturn(false);
        when(notifications.initialized).thenReturn(true);
        when(notifications.notifications).thenReturn([]);
        when(weather.weatherData).thenReturn(null);
        if (remoteMode) {
          for (final id in RemotePanelService.ids) {
            await remote.show(id, ['nas', 'usb', 'settings'].contains(id));
          }
        }
        const channel = MethodChannel('cutelauncher/storage_status');
        var snapshot = <String, dynamic>{
          'nasSupported': true,
          'nas': false,
          'usb': false,
        };
        final opened = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          (call) async {
            if (call.method == 'snapshot') return snapshot;
            if (call.method.startsWith('open')) {
              opened.add(call.method);
              return true;
            }
            return null;
          },
        );
        Future<void> refresh() async {
          await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
            channel.name,
            channel.codec.encodeMethodCall(const MethodCall('changed')),
            (_) {},
          );
          await tester.pump(const Duration(milliseconds: 100));
          await tester.pump();
        }

        final bar = GlobalKey<FocusAwareAppBarState>();
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: storage),
              ChangeNotifierProvider.value(value: remote),
              ChangeNotifierProvider<TvInputsService>.value(value: inputs),
              ChangeNotifierProvider<NotificationsService>.value(
                value: notifications,
              ),
              ChangeNotifierProvider<WeatherService>.value(value: weather),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Consumer<RemotePanelService>(
                builder: (_, panel, _) => Scaffold(
                  appBar: FocusAwareAppBar(
                    key: bar,
                    remotePanel: remoteMode ? panel : null,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(const ValueKey('nas_button')), findsNothing);
        expect(find.byKey(const ValueKey('usb_button')), findsNothing);
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.byKey(const ValueKey('nas_button')), findsNothing);
        expect(find.byKey(const ValueKey('usb_button')), findsNothing);
        snapshot = {'nasSupported': true, 'nas': true, 'usb': true};
        await refresh();
        expect(find.byKey(const ValueKey('nas_button')), findsOneWidget);
        expect(find.byKey(const ValueKey('usb_button')), findsOneWidget);
        for (final id in ['nas', 'usb']) {
          tester
              .widget<TopPanelItem>(find.byKey(ValueKey('${id}_button')))
              .focusNode!
              .requestFocus();
          await tester.pump();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
        }
        expect(opened, ['openNas', 'openUsb']);
        snapshot = {'nasSupported': true, 'nas': true, 'usb': false};
        await refresh();
        expect(find.byKey(const ValueKey('usb_button')), findsNothing);
        expect(bar.currentState!.settingsFocusNode.hasFocus, true);
        if (remoteMode) {
          await remote.show('nas', false);
        } else {
          await settings.setShowNasInStatusBar(false);
        }
        await tester.pump();
        expect(find.byKey(const ValueKey('nas_button')), findsNothing);
        snapshot = {'nasSupported': false, 'nas': true, 'usb': true};
        await refresh();
        expect(find.byKey(const ValueKey('nas_button')), findsNothing);
        expect(find.byKey(const ValueKey('usb_button')), findsOneWidget);
        await tester.pumpWidget(const SizedBox());
        storage.dispose();
        settings.dispose();
        remote.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
