import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../adaptive_landscape.dart';
import '../../diagnostics/screenshot_scene.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'settings_help.dart';
import 'settings_value_stepper.dart';

/// Available only in the explicitly opted-in screenshot APK.
class ScreenshotSceneControls extends StatelessWidget {
  const ScreenshotSceneControls({super.key});

  @override
  Widget build(BuildContext context) {
    if (!screenshotBuild) return const SizedBox.shrink();
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final scene = settings.screenshotScene;
    return Column(
      children: [
        RoundedSwitchListTile(
          title: Text(l.screenshotSceneMode),
          value: scene != null,
          onChanged: (enabled) => settings.setScreenshotScene(
            enabled ? ScreenshotScene.initial() : null,
          ),
        ),
        if (scene != null) ...[
          SettingsValueStepper(
            title: l.screenshotSceneHour,
            value: scene.now.hour,
            options: List.generate(24, (hour) => hour),
            useSlider: false,
            label: (value) => value.toString().padLeft(2, '0'),
            onChanged: (value) =>
                settings.setScreenshotScene(scene.withTime(hour: value as int)),
          ),
          SettingsValueStepper(
            title: l.screenshotSceneMinute,
            value: scene.now.minute,
            options: List.generate(60, (minute) => minute),
            useSlider: false,
            label: (value) => value.toString().padLeft(2, '0'),
            onChanged: (value) => settings.setScreenshotScene(
              scene.withTime(minute: value as int),
            ),
          ),
          SettingsChoiceTile<LandscapeWeather>(
            title: l.weather,
            value: scene.weather,
            options: LandscapeWeather.values,
            label: (value) => switch (value) {
              LandscapeWeather.clear => l.landscapeDemoClear,
              LandscapeWeather.cloudy => l.landscapeDemoCloudy,
              LandscapeWeather.rain => l.weatherRain,
              LandscapeWeather.snow => l.weatherSnow,
              LandscapeWeather.fog => l.landscapeDemoFog,
            },
            onChanged: (value) =>
                settings.setScreenshotScene(scene.withWeather(value)),
          ),
        ],
        SettingsHelp(text: l.screenshotSceneHelp),
      ],
    );
  }
}
