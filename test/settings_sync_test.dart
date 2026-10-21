import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/settings_sync.dart';

void main() {
  const accent = 'accent_color', time = 'show_time_in_status_bar';
  SettingsSyncState initial(String device) => SettingsSyncState(device, {});
  SettingsSyncState copy(String device, SettingsSyncState state) =>
      SettingsSyncState(device, state.entries);
  test(
    'disjoint edits converge in both directions without clock timestamps',
    () {
      final base = initial('A').capture({accent: '7C4DFF', time: true});
      final a = base.capture({accent: 'FF0000', time: true});
      final b = copy('B', base).capture({accent: '7C4DFF', time: false});
      final plan = a.plan(b);
      expect(plan.conflicts, isEmpty);
      expect(plan.changes, [time]);
      final merged = plan.resolve({});
      final reverse = b.plan(merged).resolve({});
      expect(merged.entries[accent]!.value, 'FF0000');
      expect(merged.entries[time]!.value, false);
      expect(
        reverse.entries.map((k, v) => MapEntry(k, v.toJson())),
        merged.entries.map((k, v) => MapEntry(k, v.toJson())),
      );
      expect(merged.plan(b).changes, isEmpty);
    },
  );
  for (final useRemote in [false, true]) {
    test(
      'explicit conflict choice $useRemote propagates and is idempotent',
      () {
        final base = initial('A').capture({accent: '7C4DFF'});
        final a = base.capture({accent: 'FF0000'});
        final b = copy('B', base).capture({accent: '00FF00'});
        final plan = a.plan(b);
        expect(plan.conflicts, [accent]);
        expect(() => plan.resolve({}), throwsStateError);
        final merged = plan.resolve({accent: useRemote});
        expect(merged.entries[accent]!.value, useRemote ? '00FF00' : 'FF0000');
        final reverse = b.plan(merged);
        expect(reverse.conflicts, isEmpty);
        expect(
          reverse.resolve({}).entries[accent]!.toJson(),
          merged.entries[accent]!.toJson(),
        );
        expect(merged.plan(reverse.resolve({})).changes, isEmpty);
      },
    );
  }
  test('same concurrent value joins history without a conflict', () {
    final base = initial('A').capture({accent: '7C4DFF'});
    final a = base.capture({accent: 'FF0000'});
    final b = copy('B', base).capture({accent: 'FF0000'});
    final result = a.plan(b).resolve({});
    expect(result.entries[accent]!.clock, {'A': 2, 'B': 1});
    expect(result.plan(base).changes, isEmpty);
  });
  test(
    'reset tombstone propagates but concurrent reset/edit needs a choice',
    () {
      final base = initial('A').capture({accent: '7C4DFF'});
      final reset = base.capture({});
      expect(reset.entries[accent]!.value, isNull);
      expect(
        copy('B', base).plan(reset).resolve({}).entries[accent]!.value,
        isNull,
      );
      final edited = copy('B', base).capture({accent: 'FF0000'});
      expect(reset.plan(edited).conflicts, [accent]);
      expect(reset.capture({}).encode(), reset.encode());
    },
  );
  test(
    'copied identity with equal versions and different data needs a choice',
    () {
      final a = initial('A').capture({accent: 'FF0000'});
      final b = initial('A').capture({accent: '00FF00'});
      expect(a.plan(b).conflicts, [accent]);
    },
  );
  test('local paths and secrets never enter captured entries', () {
    final state = initial('A').capture({
      accent: '7C4DFF',
      'adb_port': 5555,
      'weather_api_key': 'secret',
      'slideshow_folder': '/private',
      'default_home': 'own.home',
    });
    expect(state.entries.keys, [accent]);
    expect(SettingsSyncState.decode(state.encode()).encode(), state.encode());
  });
  test('joined clocks and counters are bounded', () {
    final a = SettingsSyncState('A', {
      accent: SyncValue('red', {for (var i = 0; i < 64; i++) 'a$i': 1}),
    });
    final b = SettingsSyncState('B', {
      accent: SyncValue('red', {'B': 1}),
    });
    expect(() => a.plan(b).resolve({}), throwsFormatException);
    final exhausted = SettingsSyncState('A', {
      accent: SyncValue('red', {'A': 9007199254740991}),
    });
    expect(() => exhausted.capture({accent: 'blue'}), throwsFormatException);
  });
  test(
    'invalid file version, types, local keys and oversized input are rejected',
    () {
      final valid =
          jsonDecode(initial('A').capture({accent: '7C4DFF'}).encode()) as Map;
      for (final malformed in [
        {...valid, 'version': 2},
        {...valid, 'device': '/bad'},
        {
          ...valid,
          'entries': {
            'weather_api_key': {
              'value': 'secret',
              'clock': {'A': 1},
            },
          },
        },
        {
          ...valid,
          'entries': {
            accent: {
              'value': {},
              'clock': {'A': 1},
            },
          },
        },
        {
          ...valid,
          'entries': {
            accent: {
              'value': 'red',
              'clock': {'A': 0},
            },
          },
        },
        {
          ...valid,
          'entries': {
            accent: {
              'value': 'red',
              'clock': {'A': 1.5},
            },
          },
        },
        {
          ...valid,
          'entries': {
            accent: {
              'value': 'red',
              'clock': {'A': 9007199254740992},
            },
          },
        },
      ]) {
        expect(
          () => SettingsSyncState.decode(jsonEncode(malformed)),
          throwsFormatException,
        );
      }
      expect(
        () => SettingsSyncState.decode(' ' * (syncMaximumBytes + 1)),
        throwsFormatException,
      );
    },
  );
}
