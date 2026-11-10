import 'dart:convert';

import 'custom_date_format.dart';
import 'date_time_format.dart';
import 'panel_clock_style.dart';
import 'tile_appearance.dart';
import 'weather_text_format.dart';

const sharedInformationDateTimeKey = 'information_datetime';
const sharedInformationWeatherKey = 'weather_information_display';
const sharedInformationClockBehaviorKey = 'information_clock_behavior';
const defaultInformationDateFormat = 'EEEE d';
const defaultInformationTimeFormat = 'H:mm';
const informationFormatKeys = [
  sharedInformationDateTimeKey,
  sharedInformationWeatherKey,
  sharedInformationClockBehaviorKey,
];

InformationClockBehavior legacyInformationClockBehavior(
  TileAppearance appearance, {
  required bool showTime,
}) => InformationClockBehavior.fromStyle(
  appearance.informationPlacement('time', visible: showTime) == 'background'
      ? appearance.backgroundInformationStyle
      : appearance.informationStyle,
);

InformationClockBehavior? decodeInformationClockBehavior(Object? raw) {
  if (raw is! String || raw.length > 256) return null;
  try {
    final value = jsonDecode(raw);
    if (value case {
      'showColon': final bool showColon,
      'animate': final bool animate,
    }) {
      return InformationClockBehavior(showColon: showColon, animate: animate);
    }
  } on FormatException {
    return null;
  }
  return null;
}

const legacyInformationFormatKeys = [
  'information_panel_datetime',
  'information_background_datetime',
  'weather_panel_display',
  'weather_background_display',
];

Map<String, String> migrateInformationFormats(
  Map<String, Object?> source, {
  Map<String, Object?> fallback = const {},
}) {
  final needsDateTime =
      InformationDateTimeFormat.decode(source[sharedInformationDateTimeKey]) ==
      null;
  final needsWeather =
      WeatherDisplayOptions.decode(source[sharedInformationWeatherKey]) == null;
  final panel = needsDateTime
      ? InformationDateTimeFormat.decode(source['information_panel_datetime'])
      : null;
  final background = needsDateTime
      ? InformationDateTimeFormat.decode(
          source['information_background_datetime'],
        )
      : null;
  final weatherOnPanel = needsWeather
      ? WeatherDisplayOptions.decode(source['weather_panel_display'])
      : null;
  final weatherOnBackground = needsWeather
      ? WeatherDisplayOptions.decode(source['weather_background_display'])
      : null;
  if (panel == null &&
      background == null &&
      weatherOnPanel == null &&
      weatherOnBackground == null) {
    return {};
  }

  Object? setting(String key) => source[key] ?? fallback[key];
  String? text(String key) => switch (setting(key)) {
    final String value => value,
    _ => null,
  };
  final appearance = TileAppearance.decode(text(tileAppearanceKey));
  bool onBackground(String id, bool visible) =>
      appearance.informationPlacement(id, visible: visible) == 'background';
  final time = onBackground('time', setting('show_time_in_status_bar') != false)
      ? background?.time
      : panel?.time;
  final date = onBackground('date', setting('show_date_in_status_bar') != false)
      ? background?.date
      : panel?.date;
  final weather =
      onBackground('weather', setting('show_weather_in_status_bar') == true)
      ? weatherOnBackground
      : weatherOnPanel;

  return {
    if (panel != null || background != null)
      sharedInformationDateTimeKey: InformationDateTimeFormat(
        time: time ?? text('time_format') ?? defaultInformationTimeFormat,
        date: date ?? text('date_format') ?? defaultInformationDateFormat,
      ).encode(),
    if (weatherOnPanel != null || weatherOnBackground != null)
      sharedInformationWeatherKey:
          (weather ??
                  WeatherDisplayOptions(
                    format:
                        WeatherTextFormat.tryDecode(
                          setting(weatherTextFormatKey),
                        ) ??
                        WeatherTextFormat.standard,
                    fahrenheit: setting('temperature_unit') == 'fahrenheit',
                    warnings: setting('show_weather_warnings') != false,
                  ))
              .encode(),
  };
}

class InformationDateTimeFormat {
  final String time, date;
  const InformationDateTimeFormat({required this.time, required this.date});
  String encode() => jsonEncode({'time': time, 'date': date});
  static InformationDateTimeFormat? decode(Object? raw) {
    if (raw is! String || raw.length > 4096) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map ||
          value['date'] is! String ||
          !const [
            'H:mm',
            'hh:mm',
            'h:mm a',
            'hh:mm a',
            'HH:mm',
          ].contains(value['time'])) {
        return null;
      }
      final date = value['date'] as String;
      if (date != compactDateFormat &&
          date != shortWeekdayDateFormat &&
          !validateCustomDatePattern(date).valid) {
        return null;
      }
      return InformationDateTimeFormat(
        time: value['time'] as String,
        date: date,
      );
    } on FormatException {
      return null;
    }
  }
}

/// Shared weather format and units, plus the legacy warning flag.
class WeatherDisplayOptions {
  final WeatherTextFormat format;
  final bool fahrenheit, warnings;
  const WeatherDisplayOptions({
    required this.format,
    required this.fahrenheit,
    required this.warnings,
  });
  String encode() => jsonEncode({
    'format': format.encode(),
    'fahrenheit': fahrenheit,
    'warnings': warnings,
  });
  static WeatherDisplayOptions? decode(Object? raw) {
    if (raw is! String || raw.length > 20000) return null;
    try {
      final value = jsonDecode(raw);
      if (value is! Map ||
          value['fahrenheit'] is! bool ||
          value['warnings'] is! bool) {
        return null;
      }
      final format = WeatherTextFormat.tryDecode(value['format']);
      if (format == null) return null;
      return WeatherDisplayOptions(
        format: format,
        fahrenheit: value['fahrenheit'] as bool,
        warnings: value['warnings'] as bool,
      );
    } on FormatException {
      return null;
    }
  }
}

String? validateInformationFormat(String key, Object? value) {
  if (key == sharedInformationClockBehaviorKey) {
    final behavior = decodeInformationClockBehavior(value);
    return behavior == null ? null : jsonEncode(behavior.toMap());
  }
  return key.startsWith('weather_')
      ? WeatherDisplayOptions.decode(value)?.encode()
      : InformationDateTimeFormat.decode(value)?.encode();
}
