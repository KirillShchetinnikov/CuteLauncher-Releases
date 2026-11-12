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
  final panelWeather = WeatherDisplayOptions(
    format: WeatherTextFormat.standard,
    fahrenheit: false,
    warnings: true,
  );
  final backgroundWeather = WeatherDisplayOptions(
    format: WeatherTextFormat.fromBlocks(const [
      WeatherTextBlock(WeatherTextField.feelsLike),
    ])!,
    fahrenheit: true,
    warnings: false,
  );
  const panelDateTime = InformationDateTimeFormat(
    time: 'h:mm a',
    date: 'MMMM d',
  );
  const backgroundDateTime = InformationDateTimeFormat(
    time: 'HH:mm',
    date: 'yyyy-MM-dd',
  );

  Map<String, Object> legacySettings(Map<String, String> placements) => {
    tileAppearanceKey: jsonEncode({
      'panelInformationPlacements': placements,
      'panelInformationStyle': {'showColon': true, 'animate': false},
      'panelBackgroundInformationStyle': {'showColon': false, 'animate': true},
    }),
    'information_panel_datetime': panelDateTime.encode(),
    'information_background_datetime': backgroundDateTime.encode(),
    'weather_panel_display': panelWeather.encode(),
    'weather_background_display': backgroundWeather.encode(),
  };

  for (final timeOnBackground in [false, true]) {
    test(
      'upgrade keeps each active format and freezes it on placement changes: timeOnBackground=$timeOnBackground',
      () async {
        SharedPreferences.setMockInitialValues(
          legacySettings({
            'time': timeOnBackground ? 'background' : 'panel',
            'date': timeOnBackground ? 'panel' : 'background',
            'weather': timeOnBackground ? 'panel' : 'background',
          }),
        );
        final prefs = await SharedPreferences.getInstance();
        await SettingsService.upgradeInformationFormats(prefs);
        final settings = SettingsService(prefs);
        final appearance = AppearanceService(prefs);
        addTearDown(settings.dispose);
        addTearDown(appearance.dispose);

        void expectClockBehavior() {
          for (final background in [false, true]) {
            final clock = appearance.appearance.renderedInformationStyle(
              background: background,
            );
            expect(clock.showColon, !timeOnBackground);
            expect(clock.animate, timeOnBackground);
          }
        }

        expectClockBehavior();

        final time = timeOnBackground
            ? backgroundDateTime.time
            : panelDateTime.time;
        final date = timeOnBackground
            ? panelDateTime.date
            : backgroundDateTime.date;
        final weather = timeOnBackground ? panelWeather : backgroundWeather;
        expect(settings.timeFormat, time);
        expect(settings.dateFormat, date);
        expect(settings.informationWeather().encode(), weather.encode());

        await prefs.setString(
          tileAppearanceKey,
          jsonEncode({
            'panelInformationPlacements': {
              'time': timeOnBackground ? 'panel' : 'background',
              'date': timeOnBackground ? 'background' : 'panel',
              'weather': timeOnBackground ? 'background' : 'panel',
            },
          }),
        );
        await SettingsService.upgradeInformationFormats(prefs);
        settings.reload();
        expect(settings.timeFormat, time);
        expect(settings.dateFormat, date);
        expect(settings.informationWeather().encode(), weather.encode());

        await settings.setInformationDateTime(panelDateTime);
        await settings.setInformationWeather(backgroundWeather);
        expectClockBehavior();
        final saved = settings.exportSettingsMap();
        for (final key in informationFormatKeys) {
          expect(syncSettingsKeys, contains(key));
          expect(compatibleSettings({key: saved[key]}, {})[key], saved[key]);
        }
        await prefs.clear();
        await settings.importSettingsMap(saved);
        expectClockBehavior();
        expect(settings.informationDateTime().encode(), panelDateTime.encode());
        expect(
          settings.informationWeather().encode(),
          backgroundWeather.encode(),
        );
      },
    );
  }

  test(
    'old backup restores active formats over existing shared formats',
    () async {
      SharedPreferences.setMockInitialValues({
        sharedInformationDateTimeKey: backgroundDateTime.encode(),
        sharedInformationWeatherKey: panelWeather.encode(),
        sharedInformationClockBehaviorKey: '{"showColon":false,"animate":true}',
      });
      final settings = SettingsService(await SharedPreferences.getInstance());
      addTearDown(settings.dispose);
      await settings.importSettingsMap(
        legacySettings({
          'time': 'panel',
          'date': 'hidden',
          'weather': 'background',
        }),
      );
      expect(settings.informationDateTime().encode(), panelDateTime.encode());
      expect(
        settings.informationWeather().encode(),
        backgroundWeather.encode(),
      );
      final behavior = decodeInformationClockBehavior(
        settings.exportSettingsMap()[sharedInformationClockBehaviorKey],
      );
      expect(behavior?.showColon, isTrue);
      expect(behavior?.animate, isFalse);

      expect(
        backupSyncPartGroup('setting:$sharedInformationDateTimeKey'),
        BackupSyncGroup.topPanel,
      );
      expect(
        backupSyncPartGroup('setting:$sharedInformationWeatherKey'),
        BackupSyncGroup.weatherDisplay,
      );
      expect(
        backupSyncPartGroup('setting:$sharedInformationClockBehaviorKey'),
        BackupSyncGroup.topPanel,
      );
    },
  );

  test(
    'clock behavior migrates when date and time are already shared',
    () async {
      SharedPreferences.setMockInitialValues({
        sharedInformationDateTimeKey: panelDateTime.encode(),
        tileAppearanceKey: jsonEncode({
          'panelInformationPlacements': {'time': 'background'},
          'panelInformationStyle': {'showColon': true, 'animate': false},
          'panelBackgroundInformationStyle': {
            'showColon': false,
            'animate': true,
          },
        }),
      });
      final prefs = await SharedPreferences.getInstance();
      await SettingsService.upgradeInformationFormats(prefs);
      expect(
        prefs.getString(sharedInformationDateTimeKey),
        panelDateTime.encode(),
      );
      final behavior = decodeInformationClockBehavior(
        prefs.get(sharedInformationClockBehaviorKey),
      );
      expect(behavior?.showColon, isFalse);
      expect(behavior?.animate, isTrue);
    },
  );

  test(
    'legacy whole-block placement and missing profile retain effective values',
    () async {
      SharedPreferences.setMockInitialValues({
        tileAppearanceKey: jsonEncode({
          'panelInformationPlacement': 'background',
        }),
        'show_weather_in_status_bar': true,
        'information_panel_datetime': panelDateTime.encode(),
        'weather_background_display': backgroundWeather.encode(),
        'time_format': 'H:mm',
        'date_format': 'd MMM',
      });
      final prefs = await SharedPreferences.getInstance();
      await SettingsService.upgradeInformationFormats(prefs);
      final settings = SettingsService(prefs);
      addTearDown(settings.dispose);
      expect(settings.timeFormat, 'H:mm');
      expect(settings.dateFormat, 'd MMM');
      expect(
        settings.informationWeather().encode(),
        backgroundWeather.encode(),
      );
    },
  );
  test('appearance overrides preserve legacy color and explicit reset; quick panel shares panel only', () async {
    expect(const TileAppearance().weatherIconPack, WeatherIconPack.outline);
    expect(
      const TileAppearance().forInformation(background: true).weatherIconPack,
      WeatherIconPack.outline,
    );
    expect(
      const TileAppearance({'weatherIconPack': 'standard'}).weatherIconPack,
      WeatherIconPack.standard,
    );
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
    expect(
      restored.forInformation(background: true).weatherIconPack,
      WeatherIconPack.standard,
    );
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
