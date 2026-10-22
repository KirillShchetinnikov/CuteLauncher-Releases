import 'dart:convert';

import 'package:flauncher/adaptive_landscape.dart';
import 'package:flauncher/models/weather_data.dart';
import 'package:flauncher/providers/settings_service.dart';
import 'package:flauncher/settings_import.dart';
import 'package:flauncher/backup_sync_groups.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('seasons respect month, southern hemisphere and disabled effect', () {
    const c = LandscapeConfiguration();
    expect(landscapeSeason(DateTime(2026, 1), c), LandscapeSeason.winter);
    expect(landscapeSeason(DateTime(2026, 4), c), LandscapeSeason.spring);
    expect(landscapeSeason(DateTime(2026, 7), c), LandscapeSeason.summer);
    expect(landscapeSeason(DateTime(2026, 10), c), LandscapeSeason.autumn);
    expect(
      landscapeSeason(DateTime(2026, 1), c, latitude: -30),
      LandscapeSeason.summer,
    );
    expect(
      landscapeSeason(DateTime(2026, 7), c.withValue('hemisphere', 'south')),
      LandscapeSeason.winter,
    );
    expect(
      landscapeSeason(DateTime(2026, 1), c.withValue('seasons', false)),
      LandscapeSeason.summer,
    );
  });
  test('sun cache and fallback transition boundaries are deterministic', () {
    const c = LandscapeConfiguration();
    DateTime at(int h, [int m = 0]) => DateTime(2026, 10, 21, h, m);
    expect(landscapePhase(at(5, 19), c), LandscapePhase.night);
    expect(landscapePhase(at(5, 20), c), LandscapePhase.dawn);
    expect(landscapePhase(at(6, 40), c), LandscapePhase.day);
    expect(landscapePhase(at(17, 20), c), LandscapePhase.dusk);
    expect(landscapePhase(at(18, 40), c), LandscapePhase.night);
    final days = [
      {
        'sunrise': at(8).millisecondsSinceEpoch,
        'sunset': at(16).millisecondsSinceEpoch,
      },
    ];
    expect(landscapePhase(at(7, 30), c, solarDays: days), LandscapePhase.dawn);
    expect(landscapePhase(at(16), c, solarDays: days), LandscapePhase.dusk);
    expect(
      landscapePhase(at(23), c.withValue('timeOfDay', false), solarDays: days),
      LandscapePhase.day,
    );
    expect(
      landscapePhase(DateTime(2026, 10, 22, 8), c, solarDays: days),
      LandscapePhase.day,
    );
  });
  test(
    'only current normalized weather drives effects, never forecast warnings',
    () {
      expect(landscapeWeather(null), LandscapeWeather.clear);
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 600)),
        LandscapeWeather.snow,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 211)),
        LandscapeWeather.rain,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 301)),
        LandscapeWeather.rain,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 741)),
        LandscapeWeather.fog,
      );
      expect(
        landscapeWeather(const WeatherData(currentConditionCode: 803)),
        LandscapeWeather.cloudy,
      );
      expect(
        landscapeWeather(
          const WeatherData(
            currentConditionCode: 800,
            hasWarning: true,
            warningType: WeatherWarningType.snow,
          ),
        ),
        LandscapeWeather.clear,
      );
    },
  );
  test('settings survive reload and compatible backup; invalid effects cannot import', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settings = SettingsService(prefs);
    addTearDown(settings.dispose);
    await settings.setBackgroundSource('landscape');
    await settings.setLandscape(
      const LandscapeConfiguration(
        variant: 'realistic',
        motion: true,
        fog: false,
      ),
    );
    settings.reload();
    expect(settings.backgroundSource, 'landscape');
    expect(settings.landscape.variant, 'realistic');
    expect(settings.landscape.fog, false);
    final exported = settings.exportSettingsMap();
    final imported = compatibleSettings(exported, exported);
    expect(imported[landscapeSettingsKey], exported[landscapeSettingsKey]);
    expect(imported['background_source'], 'landscape');
    expect(
      backupSyncPartGroup('setting:$landscapeSettingsKey'),
      BackupSyncGroup.background,
    );
    final invalid = compatibleSettings({
      landscapeSettingsKey: jsonEncode({'motion': 'yes'}),
    }, exported);
    expect(invalid.containsKey(landscapeSettingsKey), false);
    await settings.resetAppearanceSection('background');
    expect(settings.landscape.motion, false);
    expect(settings.landscape.variant, 'illustrated');
  });
}
