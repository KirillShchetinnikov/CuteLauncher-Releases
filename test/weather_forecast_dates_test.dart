import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/settings_import.dart';

void main() {
  test(
    'cached forecast keeps dates across midnight and uses the city offset',
    () {
      final instant = DateTime.utc(2026, 10, 28, 22);
      final raw = <String, dynamic>{
        'timestamp': instant.millisecondsSinceEpoch ~/ 1000,
        'utcOffsetSeconds': 10800,
        'forecasts': [
          for (var i = 0; i < 7; i++) {'minTemp': i, 'maxTemp': i + 1},
        ],
      };
      final parsed = WeatherData.fromJson(raw);
      expect(parsed.forecasts.first.date, DateTime(2026, 10, 29));
      final next = DateTime.utc(2026, 10, 29, 22);
      final restored = WeatherData.fromJson(
        jsonDecode(jsonEncode(raw)),
        referenceTime: next,
      );
      expect(restored.forecastDays(next, 3).map((e) => e.minTemp), [1, 2, 3]);
      expect(restored.forecasts.first.date, parsed.forecasts.first.date);
      expect(restored.forecastDays(DateTime.utc(2026, 11, 8), 7), isEmpty);
    },
  );

  test(
    'legacy cache without a timestamp anchors to fetchedAt, not read time',
    () {
      final data = WeatherData.fromJson({
        'forecasts': [
          {'minTemp': 1},
          {'minTemp': 2},
        ],
      }, referenceTime: DateTime(2026, 10, 28, 23));
      expect(data.forecastDays(DateTime(2026, 10, 29, 1), 5).single.minTemp, 2);
    },
  );

  test(
    'explicit dates preserve missing days and reject invalid calendar dates',
    () {
      final data = WeatherData.fromJson({
        'forecasts': [
          {'date': '2026-10-29', 'minTemp': 1},
          {'date': '2026-10-31', 'minTemp': 3},
        ],
      });
      expect(data.forecastDays(DateTime(2026, 10, 29), 3).map((e) => e.date), [
        DateTime(2026, 10, 29),
        DateTime(2026, 10, 31),
      ]);
      expect(parseWeatherDate('2026-02-30'), isNull);
    },
  );

  test(
    'Open-Meteo UTC timestamps and Yandex dates retain the location calendar',
    () {
      final midnight =
          DateTime.utc(2026, 10, 28, 15).millisecondsSinceEpoch ~/ 1000;
      final data = WeatherData.fromJson(
        normalizeOpenMeteo({
          'utc_offset_seconds': 32400,
          'current': {'time': midnight, 'temperature_2m': 20},
          'daily': {
            'time': [midnight, midnight + 86400],
            'weather_code': [0, 61],
          },
        }),
      );
      expect(data.forecasts.map((e) => e.date), [
        DateTime(2026, 10, 29),
        DateTime(2026, 10, 30),
      ]);
      expect(
        data.forecastDays(DateTime.utc(2026, 10, 28, 16), 3),
        hasLength(2),
      );
      final yandex = WeatherData.fromJson(
        normalizeYandex({
          'now': midnight,
          'info': {
            'tzinfo': {'offset': 32400},
          },
          'fact': {'temp': 20},
          'forecasts': [
            {
              'date': '2026-10-29',
              'parts': {
                'day': {'temp_min': 10, 'temp_max': 20},
              },
            },
          ],
        }),
      );
      expect(yandex.forecasts.single.date, DateTime(2026, 10, 29));
      expect(yandex.utcOffsetSeconds, 32400);
    },
  );

  test('forecast options and block action survive backup and reject invalid values', () {
    const fields = {
      'panelForecastDays': 7,
      'panelForecastView': 'list',
      'panelInformationAction': 'weather',
    };
    final encoded = jsonEncode(fields);
    final result = compatibleSettings(
      {tileAppearanceKey: encoded},
      {tileAppearanceKey: '{}'},
    );
    final restored = TileAppearance.decode(result[tileAppearanceKey]);
    expect(restored.forecastDays, 7);
    expect(restored.detailedForecast, isTrue);
    expect(restored.informationAction, 'weather');
    expect(
      TileAppearance.validValues({
        'panelForecastDays': 100,
        'panelForecastView': 'bad',
        'panelInformationAction': 'bad',
      }),
      isEmpty,
    );
    expect(const TileAppearance().informationAction, 'both');
    expect(
      const TileAppearance({'panelDateCalendar': true}).informationAction,
      'calendar',
    );
    expect(
      const TileAppearance({'panelDateCalendar': false}).informationAction,
      'none',
    );
  });
}
