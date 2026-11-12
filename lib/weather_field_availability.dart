import 'models/weather_data.dart';
import 'weather_sources.dart';
import 'weather_text_format.dart';

enum WeatherFieldUnavailable { unsupported, missing }

/// Null means no warning. An unloaded response is not a third UI state.
WeatherFieldUnavailable? weatherFieldUnavailable(
  WeatherTextField field,
  WeatherSource source,
  WeatherData? weather,
) {
  if (field == WeatherTextField.feelsLike &&
      (source == WeatherSource.metNorway || source == WeatherSource.gismeteo)) {
    return WeatherFieldUnavailable.unsupported;
  }
  if (weather == null) return null;
  final present = switch (field) {
    WeatherTextField.temperature => weather.currentTemp != null,
    WeatherTextField.feelsLike => weather.feelsLikeTemp != null,
    WeatherTextField.low => weather.todayMinTemp != null,
    WeatherTextField.high => weather.todayMaxTemp != null,
    WeatherTextField.wind => weather.windSpeed?.isFinite == true,
    WeatherTextField.humidity => weather.currentHumidity != null,
    WeatherTextField.city => weather.location?.trim().isNotEmpty == true,
    WeatherTextField.conditions || WeatherTextField.conditionsIcon =>
      weather.currentConditionCode != null ||
          weather.currentCondition?.trim().isNotEmpty == true,
    WeatherTextField.icon => weather.currentConditionCode != null,
    // No warning in a valid forecast is a normal result, not missing data.
    WeatherTextField.warning =>
      weather.hasWarning ||
          weather.forecasts.any((f) => f.conditionCode != null),
    WeatherTextField.text || WeatherTextField.lineBreak => true,
  };
  return present ? null : WeatherFieldUnavailable.missing;
}
