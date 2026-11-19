import 'package:flauncher/widgets/settings/app_channels_order_page.dart';
import 'package:flauncher/widgets/settings/focusable_settings_tile.dart';
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
      home: const Scaffold(body: AppChannelsSettingsPage(channelKey: 'video.app:1')),
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
      expect(find.byType(RoundedSwitchListTile), findsNothing);
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
    testWidgets('feed list opens editor and restores focus after selection: $locale', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      final channel = FeedChannel()..data = [feed(1), feed(2)];
      final service = AppChannelsService(channel, settings);
      addTearDown(() async { service.dispose(); settings.dispose(); await channel.events.close(); });
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider.value(value: settings), ChangeNotifierProvider.value(value: service),
      ], child: MaterialApp(
        locale: Locale(locale), localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)), child: Material(child: child!)),
        home: const Scaffold(body: AppChannelsOrderPage()),
      )));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('video.app:2'));
      final node = tester.widget<FocusableSettingsTile>(row).focusNode!;
      node.requestFocus();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.byType(RoundedSwitchListTile), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('video.app:2')));
      await tester.pumpAndSettle();
      expect(settings.selectedAppChannels, ['video.app:2']);
      expect(SettingsService(prefs).selectedAppChannels, ['video.app:2']);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      expect(find.byType(RoundedSwitchListTile), findsNothing);
      channel.data = [feed(1)];
      await service.refresh();
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('video.app:2')));
      await tester.pumpAndSettle();
      expect(settings.selectedAppChannels, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('broken feeds are omitted without clearing the saved selection', (tester) async {
    SharedPreferences.setMockInitialValues({'selected_app_channels': ['video.app:1']});
    final settings = SettingsService(await SharedPreferences.getInstance());
    final channel = FeedChannel()..data = [feed(1)..['hidden'] = true, feed(2)];
    final service = AppChannelsService(channel, settings);
    addTearDown(() async { service.dispose(); settings.dispose(); await channel.events.close(); });
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value: settings), ChangeNotifierProvider.value(value: service),
    ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales, home: const Scaffold(body: AppChannelsOrderPage()))));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('video.app:1')), findsNothing);
    expect(find.byKey(const ValueKey('video.app:2')), findsOneWidget);
    expect(settings.selectedAppChannels, ['video.app:1']);
    channel.data = [feed(1), feed(2)];
    await service.refresh();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('video.app:1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  for (final pointer in [false, true]) {
    testWidgets('editor keeps focus and rejects a duplicate pending save: pointer=$pointer', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final settings = _DelayedSettingsService(await SharedPreferences.getInstance());
      final channel = FeedChannel()..data = [feed(1)];
      final service = AppChannelsService(channel, settings);
      addTearDown(() async { service.dispose(); settings.dispose(); await channel.events.close(); });
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<SettingsService>.value(value: settings), ChangeNotifierProvider.value(value: service),
      ], child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: AppChannelsSettingsPage(channelKey: 'video.app:1')))));
      await tester.pumpAndSettle();
      final row = find.byKey(const ValueKey('video.app:1'));
      final focus = FocusManager.instance.primaryFocus;
      if (pointer) { await tester.tap(row); } else { await tester.sendKeyEvent(LogicalKeyboardKey.enter); }
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(settings.saveCalls, 1);
      expect(FocusManager.instance.primaryFocus, focus);
      settings.saveGate.complete();
      await tester.pumpAndSettle();
      expect(settings.selectedAppChannels, ['video.app:1']);
      expect(focus?.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
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
