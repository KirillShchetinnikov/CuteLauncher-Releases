import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/system_status_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/widgets/system_status_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('visibility opt-in and display options survive storage and backup validation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs), panel = RemotePanelService(prefs);
    expect(settings.showSystemInStatusBar, isFalse);
    expect(panel.visible('system'), isFalse);
    await panel.show('weather', false);
    await panel.show('system', true);
    final restored = RemotePanelService(prefs);
    expect(restored.visible('system'), isTrue);
    expect(restored.visible('weather'), isFalse);
    expect(settings.showSystemInStatusBar, isFalse);
    await settings.setShowSystemInStatusBar(true);
    await settings.setSystemShowCpu(false);
    await settings.setSystemShowRam(false);
    final exported = settings.exportSettingsMap();
    final valid = compatibleSettings(exported, exported);
    for (final key in [
      'show_system_in_status_bar',
      'system_show_cpu',
      'system_show_ram',
    ]) {
      expect(valid[key], exported[key]);
      expect(backupSyncPartGroup('setting:$key'), BackupSyncGroup.topPanel);
    }
    await panel.show('system', false);
    expect(panel.visible('system'), isFalse);
    expect(settings.showSystemInStatusBar, isTrue);
    restored.dispose();
    panel.dispose();
    settings.dispose();
  });

  testWidgets(
    'hidden and ticker-disabled widget stops sampling; enabling resumes',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsService(prefs);
      const channel = MethodChannel('cutelauncher/system_status');
      var reads = 0;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method != 'snapshot') return null;
        reads++;
        return {
          'cpuPercent': 24,
          'ramTotalBytes': 1000,
          'ramAvailableBytes': 400,
        };
      });
      final service = SystemStatusService(), focus = FocusNode();
      Future<void> pump({bool visible = true, bool ticker = true}) async {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: settings),
              ChangeNotifierProvider.value(value: service),
            ],
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: TickerMode(
                  enabled: ticker,
                  child: Center(
                    child: SystemStatusWidget(
                      visible: visible,
                      focusNode: focus,
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await pump();
      expect(reads, 1);
      await pump(visible: false);
      await tester.pump(const Duration(seconds: 10));
      expect(reads, 1);
      await pump();
      expect(reads, 2);
      await pump(ticker: false);
      await tester.pump(const Duration(seconds: 10));
      expect(reads, 2);
      await pump();
      expect(reads, 3);
      await tester.pumpWidget(const SizedBox());
      service.dispose();
      settings.dispose();
      focus.dispose();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    },
  );
}
