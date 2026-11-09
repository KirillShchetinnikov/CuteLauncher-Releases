import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/app_channels_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/widgets/rounded_switch_list_tile.dart';
import 'package:flauncher/widgets/settings/app_channels_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_help.dart';
import 'package:flauncher/widgets/settings/settings_slider_tile.dart';
import 'package:flauncher/widgets/settings/adb_permission_tile.dart';
import 'package:flauncher/feed_format.dart';

import '../../support/app_channels.dart';

void main() {
  testWidgets('feed card limit uses one remote slider and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final channel = FeedChannel();
    final service = AppChannelsService(channel, settings);
    addTearDown(() async {
      service.dispose();
      settings.dispose();
      await channel.events.close();
    });
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider.value(value: service),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AppChannelsSettingsPage()),
      ),
    ));
    await tester.pumpAndSettle();
    final slider = find.byType(SettingsSliderTile);
    expect(tester.widget<SettingsSliderTile>(slider).value, 20);
    await tester.ensureVisible(slider);
    final focus = Focus.of(tester.element(find.text('Maximum Items')));
    focus.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(settings.appChannelCardLimit, 20);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    for (var repeat = 0; repeat < 32; repeat++) {
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    expect(focus.hasPrimaryFocus, isTrue);
    expect(tester.widget<SettingsSliderTile>(slider).value, 50);
    final restored = SettingsService(prefs);
    addTearDown(restored.dispose);
    expect(restored.appChannelCardLimit, 50);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('broken feeds are hidden even if selected and return on recovery', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_app_channels': ['video.app:1'],
    });
    final settings = SettingsService(await SharedPreferences.getInstance());
    final channel = FeedChannel()
      ..data = [
        feed(1)..['hidden'] = true,
        feed(2),
        feed(3)..['hidden'] = true,
      ];
    final service = AppChannelsService(channel, settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppChannelsSettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('video.app:1')), findsNothing);
    expect(find.byKey(const ValueKey('video.app:2')), findsOneWidget);
    expect(find.byKey(const ValueKey('video.app:3')), findsNothing);
    expect(settings.selectedAppChannels, ['video.app:1']);

    channel.data = [feed(1), feed(2), feed(3)];
    await service.refresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('video.app:1')), findsOneWidget);
    expect(find.byKey(const ValueKey('format:video.app:1')), findsOneWidget);
    expect(find.byKey(const ValueKey('video.app:3')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    settings.dispose();
    await channel.events.close();
  });

  testWidgets('format choice persists and returns focus to its feed control', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_app_channels': ['video.app:1']});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1)];
    final service = AppChannelsService(channel, settings);
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider<SettingsService>.value(value: settings),
      ChangeNotifierProvider.value(value: service),
    ], child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: AppChannelsSettingsPage()),
    )));
    await tester.pumpAndSettle();
    final control = find.byKey(const ValueKey('format:video.app:1'));
    await tester.ensureVisible(control);
    await tester.tap(control);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Portrait'));
    await tester.pumpAndSettle();
    expect(settings.appChannelFormat('video.app:1'), FeedFormat.portrait);
    expect(SettingsService(prefs).appChannelFormat('video.app:1'), FeedFormat.portrait);
    expect(find.text('Portrait'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose(); settings.dispose(); await channel.events.close();
  });
  testWidgets('entry and manual refresh keep focus on the refresh action', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final initial = Completer<List<Map<dynamic, dynamic>>>();
    final channel = FeedChannel()..response = () => initial.future;
    final service = AppChannelsService(channel, settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: service),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppChannelsSettingsPage()),
        ),
      ),
    );
    await tester.pump();

    final button = find.text('Refresh feeds');
    final spinner = find.byType(CircularProgressIndicator);
    bool refreshHasFocus() => Focus.of(tester.element(button)).hasPrimaryFocus;
    expect(spinner, findsOneWidget);
    expect(refreshHasFocus(), isTrue, reason: 'initial refresh is pending');
    initial.complete([feed(1)]);
    await tester.pumpAndSettle();
    expect(spinner, findsNothing);
    expect(refreshHasFocus(), isTrue);

    final manual = Completer<List<Map<dynamic, dynamic>>>();
    channel.response = () => manual.future;
    final requests = channel.requests.length;
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(spinner, findsOneWidget);
    expect(refreshHasFocus(), isTrue, reason: 'manual refresh is pending');
    expect(channel.requests, hasLength(requests + 1));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    final helpFocus = FocusManager.instance.primaryFocus;
    expect(
      helpFocus?.context?.findAncestorWidgetOfExactType<SettingsHelp>(),
      isNotNull,
    );
    manual.complete([feed(1), feed(2)]);
    await tester.pumpAndSettle();
    expect(spinner, findsNothing);
    expect(helpFocus?.hasPrimaryFocus, isTrue);
    expect(channel.requests, hasLength(requests + 1));
    expect(find.byKey(const ValueKey('video.app:2')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    settings.dispose();
    await channel.events.close();
  });

  for (final pointer in [false, true]) {
    testWidgets('feed selection retains focus while saving: pointer=$pointer', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = _DelayedSettingsService(prefs);
      final channel = FeedChannel()..data = [feed(1), feed(2), feed(3)];
      final service = AppChannelsService(channel, settings);
      final appearance = AppearanceService(prefs);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(value: settings),
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AppChannelsSettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = find.byKey(const ValueKey('video.app:2'));
      final label = find
          .descendant(of: tile, matching: find.byType(Text))
          .first;
      if (pointer) {
        await tester.tap(tile);
      } else {
        Focus.of(tester.element(label)).requestFocus();
        await tester.pumpAndSettle();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      }
      await tester.pump();
      expect(settings.saveCalls, 1);
      expect(Focus.of(tester.element(label)).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(settings.saveCalls, 1);
      settings.saveGate.complete();
      await tester.pumpAndSettle();
      expect(settings.selectedAppChannels, ['video.app:2']);
      expect(Focus.of(tester.element(label)).hasFocus, isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(settings.selectedAppChannels, isEmpty);
      expect(Focus.of(tester.element(label)).hasFocus, isTrue);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      appearance.dispose();
      settings.dispose();
      await channel.events.close();
    });
  }

  testWidgets('remote arrows follow the new order after toggling a feed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'selected_app_channels': ['video.app:1'],
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final channel = FeedChannel()..data = [feed(1), feed(2), feed(3)];
    final service = AppChannelsService(channel, settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppChannelsSettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder label(String key) => find
        .descendant(of: find.byKey(ValueKey(key)), matching: find.byType(Text))
        .first;
    FocusNode focus(String key) => Focus.of(tester.element(label(key)));
    Future<void> press(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key);
      await tester.pumpAndSettle();
    }

    focus('video.app:2').requestFocus();
    await tester.pumpAndSettle();
    await press(LogicalKeyboardKey.arrowDown);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.enter);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    expect(
      tester.getTopLeft(label('video.app:3')).dy,
      lessThan(tester.getTopLeft(label('video.app:2')).dy),
    );

    await press(LogicalKeyboardKey.arrowUp);
    expect(focus('format:video.app:1').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowDown);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowDown);
    expect(focus('format:video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowDown);
    expect(focus('video.app:2').hasPrimaryFocus, isTrue);

    await press(LogicalKeyboardKey.arrowUp);
    await press(LogicalKeyboardKey.arrowUp);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowUp);
    expect(focus('format:video.app:1').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowDown);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.enter);
    expect(focus('video.app:3').hasPrimaryFocus, isTrue);
    await press(LogicalKeyboardKey.arrowUp);
    expect(focus('video.app:2').hasPrimaryFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    settings.dispose();
    await channel.events.close();
  });

  testWidgets('a moved feed stays visible and navigable in a long catalogue', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    final channel = FeedChannel()
      ..data = [for (var id = 1; id <= 24; id++) feed(id)];
    final service = AppChannelsService(channel, settings);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: service),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: AppChannelsSettingsPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tile = find.byKey(const ValueKey('video.app:24'));
    await tester.scrollUntilVisible(tile, 200);
    FocusNode focus(Finder row) => Focus.of(
      tester.element(
        find.descendant(of: row, matching: find.byType(Text)).first,
      ),
    );
    focus(tile).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tile.hitTestable(), findsOneWidget);
    expect(focus(tile).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    final format = find.byKey(const ValueKey('format:video.app:24'));
    expect(format.hitTestable(), findsOneWidget);
    expect(focus(format).hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focus(tile).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(tile.hitTestable(), findsOneWidget);
    expect(focus(tile).hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(
      focus(find.byKey(const ValueKey('video.app:23'))).hasPrimaryFocus,
      isTrue,
    );
    await tester.pumpWidget(const SizedBox());
    service.dispose();
    settings.dispose();
    await channel.events.close();
  });

  testWidgets(
    'access error offers permission and ADB instead of an empty catalogue',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final channel = FeedChannel()
        ..data = [feed(1)]
        ..fail = true;
      final service = AppChannelsService(channel, settings);
      final appearance = AppearanceService(prefs);
      const platform = MethodChannel('me.efesser.flauncher/method');
      const adb = MethodChannel('cutelauncher/adb');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(platform, (call) async {
        if (call.method == 'requestAppChannelsPermission') {
          channel.fail = false;
          return true;
        }
        if (call.method == 'checkAppChannelsPermission') return !channel.fail;
        return null;
      });
      messenger.setMockMethodCallHandler(adb, (_) async => null);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            ChangeNotifierProvider.value(value: service),
            ChangeNotifierProvider.value(value: appearance),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AppChannelsSettingsPage()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final l = AppLocalizations.of(
        tester.element(find.byType(AppChannelsSettingsPage)),
      )!;
      expect(find.text(l.appChannelsUnavailable), findsOneWidget);
      expect(find.text(l.appChannelsEmpty), findsNothing);
      expect(find.byType(AdbPermissionTile), findsOneWidget);
      expect(find.text(l.watchNextAccess), findsNothing);
      final permission = find.text(l.appChannelsAccess);
      await tester.ensureVisible(permission);
      await tester.tap(permission);
      await tester.pumpAndSettle();
      expect(find.byType(RoundedSwitchListTile), findsOneWidget);
      expect(find.text(l.appChannelsUnavailable), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      appearance.dispose();
      settings.dispose();
      await channel.events.close();
      messenger.setMockMethodCallHandler(platform, null);
      messenger.setMockMethodCallHandler(adb, null);
    },
  );
  for (final locale in ['ru', 'ar']) {
    testWidgets(
      'feed settings persist independent selections with large text $locale',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final settings = SettingsService(prefs);
        final channel = FeedChannel()..data = [feed(1), feed(2, count: 0)];
        final service = AppChannelsService(channel, settings);
        final appearance = AppearanceService(prefs);
        await settings.setSettingsMenuOnRight(true);
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: service),
              ChangeNotifierProvider.value(value: appearance),
            ],
            child: MaterialApp(
              locale: Locale(locale),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (_, child) => MediaQuery(
                data: const MediaQueryData(
                  size: Size(640, 720),
                  textScaler: TextScaler.linear(1.5),
                ),
                child: child!,
              ),
              home: const Scaffold(body: AppChannelsSettingsPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RoundedSwitchListTile), findsNWidgets(2));
        expect(find.byType(SettingsHelp), findsOneWidget);
        final tile = find.byKey(const ValueKey('video.app:2'));
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
        expect(settings.selectedAppChannels, ['video.app:2']);
        expect(SettingsService(prefs).selectedAppChannels, ['video.app:2']);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        channel.data = [];
        await service.refresh();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('video.app:2')), findsOneWidget);
        await tester.ensureVisible(find.byKey(const ValueKey('video.app:2')));
        await tester.tap(find.byKey(const ValueKey('video.app:2')));
        await tester.pumpAndSettle();
        expect(settings.selectedAppChannels, isEmpty);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        appearance.dispose();
        settings.dispose();
        await channel.events.close();
      },
    );
  }
}

class _DelayedSettingsService extends SettingsService {
  final saveGate = Completer<void>();
  int saveCalls = 0;
  _DelayedSettingsService(super.preferences);

  @override
  Future<void> setSelectedAppChannels(List<String> keys) async {
    saveCalls++;
    await saveGate.future;
    await super.setSelectedAppChannels(keys);
  }
}
