import 'dart:convert';

import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/sleep_timer_configuration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('move across boundaries, reorder hidden list, then show again', () {
    var config = SleepTimerConfiguration(
      presets: [
        const SleepTimerPreset('a', 60),
        const SleepTimerPreset('b', 120),
        const SleepTimerPreset('c', 180, visible: false),
      ],
    );
    config = config.move('b', 1);
    expect(config.presets.map((p) => p.id), ['a', 'b', 'c']);
    expect(config.presets.where((p) => p.visible).map((p) => p.id), ['a']);
    config = config.move('b', 1);
    expect(config.presets.map((p) => p.id), ['a', 'c', 'b']);
    config = config.move('c', -1);
    expect(config.presets.where((p) => p.visible).map((p) => p.id), ['a', 'c']);
    config = config.move('a', -1);
    expect(config.presets.first.id, 'a');
  });

  test('empty list stays empty; invalid backup cannot erase timers', () {
    final empty = SleepTimerConfiguration(presets: []);
    expect(SleepTimerConfiguration.parse(empty.encode()).presets, isEmpty);
    final encoded = jsonDecode(empty.encode()) as Map;
    encoded['presets'] = [
      {'id': 'x', 'seconds': 0, 'visible': true},
    ];
    expect(
      compatibleSettings({sleepTimerConfigurationKey: jsonEncode(encoded)}, {}),
      isEmpty,
    );
    encoded['presets'] = [
      {'id': 'x', 'seconds': 5, 'visible': true},
      {'id': 'x', 'seconds': 6, 'visible': false},
    ];
    expect(
      () => SleepTimerConfiguration.parse(jsonEncode(encoded)),
      throwsFormatException,
    );
    expect(SleepTimerConfiguration.decode('broken').presets.length, 13);
  });

  test(
    'settings and arbitrary presets survive restart, export and import',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = SettingsService(prefs);
      final config = SleepTimerConfiguration(
        display: 'both',
        showSeconds: false,
        closeAfterSelection: false,
        presets: [
          const SleepTimerPreset('custom', 90061),
          const SleepTimerPreset('hidden', 7, visible: false),
        ],
      );
      await service.setSleepTimerConfiguration(config);
      final restarted = SettingsService(prefs);
      expect(restarted.sleepTimerConfiguration.encode(), config.encode());
      final exported = service.exportSettingsMap();
      await prefs.remove(sleepTimerConfigurationKey);
      await restarted.importSettingsMap(exported);
      expect(restarted.sleepTimerConfiguration.encode(), config.encode());
      expect(
        backupSyncPartGroup('setting:$sleepTimerConfigurationKey'),
        BackupSyncGroup.topPanel,
      );
      service.dispose();
      restarted.dispose();
    },
  );

  test('duration supports seconds and more than six hours, rounds up hidden seconds', () {
    expect(validSleepTimerSeconds(1), isTrue);
    expect(validSleepTimerSeconds(90061), isTrue);
    expect(validSleepTimerSeconds(maxSleepTimerSeconds), isTrue);
    expect(validSleepTimerSeconds(maxSleepTimerSeconds + 1), isFalse);
    expect(validSleepTimerSeconds(0), isFalse);
    expect(formatTimerDuration(90061), '25:01:01');
    expect(formatTimerDuration(59, showSeconds: false), '0:01');
  });
}
