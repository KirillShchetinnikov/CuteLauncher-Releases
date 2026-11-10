import 'dart:convert';

import 'adaptive_landscape.dart';
import 'date_time_format.dart';
import 'sleep_timer_configuration.dart';
import 'tile_appearance.dart';
import 'weather_sources.dart';

/// Explicit first-run/reset values. Never merge these into existing preferences:
/// legacy getters keep their fallbacks so an update cannot restyle an old install.
abstract final class LauncherDefaults {
  static const appearance = <String, dynamic>{
    'settingsInterfaceStyle': 'standard',
    'settingsInterfaceFont': 'medeo-sans',
    'settingsTextSize': 16,
    'settingsColor': 0xff393939,
    'settingsOpacity': 1.0,
    'settingsScrollbarMode': 'onScroll',
    'settingsSectionStyle': 'surface',
    'size': 128,
    'aspectRatio': 16 / 9,
    'radius': 16,
    'horizontalGap': 6,
    'verticalGap': 6,
    'labels': 'none',
    'labelPosition': 'below',
    'labelSize': 14,
    'focusEffect': 'scale',
    'focusScale': 0.2,
    'focusBorderStyle': 'glow',
    'focusBorderColor': 'dynamic',
    'focusPulse': true,
    'focusShadow': false,
    'focusTransition': true,
    'animateReordering': true,
    'panelCombinedInformation': true,
    'panelTextSize': 16,
    'panelFont': 'medeo-sans',
    'panelTextBackground': true,
    'panelTextBackgroundOpacity': 0.5,
    'panelTextBackgroundColor': 0xff393939,
    'panelWrapNavigation': true,
    'sectionTitles': true,
    'sectionTitleSize': 24,
    'sectionIcons': true,
    'sectionTitleAligned': false,
    'noticeWidth': 360,
    'noticeColor': 0xff393939,
    'noticeOpacity': 0.8,
    'noticeTextSize': 16,
    'weatherIconPack': 'outline',
    'panelInformationAction': 'both',
    'panelInformationStyle': {
      'inheritPanelTypography': true,
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
      'systemSettings',
      'inputs',
      'sleepTimer',
      'notifications',
      'nightMode',
      'traffic',
      'networkSpeed',
      'system',
      'nas',
      'usb',
    ],
    'panelInfoOrder': ['network', 'vpn', 'audio', 'time', 'date', 'weather'],
  };
  static const landscape = LandscapeConfiguration(
    variant: 'realistic',
    motion: true,
    starRotation: true,
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
    tileAppearanceKey: jsonEncode({
      ...appearance,
      'sectionScroll': 'anchored',
      'sectionPosition': 0.2,
    }),
    'accent_color': 'FF6D00',
    'settings_menu_on_right': false,
    'background_source': 'landscape',
    landscapeSettingsKey: landscape.encode(),
    'card_focus_mode': 'first',
    'remember_category_focus': false,
    'hide_launcher_tile': true,
    'hide_android_settings_tile': true,
    'show_app_names_below_icons': false,
    'show_category_titles': true,
    'panel_tooltips_enabled': false,
    'auto_hide_notifications_widget': true,
    'show_weather_in_status_bar': true,
    'show_night_mode_in_status_bar': false,
    'show_volume_in_status_bar': true,
    'show_nas_in_status_bar': true,
    'show_usb_in_status_bar': true,
    'date_format': shortWeekdayDateFormat,
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
      'hidden': ['traffic', 'networkSpeed', 'system'],
      'leftOrder': appearance['panelButtonsOrder'],
      'rightOrder': appearance['panelInfoOrder'],
    }),
  };
}
