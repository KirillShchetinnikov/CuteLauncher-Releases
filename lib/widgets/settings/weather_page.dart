import 'settings_information.dart';
import 'settings_read_only_value.dart';
import 'settings_section.dart';
import 'settings_help.dart';
import '../remote_text_input.dart';
import 'city_search_dialog.dart';

import 'package:flauncher/widgets/launcher_dialog.dart';

import 'settings_value_stepper.dart';
import 'settings_choice_tile.dart';

import 'package:flauncher/widgets/action_notice.dart';

import 'settings_page_layout.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/weather_service.dart';
import '../../document_files.dart';
import '../../diagnostics_store.dart';
import '../../weather_sources.dart';
import 'focusable_settings_tile.dart';
import '../../providers/appearance_service.dart';

String _updatedLabel(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final now = DateTime.now();
  final l = MaterialLocalizations.of(context);
  final time = l.formatTimeOfDay(TimeOfDay.fromDateTime(local));
  return DateUtils.isSameDay(now, local)
      ? time
      : '${l.formatCompactDate(local)} $time';
}

class WeatherPage extends StatefulWidget {
  static const routeName = 'weather_panel';
  const WeatherPage({super.key});
  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

enum _WeatherImport { server, serverToken, apiKey }

enum _WeatherImportStage { read, validate, save }

class _WeatherPageState extends State<WeatherPage> {
  _WeatherImport? _importing;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final service = context.watch<WeatherService>();
    final config = service.configuration;
    final appearanceService = context.watch<AppearanceService>();
    final appearance = appearanceService.appearance;
    final names = {
      WeatherSource.breezy: 'Breezy Weather',
      WeatherSource.openMeteo: 'Open-Meteo',
      WeatherSource.customOpenMeteo: l.weatherCustomServer,
      WeatherSource.metNorway: 'MET Norway',
      WeatherSource.yandex: l.yandexWeather,
      WeatherSource.openWeather: 'OpenWeather',
      WeatherSource.gismeteo: 'Gismeteo',
    };
    final custom = config.source == WeatherSource.customOpenMeteo;
    final server = config.server;
    Widget refreshControl() => FocusableSettingsTile(
      leading: const Icon(Icons.refresh),
      title: Text(custom ? l.weatherCheckConnection : l.weatherRefresh),
      enabled: service.canRefresh,
      busy: service.loading || service.locating,
      onPressed: service.loading || service.locating || !service.canRefresh
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
                  showActionNotice(context, l.weatherUnavailable, error: true);
                }
              }
            },
    );
    return SettingsPageLayout(
      title: Text(
        l.weatherSettings,
        style: Theme.of(context).textTheme.titleLarge,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SettingsSection(
            key: const ValueKey('settingsGroupSourceAccess'),
            title: l.settingsGroupSourceAccess,
            children: [
              SettingsChoiceTile<WeatherSource>(
                autofocus: true,
                title: l.weatherSource,
                value: config.source,
                busy: service.loading || service.locating || _importing != null,
                options: const [
                  WeatherSource.openMeteo,
                  WeatherSource.customOpenMeteo,
                  WeatherSource.metNorway,
                  WeatherSource.openWeather,
                  WeatherSource.yandex,
                  WeatherSource.gismeteo,
                  WeatherSource.breezy,
                ],
                label: (v) => names[v]!,
                onChanged: (v) => service.configure(config.copyWith(source: v)),
              ),
              if (config.source != WeatherSource.breezy) ...[
                if (custom) ...[
                  FocusableSettingsTile(
                    title: Text(l.weatherServerUrl),
                    trailing: Text(
                      server?.toString() ?? l.settingsValueNotSet,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                    ),
                    valueIcon: Icons.edit_outlined,
                    onPressed: service.loading || _importing != null
                        ? null
                        : () => _server(context, service),
                  ),
                  _importTile(context, service, _WeatherImport.server),
                ],
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
                    onPressed: service.loading || _importing != null
                        ? null
                        : () => _key(context, service, config.source),
                  ),
                  _importTile(context, service, _WeatherImport.apiKey),
                ],
                if (custom && server != null) ...[
                  FocusableSettingsTile(
                    valueIcon: Icons.edit_outlined,
                    trailing: FutureBuilder<bool>(
                      future: service.hasServerToken(server),
                      builder: (_, snapshot) =>
                          Text(snapshot.data == true ? '••••••' : '—'),
                    ),
                    title: Text(l.weatherServerToken),
                    onPressed: service.loading || _importing != null
                        ? null
                        : () => _serverToken(context, service, server),
                  ),
                  _importTile(context, service, _WeatherImport.serverToken),
                ],
                if (custom) refreshControl(),
              ],
              if (config.source == WeatherSource.breezy)
                SettingsHelp(
                  title: 'Breezy Weather',
                  text: l.breezyWeatherSetupHint,
                ),
            ],
          ),
          if (!custom && config.source != WeatherSource.breezy)
            SettingsSection(
              key: const ValueKey('weatherLocation'),
              title: l.weatherLocation,
              children: [
                if (!custom) ...[
                  SettingsChoiceTile<WeatherLocationMode>(
                    title: l.weatherLocation,
                    value: config.locationMode,
                    options: WeatherLocationMode.values,
                    busy: service.loading || service.locating,
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
                      busy: service.loading || service.locating,
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
                ],
                if (config.source == WeatherSource.gismeteo)
                  FocusableSettingsTile(
                    title: Text(l.weatherServerCoordinates),
                    valueIcon: Icons.edit_outlined,
                    onPressed: service.loading || service.locating
                        ? null
                        : () => _coordinates(context, service),
                  ),
                SizedBox(
                  child: service.locating
                      ? const LinearProgressIndicator()
                      : null,
                ),
              ],
            ),
          if (config.source != WeatherSource.breezy)
            SettingsSection(
              key: const ValueKey('settingsGroupUpdate'),
              title: l.settingsGroupUpdate,
              children: [
                SettingsValueStepper(
                  title: l.weatherInterval,
                  options: const [30, 60, 120, 180],
                  value: config.intervalMinutes,
                  busy: service.loading,
                  label: (v) => '$v ${l.weatherMinutes}',
                  onChanged: (v) => service.configure(
                    config.copyWith(intervalMinutes: v as int),
                  ),
                ),
                if (!custom) refreshControl(),
                SizedBox(
                  child: service.loading
                      ? const LinearProgressIndicator()
                      : null,
                ),
                if (service.failure != null &&
                    !(custom &&
                        server == null &&
                        service.failure == WeatherFailure.serverAddress))
                  SettingsMessage(
                    text: weatherFailureMessage(
                      l,
                      service.failure!,
                      config.source,
                    ),
                    kind: SettingsMessageKind.error,
                  ),
                if (service.updatedAt != null)
                  SettingsReadOnlyValue(
                    label: service.stale ? l.weatherStale : l.weatherUpdated,
                    value: _updatedLabel(context, service.updatedAt!),
                    wrapLines: true,
                  ),
              ],
            ),
          if (config.source != WeatherSource.breezy)
            SettingsHelp(
              title: '${l.weatherSource}: ${names[config.source]}',
              text: [
                if (config.source == WeatherSource.openWeather)
                  l.weatherOpenWeatherHint,
                if (config.source == WeatherSource.yandex) l.weatherYandexHint,
                switch (config.source) {
                  WeatherSource.metNorway => l.weatherMetNorwayCredit,
                  WeatherSource.openMeteo => l.weatherOpenMeteoCredit,
                  WeatherSource.customOpenMeteo => l.weatherServerUrlHint,
                  WeatherSource.openWeather => l.weatherOpenWeatherCredit,
                  WeatherSource.gismeteo => '© Gismeteo',
                  _ => l.weatherYandexCredit,
                },
              ].join('\n\n'),
            ),
          SettingsSection(
            key: const ValueKey('widgetSettings'),
            title: l.widgetSettings,
            children: [
              SettingsValueStepper(
                title: l.weatherForecastPeriod,
                options: const [3, 5, 7],
                value: appearance.forecastDays,
                label: (value) => l.weatherForecastDays(value as int),
                onChanged: (value) async {
                  await appearanceService.set('panelForecastDays', value);
                  if (custom) await service.refreshForecastDays();
                },
              ),
              SettingsChoiceTile<String>(
                title: l.weatherForecastView,
                value: appearance.detailedForecast ? 'list' : 'cards',
                options: const ['cards', 'list'],
                label: (value) => value == 'cards'
                    ? l.weatherForecastCards
                    : l.weatherForecastList,
                onChanged: (value) =>
                    appearanceService.set('panelForecastView', value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _server(BuildContext context, WeatherService service) async {
    final l = AppLocalizations.of(context)!;
    final result = await showLauncherDialog<String>(
      context: context,
      builder: (_) => _WeatherInputDialog(
        title: l.weatherServerUrl,
        helper: l.weatherServerUrlHint,
        initialValue: service.configuration.server?.toString() ?? '',
        validator: (value) =>
            parseWeatherServer(value) == null ? l.weatherServerUrlHint : null,
        input: _remoteInput,
        maxLength: 2048,
        keyboardType: TextInputType.url,
      ),
    );
    if (result != null && context.mounted) {
      final server = parseWeatherServer(result)!;
      await service.configure(service.configuration.copyWith(server: server));
    }
  }

  Widget _importTile(
    BuildContext context,
    WeatherService service,
    _WeatherImport kind,
  ) {
    final l = AppLocalizations.of(context)!;
    return FocusableSettingsTile(
      title: Text(
        kind == _WeatherImport.server
            ? l.weatherServerUrlImport
            : l.weatherServerTokenImport,
      ),
      leading: const Icon(Icons.file_open_outlined),
      trailing: _importing == kind ? const Icon(Icons.hourglass_top) : null,
      onPressed: service.loading || _importing != null
          ? null
          : () => _importValue(context, service, kind),
    );
  }

  Future<void> _importValue(
    BuildContext context,
    WeatherService service,
    _WeatherImport kind,
  ) async {
    if (_importing != null) return;
    final l = AppLocalizations.of(context)!;
    final config = service.configuration;
    setState(() => _importing = kind);
    var stage = _WeatherImportStage.read;
    try {
      final value =
          (await (kind == _WeatherImport.server
                  ? DocumentFiles.pickWeatherServerText(context)
                  : DocumentFiles.pickWeatherTokenText(context)))
              ?.trim();
      if (!context.mounted ||
          value == null ||
          service.configuration.source != config.source ||
          service.configuration.server != config.server) {
        return;
      }
      stage = _WeatherImportStage.validate;
      switch (kind) {
        case _WeatherImport.server:
          final server = parseWeatherServer(value);
          if (server == null) {
            throw const FormatException('Invalid weather server');
          }
          stage = _WeatherImportStage.save;
          await service.configure(
            service.configuration.copyWith(server: server),
          );
        case _WeatherImport.serverToken:
          if (!isWeatherBearerToken(value)) {
            throw const FormatException('Invalid weather token');
          }
          stage = _WeatherImportStage.save;
          await service.setServerToken(config.server!, value);
        case _WeatherImport.apiKey:
          if (value.isEmpty ||
              value.length > 1024 ||
              RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(value)) {
            throw const FormatException('Invalid weather key');
          }
          stage = _WeatherImportStage.save;
          await service.setApiKey(value, source: config.source);
      }
      if (context.mounted) showActionNotice(context, l.actionCompleted);
    } catch (error) {
      final (reason, message) = switch (stage) {
        _WeatherImportStage.read
            when error is PlatformException &&
                error.code == 'document_too_large' =>
          ('weather_import_too_large', l.weatherImportTooLargeError),
        _WeatherImportStage.read when error is FormatException => (
          'weather_import_encoding',
          l.weatherImportEncodingError,
        ),
        _WeatherImportStage.read => (
          'weather_import_read',
          l.weatherImportReadError,
        ),
        _WeatherImportStage.validate => (
          'weather_import_format',
          kind == _WeatherImport.server
              ? l.weatherServerUrlImportError
              : l.weatherServerTokenImportError,
        ),
        _WeatherImportStage.save => (
          'weather_import_save',
          l.weatherImportSaveError,
        ),
      };
      // Fixed categories only: exceptions can contain file bytes or credentials.
      DiagnosticsStore.instance.record(
        'dart',
        'weatherImport',
        'error',
        'operation_failed',
        context: {
          'details': {'reason': reason},
        },
      );
      if (context.mounted) {
        showActionNotice(context, message, error: true);
      }
    } finally {
      if (mounted) setState(() => _importing = null);
    }
  }

  Future<void> _coordinates(
    BuildContext context,
    WeatherService service,
  ) async {
    final l = AppLocalizations.of(context)!;
    (double, double)? parse(String value) {
      final parts = value.split(',');
      if (parts.length != 2) return null;
      final lat = double.tryParse(parts[0].trim());
      final lon = double.tryParse(parts[1].trim());
      if (!WeatherConfiguration(
        latitude: lat,
        longitude: lon,
      ).validCoordinates) {
        return null;
      }
      return (lat!, lon!);
    }

    final config = service.configuration;
    final result = await showLauncherDialog<String>(
      context: context,
      builder: (_) => _WeatherInputDialog(
        title: l.weatherServerCoordinates,
        helper: l.weatherServerCoordinatesHint,
        initialValue: config.validCoordinates
            ? '${config.latitude}, ${config.longitude}'
            : '',
        validator: (value) =>
            parse(value) == null ? l.weatherServerCoordinatesHint : null,
        input: _remoteInput,
        maxLength: 64,
      ),
    );
    if (result != null && context.mounted) {
      final (lat, lon) = parse(result)!;
      await service.configure(
        service.configuration.copyWith(
          latitude: lat,
          longitude: lon,
          locationMode: WeatherLocationMode.automatic,
        ),
      );
    }
  }

  Future<void> _serverToken(
    BuildContext context,
    WeatherService service,
    Uri server,
  ) async {
    final l = AppLocalizations.of(context)!;
    final result = await showLauncherDialog<String>(
      context: context,
      builder: (_) => _WeatherInputDialog(
        title: l.weatherServerToken,
        helper: l.weatherKeyPrivate,
        input: _remoteInput,
        secret: true,
        validator: (value) =>
            value.trim().isEmpty || isWeatherBearerToken(value.trim())
            ? null
            : l.weatherTokenInvalid,
      ),
    );
    if (result == null ||
        !context.mounted ||
        service.configuration.source != WeatherSource.customOpenMeteo ||
        service.configuration.server != server) {
      return;
    }
    try {
      await service.setServerToken(server, result);
    } catch (_) {
      if (context.mounted) {
        showActionNotice(context, l.weatherImportSaveError, error: true);
      }
    }
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
      builder: (_) => _WeatherInputDialog(
        title: source == WeatherSource.openWeather
            ? l.weatherOpenWeatherKey
            : l.weatherApiKey,
        helper: l.weatherKeyPrivate,
        input: _remoteInput,
        secret: true,
      ),
    );
    if (result != null) {
      try {
        await service.setApiKey(result, source: source);
      } catch (_) {
        if (context.mounted) {
          showActionNotice(context, l.weatherImportSaveError, error: true);
        }
      }
    }
  }

  Widget _remoteInput(TextField field) => RemoteTextInput(child: field);
}

class _WeatherInputDialog extends StatefulWidget {
  final String title, helper;
  final Widget Function(TextField) input;
  final String initialValue;
  final String? Function(String)? validator;
  final bool secret;
  final int maxLength;
  final TextInputType? keyboardType;
  const _WeatherInputDialog({
    required this.title,
    required this.helper,
    required this.input,
    this.initialValue = '',
    this.validator,
    this.secret = false,
    this.maxLength = 1024,
    this.keyboardType,
  });
  @override
  State<_WeatherInputDialog> createState() => _WeatherInputDialogState();
}

class _WeatherInputDialogState extends State<_WeatherInputDialog> {
  late final controller = TextEditingController(text: widget.initialValue);
  final okFocus = FocusNode();
  String? error;
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
      children: [
        widget.input(
          TextField(
            autofocus: true,
            obscureText: widget.secret,
            maxLength: widget.maxLength,
            keyboardType: widget.keyboardType,
            textDirection: TextDirection.ltr,
            enableSuggestions: false,
            autocorrect: false,
            controller: controller,
            textInputAction: TextInputAction.done,
            onEditingComplete: () {
              SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
              okFocus.requestFocus();
            },
            decoration: InputDecoration(errorText: error, errorMaxLines: 3),
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
          ),
        ),
        SettingsHelp(title: widget.title, text: widget.helper),
      ],
    ),
    actions: [
      LauncherDialogButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      LauncherDialogButton(
        primary: true,
        focusNode: okFocus,
        onPressed: () {
          final message = widget.validator?.call(controller.text);
          if (message != null) {
            setState(() => error = message);
          } else {
            Navigator.pop(context, controller.text);
          }
        },
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
  WeatherFailure.authorization => switch (source) {
    WeatherSource.customOpenMeteo => l.weatherServerAccessError,
    WeatherSource.gismeteo => l.weatherUnavailable,
    _ => l.weatherAuthorizationError,
  },
  WeatherFailure.rateLimit => l.weatherRateLimit,
  WeatherFailure.unavailable => l.weatherUnavailable,
  WeatherFailure.invalidResponse => l.weatherInvalidResponse,
  WeatherFailure.serverAddress => l.weatherServerUrlHint,
  WeatherFailure.parameters => l.weatherServerParametersError,
};
