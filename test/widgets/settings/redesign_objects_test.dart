import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/panel_order_page.dart';
import 'package:flauncher/widgets/settings/quick_actions_settings_page.dart';
import 'package:flauncher/providers/storage_status_service.dart';
import 'package:flauncher/widgets/settings/widget_placement_page.dart';
import 'package:flauncher/widgets/settings/settings_information.dart';
import 'package:flauncher/widgets/settings/appearance_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_option_tile.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:flauncher/theme/launcher_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestNetwork extends ChangeNotifier implements NetworkService {
  @override
  NetworkType networkType = NetworkType.Wifi;

  @override
  bool hasInternetAccess = false;

  void update(NetworkType type, bool internet) {
    networkType = type;
    hasInternetAccess = internet;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  late SettingsService settings;
  late AppearanceService appearance;
  late RemotePanelService remote;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    appearance = AppearanceService(prefs);
    remote = RemotePanelService(prefs);
  });
  tearDown(() {
    settings.dispose();
    appearance.dispose();
    remote.dispose();
  });
  Future<void> pump(WidgetTester tester, Widget page) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: appearance),
          ChangeNotifierProvider.value(value: remote),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox(width: 380, child: page)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'arrows skip one or more unavailable objects in both directions',
    (tester) async {
      await appearance.setPanelOrder([
        'settings',
        'systemSettings',
        'inputs',
        'nas',
        'notifications',
      ], []);
      await pump(tester, const PanelOrderPage(editVisibility: true));
      final rows = tester
          .widgetList<FocusableSettingsTile>(find.byType(FocusableSettingsTile))
          .toList();
      final index = rows.indexWhere(
        (row) => row.key == const ValueKey('inputs'),
      );
      expect(rows[index].enabled, isFalse);
      expect(rows[index + 1].enabled, isFalse);
      final previous = rows[index - 1];
      final nextEnabled = rows.skip(index + 1).firstWhere((row) => row.enabled);
      final l = AppLocalizations.of(
        tester.element(find.byType(PanelOrderPage)),
      )!;
      expect(find.text(l.topPanelObjectsTitle), findsOneWidget);
      rows.first.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<SettingsControlHint>(find.byType(SettingsControlHint))
            .text,
        'OK — ${l.reorder}',
      );
      previous.focusNode!.requestFocus();
      await tester.pumpAndSettle();
      expect(previous.focusNode!.hasFocus, isTrue);
      expect(
        tester
            .widget<SettingsControlHint>(find.byType(SettingsControlHint))
            .text,
        l.applicationInfoButtonsHint,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(nextEnabled.focusNode!.hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(previous.focusNode!.hasFocus, isTrue);
    },
  );

  testWidgets('each style row uses its own material and only OK saves it', (
    tester,
  ) async {
    await appearance.set('settingsInterfaceStyle', 'glass');
    await pump(tester, const InterfaceStyleChoice());
    await tester.tap(find.byType(InterfaceStyleChoice));
    await tester.pumpAndSettle();
    final options = find.byType(SettingsOptionTile);
    final rows = options.evaluate().toList();
    expect(rows.length, InterfaceStyle.values.length);
    for (final (index, row) in rows.indexed) {
      final skin = InterfaceSkin.of(row);
      expect(skin.style, InterfaceStyle.values[index]);
      expect(LauncherStyle.of(row).rowRadius, skin.radius);
      expect(
        (row.widget as SettingsOptionTile).selected,
        skin.style == InterfaceStyle.glass,
      );
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(appearance.appearance.interfaceStyle, 'glass');
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(appearance.appearance.interfaceStyle, 'soft');
    expect(options, findsNothing);
  });

  testWidgets('network placement and live connectivity share one page', (tester) async {
    final network = _TestNetwork();
    addTearDown(network.dispose);
    await pump(tester, ChangeNotifierProvider<NetworkService>.value(
      value: network,
      child: const WidgetPlacementPage(id: 'network', title: 'Network'),
    ));
    final l = AppLocalizations.of(tester.element(find.byType(WidgetPlacementPage)))!;
    expect(find.text('Wi-Fi'), findsOneWidget);
    expect(find.text(l.networkOffline), findsOneWidget);
    expect(find.text(l.networkDisconnected), findsNothing);
    expect(find.byType(WidgetPlacementLink), findsNothing);
    final top = settings.showNetworkIndicatorInStatusBar;
    final quick = remote.visible('network');
    await tester.tap(find.text(l.topPanel));
    await tester.pumpAndSettle();
    expect(settings.showNetworkIndicatorInStatusBar, !top);
    expect(remote.visible('network'), quick);
    await tester.tap(find.text(l.remotePanel));
    await tester.pumpAndSettle();
    expect(remote.visible('network'), !quick);
    network.update(NetworkType.Wired, true);
    await tester.pumpAndSettle();
    expect(find.text('Ethernet'), findsOneWidget);
    expect(find.text(l.networkConnected), findsOneWidget);
    network.update(NetworkType.Unknown, false);
    await tester.pumpAndSettle();
    expect(find.text(l.networkDisconnected), findsOneWidget);
  });

  testWidgets(
    'only placement of NAS and storage status pages request snapshots',
    (tester) async {
      const channel = MethodChannel('cutelauncher/storage_status');
      final messenger = tester.binding.defaultBinaryMessenger;
      var reads = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        if (call.method != 'snapshot') return null;
        reads++;
        return {'nasSupported': true, 'nas': false, 'usb': true};
      });
      final storage = StorageStatusService(channel: channel);
      addTearDown(() {
        storage.dispose();
        messenger.setMockMethodCallHandler(channel, null);
      });
      Future<int> visits(Widget page) async {
        final before = reads;
        await pump(
          tester,
          ChangeNotifierProvider.value(value: storage, child: page),
        );
        await tester.pump(const Duration(milliseconds: 200));
        return reads - before;
      }

      expect(
        await visits(const WidgetPlacementPage(id: 'audio', title: 'Audio')),
        0,
      );
      expect(
        await visits(const WidgetPlacementPage(id: 'usb', title: 'USB')),
        1,
      );
      expect(find.byType(WidgetPlacementLink), findsNothing);
      expect(find.text('USB'), findsOneWidget);
      final l = AppLocalizations.of(tester.element(find.byType(WidgetPlacementPage)))!;
      expect(find.text(l.inputConnected), findsOneWidget);
      expect(find.text(l.topPanel), findsOneWidget);
      expect(find.text(l.remotePanel), findsOneWidget);
      expect(
        await visits(
          const WidgetPlacementPage(id: 'network', title: 'Network'),
        ),
        0,
      );
      await tester.pump(const Duration(seconds: 6));
      expect(reads, 1);
      expect(
        await visits(const WidgetPlacementPage(id: 'nas', title: 'NAS')),
        1,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'quick actions toggle and reorder independently without losing focus',
    (tester) async {
      await pump(tester, const QuickActionsSettingsPage());
      final first = settings.quickActionsOrder.first;
      final original = settings.quickActions.toSet();
      final row = find.byKey(ValueKey(first));
      Focus.of(
        tester.element(
          find.descendant(of: row, matching: find.byType(Text)).first,
        ),
      ).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(settings.quickActions.contains(first), !original.contains(first));
      final enabled = settings.quickActions.toSet();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(settings.quickActionsOrder[1], first);
      expect(settings.quickActions.toSet(), enabled);
      expect(SettingsService(prefs).quickActionsOrder[1], first);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hidden remote clock stays in the order editor and can be re-enabled',
    (tester) async {
      await remote.show('time', false);
      final initialOrder = remote.layout.right.toList();
      await pump(
        tester,
        const PanelOrderPage(remotePanel: true, editVisibility: true),
      );
      final l = AppLocalizations.of(
        tester.element(find.byType(PanelOrderPage)),
      )!;
      expect(find.text(l.quickPanelObjectsTitle), findsOneWidget);
      final row = find.byKey(const ValueKey('time'));
      await tester.scrollUntilVisible(row, 250);
      await tester.pumpAndSettle();
      expect(tester.widget<FocusableSettingsTile>(row).toggled, isFalse);
      await tester.tap(
        find.descendant(of: row, matching: find.byType(Text)).first,
      );
      await tester.pumpAndSettle();
      expect(remote.visible('time'), isTrue);
      expect(remote.layout.right, initialOrder);
      expect(find.byKey(const ValueKey('time')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
