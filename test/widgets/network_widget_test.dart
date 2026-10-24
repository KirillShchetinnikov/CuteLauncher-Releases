import 'package:flutter/services.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/design_fixture.dart' show loadDesignFonts;

import 'package:flauncher/widgets/side_panel_dialog.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/settings/settings_panel_style.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/widgets/network_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

import '../mocks.mocks.dart';

void main() {
  late MockNetworkService mockNetworkService;

  setUp(() {
    mockNetworkService = MockNetworkService();
    when(mockNetworkService.vpnActive).thenReturn(false);
    when(mockNetworkService.getSummary()).thenAnswer(
      (_) async => {
        'networkType': 1,
        'internetAccess': true,
        'ssid': 'Home',
        'linkSpeed': 144,
        'rssi': -60,
        'addresses': '192.168.1.10',
      },
    );
  });

  Widget createWidgetUnderTest({
    Alignment alignment = Alignment.topLeft,
    Locale locale = const Locale('en'),
    double scale = 1,
    InterfaceStyle skin = InterfaceStyle.standard,
    ValueChanged<bool>? onMenuChanged,
  }) {
    return MaterialApp(
      locale: locale,
      theme: ThemeData.dark().copyWith(extensions: [InterfaceSkin(skin)]),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ChangeNotifierProvider<NetworkService>.value(
          value: mockNetworkService,
          child: Align(
            alignment: alignment,
            child: NetworkWidget(onMenuChanged: onMenuChanged),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'renders link_off icon using the shared panel color when network state is Unknown',
    (WidgetTester tester) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Unknown);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      final iconFinder = find.byType(Icon);
      expect(iconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.icon, Icons.link_off);
      expect(IconTheme.of(tester.element(iconFinder)).color, Colors.white);
    },
  );

  group('Wifi Network', () {
    testWidgets('renders signal_wifi_0_bar when signal is 0', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.signal_wifi_0_bar), findsOneWidget);
    });

    testWidgets('renders signal_wifi_1_bar when signal is 1', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(1);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.network_wifi_1_bar), findsOneWidget);
    });

    testWidgets('renders signal_wifi_2_bar when signal is 2', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(2);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.network_wifi_2_bar), findsOneWidget);
    });

    testWidgets('renders signal_wifi_3_bar when signal is 3', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(3);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.network_wifi_3_bar), findsOneWidget);
    });

    testWidgets('renders signal_wifi_4_bar when signal is 4 or higher', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(4);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.signal_wifi_4_bar), findsOneWidget);
    });
  });

  group('Cellular Network', () {
    testWidgets('renders g_mobiledata for GPRS/EDGE/CDMA', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Gprs);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('renders e_mobiledata for EDGE', (WidgetTester tester) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Edge);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.e_mobiledata), findsOneWidget);
    });

    testWidgets('renders h_mobiledata for HSPA/HSDPA/HSUPA', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Hspa);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.h_mobiledata), findsOneWidget);
    });

    testWidgets('renders h_plus_mobiledata for HSPAP', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Hspap);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.h_plus_mobiledata), findsOneWidget);
    });

    testWidgets('renders three_g_mobiledata for UMTS/TD_SCDMA', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Umts);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.three_g_mobiledata), findsOneWidget);
    });

    testWidgets('renders four_g_mobiledata_outlined for LTE', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Lte);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.four_g_mobiledata_outlined), findsOneWidget);
    });

    testWidgets('renders five_g for NR', (WidgetTester tester) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Nr);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.five_g), findsOneWidget);
    });

    testWidgets('renders question_mark for other cellular types', (
      WidgetTester tester,
    ) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Cellular);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.question_mark), findsOneWidget);
    });
  });

  testWidgets('renders vpn_key when network type is VPN', (
    WidgetTester tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Vpn);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byIcon(Icons.vpn_key), findsOneWidget);
  });

  testWidgets('renders lan when network type is Wired', (
    WidgetTester tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Wired);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);

    await tester.pumpWidget(createWidgetUnderTest());

    expect(find.byIcon(Icons.lan), findsOneWidget);
  });

  testWidgets('summary shows connection details and opens system settings', (
    WidgetTester tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Unknown);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);
    when(mockNetworkService.openWifiSettings())
        .thenAnswer((_) => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byType(InkWell));
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(SettingsPanelStyle), findsOneWidget);
    expect(find.text('Close'), findsNothing);
    final panel = find
        .descendant(
          of: find.byType(SidePanelDialog),
          matching: find.byType(Material),
        )
        .first;
    final panelRect = tester.getRect(panel);
    final anchor = tester
        .widget<SidePanelDialog>(find.byType(SidePanelDialog))
        .anchor!;
    expect(panelRect.top, closeTo(anchor.bottom + 8, .1));
    expect(panelRect.width, 380);
    expect(panelRect.height, lessThan(550));
    final settings = tester.getRect(find.byType(MenuHeaderAction));
    expect(settings.center.dy, lessThan(tester.getRect(find.text('Home')).top));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('144 Mbps'), findsOneWidget);
    expect(find.text('192.168.1.10'), findsOneWidget);
    verifyNever(mockNetworkService.openWifiSettings());
    await tester.tap(find.byType(MenuHeaderAction));
    verify(mockNetworkService.openWifiSettings()).called(1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'renders both wifi and vpn_key when wifi is active and vpnActive is true',
    (WidgetTester tester) async {
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(4);
      when(mockNetworkService.vpnActive).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.signal_wifi_4_bar), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key), findsOneWidget);
    },
  );

  testWidgets('tapping wifi icon when vpn is active opens summary', (
    WidgetTester tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(4);
    when(mockNetworkService.vpnActive).thenReturn(true);
    when(mockNetworkService.openWifiSettings())
        .thenAnswer((_) => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.signal_wifi_4_bar));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    verifyNever(mockNetworkService.openWifiSettings());
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('tapping vpn key icon when vpn is active opens vpn settings', (
    WidgetTester tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(4);
    when(mockNetworkService.vpnActive).thenReturn(true);
    when(mockNetworkService.openVpnSettings())
        .thenAnswer((_) => Future.value());

    await tester.pumpWidget(createWidgetUnderTest());

    await tester.tap(find.byIcon(Icons.vpn_key));
    await tester.pumpAndSettle();

    verify(mockNetworkService.openVpnSettings()).called(1);
  });

  testWidgets('summary stops polling in background and after closing', (
    tester,
  ) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Wired);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);
    var calls = 0;
    when(mockNetworkService.getSummary()).thenAnswer((_) async {
      calls++;
      return {
        'networkType': 3,
        'internetAccess': true,
        'rxBytes': calls * 3072,
        'txBytes': calls * 6144,
        'elapsedMs': calls * 3000,
      };
    });
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byIcon(Icons.lan));
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    expect(find.text('1.0 KB/s'), findsOneWidget);
    expect(find.text('2.0 KB/s'), findsOneWidget);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 9));
    expect(calls, 2);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(calls, 3);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 9));
    expect(calls, 3);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<NetworkWidget>(),
      isNotNull,
    );
  });

  testWidgets('failed snapshot keeps settings accessible', (tester) async {
    when(mockNetworkService.networkType).thenReturn(NetworkType.Unknown);
    when(mockNetworkService.cellularNetworkType)
        .thenReturn(CellularNetworkType.Unknown);
    when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(0);
    when(mockNetworkService.getSummary())
        .thenAnswer((_) async => throw StateError('unavailable'));
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.tap(find.byIcon(Icons.link_off));
    await tester.pumpAndSettle();
    expect(find.text('Could not read network status'), findsOneWidget);
    expect(find.byType(MenuHeaderAction), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'menu inherits settings and stays below either edge at large text',
    (tester) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final appearance = AppearanceService(
        await SharedPreferences.getInstance(),
      );
      addTearDown(appearance.dispose);
      await appearance.set('settingsColor', 0xff123456);
      await appearance.set('settingsTextColor', 0xffffcc80);
      await appearance.set('settingsOpacity', .8);
      when(mockNetworkService.networkType).thenReturn(NetworkType.Wifi);
      when(mockNetworkService.cellularNetworkType)
          .thenReturn(CellularNetworkType.Unknown);
      when(mockNetworkService.wirelessNetworkSignalLevel).thenReturn(4);
      const capture = bool.fromEnvironment('CAPTURE_NETWORK_MENU');
      if (capture) await loadDesignFonts(tester);
      for (final skin in InterfaceStyle.values) {
        for (final right in [false, true]) {
          for (final scale in [1.0, 1.6]) {
            final boundary = GlobalKey();
            final changes = <bool>[];
            await tester.pumpWidget(
              ChangeNotifierProvider.value(
                value: appearance,
                child: RepaintBoundary(
                  key: boundary,
                  child: createWidgetUnderTest(
                    alignment: right ? Alignment.topRight : Alignment.topLeft,
                    locale: const Locale('ru'),
                    scale: scale,
                    skin: skin,
                    onMenuChanged: changes.add,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byIcon(Icons.signal_wifi_4_bar));
            await tester.pumpAndSettle();
            final panel = find.byType(SidePanelDialog);
            final surface = find
                .descendant(of: panel, matching: find.byType(Material))
                .first;
            final rect = tester.getRect(surface);
            final anchor = tester.widget<SidePanelDialog>(panel).anchor!;
            expect(rect.top, closeTo(anchor.bottom + 8, .1));
            expect(rect.left, greaterThanOrEqualTo(12));
            expect(rect.right, lessThanOrEqualTo(948));
            expect(rect.bottom, lessThanOrEqualTo(528));
            final material = tester.widget<Material>(surface);
            expect(material.color!.toARGB32(), 0xcc123456);
            final context = tester.element(find.text('Home'));
            expect(
              Theme.of(context).colorScheme.onSurface,
              const Color(0xffffcc80),
            );
            expect(InterfaceSkin.of(context).style, skin);
            expect(
              MediaQuery.textScalerOf(context).scale(16),
              closeTo(16 * scale, .01),
            );
            expect(tester.takeException(), isNull);
            if (scale > 1) {
              final scroll = tester
                  .widget<SingleChildScrollView>(
                    find
                        .descendant(
                          of: panel,
                          matching: find.byType(SingleChildScrollView),
                        )
                        .first,
                  )
                  .controller!;
              expect(scroll.position.maxScrollExtent, greaterThan(0));
              await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
              await tester.pump();
              expect(scroll.offset, greaterThan(0));
              scroll.jumpTo(0);
              await tester.pump();
            }

            if (capture &&
                skin == InterfaceStyle.standard &&
                !right &&
                scale == 1) {
              await tester.runAsync(() async {
                final image =
                    await (boundary.currentContext!.findRenderObject()
                            as RenderRepaintBoundary)
                        .toImage();
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                await File('.tools/network-menu-preview.png')
                    .writeAsBytes(bytes!.buffer.asUint8List());
                image.dispose();
              });
            }
            await tester.tapAt(const Offset(480, 500));
            await tester.pumpAndSettle();
            expect(find.byType(SidePanelDialog), findsNothing);
            expect(changes, [true, false]);
            await tester.pumpWidget(const SizedBox());
          }
        }
      }
    },
  );
}
