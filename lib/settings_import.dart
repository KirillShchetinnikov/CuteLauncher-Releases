import 'tv_inputs_configuration.dart';
import 'tile_appearance.dart';
import 'category_appearance.dart';
import 'providers/night_mode_service.dart';
import 'l10n/app_localizations.dart';
import 'weather_sources.dart';
import 'dart:convert';
import 'watch_next_selection.dart';
import 'backup_sync_groups.dart';
import 'providers/online_wallpaper_service.dart';

/// Merge only compatible entries. Missing or invalid settings never reset values.
/// Unknown primitive keys are retained for round-tripping between app releases.
Map<String, dynamic> compatibleSettings(dynamic source, Map<String, dynamic> expected) {
  if (source is! Map) return {};
  final schema = <String, dynamic>{
    'gradient_uuid': '',
    'brightness_scheduler_enabled': false,
    'brightness_solar': false,
    'brightness_transition_minutes': 1,
    'brightness_sunrise': 80,
    'brightness_sunset': 20,
    for (final slot in ['morning', 'day', 'afternoon', 'evening', 'night']) 'brightness_$slot': 0,
    'system_notifications_popup': false,
    'show_now_playing': false,
    'hide_persistent_notifications': false,
    'automatic_update_checks': false,
    'update_prereleases': false,
    'show_update_notifications': true,
    'blocked_notification_packages': <String>[],
    'tv_apps_section_order_default_v1': false,
    backupSyncGroupsKey: <String>[],
    ...expected,
  };
  final result = <String, dynamic>{};
  for (final entry in source.entries) {
    final key = entry.key;
    var value = entry.value;
    if (key is! String || key.isEmpty) continue;
    if (key == watchNextAppLimitsKey) {
      if (value is String && parseWatchNextAppLimits(value) != null) result[key] = value;
      continue;
    }
    if (isDeviceLocalBackupKey(key)) continue;
    if (key == categoryAppearanceKey) {
      if (value is String) {
        try {
          if (jsonDecode(value) is! Map) continue;
          final current = CategoryAppearance.decode(schema[key] is String ? schema[key] as String : null);
          for (final entry in CategoryAppearance.decode(value).entries) {
            current[entry.key] = {...?current[entry.key] as Map<String, dynamic>?, ...entry.value as Map<String, dynamic>};
          }
          result[key] = jsonEncode(current);
        } catch (_) {}
      }
      continue;
    }
    if (key == onlineWallpaperKey) {
      if (value is String && validOnlineWallpaperConfiguration(value)) result[key] = OnlineWallpaperConfiguration.decode(value).encode();
      continue;
    }
    if (key == weatherConfigurationKey) {
      if (value is! String || !validWeatherConfiguration(value)) continue;
      final configuration = WeatherConfiguration.decode(value);
      if (configuration.source != WeatherSource.breezy && !configuration.validCoordinates) continue;
      try { if (jsonDecode(value) is! Map) continue; } catch (_) { continue; }
      result[key] = jsonEncode(configuration.toJson());
      continue;
    }
    if (key == tvInputsConfigurationKey) {
      if (value is! String) continue;
      try { result[key] = TvInputsConfiguration.parse(jsonDecode(value) as Map).encode(); }
      catch (_) {}
      continue;
    }
    if (key == nightModeKey) {
      if (value is! String) continue;
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) result[key] = jsonEncode(NightModeConfiguration.parse(decoded).toJson());
      } catch (_) {}
      continue;
    }
    if (key == tileAppearanceKey) {
      if (value is String) result[key] = TileAppearance.merge(schema[key] is String ? schema[key] as String : '{}', value);
      continue;
    }
    if (!(value is bool || value is int || value is double || value is String ||
        (value is List && value.every((item) => item is String)))) {
      continue;
    }
    if (value is double && !value.isFinite) continue;
    final sample = key.startsWith('custom_banner_') ? '' : schema[key];
    if (sample != null) {
      if (sample is double && value is int) value = value.toDouble();
      if (!((sample is bool && value is bool) || (sample is int && value is int) ||
          (sample is double && value is double) || (sample is String && value is String) ||
          (sample is List && value is List))) {
        continue;
      }
    }
    if (!_validValue(key, value)) continue;
    result[key] = value;
  }
  return result;
}

bool _validValue(String key, dynamic value) {
  if (key == backupSyncGroupsKey) {
    try {
      disabledBackupSyncGroups(value);
      return true;
    } on FormatException {
      return false;
    }
  }
  if (key == 'wallpaper_fit') return ['cover', 'contain', 'blurred'].contains(value);
  if (['wallpaper_brightness', 'wallpaper_saturation', 'wallpaper_dimming'].contains(key)) {
    return value is num && value.isFinite && value >= 0 && value <= 2;
  }
  if (key == 'background_source') return ['gradient', 'picture', 'scheduled', 'online', 'slideshow', 'app'].contains(value);
  if (key == 'slideshow_interval') return value is int && [30, 60, 300, 600, 1800, 3600].contains(value);
  if (key == 'slideshow_recursive' || key == 'slideshow_random') return value is bool;
  if (key == 'automatic_backup_keep_count') return value is int && [1, 3, 5, 10].contains(value);
  if (key == 'automatic_backup_enabled') return value is bool;
  if (key == 'card_focus_mode') return value is String && ['remember', 'first', 'settings'].contains(value);
  const choices = {
    'app_banner_shape': ['modern', 'premium', 'classic', 'capsule'],
    'back_button_action': ['', 'CLOCK', 'SCREENSAVER'],
    'wifi_usage_period': ['daily', 'weekly', 'monthly'],
    'temperature_unit': ['celsius', 'fahrenheit'],
    'screensaver_clock_style': ['minimal', 'bold', 'retro', 'elegant', 'neon', 'pixel', 'digital'],
  };
  if (choices.containsKey(key)) return choices[key]!.contains(value);
  if (key == 'accent_color') return value is String && RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value);
  if (key == 'app_language') {
    return value == '' || AppLocalizations.supportedLocales.any((locale) => locale.languageCode == value);
  }
  if (key == 'brightness_transition_minutes') return value is int && value >= 1 && value <= 60;
  if (['brightness_sunrise', 'brightness_sunset', 'brightness_morning', 'brightness_day', 'brightness_afternoon', 'brightness_evening', 'brightness_night'].contains(key)) {
    return value is int && value >= 0 && value <= 100;
  }
  if (key == 'continue_watching_max_items' || key == 'continue_watching_order') {
    return value is int && value >= 0;
  }
  if (key == 'continue_watching_card_size') {
    return value is String && (['small', 'normal', 'large'].contains(value) ||
      ((int.tryParse(value) ?? 0) > 0 && (int.tryParse(value) ?? 0) <= 1000));
  }
  return true;
}

/// Runtime state and credentials must never travel with a portable settings copy.
bool isDeviceLocalBackupKey(String key) => key.startsWith('adb_') ||
    key.startsWith('settings_sync_') ||
    key.startsWith('cloud_') ||
    key.startsWith('backup_transport_') ||
    key.startsWith('automatic_backup_') ||
    key == 'slideshow_folder' ||
    key == 'weather_api_key' || key.startsWith('weather_api_key_') ||
    const {'weather_cache', 'online_wallpaper_cache', 'update_last_check',
      'update_pending_notification', 'update_shown_notification',
      'automatic_backup_last_success', 'overlay_permission', 'write_settings_permission',
      'accessibility_enabled', 'default_home', 'notification_permission'}.contains(key);
