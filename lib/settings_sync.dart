import 'dart:convert';

/// An explicit portable surface. New preferences remain local until reviewed.
const syncSettingsKeys = <String>{
  'app_language',
  'accent_color',
  'app_banner_shape',
  'screensaver_clock_style',
  'app_key_click_enabled',
  'auto_hide_app_bar',
  'show_category_titles',
  'show_app_names_below_icons',
  'hide_highlight_outline_on_homescreen',
  'app_highlight_animation_enabled',
  'app_selector_transition_animation_enabled',
  'show_date_in_status_bar',
  'show_time_in_status_bar',
  'date_format',
  'time_format',
  'wifi_usage_period',
  'show_wifi_widget_in_status_bar',
  'show_network_indicator_in_status_bar',
  'show_inputs_widget_in_status_bar',
  'tv_inputs_configuration',
  'show_system_settings_in_status_bar',
  'show_night_mode_in_status_bar',
  'hide_launcher_tile',
  'hide_android_settings_tile',
  'show_weather_in_status_bar',
  'show_weather_warnings',
  'temperature_unit',
  'show_continue_watching',
  'continue_watching_card_size',
  'continue_watching_max_items',
  'continue_watching_show_progress',
  'continue_watching_show_percentage',
  'continue_watching_show_description',
  'continue_watching_order',
  'show_now_playing',
  'show_notifications_widget_in_status_bar',
  'auto_hide_notifications_widget',
  'remember_category_focus',
  'card_focus_mode',
  'settings_menu_on_right',
  'back_button_action',
  'wallpaper_fit',
  'wallpaper_brightness',
  'wallpaper_saturation',
  'wallpaper_dimming',
  'tile_appearance',
};

const syncStateKey = 'settings_sync_state';
const syncMaximumBytes = 1024 * 1024;
const _maximumCounter = 9007199254740991;
final _id = RegExp(r'^[a-zA-Z0-9_-]{1,64}$');

bool syncEqual(Object? first, Object? second) =>
    jsonEncode(first) == jsonEncode(second);

class SyncValue {
  final Object? value;
  final Map<String, int> clock;
  SyncValue(this.value, Map<String, int> clock)
    : clock = Map.unmodifiable(clock);
  Map<String, Object?> toJson() => {'value': value, 'clock': clock};
  static SyncValue parse(Object? raw) {
    if (raw is! Map ||
        raw.length != 2 ||
        !raw.containsKey('value') ||
        raw['clock'] is! Map) {
      throw const FormatException('Invalid sync entry');
    }
    final value = raw['value'];
    if (!(value == null ||
        value is bool ||
        value is int ||
        value is double && value.isFinite ||
        value is String && value.length <= 65536 ||
        value is List &&
            value.length <= 256 &&
            value.every((v) => v is String && v.length <= 1024))) {
      throw const FormatException('Invalid sync value');
    }
    final clock = <String, int>{};
    for (final entry in (raw['clock'] as Map).entries) {
      if (entry.key is! String ||
          !_id.hasMatch(entry.key) ||
          entry.value is! int ||
          entry.value <= 0 ||
          entry.value > _maximumCounter) {
        throw const FormatException('Invalid sync version');
      }
      clock[entry.key as String] = entry.value as int;
    }
    if (clock.isEmpty || clock.length > 64) {
      throw const FormatException('Too many sync devices');
    }
    return SyncValue(value, clock);
  }
}

