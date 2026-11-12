import 'dart:convert';

import 'package:flutter/widgets.dart' show StringCharacters;
import 'package:intl/intl.dart';

import 'l10n/app_localizations.dart';
import 'models/weather_data.dart';
import 'weather_warning_text.dart';

const weatherTextFormatKey = 'weather_text_format';
const maxWeatherTextBlocks = 64;
const maxWeatherBlockText = 60;
const weatherInlineIcon = '\uFFFC';
final weatherTextLineBreak = RegExp(r'[\r\n\u0085\u2028\u2029]+');

enum WeatherTextField {
  temperature,
  feelsLike,
  conditions,
  wind,
  humidity,
  city,
  low,
  high,
  conditionsIcon,
  icon,
  warning,
  text,
  lineBreak;

  bool get isValue => this != text && this != lineBreak;
}

class WeatherTextBlock {
  const WeatherTextBlock(this.field, {this.before = '', this.after = ''});

  final WeatherTextField field;
  // A text block uses before for its entire literal value.
  final String before, after;

  List<String> toJson() => [field.name, before, after];
}

class WeatherTextFormat {
  const WeatherTextFormat._(this.blocks, {this.explicitLayout = false});

  static const standard = WeatherTextFormat._([
    WeatherTextBlock(WeatherTextField.temperature),
  ]);

  final List<WeatherTextBlock> blocks;

  /// New templates place their own icons and warnings; legacy formats keep the
  /// surrounding weather widget's defaults until edited.
  final bool explicitLayout;
  bool get isStandard => identical(this, standard);

  static WeatherTextFormat? fromBlocks(
    List<WeatherTextBlock> blocks, {
    bool explicitLayout = false,
  }) {
    if (blocks.length > maxWeatherTextBlocks ||
        !blocks.any((block) => block.field.isValue)) {
      return null;
    }
    final breaks = blocks
        .where((block) => block.field == WeatherTextField.lineBreak)
        .length;
    if (breaks > 1) return null;
    for (final block in blocks) {
      if (!_validText(block.before) || !_validText(block.after)) return null;
      if (!block.field.isValue && block.after.isNotEmpty) return null;
      if (block.field == WeatherTextField.lineBreak &&
          block.before.isNotEmpty) {
        return null;
      }
    }
    final first = blocks.first;
    if (!explicitLayout &&
        blocks.length == 1 &&
        first.field == WeatherTextField.temperature &&
        first.before.isEmpty &&
        first.after.isEmpty) {
      return standard;
    }
    return WeatherTextFormat._(
      List.unmodifiable(blocks),
      explicitLayout: explicitLayout,
    );
  }

  static bool _validText(String value) =>
      value.length <= maxWeatherBlockText * 4 &&
      value.characters.length <= maxWeatherBlockText &&
      !value.contains(weatherTextLineBreak);

  static WeatherTextFormat? tryDecode(Object? raw) {
    if (raw is! String || raw.length > 10000) return null;
    try {
      final decoded = jsonDecode(raw);
      final explicit = decoded is Map;
      if (explicit && (decoded['version'] != 2 || decoded['blocks'] is! List)) {
        return null;
      }
      final items = explicit ? decoded['blocks'] : decoded;
      if (items is! List || items.length > maxWeatherTextBlocks) return null;
      final blocks = <WeatherTextBlock>[];
      for (final item in items) {
        if (item case [String name, String before, String after]) {
          blocks.add(
            WeatherTextBlock(
              WeatherTextField.values.byName(name),
              before: before,
              after: after,
            ),
          );
        } else {
          return null;
        }
      }
      return fromBlocks(blocks, explicitLayout: explicit);
    } on FormatException {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  String encode() {
    final items = [for (final block in blocks) block.toJson()];
    return jsonEncode(explicitLayout ? {'version': 2, 'blocks': items} : items);
  }

  String format(
    WeatherData? weather,
    AppLocalizations? l, {
    required bool fahrenheit,
    bool warningsAvailable = true,
    bool missingAsDash = false,
    DateTime? now,
  }) {
    if (isStandard) {
      return weather?.formatTemperature(useFahrenheit: fahrenheit) ?? '—';
    }
    if (weather == null && !missingAsDash) return '—';
    weather ??= const WeatherData();
    String? temperature(int? value) => value == null
        ? null
        : WeatherData.formatDegrees(value, useFahrenheit: fahrenheit);
    final text = StringBuffer();
    for (final block in blocks) {
      final value = switch (block.field) {
        WeatherTextField.temperature => temperature(weather.currentTemp),
        WeatherTextField.feelsLike => temperature(weather.feelsLikeTemp),
        WeatherTextField.conditions =>
          localizedWeatherCondition(weather.currentConditionCode, l) ??
              weather.currentCondition,
        WeatherTextField.conditionsIcon => weather.currentConditionCode == null &&
          (weather.currentCondition == null || weather.currentCondition!.trim().isEmpty) ? null : [
          localizedWeatherCondition(weather.currentConditionCode, l) ??
              weather.currentCondition,
          if (weather.currentConditionCode != null) weatherInlineIcon,
        ].whereType<String>().where((s) => s.trim().isNotEmpty).join(' '),
        WeatherTextField.icon => weather.currentConditionCode == null ? null : weatherInlineIcon,
        WeatherTextField.warning =>
          warningsAvailable && weather.hasWarning
              ? (l == null
                    ? weather.warningText
                    : localizedWeatherWarning(
                        weather,
                        l,
                        now ?? DateTime.now(),
                      ))
              : null,
        WeatherTextField.wind => _wind(weather.windSpeed, l),
        WeatherTextField.humidity =>
          weather.currentHumidity == null
              ? null
              : '${weather.currentHumidity}%',
        WeatherTextField.city => weather.location,
        WeatherTextField.low => temperature(weather.todayMinTemp),
        WeatherTextField.high => temperature(weather.todayMaxTemp),
        WeatherTextField.text => block.before,
        WeatherTextField.lineBreak => '\n',
      };
      if (!block.field.isValue) {
        text.write(value);
      } else if (value != null && value.trim().isNotEmpty) {
        text
          ..write(block.before)
          ..write(_singleLine(value))
          ..write(block.after);
      } else if (missingAsDash && block.field != WeatherTextField.warning) {
        text..write(block.before)..write('—')..write(block.after);
      }
    }
    final lines = text
        .toString()
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty);
    return lines.isEmpty ? '—' : lines.join('\n');
  }

  static String _singleLine(String value) =>
      value.replaceAll(weatherTextLineBreak, ' ').trim();

  static String? _wind(double? speed, AppLocalizations? l) {
    if (speed == null || !speed.isFinite) return null;
    final value = NumberFormat.decimalPattern(l?.localeName)
        .format((speed * 10).roundToDouble() / 10);
    return l?.weatherTextMetersPerSecond(value) ?? '$value m/s';
  }
}
