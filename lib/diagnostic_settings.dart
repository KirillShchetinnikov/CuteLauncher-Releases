import 'dart:convert';

/// Only behavior/style settings; credentials, chosen content and device identifiers are excluded.
class DiagnosticSettings {
  static const preferenceKeys = {
    'tile_appearance',
    'night_mode_configuration',
    'weather_configuration',
    'online_wallpaper',
    'wallpaper_landscape',
    'sleep_timer_configuration',
    'tv_inputs_configuration',
    'panel_clock_styles',
    'home_style',
    'system_notifications_popup',
    'hide_persistent_notifications',
    'automatic_update_checks',
    'update_prereleases',
    'show_update_notifications',
    'brightness_scheduler_enabled',
    'brightness_solar',
    'brightness_transition_minutes',
    'brightness_sunrise',
    'brightness_sunset',
    'brightness_morning',
    'brightness_day',
    'brightness_afternoon',
    'brightness_evening',
    'brightness_night',
  };
  static final _excluded = RegExp(
    r'password|secret|token|credential|account|username|latitude|longitude|coordinates|(?:^|_)(?:lat|lon|ip|mac|ssid|bssid|url|uri|path|file|folder|name|title|text|body|content|package|packages|target|id|ids|key|keys|cache)(?:_|$)|fingerprint|serial|location|city|subreddit|excludedApps|ignoredHdmiInput|ignoredPictureModes|custom',
    caseSensitive: false,
  );
  static const _tokens = {
    '',
    'default',
    'system',
    'none',
    'off',
    'on',
    'auto',
    'all',
    'minimal',
    'modern',
    'standard',
    'glass',
    'soft',
    'outline',
    'gradient',
    'picture',
    'scheduled',
    'online',
    'slideshow',
    'app',
    'landscape',
    'cover',
    'contain',
    'blurred',
    'left',
    'right',
    'top',
    'bottom',
    'topLeft',
    'topRight',
    'bottomLeft',
    'bottomRight',
    'center',
    'start',
    'end',
    'normal',
    'small',
    'large',
    'daily',
    'weekly',
    'monthly',
    'celsius',
    'fahrenheit',
    'C',
    'F',
    'breezy',
    'metNorway',
    'openWeather',
    'yandex',
    'bing',
    'reddit',
    'fixed',
    'random',
    'manual',
    'solar',
    'light',
    'dark',
    'spring',
    'summer',
    'autumn',
    'winter',
    'day',
    'night',
    'sunrise',
    'sunset',
    'nothing',
    'screensaver',
    'sleep',
    'apps',
    'home',
    'remember',
    'first',
    'below', 'inside', 'selected', 'free', 'anchored', 'scale', 'border', 'lift',
    'accent', 'dynamic', 'glow', 'row', 'grid',
    'roboto',
    'notoserif',
    'robotomono',
    'robotocondensed',
    'outfit',
    'manrope',
    'onest',
    'googlesans',
  };

  static Map<String, Object> sanitize(Map<dynamic, dynamic> source) {
    var remaining = 512;
    Map<String, Object> project(Map<dynamic, dynamic> input, int depth) {
      final output = <String, Object>{};
      if (depth > 4) return output;
      for (final entry in input.entries.take(256)) {
        if (remaining-- <= 0) break;
        final key = entry.key;
        if (key is! String ||
            !RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{0,79}$').hasMatch(key) ||
            _excluded.hasMatch(key)) {
          continue;
        }
        var value = entry.value;
        if (value is String &&
            preferenceKeys.contains(key) &&
            value.length <= 65536) {
          try {
            value = jsonDecode(value);
          } catch (_) {
            /* Scalar settings are checked below. */
          }
        }
        if (value is bool ||
            value is num && value.isFinite && value.abs() <= (1 << 53)) {
          output[key] = value as Object;
        } else if (value is String &&
            (_tokens.contains(value) ||
                key == 'app_language' &&
                    RegExp(r'^[a-z]{2}(?:_[A-Z]{2})?$').hasMatch(value) ||
                key.toLowerCase().contains('color') &&
                    RegExp(r'^#?[A-Fa-f0-9]{6,8}$').hasMatch(value))) {
          output[key] = value;
        } else if (value is Map) {
          final nested = project(value, depth + 1);
          if (nested.isNotEmpty) output[key] = nested;
        }
        // Lists of applications, input IDs and user content are intentionally excluded.
      }
      return output;
    }

    return project(source, 0);
  }
}
