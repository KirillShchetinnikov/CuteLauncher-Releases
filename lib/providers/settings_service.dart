import '../tv_inputs_configuration.dart';
import 'online_wallpaper_service.dart';
// Historical constants and enum names are preserved for upstream and serialized data compatibility.
// ignore_for_file: constant_identifier_names

/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'service_lifecycle.dart';
import 'dart:async';
import 'dart:convert';
import '../watch_next_selection.dart';
import '../settings_import.dart';
import '../l10n/app_localizations.dart';

import 'package:flauncher/widgets/settings/back_button_actions.dart';
import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

const _appHighlightAnimationEnabledKey = "app_highlight_animation_enabled";
const _memorySaverEnabledKey = "memory_saver_enabled";
const _appKeyClickEnabledKey = "app_key_click_enabled";
const _autoHideAppBarKey = "auto_hide_app_bar";
const _gradientUuidKey = "gradient_uuid";
const _backButtonActionKey = "back_button_action";
const _dateFormatKey = "date_format";
const _showCategoryTitlesKey = "show_category_titles";
const _showAppNamesBelowIconsKey = "show_app_names_below_icons";
const _themesKey = "app_banner_shape";
const _hideHighlightOutlineOnHomescreenKey = "hide_highlight_outline_on_homescreen";
const _appSelectorTransitionAnimationEnabledKey = "app_selector_transition_animation_enabled";
const _showDateInStatusBarKey = "show_date_in_status_bar";
const _showTimeInStatusBarKey = "show_time_in_status_bar";
const _timeFormatKey = "time_format";
const _dataUsagePeriodKey = "wifi_usage_period";
const _showDataWidgetInStatusBarKey = "show_wifi_widget_in_status_bar";
const String _showNetworkIndicatorInStatusBarKey = "show_network_indicator_in_status_bar";
const String _accentColorKey = "accent_color";
const String _screensaverClockStyleKey = "screensaver_clock_style";
const String _timeBasedWallpaperEnabledKey = "time_based_wallpaper_enabled";
const String _showInputsWidgetInStatusBarKey = "show_inputs_widget_in_status_bar";
const String _showSystemSettingsInStatusBarKey = "show_system_settings_in_status_bar";
const String _hideLauncherTileKey = "hide_launcher_tile";
const String _hideAndroidSettingsTileKey = "hide_android_settings_tile";
const String _showContinueWatchingKey = "show_continue_watching";
const String _continueWatchingCardSizeKey = "continue_watching_card_size";
const String _continueWatchingMaxItemsKey = "continue_watching_max_items";
const String _continueWatchingShowProgressKey = "continue_watching_show_progress";
const String _continueWatchingShowPercentageKey = "continue_watching_show_percentage";
const String _continueWatchingShowDescriptionKey = "continue_watching_show_description";
const String _continueWatchingOrderKey = "continue_watching_order";
const String _hiddenWatchNextProgramIdsKey = "hidden_watch_next_program_ids";
const String _hiddenWatchNextPackagesKey = "hidden_watch_next_packages";
const String _startOnBootKey = "start_on_boot";
const String _showNotificationsWidgetInStatusBarKey = "show_notifications_widget_in_status_bar";
const String _autoHideNotificationsWidgetKey = "auto_hide_notifications_widget";
const String _appLanguageKey = "app_language";
const String _showWeatherInStatusBarKey = "show_weather_in_status_bar";
const String _showWeatherWarningsKey = "show_weather_warnings";
const String _temperatureUnitKey = "temperature_unit";

const String TEMPERATURE_UNIT_CELSIUS = "celsius";
const String TEMPERATURE_UNIT_FAHRENHEIT = "fahrenheit";

// WiFi usage period options
const String DATA_USAGE_DAILY = "daily";
const String DATA_USAGE_WEEKLY = "weekly";
const String DATA_USAGE_MONTHLY = "monthly";

// Accent color presets (hex values)
const String ACCENT_COLOR_PURPLE = "7C4DFF";
const String ACCENT_COLOR_TEAL = "00BFA5";
const String ACCENT_COLOR_BLUE = "2979FF";
const String ACCENT_COLOR_ORANGE = "FF6D00";
const String ACCENT_COLOR_PINK = "F50057";
const String ACCENT_COLOR_GREEN = "00C853";
const String ACCENT_COLOR_WHITE = "FFFFFF";
const String ACCENT_COLOR_YELLOW = "FFD600";
const String ACCENT_COLOR_RED = "D50000";
const String ACCENT_COLOR_CYAN = "00E5FF";
const String ACCENT_COLOR_INDIGO = "536DFE";
const String ACCENT_COLOR_LIME = "AEEA00";
const String ACCENT_COLOR_AMBER = "FFAB00";
const String ACCENT_COLOR_ROSE = "FF4081";
const String ACCENT_COLOR_ICE_BLUE = "80D8FF";