/// Vector versions detect concurrent edits without depending on TV clocks.
class SettingsSyncState {
  final String device;
  final Map<String, SyncValue> entries;
  SettingsSyncState(this.device, Map<String, SyncValue> entries)
    : entries = Map.unmodifiable(entries) {
    if (!_id.hasMatch(device)) {
      throw const FormatException('Invalid sync device');
    }
  }
  String encode() => jsonEncode({
    'format': 'cutelauncher-settings-sync',
    'version': 1,
    'device': device,
    'entries': {
      for (final key in (entries.keys.toList()..sort()))
        key: entries[key]!.toJson(),
    },
  });
  static SettingsSyncState decode(String encoded) {
    if (utf8.encode(encoded).length > syncMaximumBytes) {
      throw const FormatException('Sync file is too large');
    }
    final raw = jsonDecode(encoded);
    if (raw is! Map ||
        raw['format'] != 'cutelauncher-settings-sync' ||
        raw['version'] != 1 ||
        raw['device'] is! String ||
        raw['entries'] is! Map ||
        (raw['entries'] as Map).length > syncSettingsKeys.length) {
      throw const FormatException('Unsupported sync file');
    }
    final entries = <String, SyncValue>{};
    for (final entry in (raw['entries'] as Map).entries) {
      if (!syncSettingsKeys.contains(entry.key)) {
        throw const FormatException('Local setting in sync file');
      }
      entries[entry.key as String] = SyncValue.parse(entry.value);
    }
    return SettingsSyncState(raw['device'] as String, entries);
  }

  SettingsSyncState capture(Map<String, Object> current) {
    final next = Map<String, SyncValue>.of(entries);
    for (final key in {...entries.keys, ...current.keys}) {
      if (!syncSettingsKeys.contains(key)) continue;
      final previous = entries[key];
      final value = current[key];
      if (previous != null && syncEqual(previous.value, value)) continue;
      final clock = <String, int>{...?previous?.clock};
      final counter = clock[device] ?? 0;
      if (counter >= _maximumCounter) {
        throw const FormatException('Sync version exhausted');
      }
      clock[device] = counter + 1;
      next[key] = SyncValue(value, clock);
    }
    return SettingsSyncState(device, next);
  }

  SyncPlan plan(SettingsSyncState remote) => SyncPlan(this, remote);
}

Map<String, int> _join(SyncValue a, SyncValue b) => {
  for (final id in {...a.clock.keys, ...b.clock.keys})
    id: (a.clock[id] ?? 0) > (b.clock[id] ?? 0) ? a.clock[id]! : b.clock[id]!,
};
bool _dominates(SyncValue a, SyncValue b) =>
    b.clock.entries.every((e) => (a.clock[e.key] ?? 0) >= e.value);

class SyncPlan {
  final SettingsSyncState local, remote;
  final Map<String, SyncValue> _merged = {};
  final List<String> conflicts = [], changes = [];
  SyncPlan(this.local, this.remote) {
    for (final key in {
      ...local.entries.keys,
      ...remote.entries.keys,
    }.toList()..sort()) {
      final a = local.entries[key], b = remote.entries[key];
      if (b == null) {
        _merged[key] = a!;
        continue;
      }
      if (a == null) {
        _merged[key] = b;
        changes.add(key);
        continue;
      }
      if (syncEqual(a.value, b.value)) {
        _merged[key] = SyncValue(a.value, _join(a, b));
      } else if (_dominates(a, b) && _dominates(b, a)) {
        // A copied/corrupted identity must not silently discard different data.
        conflicts.add(key);
      } else if (_dominates(a, b)) {
        _merged[key] = a;
      } else if (_dominates(b, a)) {
        _merged[key] = b;
        changes.add(key);
      } else {
        conflicts.add(key);
      }
    }
  }
  SettingsSyncState resolve(Map<String, bool> useRemote) {
    final merged = Map<String, SyncValue>.of(_merged);
    for (final key in conflicts) {
      if (!useRemote.containsKey(key)) {
        throw StateError('Unresolved sync conflict');
      }
      final a = local.entries[key]!, b = remote.entries[key]!;
      final clock = _join(a, b);
      if (clock.length > 64) {
        throw const FormatException('Too many sync devices');
      }
      final counter = clock[local.device] ?? 0;
      if (counter >= _maximumCounter) {
        throw const FormatException('Sync version exhausted');
      }
      clock[local.device] = counter + 1;
      merged[key] = SyncValue(useRemote[key]! ? b.value : a.value, clock);
    }
    // Validate joined clocks and bound the resulting file as well as the input.
    return SettingsSyncState.decode(
      SettingsSyncState(local.device, merged).encode(),
    );
  }
}
