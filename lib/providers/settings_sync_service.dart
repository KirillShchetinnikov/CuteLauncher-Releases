import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import '../settings_import.dart';
import '../settings_sync.dart';
import '../tile_appearance.dart';
import '../image_limits.dart';

const _journalKey = 'settings_sync_pending';
final _schema = <String, Object>{
  for (final key in syncSettingsKeys) key: false,
  for (final key in [
    'app_language',
    'accent_color',
    'app_banner_shape',
    'screensaver_clock_style',
    'date_format',
    'time_format',
    'wifi_usage_period',
    'temperature_unit',
    'continue_watching_card_size',
    'card_focus_mode',
    'back_button_action',
    'wallpaper_fit',
    'tile_appearance',
  ])
    key: '',
  'continue_watching_max_items': 0,
  'continue_watching_order': 0,
  'wallpaper_brightness': 1.0,
  'wallpaper_saturation': 1.0,
  'wallpaper_dimming': 1.0,
};

class SettingsSyncPreview {
  final SyncPlan plan;
  final String _baseline;
  final String _state;
  SettingsSyncPreview(this.plan, this._baseline, this._state);
}

/// File transport keeps accounts, credentials, installed apps and paths local.
/// A write-ahead journal recovers interrupted applies before the next exchange.
class SettingsSyncService {
  final SharedPreferences preferences;
  final String Function() _newId;
  Future<void> _operation = Future.value();
  SettingsSyncService(this.preferences, {String Function()? newId})
    : _newId =
          newId ??
          (() {
            final random = Random.secure();
            return List.generate(
              16,
              (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
            ).join();
          });

  Future<T> _exclusive<T>(Future<T> Function() action) async {
    final previous = _operation;
    final done = Completer<void>();
    _operation = done.future;
    await previous;
    try {
      return await action();
    } finally {
      done.complete();
    }
  }

  Object _validate(String key, Object value) {
    if (key == tileAppearanceKey) {
      if (value is! String) throw const FormatException('Invalid appearance');
      final raw = jsonDecode(value);
      if (raw is! Map) throw const FormatException('Invalid appearance');
      final valid = TileAppearance.validValues(raw);
      if (valid.length != raw.length ||
          raw.entries.any((e) => !syncEqual(valid[e.key], e.value))) {
        throw const FormatException('Invalid appearance');
      }
      return jsonEncode({
        for (final key in (valid.keys.toList()..sort())) key: valid[key],
      });
    }
    final valid = compatibleSettings({key: value}, _schema);
    if (!valid.containsKey(key)) {
      throw const FormatException('Invalid shared setting');
    }
    return valid[key] as Object;
  }

  Map<String, Object> _current() => {
    for (final key in (syncSettingsKeys.toList()..sort()))
      if (preferences.get(key) != null)
        key: _validate(key, preferences.get(key)!),
  };
  Future<void> _put(String key, Object? value) async {
    final bool saved;
    if (value == null) {
      saved = await preferences.remove(key);
    } else if (value is String) {
      saved = await preferences.setString(key, value);
    } else if (value is bool) {
      saved = await preferences.setBool(key, value);
    } else if (value is int) {
      saved = await preferences.setInt(key, value);
    } else if (value is double) {
      saved = await preferences.setDouble(key, value);
    } else {
      throw const FormatException('Invalid setting type');
    }
    if (!saved) {
      throw const FileSystemException('Unable to save shared settings');
    }
  }

  Future<void> recover() => _exclusive(_recover);
  Future<void> _recover() async {
    final encoded = preferences.getString(_journalKey);
    if (encoded == null) return;
    final raw = jsonDecode(encoded);
    if (raw is! Map ||
        raw['before'] is! Map ||
        !(raw['state'] == null || raw['state'] is String)) {
      throw const FormatException('Invalid settings recovery journal');
    }
    final before = <String, Object?>{};
    if (raw['state'] != null) SettingsSyncState.decode(raw['state'] as String);
    for (final entry in (raw['before'] as Map).entries) {
      if (!syncSettingsKeys.contains(entry.key)) {
        throw const FormatException('Invalid recovery setting');
      }
      final value = entry.value;
      before[entry.key as String] = value == null
          ? null
          : _validate(entry.key as String, value as Object);
    }
    for (final entry in before.entries) {
      await _put(entry.key, entry.value);
    }
    await _put(syncStateKey, raw['state']);
    await _put(_journalKey, null);
  }

  Future<SettingsSyncState> _capture() async {
    await _recover();
    final encoded = preferences.getString(syncStateKey);
    final state =
        (encoded == null
                ? SettingsSyncState(_newId(), {})
                : SettingsSyncState.decode(encoded))
            .capture(_current());
    final next = state.encode();
    SettingsSyncState.decode(next); // Bound local clocks/file too.
    if (encoded != next) await _put(syncStateKey, next);
    return state;
  }

  Future<void> exportTo(File file) => _exclusive(() async {
    final state = await _capture();
    await file.writeAsString(state.encode(), flush: true);
  });
  Future<SettingsSyncPreview> preview(File file) => _exclusive(() async {
    final bytes = await readBoundedImage(
      file.openRead(),
      limit: syncMaximumBytes,
    );
    final remote = SettingsSyncState.decode(utf8.decode(bytes));
    // Reject the entire exchange before any change if even one value is invalid.
    final clean = <String, SyncValue>{};
    for (final entry in remote.entries.entries) {
      clean[entry.key] = SyncValue(
        entry.value.value == null
            ? null
            : _validate(entry.key, entry.value.value!),
        entry.value.clock,
      );
    }
    final local = await _capture();
    return SettingsSyncPreview(
      local.plan(SettingsSyncState(remote.device, clean)),
      jsonEncode(_current()),
      local.encode(),
    );
  });
  Future<void> apply(
    SettingsSyncPreview preview,
    Map<String, bool> useRemote,
  ) => _exclusive(() async {
    await _recover();
    if (preview._baseline != jsonEncode(_current()) ||
        preview._state != preferences.getString(syncStateKey)) {
      throw StateError('Settings changed; preview again');
    }
    final next = preview.plan.resolve(useRemote);
    final before = <String, Object?>{};
    final changes = <String, Object?>{};
    for (final entry in next.entries.entries) {
      final value = entry.value.value == null
          ? null
          : _validate(entry.key, entry.value.value!);
      if (syncEqual(value, preferences.get(entry.key))) continue;
      before[entry.key] = preferences.get(entry.key);
      changes[entry.key] = value;
    }
    await _put(
      _journalKey,
      jsonEncode({
        'before': before,
        'state': preferences.getString(syncStateKey),
      }),
    );
    try {
      for (final entry in changes.entries) {
        await _put(entry.key, entry.value);
      }
      await _put(syncStateKey, next.encode());
      await _put(_journalKey, null);
    } catch (_) {
      await _recover();
      rethrow;
    }
  });
}