enum CardFocusMode { remember, first, settings }

class SettingsService extends ChangeNotifier with ServiceLifecycle {
  static final defaultDateFormat = "EEEE d";
  static final defaultTimeFormat = "H:mm";
  final SharedPreferences _sharedPreferences;

  late bool _appHighlightAnimationEnabled;
  late bool _appKeyClickEnabled;
  late bool _memorySaverEnabled;
  bool get memorySaverEnabled => _memorySaverEnabled;
  late bool _autoHideAppBarEnabled;
  late bool _showCategoryTitles;
  late bool _showAppNamesBelowIcons;
  late bool _hideHighlightOutlineOnHomescreen;
  late bool _appSelectorTransitionAnimationEnabled;
  late bool _showDateInStatusBar;
  late bool _showTimeInStatusBar;
  late String? _gradientUuid;
  late String _backButtonAction;
  late String _dateFormat;
  late String _timeFormat;
  late String _dataUsagePeriod;
  late bool _showDataWidgetInStatusBar;
  late bool _showNetworkIndicatorInStatusBar;
  late String _accentColorHex;
  late String _screensaverClockStyle;
  late bool _timeBasedWallpaperEnabled;
  late bool _showInputsWidgetInStatusBar;
  late bool _showSystemSettingsInStatusBar;
  late bool _hideLauncherTile;
  late bool _hideAndroidSettingsTile;
  late bool _showContinueWatching;
  late String _continueWatchingCardSize;
  late int _continueWatchingMaxItems;
  late bool _continueWatchingShowProgress;
  late bool _continueWatchingShowPercentage;
  late bool _continueWatchingShowDescription;
  late int _continueWatchingOrder;
  late List<String> _hiddenWatchNextProgramIds;
  late List<String> _hiddenWatchNextPackages;
  late bool _startOnBoot;
  late bool _showNotificationsWidgetInStatusBar;
  late bool _autoHideNotificationsWidget;
  late String _appLanguage;
  late bool _showWeatherInStatusBar;
  late bool _showWeatherWarnings;
  late String _temperatureUnit;

  bool get appHighlightAnimationEnabled => _appHighlightAnimationEnabled;

  bool get appKeyClickEnabled => _appKeyClickEnabled;

  bool get autoHideAppBarEnabled => _autoHideAppBarEnabled;

  bool get showCategoryTitles => _showCategoryTitles;

  bool get showAppNamesBelowIcons => _showAppNamesBelowIcons;

  String get themes => 'modern';
  String get wallpaperFit => _sharedPreferences.getString('wallpaper_fit') ?? 'cover';
  double get wallpaperBrightness => _sharedPreferences.getDouble('wallpaper_brightness') ?? 1;
  double get wallpaperSaturation => _sharedPreferences.getDouble('wallpaper_saturation') ?? 1;
  double get wallpaperDimming => _sharedPreferences.getDouble('wallpaper_dimming') ?? 1;

  Future<void> setWallpaperFit(String value) async {
    if (!['cover', 'contain', 'blurred'].contains(value)) return;
    await _sharedPreferences.setString('wallpaper_fit', value);
    notifyListeners();
  }

  Future<void> setWallpaperAdjustment(String key, double value) async {
    if (!['wallpaper_brightness', 'wallpaper_saturation', 'wallpaper_dimming'].contains(key) ||
        !value.isFinite || value < 0 || value > 2) {
      return;
    }
    await _sharedPreferences.setDouble(key, value);
    notifyListeners();
  }
  String get backgroundSource => _sharedPreferences.getString('background_source') ??
      (OnlineWallpaperConfiguration.decode(_sharedPreferences.getString(onlineWallpaperKey)).enabled
          ? 'online' : timeBasedWallpaperEnabled ? 'scheduled' : 'picture');
  Future<void> setBackgroundSource(String source) async {
    if (!['gradient', 'picture', 'scheduled', 'online', 'slideshow', 'app'].contains(source)) return;
    await _sharedPreferences.setString('background_source', source);
    await setTimeBasedWallpaperEnabled(source == 'scheduled');
    notifyListeners();
  }
  Future<void> resetAppearanceSettings() async {
    for (final key in [_gradientUuidKey, _accentColorKey, _themesKey,
      _showAppNamesBelowIconsKey, _hideHighlightOutlineOnHomescreenKey,
      _appHighlightAnimationEnabledKey, _appSelectorTransitionAnimationEnabledKey,
      _timeBasedWallpaperEnabledKey, _screensaverClockStyleKey, 'settings_menu_on_right', 'background_source', 'wallpaper_fit',
      'wallpaper_brightness', 'wallpaper_saturation', 'wallpaper_dimming']) {
      await _sharedPreferences.remove(key);
    }
    await _sharedPreferences.setString('background_source', 'gradient');
    reload();
    notifyListeners();
  }

