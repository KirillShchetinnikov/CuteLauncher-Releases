import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/weather_warning_text.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('warnings follow forecast calendar dates across midnight', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final weather = WeatherData.fromJson({
      'utcOffsetSeconds': 10800,
      'forecasts': [
        {'date': '2026-10-29', 'conditionCode': 500, 'precipProbability': 90},
        {'date': '2026-10-30', 'conditionCode': 800},
        {'date': '2026-10-31', 'conditionCode': 200, 'precipProbability': 70},
      ],
    });
    expect(localizedWeatherWarning(weather, l10n, DateTime.utc(2026, 10, 29, 21, 5)),
        '70% Storm tomorrow');
  });

  test('expired forecast warnings disappear', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final weather = WeatherData.fromJson({
      'forecasts': [
        {'date': '2026-10-29', 'conditionCode': 600},
        {'date': '2026-10-30', 'conditionCode': 800},
      ],
    });
    expect(localizedWeatherWarning(weather, l10n, DateTime(2026, 10, 30)), isNull);
  });
}
