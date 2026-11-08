import 'dart:convert';

import 'custom_date_format.dart';
import 'date_time_format.dart';
import 'weather_text_format.dart';

const informationFormatKeys = [
  'information_panel_datetime',
  'information_background_datetime',
  'weather_panel_display',
  'weather_background_display',
];

String informationDateTimeKey(bool background) =>
    background ? informationFormatKeys[1] : informationFormatKeys[0];
String informationWeatherKey(bool background) =>
    background ? informationFormatKeys[3] : informationFormatKeys[2];

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

/// One placement's saved weather format and units, plus its legacy warning flag.
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

String? validateInformationFormat(String key, Object? value) =>
    key.startsWith('weather_')
    ? WeatherDisplayOptions.decode(value)?.encode()
    : InformationDateTimeFormat.decode(value)?.encode();
