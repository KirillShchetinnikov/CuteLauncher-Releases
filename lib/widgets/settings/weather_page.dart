import 'settings_help.dart';
import '../remote_text_input.dart';
import 'city_search_dialog.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_value_stepper.dart';
import 'settings_choice_tile.dart';

import 'package:flauncher/widgets/action_notice.dart';

import 'settings_page_layout.dart';
import '../../providers/settings_service.dart';
import '../rounded_switch_list_tile.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/weather_service.dart';
import '../../weather_sources.dart';
import 'focusable_settings_tile.dart';

class WeatherPage extends StatelessWidget {
  static const routeName = 'weather_panel';
  const WeatherPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<WeatherService>();
    final config = service.configuration;
    final settings = context.watch<SettingsService>();
    final names = {
      WeatherSource.breezy: 'Breezy Weather',
      WeatherSource.openMeteo: 'Open-Meteo',
      WeatherSource.yandex: l.yandexWeather,
      WeatherSource.openWeather: 'OpenWeather',
    };
    return SettingsPageLayout(
      title: Text(
        l.weatherSettings,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SettingsChoiceTile<WeatherSource>(
            autofocus: true,
            title: l.weatherSource,
            value: config.source,
            enabled: !service.loading && !service.locating,
            options: const [
              WeatherSource.openMeteo,
              WeatherSource.openWeather,
              WeatherSource.yandex,
              WeatherSource.breezy,
            ],
            label: (v) => names[v]!,
            onChanged: (v) => service.configure(config.copyWith(source: v)),
          ),
          if (config.source != WeatherSource.breezy) ...[
            SettingsChoiceTile<WeatherLocationMode>(
              title: l.weatherLocation,
              value: config.locationMode,
              options: WeatherLocationMode.values,
              enabled: !service.loading && !service.locating,
              label: (mode) => mode == WeatherLocationMode.automatic
                  ? l.weatherLocationAutomatic
                  : l.weatherLocationManual,
              onChanged: (mode) =>
                  service.configure(config.copyWith(locationMode: mode)),
            ),
            if (config.locationMode == WeatherLocationMode.automatic)
              FocusableSettingsTile(
                title: Text(l.weatherGetLocation),
                trailing: Text(
                  config.validCoordinates
                      ? '${config.latitude!.toStringAsFixed(3)}, ${config.longitude!.toStringAsFixed(3)}'
                      : l.settingsValueNotSet,
                ),
                enabled: !service.loading && !service.locating,
                onPressed: () => _automaticLocation(context, service),
              )
            else
              FocusableSettingsTile(
                valueIcon: Icons.edit_outlined,
                trailing: Text(
                  config.location.isNotEmpty
                      ? config.location
                      : l.settingsValueNotSet,
                ),
                title: Text(l.nightCityName),
                onPressed: service.loading || service.locating
                    ? null
                    : () => _location(context, service),
              ),
            if (service.locating) const LinearProgressIndicator(),
            SettingsValueStepper(
              title: l.weatherInterval,
              options: const [30, 60, 120, 180],
              value: config.intervalMinutes,
              enabled: !service.loading,
              label: (v) => '$v ${l.weatherMinutes}',
              onChanged: (v) =>
                  service.configure(config.copyWith(intervalMinutes: v as int)),
            ),
            if (config.source == WeatherSource.yandex ||
                config.source == WeatherSource.openWeather) ...[
              FocusableSettingsTile(
                valueIcon: Icons.edit_outlined,
                trailing: FutureBuilder<bool>(
                  future: service.hasApiKey(source: config.source),
                  builder: (_, snapshot) =>
                      Text(snapshot.data == true ? '••••••' : '—'),
                ),
                title: Text(
                  config.source == WeatherSource.openWeather
                      ? l.weatherOpenWeatherKey
                      : l.weatherApiKey,
                ),
                onPressed: service.loading
                    ? null
                    : () => _key(context, service, config.source),
              ),
              SettingsHelp(text: config.source == WeatherSource.openWeather ? l.weatherOpenWeatherHint : l.weatherYandexHint),
            ],
            FocusableSettingsTile(
              leading: const Icon(Icons.refresh),
              title: Text(l.weatherRefresh),
              enabled:
                  !service.loading && !service.locating && service.canRefresh,
              onPressed:
                  service.loading || service.locating || !service.canRefresh
                  ? null
                  : () async {
                      try {
                        await service.refresh();
                        if (!context.mounted) return;
                        showActionNotice(
                          context,
                          service.failure != null
                              ? weatherFailureMessage(
                                  l,
                                  service.failure!,
                                  config.source,
                                )
                              : l.actionCompleted,
                          error: service.failure != null,
                        );
                      } catch (_) {
                        if (context.mounted) {
                          showActionNotice(
                            context,
                            l.weatherUnavailable,
                            error: true,
                          );
                        }
                      }
                    },
            ),
            if (service.loading) const LinearProgressIndicator(),
            if (service.failure != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  weatherFailureMessage(l, service.failure!, config.source),
                ),
              ),
            if (service.updatedAt != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${service.stale ? l.weatherStale : l.weatherUpdated}: ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(service.updatedAt!))}',
                ),
              ),
            SettingsHelp(text: switch (config.source) {WeatherSource.openMeteo => l.weatherOpenMeteoCredit, WeatherSource.openWeather => l.weatherOpenWeatherCredit, _ => l.weatherYandexCredit}),
          ] else
            SettingsHelp(text: l.breezyWeatherSetupHint),
          RoundedSwitchListTile(
            value: settings.showWeatherWarnings,
            onChanged: settings.setShowWeatherWarnings,
            title: Text(l.showWeatherWarnings),
          ),
          FocusableSettingsTile(
            title: Text(
              '${l.temperatureUnit}: ${settings.useFahrenheit ? l.fahrenheit : l.celsius}',
            ),
            onPressed: () => settings.setTemperatureUnit(
              settings.useFahrenheit
                  ? TEMPERATURE_UNIT_CELSIUS
                  : TEMPERATURE_UNIT_FAHRENHEIT,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _automaticLocation(
    BuildContext context,
    WeatherService service,
  ) async {
    final l = AppLocalizations.of(context)!;
    try {
      await service.locateAutomatically();
      if (!context.mounted) return;
    } on PlatformException catch (error) {
      if (context.mounted) {
        showActionNotice(
          context,
          error.code == 'LOCATION_PERMISSION_DENIED'
              ? l.weatherLocationPermissionDenied
              : l.weatherLocationUnavailable,
          error: true,
        );
      }
    } catch (_) {
      if (context.mounted) {
        showActionNotice(context, l.weatherLocationUnavailable, error: true);
      }
    }
  }

  Future<void> _location(BuildContext context, WeatherService service) async {
    final l = AppLocalizations.of(context)!;
    final result = await showLauncherDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => CitySearchDialog(searchCities: service.searchCities),
    );
    if (result != null) {
      final config = service.configuration.copyWith(
        locationMode: WeatherLocationMode.manual,
        location: result['city'] as String?,
        cityLatitude: (result['latitude'] as num?)?.toDouble(),
        cityLongitude: (result['longitude'] as num?)?.toDouble(),
      );
      if (!config.validCityCoordinates || config.location.trim().isEmpty) {
        if (context.mounted) {
          showActionNotice(context, l.weatherLocationUnavailable, error: true);
        }
        return;
      }
      await service.configure(config);
    }
  }

  Future<void> _key(
    BuildContext context,
    WeatherService service,
    WeatherSource source,
  ) async {
    final l = AppLocalizations.of(context)!;
    final result = await showLauncherDialog<String>(
      context: context,
      builder: (_) => _WeatherKeyDialog(
        title: source == WeatherSource.openWeather
            ? l.weatherOpenWeatherKey
            : l.weatherApiKey,
        helper: l.weatherKeyPrivate,
        input: _remoteInput,
      ),
    );
    if (result != null) {
      try {
        await service.setApiKey(result, source: source);
        if (service.canRefresh) await service.refresh();
      } catch (_) {
        if (context.mounted) {
          showActionNotice(context, l.weatherUnavailable, error: true);
        }
      }
    }
  }

  Widget _remoteInput(TextField field) =>
      RemoteTextInput(traverseWhenHidden: false, child: field);
}