  Future<void> resetAppearanceSection(String section) async {
    final keys = switch (section) {
      'tiles' => [_themesKey, _showAppNamesBelowIconsKey],
      'focus' => [_hideHighlightOutlineOnHomescreenKey,
        _appHighlightAnimationEnabledKey, _appSelectorTransitionAnimationEnabledKey],
      'settings' => ['settings_menu_on_right'],
      'accent' => [_accentColorKey],
      'clock' => [_screensaverClockStyleKey],
      'wallpaperDisplay' => ['wallpaper_fit', 'wallpaper_brightness', 'wallpaper_saturation', 'wallpaper_dimming'],
      'background' => [_gradientUuidKey, _timeBasedWallpaperEnabledKey, 'background_source'],
      'panel' => ['auto_hide_app_bar'],
      _ => <String>[],
    };
    for (final key in keys) { await _sharedPreferences.remove(key); }
    reload();
    notifyListeners();
  }

  bool get hideHighlightOutlineOnHomescreen => _hideHighlightOutlineOnHomescreen;

  bool get appSelectorTransitionAnimationEnabled => _appSelectorTransitionAnimationEnabled;

  bool get showDateInStatusBar => _showDateInStatusBar;

  bool get showTimeInStatusBar => _showTimeInStatusBar;

  String? get gradientUuid => _gradientUuid;

  String get backButtonAction => _backButtonAction;

  String get dateFormat => _dateFormat;

  String get timeFormat => _timeFormat;

  String get dataUsagePeriod => _dataUsagePeriod;

  bool get showDataWidgetInStatusBar => _showDataWidgetInStatusBar;

  bool get showNetworkIndicatorInStatusBar => _showNetworkIndicatorInStatusBar;

  bool get showInputsWidgetInStatusBar => _showInputsWidgetInStatusBar;
  bool get showSystemSettingsInStatusBar => _showSystemSettingsInStatusBar;
  bool get hideLauncherTile => _hideLauncherTile;
  bool get hideAndroidSettingsTile => _hideAndroidSettingsTile;
  bool get settingsMenuOnRight => _sharedPreferences.getBool('settings_menu_on_right') ?? false;

  Future<void> setSettingsMenuOnRight(bool value) async {
    await _sharedPreferences.setBool('settings_menu_on_right', value);
    notifyListeners();
  }
  bool get showContinueWatching => _showContinueWatching;
  bool get showNowPlaying => _sharedPreferences.getBool('show_now_playing') ?? false;
  Future<void> setShowNowPlaying(bool value) async {
    await _sharedPreferences.setBool('show_now_playing', value);
    notifyListeners();
  }
  String get continueWatchingCardSize => _continueWatchingCardSize;
  int get continueWatchingMaxItems => _continueWatchingMaxItems;
  CardFocusMode get cardFocusMode {
    final saved = _sharedPreferences.getString('card_focus_mode');
    return CardFocusMode.values.where((mode) => mode.name == saved).firstOrNull ??
        CardFocusMode.first;
  }
  // Legacy backup field; Home and section-entry policies are independent.
  bool get rememberCategoryFocus => _sharedPreferences.getBool('remember_category_focus') ?? false;

  Future<void> setCardFocusMode(CardFocusMode mode) async {
    await _sharedPreferences.setString('card_focus_mode', mode.name);
    notifyListeners();
  }

  Future<void> setRememberCategoryFocus(bool value) async {
    await _sharedPreferences.setBool('remember_category_focus', value);
    notifyListeners();
  }

  Map<String, int> get watchNextAppLimits => Map.unmodifiable(
      parseWatchNextAppLimits(_sharedPreferences.getString(watchNextAppLimitsKey) ?? '{}') ?? {});

