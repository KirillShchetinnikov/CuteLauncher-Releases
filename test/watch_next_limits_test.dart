import 'dart:convert';

import 'package:flauncher/models/watch_next_program.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/watch_next_selection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('hidden cards do not consume caps; app caps precede total cap', () {
    final programs = [
      for (final (id, package) in [
        (1, 'a'),
        (2, 'a'),
        (3, 'b'),
        (4, 'a'),
        (5, 'b'),
        (6, 'c'),
      ])
        WatchNextProgram.fromMap({'id': id, 'packageName': package}),
    ];
    List<int> select(int total) => selectWatchNextPrograms(
      programs,
      hiddenIds: {'1'},
      hiddenPackages: {'c'},
      appLimits: {'a': 1},
      totalLimit: total,
    ).map((p) => p.id).toList();
    expect(select(3), [2, 3, 5]);
    expect(select(2), [2, 3]);
    expect(select(0), [2, 3, 5]);
    expect(programs.length, 6);
  });
  test('source limits persist, round trip, reject invalid imports and reset independently', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    await settings.setWatchNextAppLimit('a', 3);
    await settings.setWatchNextAppLimit('b', 1);
    final restored = SettingsService(prefs);
    expect(restored.watchNextAppLimits, {'a': 3, 'b': 1});
    final backup = settings.exportSettingsMap();
    await settings.setWatchNextAppLimit('a', 0);
    expect(settings.watchNextAppLimits, {'b': 1});
    await settings.importSettingsMap(backup);
    expect(settings.watchNextAppLimits, {'a': 3, 'b': 1});
    for (final bad in ['[]', '{"a":-1}', '{"a":"3"}', 'null', '{"a":10001}']) {
      await settings.importSettingsMap({watchNextAppLimitsKey: bad});
      expect(settings.watchNextAppLimits, {'a': 3, 'b': 1});
    }
    await settings.importSettingsMap({
      watchNextAppLimitsKey: jsonEncode({'b': 5}),
    });
    expect(settings.watchNextAppLimits, {'b': 5});
    settings.dispose();
    restored.dispose();
  });
}
