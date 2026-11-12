import 'dart:convert';

import 'package:flauncher/information_formats.dart';
import 'package:flauncher/l10n/app_localizations_ru.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/weather_field_availability.dart';
import 'package:flauncher/weather_format_template.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/weather_text_format.dart';
import 'package:flauncher/widgets/weather_display_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = AppLocalizationsRu();
  test('missing values use dashes with affixes; no alert stays empty', () {
    final format = parseWeatherTemplate(
      '{TEMP} ({MIN}) / {MAX}{BR}{HUM} {WIND} ({WARN})',
    ).format!;
    const data = WeatherData(currentTemp: 0, currentHumidity: 0, windSpeed: 0);
    expect(
      format.format(data, l, fahrenheit: false, missingAsDash: true),
      '0°C (—) / —\n0% 0 м/с',
    );
    expect(format.format(data, l, fahrenheit: false), '0°C  /\n0% 0 м/с');
    expect(
      format.format(null, l, fahrenheit: false, missingAsDash: true),
      '— (—) / —\n— —',
    );
  });

  test('missing condition and icon do not become an invented cloud', () {
    final format = parseWeatherTemplate('{ICON} {COND}').format!;
    expect(format.format(const WeatherData(currentCondition: 'Sunny'), l, fahrenheit: false), 'Sunny');
    expect(
      format.format(
        const WeatherData(),
        l,
        fahrenheit: false,
        missingAsDash: true,
      ),
      '— —',
    );
    expect(format.format(const WeatherData(), l, fahrenheit: false), '—');
  });

  test('options survive serialization, unit edits and backup validation', () {
    final format = parseWeatherTemplate('{TEMP}{BR}{MIN}').format!;
    final options = WeatherDisplayOptions(
      format: format,
      fahrenheit: false,
      warnings: false,
      missingAsDash: true,
      panelAlignment: 'right',
    );
    final updated = options.copyWith(fahrenheit: true);
    final decoded = WeatherDisplayOptions.decode(updated.encode())!;
    expect(decoded.missingAsDash, isTrue);
    expect(decoded.panelAlignment, 'right');
    expect(decoded.fahrenheit, isTrue);
    expect(
      compatibleSettings({sharedInformationWeatherKey: updated.encode()}, {}),
      {sharedInformationWeatherKey: updated.encode()},
    );
    final legacy = jsonDecode(options.encode()) as Map;
    legacy.remove('missingAsDash');
    legacy.remove('panelAlignment');
    expect(
      WeatherDisplayOptions.decode(jsonEncode(legacy))!.panelAlignment,
      'left',
    );
    expect(
      WeatherDisplayOptions.decode(
        jsonEncode({...legacy, 'panelAlignment': 'wrong'}),
      ),
      isNull,
    );
  });

  test('only unsupported and missing states; no false missing warning before fetch', () {
    expect(
      weatherFieldUnavailable(
        WeatherTextField.feelsLike,
        WeatherSource.metNorway,
        null,
      ),
      WeatherFieldUnavailable.unsupported,
    );
    expect(
      weatherFieldUnavailable(
        WeatherTextField.feelsLike,
        WeatherSource.gismeteo,
        const WeatherData(),
      ),
      WeatherFieldUnavailable.unsupported,
    );
    expect(
      weatherFieldUnavailable(
        WeatherTextField.low,
        WeatherSource.openWeather,
        null,
      ),
      isNull,
    );
    expect(
      weatherFieldUnavailable(
        WeatherTextField.low,
        WeatherSource.openWeather,
        const WeatherData(),
      ),
      WeatherFieldUnavailable.missing,
    );
    expect(
      weatherFieldUnavailable(
        WeatherTextField.low,
        WeatherSource.openWeather,
        const WeatherData(todayMinTemp: 0),
      ),
      isNull,
    );
    expect(
      weatherFieldUnavailable(
        WeatherTextField.warning,
        WeatherSource.openWeather,
        const WeatherData(forecasts: [WeatherForecastItem(conditionCode: 800)]),
      ),
      isNull,
    );
  });

  for (final direction in TextDirection.values) {
    for (final alignment in ['left', 'center', 'right']) {
      testWidgets(
        'weather lines align $alignment with $direction including inline icons',
        (tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Directionality(
                textDirection: direction,
                child: Center(
                  child: WeatherDisplayText(
                    'Long weather description\n7° $weatherInlineIcon',
                    style: const TextStyle(fontSize: 20),
                    maxWidth: 300,
                    alignment: alignment,
                    inlineIcon: const SizedBox(width: 20, height: 20),
                  ),
                ),
              ),
            ),
          );
          final lines = find.descendant(
            of: find.byType(WeatherDisplayText),
            matching: find.byType(Text),
          );
          final a = tester.getRect(lines.at(0)),
              b = tester.getRect(lines.at(1));
          switch (alignment) {
            case 'left':
              expect(b.left, closeTo(a.left, .1));
            case 'right':
              expect(b.right, closeTo(a.right, .1));
            case 'center':
              expect(b.center.dx, closeTo(a.center.dx, .1));
          }
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
