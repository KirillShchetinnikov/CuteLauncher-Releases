import 'package:flauncher/l10n/app_localizations.dart';
import 'package:flauncher/providers/update_service.dart';
import 'package:flauncher/weather_sources.dart';
import 'package:flauncher/widgets/settings/updates_page.dart';
import 'package:flauncher/widgets/settings/weather_page.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final locale in ['ru', 'en']) {
    test('Weather failures identify the cause in $locale', () async {
      final l = await AppLocalizations.delegate.load(Locale(locale));
      expect(
        weatherFailureMessage(
          l,
          WeatherFailure.authorization,
          WeatherSource.openWeather,
        ),
        l.weatherAuthorizationError,
      );
      expect(
        weatherFailureMessage(
          l,
          WeatherFailure.rateLimit,
          WeatherSource.openMeteo,
        ),
        l.weatherRateLimit,
      );
      expect(
        weatherFailureMessage(
          l,
          WeatherFailure.keyRequired,
          WeatherSource.openWeather,
        ),
        l.weatherSourceKeyRequired,
      );
      expect(
        weatherFailureMessage(
          l,
          WeatherFailure.keyRequired,
          WeatherSource.yandex,
        ),
        l.weatherKeyRequired,
      );
    });
    test('Update failures identify the action in $locale', () async {
      final l = await AppLocalizations.delegate.load(Locale(locale));
      SharedPreferences.setMockInitialValues({});
      final service = UpdateService(await SharedPreferences.getInstance());
      addTearDown(service.dispose);
      expect(updateFailureMessage(l, service), l.updateCheckFailed);
      service.installStatus = 'invalid';
      expect(updateFailureMessage(l, service), l.updateIncompatible);
      service.installStatus = 'unavailable';
      expect(updateFailureMessage(l, service), l.updateInstallerFailed);
      service.installStatus = null;
      service.ready = true;
      expect(updateFailureMessage(l, service), l.updateInstallerFailed);
    });
  }
}
