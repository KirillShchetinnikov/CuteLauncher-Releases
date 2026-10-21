/// Portable policy: even when every block is local, this choice is synchronized.
const backupSyncGroupsKey = 'backup_sync_disabled_groups';

enum BackupSyncGroup {
  sections,
  homeOptions,
  continueWatching,
  topPanel,
  background,
  tiles,
  accent,
  animations,
  menuLayout,
  clockStyle,
  weatherSource,
  weatherDisplay,
  nightMode,
  brightness,
  notificationSettings,
  startup,
  language,
  updates,
  memory,
  other,
}

enum BackupSyncSection {
  home,
  appearance,
  weather,
  display,
  notifications,
  controls,
  general,
}

const backupSyncSections = {
  BackupSyncSection.home: [
    BackupSyncGroup.sections,
    BackupSyncGroup.homeOptions,
    BackupSyncGroup.continueWatching,
    BackupSyncGroup.topPanel,
  ],
  BackupSyncSection.appearance: [
    BackupSyncGroup.background,
    BackupSyncGroup.tiles,
    BackupSyncGroup.accent,
    BackupSyncGroup.animations,
    BackupSyncGroup.menuLayout,
    BackupSyncGroup.clockStyle,
  ],
  BackupSyncSection.weather: [
    BackupSyncGroup.weatherSource,
    BackupSyncGroup.weatherDisplay,
  ],
  BackupSyncSection.display: [
    BackupSyncGroup.nightMode,
    BackupSyncGroup.brightness,
  ],
  BackupSyncSection.notifications: [BackupSyncGroup.notificationSettings],
  BackupSyncSection.controls: [BackupSyncGroup.startup],
  BackupSyncSection.general: [
    BackupSyncGroup.language,
    BackupSyncGroup.updates,
    BackupSyncGroup.memory,
    BackupSyncGroup.other,
  ],
};

// Old broad choices expand into their children without resetting local data.
const _legacyGroups = {
  'home': [
    BackupSyncGroup.sections,
    BackupSyncGroup.homeOptions,
    BackupSyncGroup.continueWatching,
    BackupSyncGroup.topPanel,
  ],
  'appearance': [
    BackupSyncGroup.background,
    BackupSyncGroup.tiles,
    BackupSyncGroup.accent,
    BackupSyncGroup.animations,
    BackupSyncGroup.menuLayout,
  ],
  'weather': [BackupSyncGroup.weatherSource, BackupSyncGroup.weatherDisplay],
  'display': [
    BackupSyncGroup.nightMode,
    BackupSyncGroup.brightness,
    BackupSyncGroup.clockStyle,
  ],
  'notifications': [
    BackupSyncGroup.notificationSettings,
    BackupSyncGroup.updates,
  ],
  'controls': [BackupSyncGroup.homeOptions, BackupSyncGroup.startup],
  'general': [
    BackupSyncGroup.language,
    BackupSyncGroup.updates,
    BackupSyncGroup.memory,
    BackupSyncGroup.other,
  ],
};

bool hasLegacyBackupSyncGroups(Object? value) =>
    value is List && value.any(_legacyGroups.containsKey);

Set<BackupSyncGroup> disabledBackupSyncGroups(Object? value) {
  if (value == null) return {};
  if (value is! List ||
      value.any(
        (v) =>
            v is! String ||
            (!_legacyGroups.containsKey(v) &&
                !BackupSyncGroup.values.any((group) => group.name == v)),
      )) {
    throw const FormatException('Invalid sync groups');
  }
  return {
    for (final group in BackupSyncGroup.values)
      if (value.contains(group.name)) group,
    for (final name in value) ...?_legacyGroups[name],
  };
}

BackupSyncGroup? backupSyncPartGroup(String part) {
  if (part == 'database') return BackupSyncGroup.sections;
  if (part == 'resources') return BackupSyncGroup.background;
  final key = part.substring('setting:'.length);
  if (key == backupSyncGroupsKey) return null;
  if (key == 'weather_configuration') return BackupSyncGroup.weatherSource;
  if (key.startsWith('weather_') ||
      key == 'show_weather_in_status_bar' ||
      key == 'show_weather_warnings' ||
      key == 'temperature_unit') {
    return BackupSyncGroup.weatherDisplay;
  }
  if (key.startsWith('night_')) return BackupSyncGroup.nightMode;
  if (key.startsWith('brightness_')) return BackupSyncGroup.brightness;
  if (key.startsWith('screensaver_')) return BackupSyncGroup.clockStyle;
  if (const {
    'automatic_update_checks',
    'update_prereleases',
    'show_update_notifications',
  }.contains(key)) {
    return BackupSyncGroup.updates;
  }
  if (key.contains('notification')) return BackupSyncGroup.notificationSettings;
  if (key == 'app_language') return BackupSyncGroup.language;
  if (key == 'memory_saver_enabled') return BackupSyncGroup.memory;
  if (key == 'start_on_boot') return BackupSyncGroup.startup;
  if (key == 'tile_appearance' || key == 'app_banner_shape') {
    return BackupSyncGroup.tiles;
  }
  if (key == 'accent_color') return BackupSyncGroup.accent;
  if (key == 'settings_menu_on_right') return BackupSyncGroup.menuLayout;
  if (const {
    'app_highlight_animation_enabled',
    'hide_highlight_outline_on_homescreen',
    'app_selector_transition_animation_enabled',
  }.contains(key)) {
    return BackupSyncGroup.animations;
  }
  if (key.startsWith('wallpaper_') ||
      key.startsWith('slideshow_') ||
      key.startsWith('custom_banner_') ||
      const {
        'background_source',
        'gradient_uuid',
        'time_based_wallpaper_enabled',
        'online_wallpaper',
      }.contains(key)) {
    return BackupSyncGroup.background;
  }
  if (key == 'category_appearance' || key.startsWith('tv_apps_section_')) {
    return BackupSyncGroup.sections;
  }
  if (key.startsWith('continue_watching_') ||
      key.startsWith('hidden_watch_next_') ||
      key.startsWith('watch_next_') ||
      key == 'show_continue_watching') {
    return BackupSyncGroup.continueWatching;
  }
  if (const {
    'auto_hide_app_bar',
    'show_date_in_status_bar',
    'show_time_in_status_bar',
    'date_format',
    'time_format',
    'wifi_usage_period',
    'show_wifi_widget_in_status_bar',
    'show_network_indicator_in_status_bar',
    'show_inputs_widget_in_status_bar',
    'tv_inputs_configuration',
    'show_system_settings_in_status_bar',
    'show_sleep_timer_in_status_bar',
    'show_night_mode_in_status_bar',
    'show_now_playing',
  }.contains(key)) {
    return BackupSyncGroup.topPanel;
  }
  if (const {
    'back_button_action',
    'app_key_click_enabled',
    'card_focus_mode',
    'remember_category_focus',
    'show_category_titles',
    'show_app_names_below_icons',
    'hide_launcher_tile',
    'hide_android_settings_tile',
  }.contains(key)) {
    return BackupSyncGroup.homeOptions;
  }
  return BackupSyncGroup.other;
}

bool backupSyncPartEnabled(String part, Map settings) =>
    !disabledBackupSyncGroups(settings[backupSyncGroupsKey])
        .contains(backupSyncPartGroup(part));
