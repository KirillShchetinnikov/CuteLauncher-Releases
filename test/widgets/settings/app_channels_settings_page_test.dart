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
import 'package:flauncher/widgets/settings/adb_permission_tile.dart';

import '../../support/app_channels.dart';

void main() {
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
