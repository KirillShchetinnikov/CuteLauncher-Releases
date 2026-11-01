import '../adaptive_landscape.dart';

/// Only explicit screenshot builds expose manual scene controls.
const screenshotBuild = bool.fromEnvironment('CUTE_SCREENSHOT_MODE');

/// Session-only scene; never changes the system clock or saved weather data.
class ScreenshotScene {
  final DateTime now;
  final LandscapeWeather weather;

  const ScreenshotScene({required this.now, required this.weather});

  factory ScreenshotScene.initial() {
    final today = DateTime.now();
    return ScreenshotScene(
      now: DateTime(today.year, today.month, today.day, 16),
      weather: LandscapeWeather.cloudy,
    );
  }

  ScreenshotScene withTime({int? hour, int? minute}) => ScreenshotScene(
    now: DateTime(
      now.year,
      now.month,
      now.day,
      hour ?? now.hour,
      minute ?? now.minute,
    ),
    weather: weather,
  );

  ScreenshotScene withWeather(LandscapeWeather value) =>
      ScreenshotScene(now: now, weather: value);
}