  Future<void> setWatchNextAppLimit(String package, int limit) async {
    if (package.isEmpty || limit < 0 || limit > 10000) throw ArgumentError('Invalid source limit');
    final limits = Map<String, int>.from(watchNextAppLimits);
    if (limit == 0) { limits.remove(package); } else { limits[package] = limit; }
    await _sharedPreferences.setString(watchNextAppLimitsKey, jsonEncode(limits));
    notifyListeners();
  }
  bool get continueWatchingShowProgress => _continueWatchingShowProgress;
  bool get continueWatchingShowPercentage => _continueWatchingShowPercentage;
  bool get continueWatchingShowDescription => _continueWatchingShowDescription;
  int get continueWatchingOrder => _continueWatchingOrder;
  List<String> get hiddenWatchNextProgramIds => List.unmodifiable(_hiddenWatchNextProgramIds);
  List<String> get hiddenWatchNextPackages => List.unmodifiable(_hiddenWatchNextPackages);
  bool get startOnBoot => _startOnBoot;
  bool get showNotificationsWidgetInStatusBar => _showNotificationsWidgetInStatusBar;
  bool get showSleepTimerInStatusBar => _sharedPreferences.getBool('show_sleep_timer_in_status_bar') ?? true;
  bool get showNightModeInStatusBar => _sharedPreferences.getBool('show_night_mode_in_status_bar') ?? true;
  Future<void> setShowNightModeInStatusBar(bool value) async {
    await _sharedPreferences.setBool('show_night_mode_in_status_bar', value);
    notifyListeners();
  }
  Future<void> setShowSleepTimerInStatusBar(bool value) async {
    await _sharedPreferences.setBool('show_sleep_timer_in_status_bar', value);
    notifyListeners();
  }
  bool get autoHideNotificationsWidget => _autoHideNotificationsWidget;
  bool get showWeatherInStatusBar => _showWeatherInStatusBar;
  bool get showWeatherWarnings => _showWeatherWarnings;
  String get temperatureUnit => _temperatureUnit;
  bool get useFahrenheit => _temperatureUnit == TEMPERATURE_UNIT_FAHRENHEIT;

  String get appLanguage => _appLanguage;

  Locale? get appLocale {
    if (_appLanguage.isEmpty || !AppLocalizations.supportedLocales.any(
      (locale) => locale.languageCode == _appLanguage,
    )) {
      return null;
    }
    return Locale(_appLanguage);
  }

  String get accentColorHex => _accentColorHex;

  String get screensaverClockStyle => _screensaverClockStyle;

  Color get accentColor {
    final hex = accentColorHex;
    return Color(int.parse("0xFF$hex"));
  }

  SettingsService(this._sharedPreferences) {
    reload();
  }

