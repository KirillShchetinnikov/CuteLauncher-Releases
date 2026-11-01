import 'dart:async';

import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/network_service.dart';
import 'package:flauncher/providers/vpn_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/theme/interface_style.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/widgets/menu_header_action.dart';
import 'package:flauncher/widgets/top_panel_item.dart';
import 'package:flauncher/widgets/vpn_menu.dart';
import 'package:flauncher/widgets/vpn_widget.dart';
import 'package:flauncher/widgets/settings/vpn_settings_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/settings/settings_page_layout.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../mocks.mocks.dart';

void main() {
  const channel = MethodChannel('cutelauncher/vpn');
  late VpnService vpn;
  late MockNetworkService network;
  late SettingsService settings;
  late AppearanceService appearance;
  late Map<String, Object> state;
  Widget app(Widget child, {double scale = 1}) => MultiProvider(
    providers: [
      ChangeNotifierProvider<VpnService>.value(value: vpn),
      ChangeNotifierProvider<NetworkService>.value(value: network),
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider<AppearanceService>.value(value: appearance),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      theme: ThemeData.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: Scaffold(
        body: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    settings = SettingsService(prefs);
    appearance = AppearanceService(prefs);
    state = {
      'active': true,
      'owner': 'org.amnezia.awg',
      'target': 'org.amnezia.awg',
      'profile': 'home',
      'profiles': {'org.amnezia.awg': 'home'},
      'canControl': true,
      'supported': true,
      'permission': true,
      'selected': '',
      'onlyActive': true,
      'clients': [
        {
          'app': 'org.amnezia.awg',
          'name': 'AmneziaWG',
          'supported': true,
          'permission': true,
        },
      ],
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'save') {
            final args = call.arguments as Map;
            state[args['key'] as String] = args['value'] as Object;
            return true;
          }
          return Map<String, Object>.from(state);
        });
    network = MockNetworkService();
    vpn = VpnService(network);
    await vpn.initialLoad;
  });
  tearDown(() {
    vpn.dispose();
    settings.dispose();
    appearance.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  for (final enabled in [false, true]) {
    testWidgets('restart notice follows enabled system startup: $enabled', (
      tester,
    ) async {
      state.addAll({
        'restartRequired': true,
        'bootEnabled': enabled,
        'bootMode': 'alwaysOn',
      });
      await vpn.refresh();
      await tester.pumpWidget(app(const VpnWidget()));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.vpn_key));
      await tester.pumpAndSettle();
      expect(
        find.text('Для применения системного режима перезапустите ТВ.'),
        enabled ? findsOneWidget : findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('VPN uses the same button geometry as its neighbors', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TopPanelItem(key: ValueKey('left'), child: Icon(Icons.wifi)),
            SizedBox(width: 12),
            VpnWidget(),
            SizedBox(width: 12),
            TopPanelItem(key: ValueKey('right'), child: Icon(Icons.tv)),
          ],
        ),
      ),
    );
    final left = tester.getRect(find.byKey(const ValueKey('left')));
    final center = tester.getRect(
      find.descendant(
        of: find.byType(VpnWidget),
        matching: find.byType(TopPanelItem),
      ),
    );
    final right = tester.getRect(find.byKey(const ValueKey('right')));
    expect(center.center.dy, left.center.dy);
    expect(center.height, left.height);
    expect(center.left - left.right, 12);
    expect(right.left - center.right, 12);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VPN opens its own menu and Back returns focus', (tester) async {
    final focus = FocusNode();
    await tester.pumpWidget(app(VpnWidget(focusNode: focus)));
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(VpnMenu), findsOneWidget);
    expect(find.text('VPN подключён'), findsOneWidget);
    expect(find.text('Отключить'), findsOneWidget);
    expect(find.byType(MenuHeaderAction), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(VpnMenu), findsNothing);
    expect(focus.hasFocus, isTrue);
    await tester.pumpWidget(const SizedBox());
    focus.dispose();
  });

  testWidgets('unknown owner hides control and remains usable at large text', (
    tester,
  ) async {
    state.addAll({
      'owner': '',
      'target': '',
      'canControl': false,
      'profile': '',
      'supported': false,
    });
    await vpn.refresh();
    await tester.pumpWidget(app(const VpnWidget(), scale: 1.7));
    await tester.tap(find.byIcon(Icons.vpn_key));
    await tester.pumpAndSettle();
    expect(find.text('Отключить'), findsNothing);
    expect(find.text('Настройки VPN Android'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'widget settings offer automatic selection and preserve startup',
    (tester) async {
      await tester.pumpWidget(
        app(const SizedBox(width: 600, child: VpnSettingsPage())),
      );
      await tester.pumpAndSettle();
      expect(find.text('Автоматически'), findsOneWidget);
      expect(find.text('Профиль VPN'), findsOneWidget);
      await tester.tap(find.text('Автоматически'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('AmneziaWG'));
      await tester.pumpAndSettle();
      expect(vpn.selected, 'org.amnezia.awg');
      expect(vpn.bootApp, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'Happ and MantaRay settings do not request tunnel names or control permission',
    (tester) async {
      for (final client in [
        ('com.happproxy', 'Happ'),
        ('com.mantaray.vpn', 'MantaRay'),
      ]) {
        state.addAll({
          'target': client.$1,
          'requiresProfile': false,
          'clients': [
            {
              'app': client.$1,
              'name': client.$2,
              'supported': true,
              'permission': true,
              'requiresProfile': false,
              'alwaysOnSupported': true,
            },
          ],
        });
        await vpn.refresh();
        await tester.pumpWidget(
          app(const SizedBox(width: 600, child: VpnSettingsPage())),
        );
        await tester.pumpAndSettle();
        expect(find.text('Профиль VPN'), findsNothing);
        expect(find.text('Разрешить управление VPN'), findsNothing);
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is SettingsHelp &&
                widget.text == 'Подтвердите команду в окне MantaRay.',
          ),
          client.$1 == 'com.mantaray.vpn' ? findsOneWidget : findsNothing,
        );
        await tester.pumpWidget(const SizedBox());
      }
    },
  );

  testWidgets(
    'always-on startup hides one-shot settings and shows restart requirement',
    (tester) async {
      state.addAll({
        'bootMode': 'alwaysOn',
        'bootApp': 'com.happproxy',
        'systemApp': 'com.happproxy',
        'restartRequired': true,
        'clients': [
          {
            'app': 'com.happproxy',
            'name': 'Happ',
            'supported': true,
            'permission': true,
            'requiresProfile': false,
            'alwaysOnSupported': true,
          },
        ],
      });
      await vpn.refresh();
      await tester.pumpWidget(
        app(
          const SizedBox(
            width: 600,
            child: SettingsPageLayout(
              title: Text('Автозапуск'),
              child: SingleChildScrollView(child: VpnStartupSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Постоянный VPN Android'), findsOneWidget);
      expect(
        find.text('Для применения системного режима перезапустите ТВ.'),
        findsOneWidget,
      );
      expect(find.text('После пробуждения'), findsNothing);
      expect(find.text('Задержка запуска'), findsNothing);
      expect(find.text('Профиль VPN'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('disabled startup keeps restart notice in settings', (
    tester,
  ) async {
    state.addAll({
      'bootEnabled': false,
      'restartRequired': true,
      'bootMode': 'alwaysOn',
    });
    await vpn.refresh();
    await tester.pumpWidget(
      app(
        const SettingsPageLayout(
          title: Text('Автозапуск'),
          child: SingleChildScrollView(child: VpnStartupSection()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Для применения системного режима перезапустите ТВ.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('vpn_boot_mode')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  FocusNode rowFocus(WidgetTester tester, String title) {
    final row = find.widgetWithText(FocusableSettingsTile, title);
    return tester
        .widget<Focus>(
          find.descendant(of: row, matching: find.byType(Focus)).first,
        )
        .focusNode!;
  }

  for (final setting in [
    ('onlyActive', 'Показывать только при подключении'),
    ('showName', 'Показывать название приложения'),
    ('color', 'Выделять подключение цветом'),
    ('notify', 'Уведомлять о результате команд'),
  ]) {
    for (final success in [true, false]) {
      testWidgets(
        'VPN ${setting.$1} keeps remote focus during and after save: success=$success',
        (tester) async {
          final pending = Completer<bool>();
          var saves = 0;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(channel, (call) async {
                if (call.method == 'save') {
                  saves++;
                  final args = call.arguments as Map;
                  final ok = await pending.future;
                  if (ok) {
                    state[args['key'] as String] = args['value'] as Object;
                  }
                  return ok;
                }
                return Map<String, Object>.from(state);
              });
          await tester.pumpWidget(
            app(const SizedBox(width: 600, child: VpnSettingsPage())),
          );
          await tester.pumpAndSettle();
          final focus = rowFocus(tester, setting.$2);
          focus.requestFocus();
          await tester.pumpAndSettle();
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(vpn.busy, isTrue);
          expect(
            focus.hasFocus,
            isTrue,
            reason: 'Saving must not disable the focused row',
          );
          await tester.sendKeyEvent(LogicalKeyboardKey.enter);
          await tester.pump();
          expect(saves, 1);
          pending.complete(success);
          await tester.pumpAndSettle();
          expect(vpn.busy, isFalse);
          expect(rowFocus(tester, setting.$2), same(focus));
          expect(focus.hasFocus, isTrue);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
        },
      );
    }
  }

  testWidgets('VPN app choice keeps its opener focused while saving', (
    tester,
  ) async {
    final pending = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'save') {
            final ok = await pending.future;
            if (ok) state['selected'] = 'org.amnezia.awg';
            return ok;
          }
          return Map<String, Object>.from(state);
        });
    await tester.pumpWidget(
      app(const SizedBox(width: 600, child: VpnSettingsPage())),
    );
    await tester.pumpAndSettle();
    final focus = rowFocus(tester, 'VPN-приложение');
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.tap(find.text('AmneziaWG'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(vpn.busy, isTrue);
    expect(focus.hasFocus, isTrue);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(rowFocus(tester, 'VPN-приложение'), same(focus));
    expect(focus.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('VPN profile editor returns to the same row while saving', (
    tester,
  ) async {
    final pending = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'save') {
            final args = call.arguments as Map;
            final ok = await pending.future;
            if (ok) {
              (state['profiles'] as Map)['org.amnezia.awg'] = args['value'];
            }
            return ok;
          }
          return Map<String, Object>.from(state);
        });
    await tester.pumpWidget(
      app(const SizedBox(width: 600, child: VpnSettingsPage())),
    );
    await tester.pumpAndSettle();
    final focus = rowFocus(tester, 'Профиль VPN');
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'work');
    await tester.tap(find.text('ОК'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(vpn.busy, isTrue);
    expect(focus.hasFocus, isTrue);
    pending.complete(true);
    await tester.pumpAndSettle();
    expect(rowFocus(tester, 'Профиль VPN'), same(focus));
    expect(focus.hasFocus, isTrue);
    expect(vpn.profileFor('org.amnezia.awg'), 'work');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'VPN startup wake and delay keep focus and ignore repeated saves',
    (tester) async {
      state.addAll({'bootApp': 'org.amnezia.awg', 'wake': false, 'delay': 5});
      await vpn.refresh();
      var pending = Completer<bool>();
      var saves = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'save') {
              saves++;
              final args = call.arguments as Map;
              final ok = await pending.future;
              if (ok) state[args['key'] as String] = args['value'] as Object;
              return ok;
            }
            return Map<String, Object>.from(state);
          });
      await tester.pumpWidget(
        app(
          const SizedBox(
            width: 600,
            child: SettingsPageLayout(
              title: Text('Автозапуск'),
              child: SingleChildScrollView(child: VpnStartupSection()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final field in [
        ('После пробуждения', LogicalKeyboardKey.enter),
        ('Задержка запуска', LogicalKeyboardKey.arrowRight),
      ]) {
        final focus = rowFocus(tester, field.$1);
        focus.requestFocus();
        await tester.pumpAndSettle();
        final before = saves;
        await tester.sendKeyEvent(field.$2);
        await tester.pump();
        expect(vpn.busy, isTrue);
        expect(focus.hasFocus, isTrue);
        await tester.sendKeyEvent(field.$2);
        await tester.pump();
        expect(saves, before + 1);
        pending.complete(true);
        await tester.pumpAndSettle();
        expect(rowFocus(tester, field.$1), same(focus));
        expect(focus.hasFocus, isTrue);
        pending = Completer<bool>();
      }
      expect(vpn.wake, isTrue);
      expect(vpn.delay, 10);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'moving with remote during VPN save is not undone by completion',
    (tester) async {
      final pending = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'save') return pending.future;
            return Map<String, Object>.from(state);
          });
      await tester.pumpWidget(
        app(const SizedBox(width: 600, child: VpnSettingsPage())),
      );
      await tester.pumpAndSettle();
      rowFocus(tester, 'Показывать только при подключении').requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 250));
      final next = rowFocus(tester, 'Показывать название приложения');
      expect(next.hasFocus, isTrue);
      pending.complete(true);
      await tester.pumpAndSettle();
      expect(next.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final side in [false, true]) {
    testWidgets(
      'menu settings keep toolbar and restore gear focus: right=$side',
      (tester) async {
        await settings.setSettingsMenuOnRight(side);
        await appearance.set(
          'settingsInterfaceStyle',
          InterfaceStyle.glass.name,
        );
        await tester.pumpWidget(app(const VpnWidget()));
        await tester.tap(find.byIcon(Icons.vpn_key));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(MenuHeaderAction));
        await tester.pumpAndSettle();
        expect(find.byType(VpnSettingsPage), findsOneWidget);
        expect(
          tester.getTopLeft(find.byType(VpnSettingsPage)).dy,
          greaterThanOrEqualTo(kToolbarHeight),
        );
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byType(VpnSettingsPage), findsNothing);
        final button = tester.widget<IconButton>(
          find.descendant(
            of: find.byType(MenuHeaderAction),
            matching: find.byType(IconButton),
          ),
        );
        expect(button.focusNode?.hasFocus, isTrue);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
