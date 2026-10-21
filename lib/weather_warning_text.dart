import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:intl/intl.dart';

String? localizedWeatherWarning(WeatherData weather, AppLocalizations l10n, DateTime now) {
  if (!weather.hasWarning || weather.warningType == WeatherWarningType.none) return null;
  final condition = switch (weather.warningType) {
    WeatherWarningType.rain => l10n.weatherRain,
    WeatherWarningType.snow => l10n.weatherSnow,
    WeatherWarningType.storm => l10n.weatherStorm,
    WeatherWarningType.none => '',
  };
  final index = weather.warningDayIndex ?? 0;
  final day = index == 0 ? l10n.weatherToday : index == 1 ? l10n.weatherTomorrow
      : l10n.weatherOnDay(DateFormat('EEE', l10n.localeName).format(
          DateTime(now.year, now.month, now.day + index)));
  final probability = weather.warningPrecipProbability;
  final prefix = probability != null && probability > 0 ? '$probability% ' : '';
  return l10n.weatherWarning(prefix, condition, day);
}