  void reload() {
    _memorySaverEnabled = _sharedPreferences.getBool(_memorySaverEnabledKey) ?? false;
    _appHighlightAnimationEnabled = _sharedPreferences.getBool(_appHighlightAnimationEnabledKey) ?? true;
    _appKeyClickEnabled = _sharedPreferences.getBool(_appKeyClickEnabledKey) ?? false;
    _autoHideAppBarEnabled = _sharedPreferences.getBool(_autoHideAppBarKey) ?? false;
    _showCategoryTitles = _sharedPreferences.getBool(_showCategoryTitlesKey) ?? true;
    _showAppNamesBelowIcons = _sharedPreferences.getBool(_showAppNamesBelowIconsKey) ?? false;
    _hideHighlightOutlineOnHomescreen = _sharedPreferences.getBool(_hideHighlightOutlineOnHomescreenKey) ?? false;
    _appSelectorTransitionAnimationEnabled = _sharedPreferences.getBool(_appSelectorTransitionAnimationEnabledKey) ?? true;
    _showDateInStatusBar = _sharedPreferences.getBool(_showDateInStatusBarKey) ?? true;
    _showTimeInStatusBar = _sharedPreferences.getBool(_showTimeInStatusBarKey) ?? true;
    _gradientUuid = _sharedPreferences.getString(_gradientUuidKey);
    _backButtonAction = _sharedPreferences.getString(_backButtonActionKey) ?? BACK_BUTTON_ACTION_NOTHING;
    _dateFormat = _sharedPreferences.getString(_dateFormatKey) ?? defaultDateFormat;
    _timeFormat = _sharedPreferences.getString(_timeFormatKey) ?? defaultTimeFormat;
    _dataUsagePeriod = _sharedPreferences.getString(_dataUsagePeriodKey) ?? DATA_USAGE_DAILY;
    _showDataWidgetInStatusBar = _sharedPreferences.getBool(_showDataWidgetInStatusBarKey) ?? false;
    _showNetworkIndicatorInStatusBar = _sharedPreferences.getBool(_showNetworkIndicatorInStatusBarKey) ?? true;
    _accentColorHex = _sharedPreferences.getString(_accentColorKey) ?? ACCENT_COLOR_PURPLE;
    _screensaverClockStyle = _sharedPreferences.getString(_screensaverClockStyleKey) ?? "minimal";
    _timeBasedWallpaperEnabled = _sharedPreferences.getBool(_timeBasedWallpaperEnabledKey) ?? false;
    _showInputsWidgetInStatusBar = _sharedPreferences.getBool(_showInputsWidgetInStatusBarKey) ?? true;
    _showSystemSettingsInStatusBar = _sharedPreferences.getBool(_showSystemSettingsInStatusBarKey) ?? true;
    _hideLauncherTile = _sharedPreferences.getBool(_hideLauncherTileKey) ?? false;
    _hideAndroidSettingsTile = _sharedPreferences.getBool(_hideAndroidSettingsTileKey) ?? true;
    _showContinueWatching = _sharedPreferences.getBool(_showContinueWatchingKey) ?? false;
    _continueWatchingCardSize = _sharedPreferences.getString(_continueWatchingCardSizeKey) ?? "normal";
    _continueWatchingMaxItems = _sharedPreferences.getInt(_continueWatchingMaxItemsKey) ?? 15;
    _continueWatchingShowProgress = _sharedPreferences.getBool(_continueWatchingShowProgressKey) ?? true;
    _continueWatchingShowPercentage = _sharedPreferences.getBool(_continueWatchingShowPercentageKey) ?? true;
    _continueWatchingShowDescription = _sharedPreferences.getBool(_continueWatchingShowDescriptionKey) ?? true;
    _continueWatchingOrder = _sharedPreferences.getInt(_continueWatchingOrderKey) ?? 0;
    _hiddenWatchNextProgramIds = _sharedPreferences.getStringList(_hiddenWatchNextProgramIdsKey) ?? [];
    _hiddenWatchNextPackages = _sharedPreferences.getStringList(_hiddenWatchNextPackagesKey) ?? [];
    _startOnBoot = _sharedPreferences.getBool(_startOnBootKey) ?? false;
    _showNotificationsWidgetInStatusBar = _sharedPreferences.getBool(_showNotificationsWidgetInStatusBarKey) ?? true;
    _autoHideNotificationsWidget = _sharedPreferences.getBool(_autoHideNotificationsWidgetKey) ?? false;
    _appLanguage = _sharedPreferences.getString(_appLanguageKey) ?? "";
    _showWeatherInStatusBar = _sharedPreferences.getBool(_showWeatherInStatusBarKey) ?? false;
    _showWeatherWarnings = _sharedPreferences.getBool(_showWeatherWarningsKey) ?? true;
    _temperatureUnit = _sharedPreferences.getString(_temperatureUnitKey) ?? TEMPERATURE_UNIT_CELSIUS;
    notifyListeners();
  }

