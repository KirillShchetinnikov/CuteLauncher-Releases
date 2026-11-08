import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:intl/intl.dart';

String? localizedWeatherCondition(int? code, AppLocalizations? l) =>
    switch (code) {
      800 => l?.weatherClear,
      801 || 802 || 803 || 804 => l?.weatherCloudy,
      701 || 711 || 721 || 741 || 751 => l?.weatherFog,
      771 => l?.weatherWind,
      _ => WeatherData.stormCodes.contains(code) ? l?.weatherStorm
          : WeatherData.snowCodes.contains(code) ? l?.weatherSnow
          : WeatherData.rainCodes.contains(code) ? l?.weatherRain : null,
    };

String? localizedWeatherWarning(WeatherData weather, AppLocalizations l10n, DateTime now) {
  var type = weather.warningType;
  var probability = weather.warningPrecipProbability;
  final today = weatherCalendarDay(now, weather.utcOffsetSeconds);
  var date = DateTime(today.year, today.month, today.day + (weather.warningDayIndex ?? 0));
  if (weather.forecasts.isNotEmpty) {
    type = WeatherWarningType.none;
    for (final item in weather.forecastDays(now, 7)) {
      final code = item.conditionCode;
      type = WeatherData.rainCodes.contains(code) ? WeatherWarningType.rain
          : WeatherData.snowCodes.contains(code) ? WeatherWarningType.snow
          : WeatherData.stormCodes.contains(code) ? WeatherWarningType.storm
          : WeatherWarningType.none;
      if (type == WeatherWarningType.none) continue;
      date = item.date!;
      probability = item.precipProbability;
      break;
    }
  } else if (!weather.hasWarning) {
    return null;
  }
  if (type == WeatherWarningType.none) return null;
  final condition = switch (type) {
    WeatherWarningType.rain => l10n.weatherRain,
    WeatherWarningType.snow => l10n.weatherSnow,
    WeatherWarningType.storm => l10n.weatherStorm,
    WeatherWarningType.none => '',
  };
  final tomorrow = DateTime(today.year, today.month, today.day + 1);
  final day = date == today ? l10n.weatherToday : date == tomorrow ? l10n.weatherTomorrow
      : l10n.weatherOnDay(DateFormat('EEE', l10n.localeName).format(date));
  final prefix = probability != null && probability > 0 ? '$probability% ' : '';
  return l10n.weatherWarning(prefix, condition, day);
}
