import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/network_speed_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/settings_sync.dart';
import 'package:flauncher/widgets/network_speed_widget.dart';
import 'package:flauncher/widgets/settings/network_speed_settings_page.dart';
import 'package:flauncher/widgets/settings/settings_value_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('opt-in visibility and interval survive storage, backup and synchronization', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs), panel = RemotePanelService(prefs);
    expect(settings.showNetworkSpeedInStatusBar, false);
    expect(settings.networkSpeedInterval, 3);
    expect(panel.visible('networkSpeed'), false);
    await panel.show('weather', false);
    expect(panel.visible('networkSpeed'), false);
    await panel.show('networkSpeed', true);
    final restored = RemotePanelService(prefs);
    expect(restored.visible('networkSpeed'), true);
    expect(settings.showNetworkSpeedInStatusBar, false);
    await settings.setShowNetworkSpeedInStatusBar(true);
    await settings.setNetworkSpeedInterval(10);
    final saved = SettingsService(prefs);
    expect(saved.showNetworkSpeedInStatusBar, true);
    expect(saved.networkSpeedInterval, 10);
    final exported = settings.exportSettingsMap();
    final valid = compatibleSettings(exported, exported);
    for (final key in [
      'show_network_speed_in_status_bar',
      'network_speed_interval',
    ]) {
      expect(valid[key], exported[key]);
      expect(syncSettingsKeys, contains(key));
      expect(backupSyncPartGroup('setting:$key'), BackupSyncGroup.topPanel);
    }
    await settings.setNetworkSpeedInterval(0);
    expect(settings.networkSpeedInterval, 1);
    await settings.setNetworkSpeedInterval(100);
    expect(settings.networkSpeedInterval, 10);
    await panel.show('networkSpeed', false);
    expect(settings.showNetworkSpeedInStatusBar, true);
    saved.dispose();
    restored.dispose();
    panel.dispose();
    settings.dispose();
  });

  testWidgets(
    'rates inherit panel style and hidden or ticker-disabled widgets stop sampling',
    (tester) async {
      const channel = MethodChannel('cutelauncher/network_speed');
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method != 'snapshot') return null;
        reads++;
        return {
          'rxBytes': reads * 3072,
          'txBytes': reads * 6144,
          'elapsedMs': reads * 3000,
        };
      });
      final service = NetworkSpeedService(), focus = FocusNode();
      Future<void> pump({bool visible = true, bool ticker = true}) async {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: service,
            child: MaterialApp(
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TickerMode(
                  enabled: ticker,
                  child: Center(
                    child: DefaultTextStyle(
                      style: const TextStyle(fontSize: 22, color: Colors.green),
                      child: NetworkSpeedWidget(
                        visible: visible,
                        focusNode: focus,
                        onPressed: () {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      try {
        await pump();
        expect(reads, 1);
        expect(find.text('↓ —'), findsOneWidget);
        await tester.pump(const Duration(seconds: 3));
        await tester.pump();
        expect(find.text('↓ 1,0 KiB/с'), findsOneWidget);
        expect(find.text('↑ 2,0 KiB/с'), findsOneWidget);
        await pump(visible: false);
        final hidden = reads;
        await tester.pump(const Duration(seconds: 20));
        expect(reads, hidden);
        await pump();
        expect(reads, hidden + 1);
        await pump(ticker: false);
        final paused = reads;
        await tester.pump(const Duration(seconds: 20));
        expect(reads, paused);
        await pump();
        expect(reads, paused + 1);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        focus.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    },
  );

  testWidgets(
    'remote keys change interval and live service adopts saved setting',
    (tester) async {
      SharedPreferences.setMockInitialValues({'network_speed_interval': 1});
      final settings = SettingsService(await SharedPreferences.getInstance());
      const channel = MethodChannel('cutelauncher/network_speed');
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'snapshot') {
          reads++;
          return {'rxBytes': 0, 'txBytes': 0, 'elapsedMs': reads * 1000};
        }
        return null;
      });
      final service = NetworkSpeedService(settings: settings);
      try {
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: SizedBox(width: 500, child: NetworkSpeedSettingsPage()),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<SettingsValueStepper>(find.byType(SettingsValueStepper))
              .options,
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        );
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();
        expect(settings.networkSpeedInterval, 2);
        service.setVisible(Object(), true);
        await tester.pump();
        final start = reads;
        await tester.pump(const Duration(seconds: 1));
        expect(reads, start);
        await tester.pump(const Duration(seconds: 1));
        expect(reads, start + 1);
        await settings.setNetworkSpeedInterval(10);
        await tester.pump();
        final slow = reads;
        await tester.pump(const Duration(seconds: 9));
        expect(reads, slow);
        await tester.pump(const Duration(seconds: 1));
        expect(reads, slow + 1);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox());
        service.dispose();
        settings.dispose();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
      }
    },
  );
}