  Map<String, dynamic> exportSettingsMap() {
    return {
      tvInputsConfigurationKey: _sharedPreferences.getString(tvInputsConfigurationKey) ?? const TvInputsConfiguration().encode(),
      _memorySaverEnabledKey: _memorySaverEnabled,
      _appHighlightAnimationEnabledKey: _appHighlightAnimationEnabled,
      _appKeyClickEnabledKey: _appKeyClickEnabled,
      _autoHideAppBarKey: _autoHideAppBarEnabled,
      _showCategoryTitlesKey: _showCategoryTitles,
      _showAppNamesBelowIconsKey: _showAppNamesBelowIcons,
      'background_source': backgroundSource,
      'wallpaper_fit': wallpaperFit,
      'wallpaper_brightness': wallpaperBrightness,
      'wallpaper_saturation': wallpaperSaturation,
      'wallpaper_dimming': wallpaperDimming,
      _hideHighlightOutlineOnHomescreenKey: _hideHighlightOutlineOnHomescreen,
      _appSelectorTransitionAnimationEnabledKey: _appSelectorTransitionAnimationEnabled,
      _showDateInStatusBarKey: _showDateInStatusBar,
      _showTimeInStatusBarKey: _showTimeInStatusBar,
      if (_gradientUuid != null) _gradientUuidKey: _gradientUuid,
      _backButtonActionKey: _backButtonAction,
      _dateFormatKey: _dateFormat,
      _timeFormatKey: _timeFormat,
      _dataUsagePeriodKey: _dataUsagePeriod,
      _showDataWidgetInStatusBarKey: _showDataWidgetInStatusBar,
      _showNetworkIndicatorInStatusBarKey: _showNetworkIndicatorInStatusBar,
      _accentColorKey: _accentColorHex,
      _screensaverClockStyleKey: _screensaverClockStyle,
      _timeBasedWallpaperEnabledKey: _timeBasedWallpaperEnabled,
      _showInputsWidgetInStatusBarKey: _showInputsWidgetInStatusBar,
      _showSystemSettingsInStatusBarKey: _showSystemSettingsInStatusBar,
      _hideLauncherTileKey: _hideLauncherTile,
      _hideAndroidSettingsTileKey: _hideAndroidSettingsTile,
      _showContinueWatchingKey: _showContinueWatching,
      'show_now_playing': showNowPlaying,
      _continueWatchingCardSizeKey: _continueWatchingCardSize,
      _continueWatchingMaxItemsKey: _continueWatchingMaxItems,
      'remember_category_focus': rememberCategoryFocus,
      'card_focus_mode': cardFocusMode.name,
      'settings_menu_on_right': settingsMenuOnRight,
      watchNextAppLimitsKey: jsonEncode(watchNextAppLimits),
      _continueWatchingShowProgressKey: _continueWatchingShowProgress,
      _continueWatchingShowPercentageKey: _continueWatchingShowPercentage,
      _continueWatchingShowDescriptionKey: _continueWatchingShowDescription,
      _continueWatchingOrderKey: _continueWatchingOrder,
      _hiddenWatchNextProgramIdsKey: _hiddenWatchNextProgramIds,
      _hiddenWatchNextPackagesKey: _hiddenWatchNextPackages,
      _startOnBootKey: _startOnBoot,
      _showNotificationsWidgetInStatusBarKey: _showNotificationsWidgetInStatusBar,
      'show_sleep_timer_in_status_bar': showSleepTimerInStatusBar,
      'show_night_mode_in_status_bar': showNightModeInStatusBar,
      _autoHideNotificationsWidgetKey: _autoHideNotificationsWidget,
      _appLanguageKey: _appLanguage,
      _showWeatherInStatusBarKey: _showWeatherInStatusBar,
      _showWeatherWarningsKey: _showWeatherWarnings,
      _temperatureUnitKey: _temperatureUnit,
    };
  }

  Future<void> importSettingsMap(Map<String, dynamic> settingsMap) async {
    final expected = {
      for (final key in _sharedPreferences.getKeys()) key: _sharedPreferences.get(key),
      ...exportSettingsMap(),
    };
    for (final entry in compatibleSettings(settingsMap, expected).entries) {
      final key = entry.key;
      final value = entry.value;
      if (value is bool) {
        await _sharedPreferences.setBool(key, value);
      } else if (value is int) {
        await _sharedPreferences.setInt(key, value);
      } else if (value is double) {
        await _sharedPreferences.setDouble(key, value);
      } else if (value is String) {
        await _sharedPreferences.setString(key, value);
      } else if (value is List) {
        await _sharedPreferences.setStringList(key, value.cast<String>());
      }
    }
    reload();
  }

  Future<void> setAppLanguage(String value) async {
    await _sharedPreferences.setString(_appLanguageKey, value);
    _appLanguage = value;
    notifyListeners();
  }

  Future<void> setAppHighlightAnimationEnabled(bool value) async {
    await _sharedPreferences.setBool(_appHighlightAnimationEnabledKey, value);
    _appHighlightAnimationEnabled = value;
    notifyListeners();
  }

  Future<void> setAppKeyClickEnabled(bool value) async {
    await _sharedPreferences.setBool(_appKeyClickEnabledKey, value);
    _appKeyClickEnabled = value;
    notifyListeners();
  }

  Future<void> setAutoHideAppBarEnabled(bool value) async {
    await _sharedPreferences.setBool(_autoHideAppBarKey, value);
    _autoHideAppBarEnabled = value;
    notifyListeners();
  }

  Future<void> setGradientUuid(String value) async {
    await _sharedPreferences.setString(_gradientUuidKey, value);
    _gradientUuid = value;
    notifyListeners();
  }

  Future<void> setBackButtonAction(String value) async {
    await _sharedPreferences.setString(_backButtonActionKey, value);
    _backButtonAction = value;
    notifyListeners();
  }

