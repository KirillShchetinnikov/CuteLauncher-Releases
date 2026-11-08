import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flauncher/information_formats.dart';
import 'package:flauncher/information_settings_geometry.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/providers/appearance_service.dart';
import 'package:flauncher/providers/remote_panel_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/settings_sync.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flauncher/tile_appearance.dart';
import 'package:flauncher/weather_text_format.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('upgrade preserves legacy data; profiles edit, reload and restore independently', () async {
    final legacy = WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.feelsLike),
    ])!;
    SharedPreferences.setMockInitialValues({
      'time_format': 'HH:mm',
      'date_format': 'yyyy-MM-dd',
      'temperature_unit': 'fahrenheit',
      'show_weather_warnings': false,
      weatherTextFormatKey: legacy.encode(),
    });
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    addTearDown(settings.dispose);
    for (final background in [false, true]) {
      expect(
        settings.informationDateTime(background: background).date,
        'yyyy-MM-dd',
      );
      expect(
        settings.informationWeather(background: background).format.encode(),
        legacy.encode(),
      );
      expect(
        settings.informationWeather(background: background).fahrenheit,
        isTrue,
      );
      expect(
        settings.informationWeather(background: background).warnings,
        isFalse,
      );
    }
    await settings.setInformationDateTime(
      const InformationDateTimeFormat(time: 'h:mm a', date: 'MMMM d'),
    );
    await settings.setInformationWeather(
      const WeatherDisplayOptions(
        format: WeatherTextFormat.standard,
        fahrenheit: false,
        warnings: true,
      ),
    );
    expect(settings.informationDateTime(background: true).time, 'HH:mm');
    expect(
      settings.informationWeather(background: true).format.encode(),
      legacy.encode(),
    );
    await settings.setInformationDateTime(
      const InformationDateTimeFormat(time: 'H:mm', date: 'd MMM'),
      background: true,
    );
    await settings.setInformationWeather(
      WeatherDisplayOptions(format: legacy, fahrenheit: true, warnings: false),
      background: true,
    );
    final saved = settings.exportSettingsMap();
    final profile = settings.informationWeather().encode();
    await settings.importSettingsMap({
      'weather_panel_display': '{bad}',
      'unrelated': false,
    });
    expect(settings.informationWeather().encode(), profile);
    await prefs.clear();
    await settings.importSettingsMap(saved);
    expect(settings.timeFormat, 'h:mm a');
    expect(settings.informationDateTime(background: true).time, 'H:mm');
    expect(settings.useFahrenheit, isFalse);
    expect(settings.informationWeather(background: true).fahrenheit, isTrue);
    for (final key in informationFormatKeys) {
      expect(syncSettingsKeys, contains(key));
      expect(compatibleSettings({key: saved[key]}, {})[key], saved[key]);
    }
    expect(
      backupSyncPartGroup('setting:weather_background_display'),
      BackupSyncGroup.weatherDisplay,
    );
  });
  test('appearance overrides preserve legacy color and explicit reset; quick panel shares panel only', () async {
    expect(const TileAppearance().weatherIconPack, WeatherIconPack.outline);
    expect(const TileAppearance().forInformation(background: true).weatherIconPack, WeatherIconPack.outline);
    expect(const TileAppearance({'weatherIconPack': 'standard'}).weatherIconPack, WeatherIconPack.standard);
    SharedPreferences.setMockInitialValues({
      tileAppearanceKey: jsonEncode({
        'weatherTextColor': 0xff123456,
        'weatherIconColor': 0xff654321,
        'weatherIconPack': 'standard',
        'panelCombinedInformation': true,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    final service = AppearanceService(prefs);
    final quick = RemotePanelService(prefs);
    addTearDown(service.dispose);
    addTearDown(quick.dispose);
    await service.setInformationAppearance('weatherTextColor', 0xffabcdef);
    await service.setInformationAppearance('weatherIconColor', null);
    await service.setInformationAppearance(
      'dateTextColor',
      0xffaaaaaa,
      background: true,
    );
    final restored = TileAppearance.decode(prefs.getString(tileAppearanceKey));
    expect(restored.weatherTextColor, const Color(0xffabcdef));
    expect(restored.weatherIconColor, isNull);
    expect(
      restored.forInformation(background: true).weatherTextColor,
      const Color(0xff123456),
    );
    expect(
      restored.forInformation(background: true).weatherIconColor,
      const Color(0xff654321),
    );
    expect(restored.dateTextColor, isNull);
    expect(restored.active, isFalse);
    await quick.set('inheritAppearance', false);
    await quick.set('combinedInformation', false);
    final popup = quick.appearanceFor(restored);
    expect(popup.weatherTextColor, restored.weatherTextColor);
    expect(restored.weatherIconPack, WeatherIconPack.standard);
    expect(restored.forInformation(background: true).weatherIconPack, WeatherIconPack.standard);
    expect(popup.weatherIconPack, WeatherIconPack.standard);
    expect(popup.weatherIconColor, isNull);
    expect(popup.combinedInformation, isFalse);
    expect(restored.combinedInformation, isTrue);
  });
  test('invalid profiles cannot replace valid settings or smuggle unrelated appearance fields', () {
    expect(
      compatibleSettings({
        'information_panel_datetime': '{"time":"bad","date":"yyyy"}',
        'weather_background_display':
            '{"fahrenheit":true,"warnings":false,"format":"invalid"}',
      }, {}),
      isEmpty,
    );
    final valid = TileAppearance.validValues({
      'backgroundInformationAppearance': {
        'weatherTextColor': 0xff000000,
        'panelTextSize': 99,
        'weatherIconPack': 'invalid',
      },
    });
    expect(valid['backgroundInformationAppearance'], {
      'weatherTextColor': 0xff000000,
    });
  });
  test('menu chooses actual free side; centered wide block enables fallback preview', () {
    ({bool onRight, bool obscured}) side(
      Rect? rect, {
      bool preferred = false,
    }) => informationSettingsSide(
      screen: const Size(960, 540),
      panelWidth: 320,
      block: rect,
      preferredRight: preferred,
    );
    expect(side(const Rect.fromLTWH(20, 90, 220, 170)), (
      onRight: true,
      obscured: false,
    ));
    expect(side(const Rect.fromLTWH(720, 90, 220, 170), preferred: true), (
      onRight: false,
      obscured: false,
    ));
    expect(side(const Rect.fromLTWH(50, 90, 860, 170)), (
      onRight: false,
      obscured: true,
    ));
    expect(side(null, preferred: true), (onRight: true, obscured: false));
  });
}
