import 'dart:convert';

import 'adaptive_landscape.dart';
import 'date_time_format.dart';
import 'sleep_timer_configuration.dart';
import 'tile_appearance.dart';
import 'weather_sources.dart';

/// Explicit first-run/reset values. Legacy getters intentionally keep their fallbacks.
abstract final class LauncherDefaults {
  static const appearance = <String, dynamic>{
    'settingsInterfaceStyle': 'glass',
    'settingsTextSize': 18,
    'settingsColor': 0xff242935,
    'settingsOpacity': 1.0,
    'size': 128,
    'aspectRatio': 16 / 9,
    'radius': 16,
    'horizontalGap': 16,
    'verticalGap': 16,
    'labels': 'all',
    'labelPosition': 'below',
    'labelSize': 14,
    'focusEffect': 'scale',
    'focusScale': 0.05,
    'focusBorderStyle': 'outline',
    'focusPulse': false,
    'focusTransition': true,
    'animateReordering': true,
    'panelCombinedInformation': true,
    'panelTextSize': 18,
    'panelInformationAction': 'both',
    'panelInformationStyle': {
      'size': 18,
      'weight': 400,
      'animate': false,
      'glow': false,
    },
    'panelClockStyle': {'animate': false},
    'panelForecastDays': 5,
    'panelForecastView': 'cards',
    'panelButtonsOrder': [
      'settings',
      'inputs',
      'sleepTimer',
      'systemSettings',
      'notifications',
      'nightMode',
      'traffic',
      'system',
    ],
    'panelInfoOrder': ['network', 'vpn', 'audio', 'time', 'date', 'weather'],
  };
  static const landscape = LandscapeConfiguration(
    variant: 'realistic',
    precipitation: false,
    fog: false,
  );
  static List<SleepTimerPreset> get timerPresets => [
    for (final preset in SleepTimerConfiguration.defaults)
      SleepTimerPreset(
        preset.id,
        preset.seconds,
        visible: const {600, 1800, 3600, 5400, 7200}.contains(preset.seconds),
      ),
  ];
  static Map<String, Object> get preferences => {
    tileAppearanceKey: jsonEncode({...appearance, 'sectionPosition': 0.1}),
    'background_source': 'landscape',
    landscapeSettingsKey: landscape.encode(),
    'card_focus_mode': 'remember',
    'hide_launcher_tile': true,
    'auto_hide_notifications_widget': true,
    'show_weather_in_status_bar': true,
    'show_night_mode_in_status_bar': false,
    'date_format': compactDateFormat,
    weatherConfigurationKey: jsonEncode(
      const WeatherConfiguration(
        source: WeatherSource.openMeteo,
        locationMode: WeatherLocationMode.manual,
      ).toJson(),
    ),
    sleepTimerConfigurationKey: SleepTimerConfiguration(
      showSeconds: false,
      presets: timerPresets,
    ).encode(),
    'remote_panel_configuration': jsonEncode({
      'inheritAppearance': true,
      'hidden': ['nightMode', 'traffic', 'system'],
      'leftOrder': appearance['panelButtonsOrder'],
      'rightOrder': appearance['panelInfoOrder'],
    }),
  };
}