  Future<void> setDateTimeFormat(String dateFormatString, String timeFormatString) async {
    await Future.wait([
      _sharedPreferences.setString(_dateFormatKey, dateFormatString),
      _sharedPreferences.setString(_timeFormatKey, timeFormatString)
    ]);
    _dateFormat = dateFormatString;
    _timeFormat = timeFormatString;
    notifyListeners();
  }

  Future<void> setShowCategoryTitles(bool show) async {
    await _sharedPreferences.setBool(_showCategoryTitlesKey, show);
    _showCategoryTitles = show;
    notifyListeners();
  }

  Future<void> setShowAppNamesBelowIcons(bool show) async {
    await _sharedPreferences.setBool(_showAppNamesBelowIconsKey, show);
    _showAppNamesBelowIcons = show;
    notifyListeners();
  }

  Future<void> setHideHighlightOutlineOnHomescreen(bool enabled) async {
    await _sharedPreferences.setBool(_hideHighlightOutlineOnHomescreenKey, enabled);
    _hideHighlightOutlineOnHomescreen = enabled;
    notifyListeners();
  }

  Future<void> setAppSelectorTransitionAnimationEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_appSelectorTransitionAnimationEnabledKey, enabled);
    _appSelectorTransitionAnimationEnabled = enabled;
    notifyListeners();
  }

  Future<void> setShowDateInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showDateInStatusBarKey, show);
    _showDateInStatusBar = show;
    notifyListeners();
  }

  Future<void> setMemorySaverEnabled(bool value) async {
    await _sharedPreferences.setBool(_memorySaverEnabledKey, value);
    if (isDisposed) return;
    _memorySaverEnabled = value;
    notifyListeners();
  }

  Future<void> setShowTimeInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showTimeInStatusBarKey, show);
    _showTimeInStatusBar = show;
    notifyListeners();
  }

  Future<void> setDataUsagePeriod(String period) async {
    await _sharedPreferences.setString(_dataUsagePeriodKey, period);
    _dataUsagePeriod = period;
    notifyListeners();
  }

  Future<void> setShowDataWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showDataWidgetInStatusBarKey, show);
    _showDataWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowNetworkIndicatorInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showNetworkIndicatorInStatusBarKey, show);
    _showNetworkIndicatorInStatusBar = show;
    notifyListeners();
  }

  Future<void> setAccentColor(String colorHex) async {
    await _sharedPreferences.setString(_accentColorKey, colorHex);
    _accentColorHex = colorHex;
    notifyListeners();
  }

  Future<void> setScreensaverClockStyle(String style) async {
    await _sharedPreferences.setString(_screensaverClockStyleKey, style);
    _screensaverClockStyle = style;
    notifyListeners();
  }

  bool get timeBasedWallpaperEnabled => _timeBasedWallpaperEnabled;

  Future<void> setTimeBasedWallpaperEnabled(bool enabled) async {
    await _sharedPreferences.setBool(_timeBasedWallpaperEnabledKey, enabled);
    _timeBasedWallpaperEnabled = enabled;
    notifyListeners();
  }

  Future<void> setShowInputsWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showInputsWidgetInStatusBarKey, show);
    _showInputsWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowSystemSettingsInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showSystemSettingsInStatusBarKey, show);
    _showSystemSettingsInStatusBar = show;
    notifyListeners();
  }

  Future<void> setHideLauncherTile(bool hide) async {
    await _sharedPreferences.setBool(_hideLauncherTileKey, hide);
    _hideLauncherTile = hide;
    notifyListeners();
  }

  Future<void> setHideAndroidSettingsTile(bool hide) async {
    await _sharedPreferences.setBool(_hideAndroidSettingsTileKey, hide);
    _hideAndroidSettingsTile = hide;
    notifyListeners();
  }

  Future<void> setShowContinueWatching(bool show) async {
    await _sharedPreferences.setBool(_showContinueWatchingKey, show);
    _showContinueWatching = show;
    notifyListeners();
  }

  Future<void> setContinueWatchingCardSize(String size) async {
    await _sharedPreferences.setString(_continueWatchingCardSizeKey, size);
    _continueWatchingCardSize = size;
    notifyListeners();
  }

  Future<void> setContinueWatchingMaxItems(int count) async {
    await _sharedPreferences.setInt(_continueWatchingMaxItemsKey, count);
    _continueWatchingMaxItems = count;
    notifyListeners();
  }

  Future<void> setContinueWatchingShowProgress(bool show) async {
    await _sharedPreferences.setBool(_continueWatchingShowProgressKey, show);
    _continueWatchingShowProgress = show;
    notifyListeners();
  }

  Future<void> setContinueWatchingShowPercentage(bool show) async {
    await _sharedPreferences.setBool(_continueWatchingShowPercentageKey, show);
    _continueWatchingShowPercentage = show;
    notifyListeners();
  }

  Future<void> setContinueWatchingShowDescription(bool show) async {
    await _sharedPreferences.setBool(_continueWatchingShowDescriptionKey, show);
    _continueWatchingShowDescription = show;
    notifyListeners();
  }

  Future<void> setContinueWatchingOrder(int order) async {
    await _sharedPreferences.setInt(_continueWatchingOrderKey, order);
    _continueWatchingOrder = order;
    notifyListeners();
  }

  Future<void> hideWatchNextProgram(int id) async {
    final strId = id.toString();
    if (!_hiddenWatchNextProgramIds.contains(strId)) {
      _hiddenWatchNextProgramIds = List<String>.from(_hiddenWatchNextProgramIds)..add(strId);
      await _sharedPreferences.setStringList(_hiddenWatchNextProgramIdsKey, _hiddenWatchNextProgramIds);
      notifyListeners();
    }
  }

  Future<void> unhideWatchNextProgram(int id) async {
    final strId = id.toString();
    if (_hiddenWatchNextProgramIds.contains(strId)) {
      _hiddenWatchNextProgramIds = List<String>.from(_hiddenWatchNextProgramIds)..remove(strId);
      await _sharedPreferences.setStringList(_hiddenWatchNextProgramIdsKey, _hiddenWatchNextProgramIds);
      notifyListeners();
    }
  }

  Future<void> hideWatchNextPackage(String packageName) async {
    if (!_hiddenWatchNextPackages.contains(packageName)) {
      _hiddenWatchNextPackages = List<String>.from(_hiddenWatchNextPackages)..add(packageName);
      await _sharedPreferences.setStringList(_hiddenWatchNextPackagesKey, _hiddenWatchNextPackages);
      notifyListeners();
    }
  }

  Future<void> unhideWatchNextPackage(String packageName) async {
    if (_hiddenWatchNextPackages.contains(packageName)) {
      _hiddenWatchNextPackages = List<String>.from(_hiddenWatchNextPackages)..remove(packageName);
      await _sharedPreferences.setStringList(_hiddenWatchNextPackagesKey, _hiddenWatchNextPackages);
      notifyListeners();
    }
  }

  Future<void> unhideAllWatchNextPackages() async {
    _hiddenWatchNextPackages = [];
    await _sharedPreferences.remove(_hiddenWatchNextPackagesKey);
    notifyListeners();
  }

  Future<void> clearHiddenWatchNextPrograms() async {
    _hiddenWatchNextProgramIds = [];
    await _sharedPreferences.remove(_hiddenWatchNextProgramIdsKey);
    notifyListeners();
  }

  Future<void> clearAllHiddenWatchNext() async {
    _hiddenWatchNextProgramIds = [];
    _hiddenWatchNextPackages = [];
    await _sharedPreferences.remove(_hiddenWatchNextProgramIdsKey);
    await _sharedPreferences.remove(_hiddenWatchNextPackagesKey);
    notifyListeners();
  }

  Future<void> setStartOnBoot(bool enabled) async {
    await _sharedPreferences.setBool(_startOnBootKey, enabled);
    _startOnBoot = enabled;
    notifyListeners();
  }

  Future<void> setShowNotificationsWidgetInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showNotificationsWidgetInStatusBarKey, show);
    _showNotificationsWidgetInStatusBar = show;
    notifyListeners();
  }

  Future<void> setAutoHideNotificationsWidget(bool value) async {
    await _sharedPreferences.setBool(_autoHideNotificationsWidgetKey, value);
    _autoHideNotificationsWidget = value;
    notifyListeners();
  }

  Future<void> setShowWeatherInStatusBar(bool show) async {
    await _sharedPreferences.setBool(_showWeatherInStatusBarKey, show);
    _showWeatherInStatusBar = show;
    notifyListeners();
  }

  Future<void> setShowWeatherWarnings(bool show) async {
    await _sharedPreferences.setBool(_showWeatherWarningsKey, show);
    _showWeatherWarnings = show;
    notifyListeners();
  }

  Future<void> setTemperatureUnit(String unit) async {
    await _sharedPreferences.setString(_temperatureUnitKey, unit);
    _temperatureUnit = unit;
    notifyListeners();
  }
}
