import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../information_formats.dart';
import '../../information_placement.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/appearance_service.dart';
import '../../providers/settings_service.dart';
import '../../providers/weather_service.dart';
import '../../weather_sources.dart';
import '../action_notice.dart';
import '../launcher_dialog.dart';
import '../rounded_switch_list_tile.dart';
import 'settings_choice_tile.dart';
import 'focusable_settings_tile.dart';
import 'information_preview.dart';
import 'settings_panel_presentation.dart';
import 'weather_text_format_dialog.dart';

class InformationWeatherFormatTile extends StatelessWidget {
  const InformationWeatherFormatTile({super.key});
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final options = settings.informationWeather();
    final appearance = context.watch<AppearanceService>().appearance;
    final background = InformationPlacement(
      appearance,
      settings,
    ).onBackground('weather');
    final composition = InformationPanelComposition(appearance, settings);
    return FocusableSettingsTile(
      title: Text(l.weatherTextFormat),
      valueIcon: Icons.edit_outlined,
      onPressed: () async {
        final result = await SettingsPanelPresentation.runHidden(
          context,
          () => showLauncherDialog<WeatherDisplayOptions>(
            context: context,
            parentPanelHidden: true,
            parentPanelWidth: 0,
            builder: (_) => Consumer<WeatherService?>(builder: (_, weatherService, _) => WeatherTextFormatDialog(
              background: background,
              format: options.format,
              source: weatherService == null
                  ? null
                  : weatherDataSource(weatherService.configuration.source, weatherService.weatherData),
              missingAsDash: options.missingAsDash,
              panelAlignment: options.panelAlignment,
              fahrenheit: options.fahrenheit,
              warnings: options.warnings,
              weather: weatherService?.weatherData,
              singleLine:
                  !background &&
                  composition.combined &&
                  composition.members.contains('date'),
              previewBuilder: (options, compact) => InformationPreview(
                background: background,
                dense: true,
                compact: compact,
                weatherOptions: options,
              ),
            )),
          ),
        );
        if (result == null || !context.mounted) return;
        try {
          await settings.setInformationWeather(result);
        } catch (_) {
          if (context.mounted) {
            showActionNotice(context, l.weatherTextSaveError, error: true);
          }
        }
      },
    );
  }
}

/// Display options live beside the format editor, outside its draft.
class WeatherFormatOptionsTiles extends StatelessWidget {
  const WeatherFormatOptionsTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final settings = context.watch<SettingsService>();
    final options = settings.informationWeather();
    Future<void> save(WeatherDisplayOptions value) async {
      try {
        await settings.setInformationWeather(value);
      } catch (_) {
        if (context.mounted) showActionNotice(context, l.weatherTextSaveError, error: true);
      }
    }
    return Column(children: [
      RoundedSwitchListTile(
        key: const Key('weather_missing_as_dash'),
        title: Text(l.weatherMissingAsDash),
        value: options.missingAsDash,
        onChanged: (value) => save(settings.informationWeather().copyWith(missingAsDash: value)),
      ),
      SettingsChoiceTile<String>(
        key: const Key('weather_panel_alignment'),
        title: l.weatherPanelAlignment,
        value: options.panelAlignment,
        options: const ['left', 'center', 'right'],
        label: (value) => switch (value) {
          'left' => l.settingsMenuLeft,
          'right' => l.settingsMenuRight,
          _ => l.selectionCenter,
        },
        onChanged: (value) => save(settings.informationWeather().copyWith(panelAlignment: value)),
      ),
    ]);
  }
}