class _WeatherKeyDialog extends StatefulWidget {
  final String title, helper;
  final Widget Function(TextField) input;
  const _WeatherKeyDialog({
    required this.title,
    required this.helper,
    required this.input,
  });
  @override
  State<_WeatherKeyDialog> createState() => _WeatherKeyDialogState();
}

class _WeatherKeyDialogState extends State<_WeatherKeyDialog> {
  final controller = TextEditingController();
  final okFocus = FocusNode();
  @override
  void dispose() {
    controller.dispose();
    okFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LauncherAlertDialog(
    title: Text(widget.title),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [widget.input(TextField(
        autofocus: true,
        obscureText: true,
        maxLength: 1024,
        enableSuggestions: false,
        autocorrect: false,
        controller: controller,
        textInputAction: TextInputAction.done,
        onEditingComplete: () {
          SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
          okFocus.requestFocus();
        },
        decoration: const InputDecoration(),
      ),
    ),
    SettingsHelp(text: widget.helper)],
    ),
    actions: [
      LauncherDialogButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      LauncherDialogButton(
        primary: true,
        focusNode: okFocus,
        onPressed: () => Navigator.pop(context, controller.text),
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}

String weatherFailureMessage(
  AppLocalizations l,
  WeatherFailure failure,
  WeatherSource source,
) => switch (failure) {
  WeatherFailure.coordinates => l.weatherCoordinatesError,
  WeatherFailure.cityNotFound => l.weatherCityNotFound,
  WeatherFailure.keyRequired =>
    source == WeatherSource.openWeather
        ? l.weatherSourceKeyRequired
        : l.weatherKeyRequired,
  WeatherFailure.authorization => l.weatherAuthorizationError,
  WeatherFailure.rateLimit => l.weatherRateLimit,
  WeatherFailure.unavailable => l.weatherUnavailable,
  WeatherFailure.invalidResponse => l.weatherInvalidResponse,
};
