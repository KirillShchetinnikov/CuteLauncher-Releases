import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/flauncher_channel.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/night_mode_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/tv_inputs_service.dart';
import 'package:flauncher/tv_inputs_configuration.dart';
import 'package:flauncher/widgets/settings/inputs_settings_page.dart';
import 'package:flauncher/widgets/settings/inputs_panel.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/status_bar_panel_page.dart';
import 'package:flauncher/widgets/settings/night_mode_page.dart';
import 'package:flauncher/widgets/settings/auto_launch_page.dart';
import 'package:flauncher/auto_launch_configuration.dart';
import 'package:flauncher/widgets/tv_input_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences preferences;
  late TvInputsService inputs;
  late NightModeService night;
  late SettingsService settings;
  bool nightDisposed = false;
  const native = MethodChannel('me.efesser.flauncher/method');
  const nightChannel = MethodChannel('cutelauncher/night');
  const tcl = MethodChannel('cutelauncher/tcl_blue_light');
  const auto = MethodChannel('cutelauncher/auto_launch');

  setUp(() async {
    nightDisposed = false;
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      native,
      (call) async => [
        {'id': 'port2', 'label': 'HDMI 2', 'type': 1007},
        {'id': 'cec', 'label': 'XBOX', 'parentId': 'port2', 'type': 1007},
        {'id': 'port1', 'label': 'HDMI 1', 'type': 1007},
      ],
    );
    messenger.setMockMethodCallHandler(
      nightChannel,
      (_) async => {'usagePermission': true},
    );
    messenger.setMockMethodCallHandler(
      tcl,
      (_) async => {'status': 'unsupported'},
    );
    messenger.setMockMethodCallHandler(
      auto,
      (_) async =>
          const AutoLaunchConfiguration(mode: 'hdmi', input: 'cec').toMap(),
    );
    settings = SettingsService(preferences);
    inputs = TvInputsService(
      FLauncherChannel(),
      preferences: preferences,
      settings: settings,
    );
    await inputs.refreshInputs();
    night = NightModeService(preferences);
  });
  tearDown(() {
    inputs.dispose();
    if (!nightDisposed) night.dispose();
    settings.dispose();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in [native, nightChannel, tcl, auto]) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  Widget app(Widget page) => MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: inputs),
      ChangeNotifierProvider.value(value: night),
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider(create: (_) => AppearanceService(preferences)),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routes: {InputsSettingsPage.routeName: (_) => const Scaffold(body: InputsSettingsPage())},
      home: Scaffold(body: page),
    ),
  );

  Future<void> setInputsAvailable(bool available) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(native, (_) async => available
            ? [{'id': 'port2', 'label': 'HDMI 2', 'type': 1007}]
            : []);
    await inputs.refreshInputs();
  }

  testWidgets('input settings entry follows system input availability', (tester) async {
    await setInputsAvailable(false);
    await tester.pumpWidget(app(const StatusBarObjectsPage()));
    await tester.pumpAndSettle();
    final entry = find.widgetWithText(FocusableSettingsTile, 'Настройки входов');
    await tester.scrollUntilVisible(entry, 150);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    expect(tester.widget<FocusableSettingsTile>(entry).enabled, isFalse);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(InputsSettingsPage), findsNothing);

    await setInputsAvailable(true);
    await tester.pumpAndSettle();
    tester.state<ScrollableState>(find.byType(Scrollable).first)
        .position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(entry, 150);
    await tester.ensureVisible(entry);
    await tester.pumpAndSettle();
    expect(tester.widget<FocusableSettingsTile>(entry).enabled, isTrue);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.byType(InputsSettingsPage), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('empty inputs menu disables its settings action', (tester) async {
    await setInputsAvailable(false);
    await tester.pumpWidget(app(const InputsPanel()));
    await tester.pumpAndSettle();
    final action = find.byType(IconButton);
    expect(tester.widget<IconButton>(action).onPressed, isNull);
    await setInputsAvailable(true);
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(action).onPressed, isNotNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('open input settings disable edits without losing configuration', (tester) async {
    await inputs.configure(const TvInputsConfiguration(useCecNames: false));
    final saved = preferences.getString(tvInputsConfigurationKey);
    await tester.pumpWidget(app(const InputsSettingsPage()));
    await tester.pumpAndSettle();
    await setInputsAvailable(false);
    await tester.pumpAndSettle();
    final toggle = find.byType(RoundedSwitchListTile);
    expect(tester.widget<RoundedSwitchListTile>(toggle).enabled, isFalse);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    expect(preferences.getString(tvInputsConfigurationKey), saved);

    await setInputsAvailable(true);
    await tester.pumpAndSettle();
    expect(tester.widget<RoundedSwitchListTile>(toggle).enabled, isTrue);
    expect(inputs.configuration.useCecNames, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('input disappearance blocks an open name dialog and detail edits', (tester) async {
    await tester.pumpWidget(app(InputsSettingsPage(input: inputs.inputs.last)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Своё название'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Console');
    await setInputsAvailable(false);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();
    expect(inputs.configuration.overrides, isEmpty);
    for (final label in ['Своё название', 'Иконка входа']) {
      expect(tester.widget<FocusableSettingsTile>(
        find.widgetWithText(FocusableSettingsTile, label)).enabled, isFalse);
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('input settings remain available when the top panel button is off', (tester) async {
    await settings.setShowInputsWidgetInStatusBar(false);
    await tester.pumpWidget(app(const StatusBarObjectsPage()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Настройки входов'), 150);
    await tester.ensureVisible(find.text('Настройки входов'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Настройки входов'));
    await tester.pumpAndSettle();
    expect(find.text('Брать имя устройства из CEC'), findsOneWidget);
    expect(find.text('XBOX'), findsOneWidget);
    expect(settings.showInputsWidgetInStatusBar, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'remote edits own name/icon; CEC can be disabled and name cleared',
    (tester) async {
      await tester.pumpWidget(app(const InputsSettingsPage()));
      await tester.pumpAndSettle();
      expect(find.text('XBOX'), findsOneWidget);
      await tester.tap(find.text('Брать имя устройства из CEC'));
      await tester.pumpAndSettle();
      expect(find.text('HDMI 2'), findsOneWidget);
      await tester.tap(find.text('HDMI 2'));
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Своё название'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Моя приставка');
      await tester.tap(find.text('ОК'));
      await tester.pumpAndSettle();
      expect(inputs.inputs.last.label, 'Моя приставка');
      await tester.tap(find.text('Иконка входа'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Игровая приставка'));
      await tester.pumpAndSettle();
      expect(tvInputIcon(inputs.inputs.last), Icons.sports_esports);
      expect(
        TvInputsConfiguration.decode(
          preferences.getString(tvInputsConfigurationKey),
        ).overrides['port2']!.name,
        'Моя приставка',
      );
      await tester.tap(find.text('Своё название'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('По умолчанию'));
      await tester.pumpAndSettle();
      expect(inputs.inputs.last.label, 'HDMI 2');
      expect(inputs.inputs.last.icon, 'game');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'night submenu uses common names and checkboxes without resetting selection',
    (tester) async {
      night.dispose();
      night = NightModeService(preferences);
      await inputs.configure(
        inputs.configuration.copyWith(
          id: 'port2',
          value: const TvInputOverride(name: 'Console', icon: 'game'),
        ),
      );
      await tester.pumpWidget(app(const NightModePage(section: 'inputs')));
      await tester.pumpAndSettle();
      expect(find.text('Console'), findsNothing);
      Focus.of(tester.element(find.text('Выбрать входы для игнорирования')))
          .requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(night.configuration.selectHdmiInputs, isTrue);
      await tester.scrollUntilVisible(find.text('Console'), 100);
      expect(find.text('Console'), findsOneWidget);
      expect(find.text('HDMI 1'), findsOneWidget);
      expect(find.text('XBOX'), findsNothing);
      Focus.of(tester.element(find.text('Console'))).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(night.configuration.ignoredHdmiInputIds, ['port2']);
      await tester.ensureVisible(find.text('Игнорировать HDMI-входы'));
      await tester.tap(find.text('Игнорировать HDMI-входы'));
      await tester.pumpAndSettle();
      expect(find.text('Console'), findsNothing);
      expect(night.configuration.ignoredHdmiInputIds, ['port2']);
      await tester.tap(find.text('Игнорировать HDMI-входы'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Console'), 100);
      expect(find.text('Console'), findsOneWidget);
      await tester.tap(find.text('Console'));
      await tester.pumpAndSettle();
      expect(night.configuration.ignoredHdmiInputIds, isEmpty);
      expect(night.configuration.enabled, isFalse);
      await tester.pumpWidget(const SizedBox());
      night.dispose();
      nightDisposed = true;
    },
  );

  testWidgets(
    'auto launch uses common name and live settings reload after backup',
    (tester) async {
      await inputs.configure(
        inputs.configuration.copyWith(
          id: 'port2',
          value: const TvInputOverride(name: 'Console'),
        ),
      );
      await tester.pumpWidget(app(const AutoLaunchPage()));
      await tester.pumpAndSettle();
      expect(find.text('Console'), findsOneWidget);
      await preferences.setString(
        tvInputsConfigurationKey,
        const TvInputsConfiguration(useCecNames: false).encode(),
      );
      settings.reload();
      await tester.pumpAndSettle();
      expect(find.text('HDMI 2'), findsOneWidget);
      expect(find.text('Console'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
